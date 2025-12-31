# 完整应用 Dockerfile
# 包含后端和前端的完整应用

# ============================================
# 阶段 1: 构建前端
# ============================================
FROM node:22-alpine AS frontend-builder
WORKDIR /app/frontend

ARG VERSION=1.0.0
ARG BUILD_DATE
ARG COMMIT_SHA
ARG VITE_API_BASE_URL=/api/v1

ENV NODE_ENV=production \
    VERSION=${VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    COMMIT_SHA=${COMMIT_SHA} \
    VITE_API_BASE_URL=${VITE_API_BASE_URL}

# 安装构建依赖
RUN apk add --no-cache python3 make g++

COPY frontend/package*.json ./
# 安装所有依赖（包括 devDependencies）用于构建
RUN npm install --include=dev && npm cache clean --force

COPY frontend/ ./
RUN npm run build

# ============================================
# 阶段 2: 准备后端
# ============================================
FROM node:22-alpine AS backend-builder
WORKDIR /app/backend

ARG VERSION=1.0.0
ARG BUILD_DATE
ARG COMMIT_SHA
ARG NODE_ENV=production

ENV NODE_ENV=${NODE_ENV} \
    VERSION=${VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    COMMIT_SHA=${COMMIT_SHA}

# 安装系统依赖
RUN apk add --no-cache \
    python3 \
    py3-pip \
    tesseract-ocr \
    imagemagick \
    postgresql-client \
    bash \
    curl

# 手动安装 tesseract 中文和英文语言包
RUN mkdir -p /usr/share/tessdata && \
    apk add --no-cache tesseract-ocr-data && \
    wget -q --tries=3 --timeout=30 https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/chi_sim.traineddat -O /usr/share/tessdata/chi_sim.traineddat || echo "Warning: chi_sim.traineddat download failed" && \
    wget -q --tries=3 --timeout=30 https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/eng.traineddat -O /usr/share/tessdata/eng.traineddat && \
    ls -la /usr/share/tessdata || echo "Warning: Some tessdata files may be missing"

COPY backend/package*.json ./
RUN npm install --omit=dev && npm cache clean --force

COPY backend/ ./

# ============================================
# 阶段 3: 生产镜像
# ============================================
FROM node:22-alpine AS production

ARG VERSION=1.0.0
ARG BUILD_DATE
ARG COMMIT_SHA

# 添加标签
LABEL maintainer="727566105" \
      version=${VERSION} \
      description="videoAll 完整应用" \
      org.opencontainers.image.title="videoAll" \
      org.opencontainers.image.description="内容解析、管理与热点发现系统" \
      org.opencontainers.image.version=${VERSION} \
      org.opencontainers.image.created=${BUILD_DATE} \
      org.opencontainers.image.revision=${COMMIT_SHA} \
      org.opencontainers.image.source="https://github.com/727566105/videoAll"

# 安装系统依赖
RUN apk add --no-cache \
    python3 \
    py3-pip \
    tesseract-ocr \
    imagemagick \
    postgresql-client \
    nginx \
    curl \
    dumb-init \
    bash

# 手动安装 tesseract 中文和英文语言包
RUN mkdir -p /usr/share/tessdata && \
    apk add --no-cache tesseract-ocr-data && \
    wget -q --tries=3 --timeout=30 https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/chi_sim.traineddat -O /usr/share/tessdata/chi_sim.traineddat || echo "Warning: chi_sim.traineddat download failed" && \
    wget -q --tries=3 --timeout=30 https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/eng.traineddat -O /usr/share/tessdata/eng.traineddat && \
    ls -la /usr/share/tessdata || echo "Warning: Some tessdata files may be missing"

# 设置 Python
RUN ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /app

# 从构建阶段复制后端
COPY --from=backend-builder /app/backend /app/backend

# 从构建阶段复制前端
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# 复制 Nginx 配置
COPY --chown=node:node frontend/docker/nginx.conf /etc/nginx/nginx.conf

# 创建必要的目录
RUN mkdir -p /app/logs /app/media /app/uploads /app/backups /app/config && \
    chown -R node:node /app && \
    chown -R node:node /var/lib/nginx && \
    chown -R node:node /var/log/nginx

# 复制启动脚本
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 切换到非 root 用户
USER node

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || \
        wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# 暴露端口
EXPOSE 3000 80

# 使用 entrypoint 启动
ENTRYPOINT ["dumb-init", "--"]
CMD ["docker-entrypoint.sh"]

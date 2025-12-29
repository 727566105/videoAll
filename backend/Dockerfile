# 后端 Dockerfile
# 多阶段构建，优化镜像大小

# ============================================
# 阶段 1: 基础依赖安装
# ============================================
FROM node:20-alpine AS base
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    python3 \
    py3-pip \
    tesseract-ocr \
    tesseract-ocr-data-chi-sim \
    tesseract-ocr-data-eng \
    imagemagick \
    postgresql-client \
    curl \
    bash

# 设置 Python 为默认
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ============================================
# 阶段 2: 依赖构建
# ============================================
FROM base AS dependencies
WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装生产依赖
RUN npm ci --only=production && \
    npm cache clean --force

# ============================================
# 阶段 3: 开发环境（可选）
# ============================================
FROM base AS development
WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装所有依赖（包括开发依赖）
RUN npm install

# 复制源代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动开发服务器
CMD ["npm", "run", "dev"]

# ============================================
# 阶段 4: 生产环境构建
# ============================================
FROM base AS production
WORKDIR /app

# 构建参数
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG COMMIT_SHA
ARG NODE_ENV=production

# 设置环境变量
ENV NODE_ENV=${NODE_ENV} \
    VERSION=${VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    COMMIT_SHA=${COMMIT_SHA}

# 添加标签
LABEL maintainer="727566105" \
      version=${VERSION} \
      description="videoAll 后端服务" \
      org.opencontainers.image.title="videoAll Backend" \
      org.opencontainers.image.description="内容解析、管理与热点发现系统后端" \
      org.opencontainers.image.version=${VERSION} \
      org.opencontainers.image.created=${BUILD_DATE} \
      org.opencontainers.image.revision=${COMMIT_SHA} \
      org.opencontainers.image.source="https://github.com/727566105/videoAll"

# 从依赖阶段复制 node_modules
COPY --from=dependencies /app/node_modules ./node_modules

# 复制源代码和配置文件
COPY . .

# 创建必要的目录
RUN mkdir -p /app/logs /app/media /app/uploads /app/backups /app/config && \
    chown -R node:node /app

# 切换到非 root 用户
USER node

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# 暴露端口
EXPOSE 3000

# 启动生产服务器
CMD ["node", "src/server.js"]

# 前端 Dockerfile
# 多阶段构建，优化镜像大小

# ============================================
# 阶段 1: 构建阶段
# ============================================
FROM node:18-alpine AS builder
WORKDIR /app

# 构建参数
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG COMMIT_SHA
ARG VITE_API_BASE_URL=/api/v1

# 设置环境变量
ENV NODE_ENV=production \
    VERSION=${VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    COMMIT_SHA=${COMMIT_SHA} \
    VITE_API_BASE_URL=${VITE_API_BASE_URL} \
    PNPM_VERSION=8

# 安装 pnpm（可选）
RUN npm install -g pnpm@${PNPM_VERSION}

# 复制 package 文件
COPY package*.json ./

# 安装依赖
RUN npm ci && \
    npm cache clean --force

# 复制源代码
COPY . .

# 构建生产版本
RUN npm run build && \
    ls -la dist/

# ============================================
# 阶段 2: 生产环境（使用 Nginx）
# ============================================
FROM nginx:1.25-alpine AS production

# 构建参数
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG COMMIT_SHA

# 添加标签
LABEL maintainer="727566105" \
      version=${VERSION} \
      description="videoAll 前端服务" \
      org.opencontainers.image.title="videoAll Frontend" \
      org.opencontainers.image.description="内容解析、管理与热点发现系统前端" \
      org.opencontainers.image.version=${VERSION} \
      org.opencontainers.image.created=${BUILD_DATE} \
      org.opencontainers.image.revision=${COMMIT_SHA} \
      org.opencontainers.image.source="https://github.com/727566105/videoAll"

# 从构建阶段复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制 Nginx 配置文件
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# 创建非 root 用户
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /usr/share/nginx/html -s /sbin/nologin -G nginx -g nginx nginx && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# 切换到非 root 用户
USER nginx

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# 启动 Nginx（前台运行）
CMD ["nginx", "-g", "daemon off;"]

# ============================================
# 阶段 3: 开发环境（可选）
# ============================================
FROM node:18-alpine AS development
WORKDIR /app

# 安装开发工具
RUN apk add --no-cache git bash

# 复制 package 文件
COPY package*.json ./

# 安装所有依赖（包括开发依赖）
RUN npm install

# 复制源代码
COPY . .

# 暴露端口
EXPOSE 5173

# 启动开发服务器
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]

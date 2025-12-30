# 多阶段构建 - 后端服务
FROM node:22-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖（包括 tesseract.js）
RUN npm install && npm cache clean --force

# 生产阶段
FROM node:22-alpine AS production

# 安装必要的系统依赖（Python 3、OCR、图像处理库）
RUN apk add --no-cache \
    postgresql-client \
    curl \
    python3 \
    py3-pip \
    tesseract-ocr \
    tesseract-ocr-data-chi_sim \
    tesseract-ocr-data-eng \
    imagemagick \
    ffmpeg \
    && rm -rf /var/cache/apk/*

# 升级 pip 并安装基础 Python 工具
RUN pip3 install --no-cache-dir --break-system-packages --upgrade pip setuptools wheel

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 设置工作目录
WORKDIR /app

# 从构建阶段复制依赖
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# 复制应用代码
COPY --chown=nodejs:nodejs . .

# 注意：Python SDK 需要在 docker-compose.yml 中通过 volumes 挂载
# 或者在构建时从项目根目录复制
# 这里我们选择在 docker-compose.yml 中挂载

# 创建必要的目录
RUN mkdir -p logs media backups tmp && \
    chown -R nodejs:nodejs logs media backups tmp

# 验证工具安装
RUN python3 --version && \
    tesseract --version && \
    ffmpeg -version | head -n 1 || true

# 注意：Python SDK 将在容器启动时通过 entrypoint 脚本安装
# 或者直接在运行时从挂载的卷中使用

# 切换到非root用户
USER nodejs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/v1/health || exit 1

# 启动命令
CMD ["node", "src/server.js"]
#!/bin/bash

# 本地构建前端脚本
# 避免 Docker 构建中的复杂依赖问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "🏗️ 本地构建前端"
echo "================"
echo ""

# 检查 Node.js 环境
log_step "检查 Node.js 环境"
if ! command -v node &> /dev/null; then
    log_error "Node.js 未安装"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    log_error "npm 未安装"
    exit 1
fi

log_info "Node.js 版本: $(node --version)"
log_info "npm 版本: $(npm --version)"

# 进入前端目录
cd frontend

# 清理旧的构建
log_step "清理旧的构建文件"
rm -rf dist node_modules package-lock.json

# 安装依赖
log_step "安装依赖"
log_info "正在安装 npm 依赖..."
if npm install; then
    log_info "✅ 依赖安装成功"
else
    log_error "❌ 依赖安装失败"
    exit 1
fi

# 构建项目
log_step "构建前端项目"
log_info "正在构建前端..."
if npm run build; then
    log_info "✅ 前端构建成功"
else
    log_error "❌ 前端构建失败"
    exit 1
fi

# 检查构建结果
if [ -d "dist" ]; then
    log_info "构建产物大小:"
    du -sh dist
    log_info "构建产物内容:"
    ls -la dist/
else
    log_error "构建产物目录不存在"
    exit 1
fi

echo ""
echo "🎉 前端构建完成！"
echo ""
echo "📋 接下来可以："
echo "1. 使用简化 Dockerfile 构建镜像:"
echo "   docker build -f Dockerfile.simple -t videoall-frontend ."
echo "2. 或者直接使用 dist 目录部署到 nginx"
echo ""
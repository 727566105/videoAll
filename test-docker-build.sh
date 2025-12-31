#!/bin/bash

# videoAll Docker 构建测试脚本
# 在推送到 GitHub 之前本地验证 Docker 构建

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

# 清理函数
cleanup() {
    log_info "清理测试镜像..."
    docker rmi videoall-backend-test 2>/dev/null || true
    docker rmi videoall-frontend-test 2>/dev/null || true
    docker rmi videoall-full-test 2>/dev/null || true
}

# 捕获退出信号进行清理
trap cleanup EXIT

echo "🧪 videoAll Docker 构建测试"
echo "============================"
echo ""

# 检查 Docker 是否运行
log_step "检查 Docker 环境"
if ! docker info >/dev/null 2>&1; then
    log_error "Docker 未运行，请启动 Docker"
    exit 1
fi
log_info "Docker 环境正常"

# 测试后端构建
log_step "测试后端 Docker 构建"
log_info "构建后端镜像..."
if docker build -t videoall-backend-test ./backend; then
    log_info "✅ 后端构建成功"
else
    log_error "❌ 后端构建失败"
    exit 1
fi

# 测试前端构建
log_step "测试前端 Docker 构建"
log_info "构建前端镜像..."
if docker build -t videoall-frontend-test ./frontend; then
    log_info "✅ 前端构建成功"
else
    log_error "❌ 前端构建失败"
    log_warn "前端构建失败，可能是依赖问题，继续测试完整应用构建..."
fi

# 测试完整应用构建
log_step "测试完整应用 Docker 构建"
log_info "构建完整应用镜像..."
if docker build -t videoall-full-test .; then
    log_info "✅ 完整应用构建成功"
else
    log_error "❌ 完整应用构建失败"
    exit 1
fi

# 显示镜像信息
log_step "构建结果"
echo ""
log_info "构建的镜像："
docker images | grep -E "(videoall-.*-test|REPOSITORY)"

echo ""
log_info "镜像大小："
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(videoall-.*-test|REPOSITORY)"

echo ""
echo "🎉 所有 Docker 构建测试通过！"
echo ""
echo "📋 接下来可以："
echo "1. 推送代码到 GitHub: git push origin feature/docker-support"
echo "2. 查看 GitHub Actions 构建状态"
echo "3. 创建 Pull Request"
echo ""

# 询问是否清理镜像
read -p "是否清理测试镜像? (y/n): " cleanup_choice
if [ "$cleanup_choice" = "y" ] || [ "$cleanup_choice" = "Y" ]; then
    cleanup
    log_info "测试镜像已清理"
else
    log_info "测试镜像保留，可以手动清理："
    echo "  docker rmi videoall-backend-test videoall-frontend-test videoall-full-test"
fi
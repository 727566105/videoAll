#!/bin/bash

# videoAll 部署验证脚本
# 此脚本帮助验证 Docker 部署是否成功

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

# 检查 Docker 是否安装
check_docker() {
    log_step "检查 Docker 环境"
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_info "Docker 环境检查通过"
}

# 检查环境变量文件
check_env_file() {
    log_step "检查环境变量配置"
    
    if [ ! -f ".env" ]; then
        log_warn ".env 文件不存在，正在创建..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_info ".env 文件已从模板创建"
            log_warn "请编辑 .env 文件配置数据库信息"
        else
            log_error ".env.example 文件不存在"
            exit 1
        fi
    else
        log_info ".env 文件存在"
    fi
}

# 检查服务状态
check_services() {
    log_step "检查服务状态"
    
    # 检查容器状态
    if docker-compose ps | grep -q "Up"; then
        log_info "发现运行中的服务"
        docker-compose ps
    else
        log_warn "没有运行中的服务"
    fi
}

# 启动服务
start_services() {
    log_step "启动 Docker 服务"
    
    log_info "正在启动服务..."
    docker-compose up -d
    
    log_info "等待服务启动..."
    sleep 30
    
    log_info "服务状态："
    docker-compose ps
}

# 验证服务健康状态
verify_health() {
    log_step "验证服务健康状态"
    
    # 检查后端健康状态
    log_info "检查后端服务..."
    if curl -f http://localhost:3000/api/v1/health &> /dev/null; then
        log_info "✅ 后端服务正常"
    else
        log_error "❌ 后端服务异常"
        log_info "后端日志："
        docker-compose logs --tail=20 backend
    fi
    
    # 检查前端服务
    log_info "检查前端服务..."
    if curl -f http://localhost:80/ &> /dev/null; then
        log_info "✅ 前端服务正常"
    else
        log_error "❌ 前端服务异常"
        log_info "前端日志："
        docker-compose logs --tail=20 frontend
    fi
    
    # 检查数据库连接
    log_info "检查数据库连接..."
    if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
        log_info "✅ 数据库连接正常"
    else
        log_error "❌ 数据库连接异常"
        log_info "数据库日志："
        docker-compose logs --tail=20 postgres
    fi
}

# 显示访问信息
show_access_info() {
    log_step "服务访问信息"
    
    echo ""
    echo "🎉 部署验证完成！"
    echo ""
    echo "📋 服务访问地址："
    echo "   前端应用: http://localhost:80"
    echo "   后端 API: http://localhost:3000"
    echo "   API 文档: http://localhost:3000/api-docs"
    echo "   健康检查: http://localhost:3000/api/v1/health"
    echo ""
    echo "🔧 管理命令："
    echo "   查看日志: docker-compose logs -f"
    echo "   重启服务: docker-compose restart"
    echo "   停止服务: docker-compose down"
    echo "   更新镜像: docker-compose pull && docker-compose up -d"
    echo ""
    echo "📚 更多信息："
    echo "   部署文档: DEPLOYMENT.md"
    echo "   Docker 指南: README.Docker.md"
    echo ""
}

# 主函数
main() {
    echo "🔍 videoAll 部署验证向导"
    echo "=========================="
    echo ""
    
    check_docker
    check_env_file
    check_services
    
    read -p "是否要启动服务? (y/n): " start_choice
    if [ "$start_choice" = "y" ] || [ "$start_choice" = "Y" ]; then
        start_services
        verify_health
        show_access_info
    else
        log_info "跳过服务启动"
    fi
}

# 检查是否在正确的目录
if [ ! -f "docker-compose.yml" ]; then
    log_error "请在 videoAll 项目根目录下运行此脚本"
    exit 1
fi

# 运行主函数
main "$@"
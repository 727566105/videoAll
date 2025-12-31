#!/bin/bash

# videoAll 快速部署脚本
# 一键下载配置文件并启动服务

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 和 Docker Compose
check_requirements() {
    log_info "检查系统要求..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_info "系统要求检查通过"
}

# 下载配置文件
download_configs() {
    log_info "下载配置文件..."
    
    # 下载 docker-compose.yml
    if ! curl -fsSL -o docker-compose.yml https://raw.githubusercontent.com/727566105/videoAll/main/docker-compose.yml; then
        log_error "下载 docker-compose.yml 失败"
        exit 1
    fi
    
    # 下载环境变量模板
    if ! curl -fsSL -o .env.example https://raw.githubusercontent.com/727566105/videoAll/main/.env.example; then
        log_error "下载 .env.example 失败"
        exit 1
    fi
    
    log_info "配置文件下载完成"
}

# 配置环境变量
setup_environment() {
    log_info "配置环境变量..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        log_warn "已创建 .env 文件，请编辑数据库配置"
        
        echo ""
        echo "请配置以下必需的环境变量："
        echo "1. POSTGRES_HOST - PostgreSQL 主机地址"
        echo "2. POSTGRES_USER - 数据库用户名"
        echo "3. POSTGRES_PASSWORD - 数据库密码"
        echo "4. JWT_SECRET - JWT 密钥"
        echo ""
        
        read -p "是否现在编辑 .env 文件? (y/n): " edit_env
        if [ "$edit_env" = "y" ] || [ "$edit_env" = "Y" ]; then
            ${EDITOR:-nano} .env
        fi
    else
        log_info ".env 文件已存在"
    fi
}

# 启动服务
start_services() {
    log_info "启动 videoAll 服务..."
    
    # 拉取最新镜像
    docker-compose pull
    
    # 启动服务
    docker-compose up -d
    
    log_info "服务启动完成"
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    sleep 10  # 等待服务启动
    
    # 检查容器状态
    docker-compose ps
    
    echo ""
    log_info "服务访问地址："
    log_info "前端界面: http://localhost:80"
    log_info "后端 API: http://localhost:3000"
    log_info "健康检查: http://localhost:3000/api/v1/health"
    
    # 测试健康检查
    if curl -f http://localhost:3000/api/v1/health &> /dev/null; then
        log_info "✅ 后端服务运行正常"
    else
        log_warn "⚠️  后端服务可能未完全启动，请稍后再试"
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo "🎉 videoAll 部署完成！"
    echo ""
    echo "📋 常用命令："
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo "  更新服务: docker-compose pull && docker-compose up -d"
    echo ""
    echo "📚 更多信息："
    echo "  部署文档: https://github.com/727566105/videoAll/blob/main/DEPLOYMENT.md"
    echo "  Docker 指南: https://github.com/727566105/videoAll/blob/main/README.Docker.md"
    echo ""
}

# 主函数
main() {
    echo "🚀 videoAll 快速部署向导"
    echo "========================="
    echo ""
    
    check_requirements
    download_configs
    setup_environment
    start_services
    check_services
    show_usage
}

# 运行主函数
main "$@"
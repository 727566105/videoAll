#!/bin/bash

# VideoAll Docker 快速启动脚本
# 用法: ./scripts/start.sh [环境]
# 环境: dev (开发) | prod (生产) | 默认: dev

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    print_success "Docker 和 Docker Compose 已安装"
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f .env ]; then
        print_warning ".env 文件不存在，正在从 .env.docker 创建..."

        if [ ! -f .env.docker ]; then
            print_error ".env.docker 文件不存在"
            exit 1
        fi

        cp .env.docker .env
        print_warning "请编辑 .env 文件，修改必要的配置（密码、密钥等）"
        print_warning "特别是在生产环境中，必须修改所有默认密钥！"

        read -p "是否现在编辑 .env 文件？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} .env
        fi
    else
        print_success ".env 文件已存在"
    fi
}

# 创建必要的目录
create_directories() {
    print_info "创建必要的目录..."

    mkdir -p backups
    mkdir -p logs

    print_success "目录创建完成"
}

# 启动服务
start_services() {
    local environment=$1

    print_info "启动 VideoAll 服务（环境: $environment）..."

    if [ "$environment" = "prod" ]; then
        docker-compose --profile production up -d
    else
        docker-compose up -d
    fi

    print_success "服务启动完成"
}

# 等待服务健康
wait_for_health() {
    print_info "等待服务健康检查..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker-compose exec -T backend curl -f http://localhost:3000/api/v1/health &> /dev/null; then
            print_success "后端服务已就绪"
            return 0
        fi

        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done

    echo
    print_warning "后端服务健康检查超时，但服务可能仍在启动中"
}

# 显示服务状态
show_status() {
    print_info "服务状态："
    echo ""
    docker-compose ps
    echo ""

    print_info "访问地址："
    echo "  前端: http://localhost"
    echo "  后端 API: http://localhost:3000/api/v1"
    echo "  默认账号: admin@example.com / admin123"
    echo ""
}

# 主函数
main() {
    local environment=${1:-dev}

    echo ""
    echo "=========================================="
    echo "  VideoAll Docker 启动脚本"
    echo "=========================================="
    echo ""

    # 检查 Docker
    check_docker
    echo ""

    # 检查环境变量文件
    check_env_file
    echo ""

    # 创建目录
    create_directories
    echo ""

    # 启动服务
    start_services "$environment"
    echo ""

    # 等待健康检查
    wait_for_health
    echo ""

    # 显示状态
    show_status

    print_success "VideoAll 启动完成！"
    echo ""
    print_info "查看日志: docker-compose logs -f"
    print_info "停止服务: docker-compose down"
    echo ""
}

# 执行主函数
main "$@"

#!/bin/bash

# VideoAll Docker 停止脚本
# 用法: ./scripts/stop.sh [--clean]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

stop_services() {
    print_info "停止 VideoAll 服务..."

    if docker-compose down; then
        print_success "服务已停止"
    else
        print_error "停止服务失败"
        exit 1
    fi
}

clean_volumes() {
    print_warning "警告：此操作将删除所有数据卷（数据库、媒体文件等）！"
    read -p "确定要继续吗？(yes/no) " -r

    if [[ $REPLY == "yes" ]]; then
        print_info "删除数据卷..."
        docker-compose down -v
        print_success "数据卷已删除"
    else
        print_info "取消删除数据卷"
    fi
}

main() {
    local clean_volumes_flag=false

    # 解析参数
    for arg in "$@"; do
        case $arg in
            --clean)
                clean_volumes_flag=true
                shift
                ;;
            *)
                ;;
        esac
    done

    echo ""
    echo "=========================================="
    echo "  VideoAll Docker 停止脚本"
    echo "=========================================="
    echo ""

    if [ "$clean_volumes_flag" = true ]; then
        clean_volumes
    else
        stop_services
    fi

    echo ""
    print_success "操作完成"
    echo ""
}

main "$@"

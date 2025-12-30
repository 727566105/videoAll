#!/bin/bash

# VideoAll 日志查看脚本
# 用法: ./scripts/logs.sh [服务名]

set -e

# 颜色定义
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 服务名称
SERVICE=${1:-}

echo ""
echo "=========================================="
echo "  VideoAll 日志查看"
echo "=========================================="
echo ""

if [ -z "$SERVICE" ]; then
    print_info "查看所有服务日志（按 Ctrl+C 退出）..."
    echo ""
    docker-compose logs -f
else
    print_info "查看 $SERVICE 服务日志（按 Ctrl+C 退出）..."
    echo ""
    docker-compose logs -f "$SERVICE"
fi

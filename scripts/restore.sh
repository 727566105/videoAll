#!/bin/bash

# VideoAll 数据恢复脚本
# 用法: ./scripts/restore.sh <备份文件类型> <备份文件>

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 显示使用方法
show_usage() {
    echo "用法: ./scripts/restore.sh <类型> <备份文件>"
    echo ""
    echo "类型:"
    echo "  db    - 恢复数据库"
    echo "  media - 恢复媒体文件"
    echo ""
    echo "示例:"
    echo "  ./scripts/restore.sh db backups/db_20250130_120000.sql"
    echo "  ./scripts/restore.sh media backups/media_20250130_120000.tar.gz"
    echo ""
    exit 1
}

# 检查参数
if [ $# -lt 2 ]; then
    show_usage
fi

RESTORE_TYPE=$1
BACKUP_FILE=$2

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

echo ""
echo "=========================================="
echo "  VideoAll 数据恢复脚本"
echo "=========================================="
echo ""

# 确认恢复操作
print_warning "警告：此操作将覆盖现有数据！"
read -p "确定要继续吗？(yes/no) " -r

if [[ ! $REPLY == "yes" ]]; then
    print_info "取消恢复操作"
    exit 0
fi

# 根据类型执行恢复
case $RESTORE_TYPE in
    db)
        print_info "开始恢复数据库..."
        print_info "备份文件: $BACKUP_FILE"

        # 停止后端服务（避免数据库连接冲突）
        print_info "停止后端服务..."
        docker-compose stop backend

        # 恢复数据库
        print_info "正在恢复数据库..."
        docker-compose exec -T postgres psql -U postgres video_all < "$BACKUP_FILE"

        # 重启后端服务
        print_info "重启后端服务..."
        docker-compose start backend

        print_success "数据库恢复完成！"
        ;;

    media)
        print_info "开始恢复媒体文件..."
        print_info "备份文件: $BACKUP_FILE"

        # 恢复媒体文件
        print_info "正在恢复媒体文件..."
        docker run --rm \
            -v videoall_media_data:/data \
            -v "$(pwd)/$(dirname $BACKUP_FILE):/backup" \
            alpine sh -c "cd /data && tar xzf /backup/$(basename $BACKUP_FILE)"

        print_success "媒体文件恢复完成！"
        ;;

    *)
        print_error "无效的恢复类型: $RESTORE_TYPE"
        echo ""
        show_usage
        ;;
esac

echo ""
print_success "恢复操作完成！"
echo ""

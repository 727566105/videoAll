#!/bin/bash

# VideoAll 数据备份脚本
# 用法: ./scripts/backup.sh

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

# 创建备份目录
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

# 获取当前时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

print_info "开始备份 VideoAll 数据..."
echo ""

# 1. 备份数据库
print_info "备份数据库..."
docker-compose exec -T postgres pg_dump -U postgres video_all > "$BACKUP_DIR/db_$TIMESTAMP.sql"
print_success "数据库备份完成: db_$TIMESTAMP.sql"

# 2. 备份媒体文件
print_info "备份媒体文件..."
docker run --rm \
    -v videoall_media_data:/data \
    -v "$(pwd)/$BACKUP_DIR:/backup" \
    alpine tar czf "/backup/media_$TIMESTAMP.tar.gz" -C /data .
print_success "媒体文件备份完成: media_$TIMESTAMP.tar.gz"

# 3. 显示备份信息
echo ""
print_info "备份文件列表："
ls -lh "$BACKUP_DIR" | grep "$TIMESTAMP"

# 4. 计算总大小
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
print_success "备份完成！总大小: $TOTAL_SIZE"

# 5. 清理旧备份（保留最近 7 天）
print_info "清理 7 天前的旧备份..."
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
print_success "旧备份清理完成"

echo ""
print_success "所有备份任务完成！"
echo ""

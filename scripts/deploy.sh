#!/bin/bash

# 部署脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 函数定义
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 默认配置
ENVIRONMENT="production"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
BACKUP_BEFORE_DEPLOY=true
HEALTH_CHECK_TIMEOUT=300

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--compose-file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --no-backup)
            BACKUP_BEFORE_DEPLOY=false
            shift
            ;;
        --timeout)
            HEALTH_CHECK_TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  -e, --environment ENV     部署环境 (默认: production)"
            echo "  -f, --compose-file FILE   Docker Compose文件 (默认: docker-compose.yml)"
            echo "  --env-file FILE           环境变量文件 (默认: .env)"
            echo "  --no-backup               跳过部署前备份"
            echo "  --timeout SECONDS         健康检查超时时间 (默认: 300)"
            echo "  -h, --help                显示帮助信息"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

log_info "开始部署到 $ENVIRONMENT 环境..."

# 检查必要文件
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Docker Compose文件不存在: $COMPOSE_FILE"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    log_error "环境变量文件不存在: $ENV_FILE"
    exit 1
fi

# 加载环境变量
set -a
source "$ENV_FILE"
set +a

# 检查Docker和Docker Compose
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose未安装"
    exit 1
fi

# 设置Docker Compose命令
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# 备份数据库（如果启用）
if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
    log_info "创建部署前备份..."
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)_pre_deploy"
    mkdir -p "$BACKUP_DIR"
    
    # 备份数据库
    if $DOCKER_COMPOSE ps postgres | grep -q "Up"; then
        log_info "备份PostgreSQL数据库..."
        $DOCKER_COMPOSE exec -T postgres pg_dump -U "${POSTGRES_USER:-postgres}" "${POSTGRES_DATABASE:-video_all}" > "$BACKUP_DIR/database.sql"
        log_success "数据库备份完成: $BACKUP_DIR/database.sql"
    else
        log_warning "PostgreSQL容器未运行，跳过数据库备份"
    fi
    
    # 备份媒体文件
    if [ -d "media" ]; then
        log_info "备份媒体文件..."
        tar -czf "$BACKUP_DIR/media.tar.gz" media/
        log_success "媒体文件备份完成: $BACKUP_DIR/media.tar.gz"
    fi
fi

# 拉取最新镜像
log_info "拉取最新Docker镜像..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" pull

# 停止旧服务
log_info "停止现有服务..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down

# 清理未使用的镜像
log_info "清理未使用的Docker镜像..."
docker image prune -f

# 启动新服务
log_info "启动新服务..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d

# 等待服务启动
log_info "等待服务启动..."
sleep 10

# 健康检查
log_info "执行健康检查..."
check_health() {
    local service=$1
    local url=$2
    local max_attempts=$((HEALTH_CHECK_TIMEOUT / 10))
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            log_success "$service 健康检查通过"
            return 0
        fi
        
        log_info "$service 健康检查失败，重试 $attempt/$max_attempts..."
        sleep 10
        ((attempt++))
    done
    
    log_error "$service 健康检查失败"
    return 1
}

# 检查后端健康状态
BACKEND_URL="http://localhost:${BACKEND_PORT:-3000}/api/v1/health"
if ! check_health "后端服务" "$BACKEND_URL"; then
    log_error "后端服务启动失败"
    
    # 显示日志
    log_info "后端服务日志:"
    $DOCKER_COMPOSE logs --tail=50 backend
    
    exit 1
fi

# 检查前端健康状态
FRONTEND_URL="http://localhost:${FRONTEND_PORT:-80}/health"
if ! check_health "前端服务" "$FRONTEND_URL"; then
    log_error "前端服务启动失败"
    
    # 显示日志
    log_info "前端服务日志:"
    $DOCKER_COMPOSE logs --tail=50 frontend
    
    exit 1
fi

# 显示服务状态
log_info "服务状态:"
$DOCKER_COMPOSE ps

# 显示访问信息
log_success "部署完成!"
echo ""
log_info "服务访问地址:"
echo "  前端: http://localhost:${FRONTEND_PORT:-80}"
echo "  后端: http://localhost:${BACKEND_PORT:-3000}"
echo "  健康检查: http://localhost:${BACKEND_PORT:-3000}/api/v1/health"
echo ""
log_info "查看日志: $DOCKER_COMPOSE logs -f"
log_info "停止服务: $DOCKER_COMPOSE down"

# 清理旧备份（保留最近5个）
if [ "$BACKUP_BEFORE_DEPLOY" = true ] && [ -d "backups" ]; then
    log_info "清理旧备份文件..."
    find backups/ -name "*_pre_deploy" -type d | sort -r | tail -n +6 | xargs rm -rf
fi

log_success "部署流程完成!"
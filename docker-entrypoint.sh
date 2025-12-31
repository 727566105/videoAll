#!/bin/bash
# videoAll Docker 容器启动脚本
# 同时启动后端服务和 Nginx 前端服务

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 环境变量检查
check_env_vars() {
    log_info "检查环境变量..."

    required_vars=("POSTGRES_HOST" "POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_DATABASE")
    missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "缺少必需的环境变量: ${missing_vars[*]}"
        exit 1
    fi

    log_info "环境变量检查通过"
}

# 等待 PostgreSQL 就绪
wait_for_postgres() {
    log_info "等待 PostgreSQL 数据库就绪..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if PGPASSWORD="${POSTGRES_PASSWORD}" psql \
            -h "${POSTGRES_HOST}" \
            -U "${POSTGRES_USER}" \
            -d "${POSTGRES_DATABASE}" \
            -c '\q' 2>/dev/null; then
            log_info "PostgreSQL 数据库已就绪"
            return 0
        fi

        attempt=$((attempt + 1))
        log_warn "PostgreSQL 未就绪，重试中... ($attempt/$max_attempts)"
        sleep 2
    done

    log_error "PostgreSQL 连接超时"
    exit 1
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."

    directories=(
        "/app/backend/logs"
        "/app/backend/media"
        "/app/backend/uploads"
        "/app/backend/backups"
        "/var/log/nginx"
        "/var/lib/nginx/tmp"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done

    # 设置权限
    if [ "$(id -u)" = "0" ]; then
        chown -R node:node /app/backend/logs /app/backend/media /app/backend/uploads /app/backend/backups
        chown -R node:node /var/log/nginx /var/lib/nginx
    fi
}

# 启动 Nginx（前台）
start_nginx() {
    log_info "启动 Nginx 服务..."

    # 修改 Nginx 配置以在非 root 用户下运行
    if [ "$(id -u)" != "0" ]; then
        # 非root用户，调整nginx配置
        sed -i 's/user nginx;/user node;/' /etc/nginx/nginx.conf || true
    fi

    # 启动 Nginx（前台运行）
    nginx -g "daemon off;" &
    NGINX_PID=$!

    log_info "Nginx 已启动 (PID: $NGINX_PID)"
}

# 启动后端服务
start_backend() {
    log_info "启动后端服务..."

    cd /app/backend

    # 启动 Node.js 服务
    node src/server.js &
    BACKEND_PID=$!

    log_info "后端服务已启动 (PID: $BACKEND_PID)"
}

# 优雅关闭
graceful_shutdown() {
    log_info "接收到关闭信号，正在优雅关闭..."

    if [ -n "${BACKEND_PID:-}" ]; then
        log_info "停止后端服务..."
        kill -TERM "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi

    if [ -n "${NGINX_PID:-}" ]; then
        log_info "停止 Nginx 服务..."
        kill -TERM "$NGINX_PID" 2>/dev/null || true
        wait "$NGINX_PID" 2>/dev/null || true
    fi

    log_info "所有服务已停止"
    exit 0
}

# 设置信号处理
trap graceful_shutdown SIGTERM SIGINT

# 主函数
main() {
    log_info "=========================================="
    log_info "videoAll 应用启动中..."
    log_info "版本: ${VERSION:-1.0.0}"
    log_info "环境: ${NODE_ENV:-production}"
    log_info "=========================================="

    # 检查环境变量
    check_env_vars

    # 创建目录
    create_directories

    # 等待数据库
    wait_for_postgres

    # 启动服务
    start_nginx
    start_backend

    log_info "=========================================="
    log_info "所有服务启动完成！"
    log_info "后端 API: http://localhost:3000"
    log_info "前端界面: http://localhost:80"
    log_info "=========================================="

    # 等待后台进程
    wait
}

# 执行主函数
main "$@"

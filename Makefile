# VideoAll Docker Makefile
# 用法: make <target>

.PHONY: help start stop restart logs status build clean backup restore

# 默认目标：显示帮助
.DEFAULT_GOAL := help

# 颜色定义
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

# 帮助信息
help: ## 显示此帮助信息
	@echo ''
	@echo '${GREEN}VideoAll Docker 管理命令${RESET}'
	@echo ''
	@echo '使用方法:'
	@echo '  ${YELLOW}make${RESET} ${WHITE}<target>${RESET}'
	@echo ''
	@echo '可用命令:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-15s${RESET} %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''

# 环境检查
check-env: ## 检查环境配置
	@if [ ! -f .env ]; then \
		echo "警告: .env 文件不存在，正在从 .env.docker 创建..."; \
		cp .env.docker .env; \
		echo "请编辑 .env 文件，修改必要的配置！"; \
	fi

# 启动服务
start: check-env ## 启动所有服务（开发环境）
	@echo "${GREEN}启动 VideoAll 服务...${RESET}"
	docker-compose up -d
	@echo "${GREEN}服务启动完成！${RESET}"
	@make status

start-prod: check-env ## 启动所有服务（生产环境）
	@echo "${GREEN}启动 VideoAll 服务（生产环境）...${RESET}"
	docker-compose --profile production up -d
	@echo "${GREEN}服务启动完成！${RESET}"
	@make status

# 停止服务
stop: ## 停止所有服务
	@echo "${YELLOW}停止 VideoAll 服务...${RESET}"
	docker-compose down
	@echo "${GREEN}服务已停止${RESET}"

# 停止并清理
stop-clean: ## 停止服务并删除数据卷（⚠️ 危险操作）
	@echo "${YELLOW}警告：此操作将删除所有数据！${RESET}"
	@read -p "确定要继续吗？(yes/no) " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker-compose down -v; \
		echo "${GREEN}数据已清理${RESET}"; \
	else \
		echo "${YELLOW}取消操作${RESET}"; \
	fi

# 重启服务
restart: ## 重启所有服务
	@echo "${YELLOW}重启 VideoAll 服务...${RESET}"
	docker-compose restart
	@echo "${GREEN}服务已重启${RESET}"

# 查看日志
logs: ## 查看所有服务日志
	docker-compose logs -f

logs-backend: ## 查看后端服务日志
	docker-compose logs -f backend

logs-frontend: ## 查看前端服务日志
	docker-compose logs -f frontend

logs-db: ## 查看数据库日志
	docker-compose logs -f postgres

# 查看状态
status: ## 查看服务状态
	@echo ""
	@echo "${GREEN}VideoAll 服务状态：${RESET}"
	@echo ""
	docker-compose ps
	@echo ""
	@echo "${GREEN}访问地址：${RESET}"
	@echo "  前端: http://localhost"
	@echo "  后端: http://localhost:3000/api/v1"
	@echo "  默认账号: admin@example.com / admin123"
	@echo ""

# 构建镜像
build: ## 构建所有镜像
	@echo "${YELLOW}构建 Docker 镜像...${RESET}"
	docker-compose build
	@echo "${GREEN}镜像构建完成${RESET}"

build-no-cache: ## 构建所有镜像（无缓存）
	@echo "${YELLOW}构建 Docker 镜像（无缓存）...${RESET}"
	docker-compose build --no-cache
	@echo "${GREEN}镜像构建完成${RESET}"

# 清理资源
clean: ## 清理未使用的 Docker 资源
	@echo "${YELLOW}清理未使用的 Docker 资源...${RESET}"
	docker system prune -f
	@echo "${GREEN}清理完成${RESET}"

clean-all: ## 清理所有 Docker 资源（⚠️ 危险操作）
	@echo "${YELLOW}警告：此操作将删除所有未使用的资源！${RESET}"
	@read -p "确定要继续吗？(yes/no) " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker system prune -a --volumes -f; \
		echo "${GREEN}清理完成${RESET}"; \
	else \
		echo "${YELLOW}取消操作${RESET}"; \
	fi

# 数据备份
backup: ## 备份数据库和媒体文件
	@echo "${YELLOW}开始备份...${RESET}"
	@./scripts/backup.sh

# 数据恢复
restore: ## 恢复数据（使用: make restore TYPE=db FILE=backup.sql）
	@read -p "备份类型 (db/media): " type; \
	read -p "备份文件路径: " file; \
	./scripts/restore.sh $$type $$file

# 数据库连接
db-connect: ## 连接到 PostgreSQL 数据库
	docker-compose exec postgres psql -U postgres -d video_all

# 进入容器
shell-backend: ## 进入后端容器
	docker-compose exec backend sh

shell-db: ## 进入数据库容器
	docker-compose exec postgres sh

# 查看资源占用
stats: ## 查看容器资源占用
	docker stats

# 健康检查
health: ## 检查服务健康状态
	@echo "${GREEN}检查服务健康状态...${RESET}"
	@echo ""
	@docker-compose ps
	@echo ""
	@echo "${GREEN}后端 API 健康检查：${RESET}"
	@curl -s http://localhost:3000/api/v1/health || echo "  后端服务未就绪"
	@echo ""

# 重新构建并启动
rebuild: ## 重新构建并启动服务
	@echo "${YELLOW}重新构建并启动服务...${RESET}"
	docker-compose up -d --build
	@echo "${GREEN}服务已重启${RESET}"
	@make status

# 查看容器信息
inspect: ## 查看容器详细信息
	@read -p "容器名称 (backend/frontend/postgres/redis): " container; \
	docker inspect videoall-$$container

# 安装依赖
install: check-env ## 安装并初始化项目
	@echo "${YELLOW}安装 VideoAll 项目...${RESET}"
	@mkdir -p backups logs
	@echo "${GREEN}初始化完成${RESET}"
	@echo "${YELLOW}请先配置 .env 文件，然后运行 'make start' 启动服务${RESET}"

# 开发环境初始化
dev-init: install ## 开发环境初始化
	@echo "${GREEN}开发环境初始化完成${RESET}"
	@echo "${YELLOW}运行 'make dev' 启动开发环境${RESET}"

# 更新项目
update: ## 更新项目（拉取最新代码并重新构建）
	@echo "${YELLOW}更新 VideoAll 项目...${RESET}"
	git pull
	docker-compose build
	docker-compose up -d
	@echo "${GREEN}更新完成${RESET}"

# 查看日志文件
log-files: ## 查看后端日志文件
	@tail -f backend/logs/combined.log 2>/dev/null || echo "日志文件不存在"

# 测试连接
test-connection: ## 测试数据库连接
	docker-compose exec backend sh -c "pg_isready -h postgres -p 5432"

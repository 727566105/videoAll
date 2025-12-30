# Docker 快速参考

本文档提供 VideoAll 项目 Docker 部署的快速参考指南。

## 🚀 快速启动

### 方式 1: 使用启动脚本（推荐）

```bash
# 开发环境
./scripts/start.sh dev

# 生产环境
./scripts/start.sh prod
```

### 方式 2: 使用 Docker Compose

```bash
# 1. 配置环境变量
cp .env.docker .env
# 编辑 .env 文件，修改必要的配置

# 2. 启动服务
docker-compose up -d

# 3. 查看状态
docker-compose ps
```

## 📋 常用命令

### 服务管理

| 操作 | 命令 |
|------|------|
| 启动所有服务 | `docker-compose up -d` |
| 停止所有服务 | `docker-compose down` |
| 重启所有服务 | `docker-compose restart` |
| 查看服务状态 | `docker-compose ps` |
| 查看服务日志 | `docker-compose logs -f` |
| 查看特定服务日志 | `docker-compose logs -f backend` |

### 使用脚本（推荐）

| 操作 | 命令 |
|------|------|
| 启动服务 | `./scripts/start.sh [dev\|prod]` |
| 停止服务 | `./scripts/stop.sh` |
| 停止并清理数据 | `./scripts/stop.sh --clean` |
| 查看日志 | `./scripts/logs.sh [服务名]` |
| 备份数据 | `./scripts/backup.sh` |
| 恢复数据 | `./scripts/restore.sh <类型> <文件>` |

### 数据库操作

```bash
# 连接到数据库
docker-compose exec postgres psql -U postgres -d video_all

# 数据库备份
docker-compose exec postgres pg_dump -U postgres video_all > backup.sql

# 数据库恢复
docker-compose exec -T postgres psql -U postgres video_all < backup.sql
```

### 构建和清理

```bash
# 重新构建镜像
docker-compose build

# 重新构建并启动
docker-compose up -d --build

# 清理未使用的资源
docker system prune -a

# 删除所有容器、网络、卷
docker-compose down -v
```

## 🌐 访问地址

启动成功后，可通过以下地址访问：

- **前端应用**: http://localhost
- **后端 API**: http://localhost:3000/api/v1
- **API 健康检查**: http://localhost:3000/api/v1/health
- **默认账号**: admin@example.com / admin123

## 🔧 重要配置

### 必须修改的配置项（.env 文件）

```bash
# 数据库密码
POSTGRES_PASSWORD=your_secure_password

# JWT 密钥
JWT_SECRET=your_jwt_secret_key

# 加密密钥
ENCRYPTION_KEY=your_32_byte_encryption_key

# 前端凭证加密密钥
VITE_CREDENTIAL_SECRET_KEY=your_credential_secret_key
```

### 端口配置

```bash
BACKEND_PORT=3000      # 后端端口
FRONTEND_PORT=80       # 前端端口
POSTGRES_PORT=5432     # PostgreSQL 端口
REDIS_PORT=6379        # Redis 端口
```

## 📦 服务说明

### 核心服务

| 服务名 | 说明 | 端口 |
|--------|------|------|
| postgres | PostgreSQL 数据库 | 5432 |
| redis | Redis 缓存 | 6379 |
| backend | Node.js 后端服务 | 3000 |
| frontend | React 前端应用（Nginx） | 80 |
| nginx | 反向代理（生产环境） | 80/443 |

### 数据卷

| 卷名 | 说明 |
|------|------|
| postgres_data | 数据库数据 |
| redis_data | Redis 缓存数据 |
| media_data | 媒体文件存储 |
| logs_data | 应用日志 |
| backup_data | 备份文件 |

## 🔍 监控和调试

### 查看容器资源占用

```bash
docker stats
```

### 查看容器详细信息

```bash
docker inspect <container_name>
```

### 进入容器

```bash
# 进入后端容器
docker-compose exec backend sh

# 进入数据库容器
docker-compose exec postgres sh

# 进入前端容器
docker-compose exec frontend sh
```

### 查看容器日志

```bash
# 查看最近 100 条日志
docker-compose logs --tail=100

# 查看特定时间段的日志
docker-compose logs --since="2024-01-01T00:00:00"

# 实时跟踪日志
docker-compose logs -f
```

## 💾 数据备份和恢复

### 自动备份

```bash
# 运行备份脚本
./scripts/backup.sh

# 备份文件位置
./backups/
  ├── db_YYYYMMDD_HHMMSS.sql
  └── media_YYYYMMDD_HHMMSS.tar.gz
```

### 手动备份

```bash
# 数据库备份
docker-compose exec postgres pg_dump -U postgres video_all > backup.sql

# 媒体文件备份
docker run --rm \
  -v videoall_media_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/media.tar.gz -C /data .
```

### 数据恢复

```bash
# 恢复数据库
./scripts/restore.sh db backups/db_20250130_120000.sql

# 恢复媒体文件
./scripts/restore.sh media backups/media_20250130_120000.tar.gz
```

## 🛠️ 故障排除

### 问题：容器启动失败

```bash
# 查看详细日志
docker-compose logs backend

# 重新构建镜像
docker-compose build --no-cache backend
```

### 问题：数据库连接失败

```bash
# 检查数据库容器状态
docker-compose ps postgres

# 等待数据库启动
docker-compose run --rm backend sh -c "wait-for-it postgres:5432"
```

### 问题：磁盘空间不足

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune

# 清理构建缓存
docker builder prune
```

### 问题：端口冲突

修改 `.env` 文件中的端口配置：

```bash
BACKEND_PORT=3001      # 修改后端端口
FRONTEND_PORT=8080     # 修改前端端口
```

## 📝 性能优化建议

### 1. 资源限制

在 `docker-compose.yml` 中配置：

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

### 2. 日志轮转

配置日志大小限制：

```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. 使用 BuildKit 加速构建

```bash
DOCKER_BUILDKIT=1 docker-compose build
```

## 🔒 安全建议

1. **修改默认密码**: 首次部署前必须修改所有默认密钥和密码
2. **启用 HTTPS**: 生产环境建议配置 SSL 证书
3. **限制网络访问**: 使用防火墙限制端口访问
4. **定期更新**: 定期更新 Docker 镜像和依赖包
5. **备份数据**: 配置定时备份任务

## 📚 更多文档

- [完整部署指南](./DOCKER_DEPLOYMENT.md) - 详细的部署文档
- [项目文档](./CLAUDE.md) - 项目架构和开发文档
- [Docker 官方文档](https://docs.docker.com/)

## 🆘 获取帮助

遇到问题？

1. 查看 [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) 故障排除章节
2. 查看容器日志：`docker-compose logs -f`
3. 提交 Issue 到项目仓库

---

**最后更新**: 2025-12-30

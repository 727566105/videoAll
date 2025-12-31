# Docker 部署指南

本文档提供 videoAll 项目的 Docker 部署完整指南。

## 📋 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [部署步骤](#部署步骤)
- [常见问题](#常见问题)
- [维护操作](#维护操作)

## 前置要求

### 必需软件

- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0

### 安装 Docker

**Ubuntu/Debian:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**CentOS/RHEL:**
```bash
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

**macOS/Windows:**
下载并安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)

### 验证安装

```bash
docker --version
docker compose version
```

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/727566105/videoAll.git
cd videoAll
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.docker.example .env

# 编辑环境变量（重要：修改数据库连接信息和 JWT 密钥）
vim .env
```

**必须修改的配置：**

#### 方案1: 使用外部数据库（生产环境推荐）

```bash
# PostgreSQL 配置
POSTGRES_HOST=your-postgres-host  # 你的数据库地址
POSTGRES_PORT=5432
POSTGRES_DATABASE=video_all
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-external-db-password

# Redis 配置
REDIS_HOST=your-redis-host  # 你的 Redis 地址
REDIS_PORT=6379

# JWT 密钥（请使用随机字符串）
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

#### 方案2: 使用 Docker Compose 内置数据库（开发/测试环境）

```bash
# 数据库密码（请使用强密码）
POSTGRES_PASSWORD=your-very-secure-password-here

# JWT 密钥（请使用随机字符串）
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

### 3. 启动服务

**使用外部数据库：**
```bash
# 启动服务（不包含内置数据库）
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

**使用内置数据库（开发/测试）：**
```bash
# 启动服务（包含内置数据库和 Redis）
docker compose --profile internal-db up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 4. 访问应用

- **前端**: http://localhost:80
- **后端 API**: http://localhost:3000
- **健康检查**: http://localhost:3000/api/v1/health

**默认管理员账号：**
- 邮箱: `admin@example.com`
- 密码: `admin123`

⚠️ **重要**: 首次登录后请立即修改默认密码！

## 配置说明

### 环境变量列表

| 变量名 | 说明 | 默认值 | 必需 |
|--------|------|--------|------|
| `NODE_ENV` | 运行环境 | `production` | 否 |
| `BACKEND_PORT` | 后端端口 | `3000` | 否 |
| `FRONTEND_PORT` | 前端端口 | `80` | 否 |
| `POSTGRES_DATABASE` | 数据库名称 | `video_all` | 否 |
| `POSTGRES_USER` | 数据库用户 | `postgres` | 否 |
| `POSTGRES_PASSWORD` | 数据库密码 | `postgres` | ✅ 是 |
| `REDIS_HOST` | Redis 主机 | `redis` | 否 |
| `REDIS_PORT` | Redis 端口 | `6379` | 否 |
| `JWT_SECRET` | JWT 密钥 | - | ✅ 是 |
| `JWT_EXPIRES_IN` | JWT 过期时间 | `7d` | 否 |
| `IMAGE_TAG` | 镜像标签 | `latest` | 否 |

### 端口映射

| 服务 | 容器端口 | 主机端口 | 说明 |
|------|----------|----------|------|
| Frontend | 80 | 80 | Web 界面 |
| Backend | 3000 | 3000 | API 服务 |
| PostgreSQL | 5432 | 5432 | 数据库 |
| Redis | 6379 | 6379 | 缓存 |

### 数据持久化

Docker Compose 使用命名卷来持久化数据：

```yaml
volumes:
  postgres_data:    # PostgreSQL 数据
  redis_data:       # Redis 数据
  media_data:       # 媒体文件
  logs_data:        # 应用日志
  backup_data:      # 备份文件
```

**查看卷：**
```bash
docker volume ls | grep videoall
```

**备份卷：**
```bash
docker run --rm -v videoall_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /data .
```

## 部署步骤

### 标准部署（推荐）

适用于大多数生产环境。

```bash
# 1. 下载项目
git clone https://github.com/727566105/videoAll.git
cd videoAll

# 2. 配置环境变量
cp .env.example .env
vim .env  # 修改必需的配置

# 3. 启动服务
docker compose up -d

# 4. 等待服务就绪（约 30-60 秒）
docker compose logs -f backend

# 5. 验证部署
curl http://localhost:3000/api/v1/health
```

### 使用特定版本镜像

```bash
# 编辑 .env 文件
IMAGE_TAG=feature-docker-support

# 或者直接指定
docker compose up -d
```

### 仅使用后端服务

如果前端已经单独部署：

```bash
# 启动数据库和后端
docker compose up -d postgres redis backend

# 停止前端服务
docker compose stop frontend
```

## 常见问题

### 1. 端口冲突

**问题**: 端口 80 或 3000 已被占用

**解决方案**:
```bash
# 修改 .env 文件中的端口
FRONTEND_PORT=8080
BACKEND_PORT=3001

# 重启服务
docker compose down
docker compose up -d
```

### 2. 数据库连接失败

**问题**: 后端无法连接到数据库

**解决方案**:
```bash
# 检查数据库是否健康
docker compose ps postgres

# 查看数据库日志
docker compose logs postgres

# 重启数据库
docker compose restart postgres
```

### 3. 镜像拉取失败

**问题**: 无法从 GHCR 拉取镜像

**解决方案**:
```bash
# 登录到 GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 或使用本地构建
docker compose build
docker compose up -d
```

### 4. 权限问题

**问题**: 容器内无文件写入权限

**解决方案**:
```bash
# 检查卷权限
docker exec -it videoall-backend ls -la /app/media

# 修复权限
docker exec -it videoall-backend chown -R node:node /app/media
```

### 5. 内存不足

**问题**: 容器因内存不足退出

**解决方案**:
```bash
# 增加 Docker 内存限制（Docker Desktop）
Settings > Resources > Memory > 4GB+

# 或在 docker-compose.yml 中添加限制
services:
  backend:
    mem_limit: 2g
    memswap_limit: 2g
```

## 维护操作

### 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f backend
docker compose logs -f frontend

# 查看最近 100 行日志
docker compose logs --tail=100 backend
```

### 更新镜像

```bash
# 拉取最新镜像
docker compose pull

# 重新创建容器
docker compose up -d --force-recreate

# 清理旧镜像
docker image prune -a
```

### 备份数据

```bash
# 备份 PostgreSQL 数据库
docker exec videoall-postgres pg_dump -U postgres video_all > backup_$(date +%Y%m%d).sql

# 备份所有卷
docker run --rm -v videoall_postgres_data:/data -v videoall_media_data:/media -v $(pwd):/backup alpine tar czf /backup/full_backup_$(date +%Y%m%d).tar.gz /data /media
```

### 恢复数据

```bash
# 恢复 PostgreSQL 数据库
cat backup.sql | docker exec -i videoall-postgres psql -U postgres video_all

# 恢复卷数据
docker run --rm -v videoall_postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/full_backup.tar.gz -C /
```

### 清理资源

```bash
# 停止所有服务
docker compose down

# 停止并删除卷（危险操作！会删除所有数据）
docker compose down -v

# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune
```

### 监控资源使用

```bash
# 查看容器资源使用情况
docker stats

# 查看容器详情
docker inspect videoall-backend

# 查看卷使用情况
docker system df -v
```

### 重启服务

```bash
# 重启所有服务
docker compose restart

# 重启特定服务
docker compose restart backend
docker compose restart postgres
```

### 进入容器调试

```bash
# 进入后端容器
docker exec -it videoall-backend sh

# 进入数据库容器
docker exec -it videoall-postgres psql -U postgres video_all

# 进入 Redis 容器
docker exec -it videoall-redis redis-cli
```

## 生产环境建议

### 1. 安全性

- ✅ 修改所有默认密码
- ✅ 使用强随机 JWT 密钥
- ✅ 不要暴露数据库端口到公网
- ✅ 定期更新镜像
- ✅ 启用 HTTPS（使用 Nginx 反向代理）

### 2. 性能优化

- ✅ 使用外部 PostgreSQL 和 Redis（大规模部署）
- ✅ 配置 Redis 持久化
- ✅ 定期清理日志和备份文件
- ✅ 监控容器资源使用

### 3. 备份策略

- ✅ 每日自动备份数据库
- ✅ 保留至少 7 天的备份
- ✅ 定期测试恢复流程
- ✅ 将备份存储到异地

### 4. 监控告警

- ✅ 配置健康检查
- ✅ 监控容器状态
- ✅ 设置日志告警
- ✅ 监控磁盘空间

## Docker 镜像

项目镜像托管在 **GitHub Container Registry (GHCR)**:

- **后端镜像**: `ghcr.io/727566105/videoall-backend:latest`
- **前端镜像**: `ghcr.io/727566105/videoall-frontend:latest`
- **完整镜像**: `ghcr.io/727566105/videoall:latest`

### 拉取镜像

```bash
# 拉取最新版本
docker pull ghcr.io/727566105/videoall-backend:latest
docker pull ghcr.io/727566105/videoall-frontend:latest

# 拉取特定版本
docker pull ghcr.io/727566105/videoall-backend:feature-docker-support
```

## 支持

如有问题，请：

1. 查看 [常见问题](#常见问题)
2. 检查 [GitHub Issues](https://github.com/727566105/videoAll/issues)
3. 提交新的 Issue 并附上日志信息

## 许可证

MIT License

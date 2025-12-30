# Docker 部署指南

本文档介绍如何使用 Docker 和 Docker Compose 部署 VideoAll 项目。

## 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [部署步骤](#部署步骤)
- [常用命令](#常用命令)
- [生产环境优化](#生产环境优化)
- [故障排除](#故障排除)

## 前置要求

确保你的系统已安装以下软件：

- **Docker**: >= 20.10.0
- **Docker Compose**: >= 2.0.0

### 验证安装

```bash
docker --version
docker-compose --version
```

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd videoAll
```

### 2. 配置环境变量

复制环境变量模板并修改：

```bash
cp .env.docker .env
```

**重要配置项：**

```bash
# 数据库密码（必须修改）
POSTGRES_PASSWORD=your_secure_password_here

# JWT 密钥（必须修改）
JWT_SECRET=your_super_secret_jwt_key_please_change_this

# 加密密钥（必须修改）
ENCRYPTION_KEY=your_encryption_key_here_32_bytes_long_for_aes256

# 前端凭证加密密钥（必须修改）
VITE_CREDENTIAL_SECRET_KEY=your_frontend_credential_secret_key
```

### 3. 启动服务

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 访问应用

- **前端**: http://localhost
- **后端 API**: http://localhost:3000
- **默认账号**: admin@example.com / admin123

**首次登录后请立即修改密码！**

## 配置说明

### 服务端口

通过 `.env` 文件修改服务端口：

```bash
BACKEND_PORT=3000      # 后端服务端口
FRONTEND_PORT=80       # 前端服务端口
POSTGRES_PORT=5432     # PostgreSQL 端口
REDIS_PORT=6379        # Redis 端口
```

### 持久化存储

Docker Compose 使用以下卷来持久化数据：

- `postgres_data`: PostgreSQL 数据库数据
- `redis_data`: Redis 缓存数据
- `media_data`: 媒体文件存储
- `logs_data`: 应用日志
- `backup_data`: 数据库备份

### 环境变量说明

| 变量名 | 说明 | 默认值 | 是否必须修改 |
|--------|------|--------|--------------|
| `POSTGRES_PASSWORD` | 数据库密码 | postgres | ✅ 是 |
| `JWT_SECRET` | JWT 签名密钥 | - | ✅ 是 |
| `ENCRYPTION_KEY` | 数据加密密钥 | - | ✅ 是 |
| `VITE_CREDENTIAL_SECRET_KEY` | 前端凭证加密密钥 | - | ✅ 是 |
| `NODE_ENV` | 运行环境 | production | ❌ 否 |
| `LOG_LEVEL` | 日志级别 | info | ❌ 否 |

## 部署步骤

### 开发环境

```bash
# 启动开发环境（带热重载）
docker-compose -f docker-compose.yml --profile development up -d
```

### 生产环境

```bash
# 1. 构建生产镜像
docker-compose build

# 2. 启动生产环境（包含 Nginx）
docker-compose --profile production up -d

# 3. 检查服务健康状态
docker-compose ps
curl http://localhost/api/v1/health
```

### 仅构建镜像

```bash
# 仅构建后端镜像
docker-compose build backend

# 仅构建前端镜像
docker-compose build frontend

# 构建所有镜像
docker-compose build
```

## 常用命令

### 服务管理

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
```

### 数据库操作

```bash
# 连接到 PostgreSQL
docker-compose exec postgres psql -U postgres -d video_all

# 数据库备份
docker-compose exec postgres pg_dump -U postgres video_all > backup.sql

# 数据库恢复
docker-compose exec -T postgres psql -U postgres video_all < backup.sql
```

### 清理和重置

```bash
# 停止并删除所有容器、网络
docker-compose down

# 删除所有容器、网络、卷
docker-compose down -v

# 删除所有容器、网络、卷和镜像
docker-compose down -v --rmi all

# 清理未使用的 Docker 资源
docker system prune -a
```

### 查看资源使用

```bash
# 查看容器资源占用
docker stats

# 查看磁盘使用
docker system df
```

## 生产环境优化

### 1. 资源限制

在 `docker-compose.yml` 中添加资源限制：

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 2. 日志管理

配置日志轮转（在 `docker-compose.yml` 中）：

```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. 安全加固

- ✅ 使用强密码（至少 16 位，包含大小写字母、数字、特殊字符）
- ✅ 修改所有默认密钥
- ✅ 启用 HTTPS（配置 SSL 证书）
- ✅ 配置防火墙，仅开放必要端口
- ✅ 定期更新基础镜像

### 4. 性能优化

```bash
# 使用多阶段构建减小镜像大小
docker build --no-cache --target production -t videoall-backend:latest ./backend

# 使用 BuildKit 加速构建
DOCKER_BUILDKIT=1 docker-compose build
```

### 5. 健康检查

所有服务都配置了健康检查，可以通过以下命令查看：

```bash
docker inspect --format='{{.State.Health.Status}}' videoall-backend
```

## 监控和维护

### 查看日志

```bash
# 实时查看所有服务日志
docker-compose logs -f

# 查看最近 100 条日志
docker-compose logs --tail=100

# 查看特定时间段日志
docker-compose logs --since="2024-01-01T00:00:00" --until="2024-01-02T00:00:00"
```

### 数据备份

```bash
# 创建备份目录
mkdir -p ./backups

# 备份数据库
docker-compose exec postgres pg_dump -U postgres video_all > ./backups/db_$(date +%Y%m%d_%H%M%S).sql

# 备份媒体文件
docker run --rm -v videoall_media_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/media_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### 定期清理

创建定时任务清理旧备份（保留最近 7 天）：

```bash
# 添加到 crontab
0 2 * * * find /path/to/backups -name "*.sql" -mtime +7 -delete
0 3 * * * find /path/to/backups -name "*.tar.gz" -mtime +7 -delete
```

## 故障排除

### 问题 1: 容器启动失败

**解决方案：**

```bash
# 查看详细日志
docker-compose logs backend

# 检查配置文件
docker-compose config

# 重新构建镜像
docker-compose build --no-cache backend
```

### 问题 2: 数据库连接失败

**解决方案：**

```bash
# 检查 PostgreSQL 容器状态
docker-compose ps postgres

# 查看 PostgreSQL 日志
docker-compose logs postgres

# 等待数据库启动
docker-compose run --rm backend wait-for-it postgres:5432
```

### 问题 3: 前端无法访问后端 API

**解决方案：**

1. 检查环境变量 `VITE_API_BASE_URL` 配置
2. 确认 Nginx 配置正确（生产环境）
3. 查看浏览器控制台网络请求

### 问题 4: 磁盘空间不足

**解决方案：**

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune

# 清理构建缓存
docker builder prune
```

### 问题 5: Python 解析器无法工作

**解决方案：**

```bash
# 检查 Python 环境
docker-compose exec backend python3 --version

# 检查 OCR 依赖
docker-compose exec backend tesseract --version

# 重新安装 Python SDK
docker-compose exec backend pip3 install -e /app/media_parser_sdk
```

### 问题 6: OCR 识别失败

**解决方案：**

```bash
# 检查 Tesseract 数据包
docker-compose exec backend ls -la /usr/share/tessdata/

# 手动下载中文数据包
docker-compose exec backend apk add tesseract-ocr-data-chi_sim
```

## 升级部署

### 升级到新版本

```bash
# 1. 备份数据
./scripts/backup.sh

# 2. 拉取最新代码
git pull origin main

# 3. 重新构建镜像
docker-compose build

# 4. 重启服务
docker-compose up -d

# 5. 清理旧镜像
docker image prune -f
```

### 回滚到上一版本

```bash
# 1. 停止服务
docker-compose down

# 2. 切换到上一版本
git checkout <previous-commit>

# 3. 重新构建并启动
docker-compose up -d
```

## 生产环境检查清单

部署到生产环境前，请确认以下事项：

- [ ] 修改所有默认密码和密钥
- [ ] 配置 HTTPS（SSL 证书）
- [ ] 设置防火墙规则
- [ ] 配置日志轮转
- [ ] 设置数据库备份任务
- [ ] 配置监控告警
- [ ] 测试灾难恢复流程
- [ ] 优化资源限制（CPU、内存）
- [ ] 配置 CDN（如需要）
- [ ] 设置跨域策略（CORS）

## 参考资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Node.js Docker 最佳实践](https://github.com/nodejs/docker-node/blob/main/README.md)
- [Nginx 配置指南](https://nginx.org/en/docs/)

## 支持

如有问题，请提交 Issue 或联系技术支持。

---

**最后更新**: 2025-12-30
**维护者**: VideoAll Team

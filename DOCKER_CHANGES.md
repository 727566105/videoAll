# Docker 配置总结

本文档总结了 VideoAll 项目 Docker 化的所有配置和更改。

## 📦 已创建的文件

### 1. Docker 配置文件

| 文件路径 | 说明 |
|---------|------|
| [backend/Dockerfile](backend/Dockerfile) | 后端服务 Dockerfile（已更新） |
| [frontend/Dockerfile](frontend/Dockerfile) | 前端服务 Dockerfile（已存在） |
| [docker-compose.yml](docker-compose.yml) | Docker Compose 配置（已存在） |
| [frontend/nginx.conf](frontend/nginx.conf) | Nginx 配置（已存在） |

### 2. Docker 忽略文件

| 文件路径 | 说明 |
|---------|------|
| [.dockerignore](.dockerignore) | 根目录 Docker 忽略规则（已更新） |
| [backend/.dockerignore](backend/.dockerignore) | 后端 Docker 忽略规则（新建） |
| [frontend/.dockerignore](frontend/.dockerignore) | 前端 Docker 忽略规则（新建） |

### 3. 环境配置

| 文件路径 | 说明 |
|---------|------|
| [.env.docker](.env.docker) | Docker 环境变量模板（新建） |

### 4. 文档

| 文件路径 | 说明 |
|---------|------|
| [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) | Docker 完整部署指南（新建） |
| [DOCKER_QUICKSTART.md](DOCKER_QUICKSTART.md) | Docker 快速参考（新建） |
| [DOCKER_CHECKLIST.md](DOCKER_CHECKLIST.md) | Docker 部署检查清单（新建） |

### 5. 管理脚本

| 文件路径 | 说明 |
|---------|------|
| [scripts/start.sh](scripts/start.sh) | 启动服务脚本（新建） |
| [scripts/stop.sh](scripts/stop.sh) | 停止服务脚本（新建） |
| [scripts/backup.sh](scripts/backup.sh) | 备份数据脚本（新建） |
| [scripts/restore.sh](scripts/restore.sh) | 恢复数据脚本（新建） |
| [scripts/logs.sh](scripts/logs.sh) | 查看日志脚本（新建） |

### 6. 构建工具

| 文件路径 | 说明 |
|---------|------|
| [Makefile](Makefile) | Make 命令快捷方式（新建） |

### 7. 目录结构

| 目录路径 | 说明 |
|---------|------|
| [backups/](backups/) | 备份文件存储目录（新建） |
| [logs/](logs/) | 日志文件存储目录（新建） |

## 🔧 主要更改

### 1. 后端 Dockerfile 更新

**新增功能：**
- ✅ Python 3 支持
- ✅ Tesseract OCR 支持（中文 + 英文）
- ✅ FFmpeg 视频/音频处理
- ✅ ImageMagick 图像处理
- ✅ Python SDK 自动安装
- ✅ 系统依赖验证

**关键代码：**
```dockerfile
# 安装 Python、OCR 和图像处理工具
RUN apk add --no-cache \
    python3 \
    py3-pip \
    tesseract-ocr \
    tesseract-ocr-data-chi_sim \
    tesseract-ocr-data-eng \
    imagemagick \
    ffmpeg

# 安装 Python SDK
COPY --chown=nodejs:nodejs ../media_parser_sdk /app/media_parser_sdk
RUN cd /app/media_parser_sdk && \
    pip3 install --no-cache-dir -e .
```

### 2. Docker Compose 配置

**包含的服务：**
- PostgreSQL 15 (数据库)
- Redis 7 (缓存)
- Backend (Node.js 后端)
- Frontend (React + Nginx)
- Nginx (反向代理，生产环境)

**持久化卷：**
- `postgres_data` - 数据库数据
- `redis_data` - Redis 缓存
- `media_data` - 媒体文件
- `logs_data` - 应用日志
- `backup_data` - 备份文件

### 3. 管理脚本

所有脚本都具有：
- ✅ 可执行权限（chmod +x）
- ✅ 彩色输出（易于识别）
- ✅ 错误处理（set -e）
- ✅ 友好的提示信息

### 4. Makefile 命令

提供 30+ 个便捷命令，包括：
- 服务管理（start, stop, restart）
- 日志查看（logs, logs-backend, logs-frontend）
- 数据管理（backup, restore, db-connect）
- 构建管理（build, rebuild, clean）
- 健康检查（health, status, test-connection）

## 🚀 快速开始

### 使用 Make 命令（推荐）

```bash
# 查看所有可用命令
make help

# 启动服务
make start

# 查看状态
make status

# 查看日志
make logs

# 停止服务
make stop
```

### 使用脚本

```bash
# 启动服务
./scripts/start.sh

# 停止服务
./scripts/stop.sh

# 备份数据
./scripts/backup.sh

# 查看日志
./scripts/logs.sh
```

### 使用 Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 📋 环境配置

### 必须修改的配置项

在 `.env` 文件中修改以下配置：

```bash
# 1. 数据库密码
POSTGRES_PASSWORD=your_secure_password_here

# 2. JWT 密钥
JWT_SECRET=your_jwt_secret_key_please_change_this

# 3. 加密密钥（32 字节）
ENCRYPTION_KEY=your_32_byte_encryption_key_here

# 4. 前端凭证密钥
VITE_CREDENTIAL_SECRET_KEY=your_frontend_credential_secret_key
```

### 生成安全密钥

```bash
# 生成随机密钥
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## 🌐 访问地址

启动后可通过以下地址访问：

- **前端应用**: http://localhost
- **后端 API**: http://localhost:3000/api/v1
- **健康检查**: http://localhost:3000/api/v1/health
- **默认账号**: admin@example.com / admin123

## 🔍 功能验证

### 1. 检查服务状态

```bash
make status
# 或
docker-compose ps
```

### 2. 检查后端健康

```bash
curl http://localhost:3000/api/v1/health
```

### 3. 检查前端访问

```bash
curl http://localhost
```

### 4. 检查 Python 环境

```bash
docker-compose exec backend python3 --version
docker-compose exec backend tesseract --version
```

## 📊 资源使用

### 默认资源限制

| 服务 | CPU | 内存 |
|------|-----|------|
| Backend | 未限制 | 未限制 |
| Frontend | 未限制 | 未限制 |
| PostgreSQL | 未限制 | 未限制 |
| Redis | 未限制 | 未限制 |

建议在生产环境配置资源限制（参见 `docker-compose.yml`）。

### 磁盘空间预估

- Docker 镜像: ~2-3 GB
- 数据库: 初始 ~50 MB，根据数据增长
- 媒体文件: 根据使用情况
- 日志文件: ~100 MB/天（取决于配置）

## 🔒 安全建议

1. **修改默认密码** - 首次部署前必须修改所有默认密钥和密码
2. **启用 HTTPS** - 生产环境强烈建议配置 SSL 证书
3. **限制网络访问** - 使用防火墙限制不必要的端口访问
4. **定期更新** - 定期更新 Docker 镜像和依赖包
5. **备份数据** - 配置自动备份任务
6. **监控日志** - 定期检查错误日志和异常访问

## 📚 文档索引

- [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) - 完整的部署指南
- [DOCKER_QUICKSTART.md](DOCKER_QUICKSTART.md) - 快速参考命令
- [DOCKER_CHECKLIST.md](DOCKER_CHECKLIST.md) - 部署检查清单
- [CLAUDE.md](CLAUDE.md) - 项目架构和开发文档

## 🆘 故障排除

### 常见问题

1. **端口冲突** - 修改 `.env` 文件中的端口配置
2. **权限错误** - 确保脚本有执行权限（`chmod +x scripts/*.sh`）
3. **数据库连接失败** - 检查 PostgreSQL 容器是否健康
4. **镜像构建失败** - 使用 `docker-compose build --no-cache` 重新构建

详细故障排除请参考 [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)。

## 🔄 升级和维护

### 升级到新版本

```bash
# 备份数据
make backup

# 拉取最新代码
git pull

# 重新构建镜像
make rebuild

# 或使用 Makefile
make update
```

### 日常维护

```bash
# 查看服务状态
make status

# 查看资源占用
make stats

# 清理旧日志
#（需要手动或配置定时任务）

# 备份数据
make backup
```

## ✅ 部署检查

使用检查清单确保部署正确：

```bash
# 运行健康检查
make health

# 查看所有服务状态
docker-compose ps

# 检查日志
make logs
```

完整的检查清单请参考 [DOCKER_CHECKLIST.md](DOCKER_CHECKLIST.md)。

---

**创建日期**: 2025-12-30
**维护者**: VideoAll Team
**版本**: 1.0.0

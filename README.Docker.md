# 🐳 videoAll Docker 部署指南

videoAll 提供了完整的 Docker 化解决方案，支持一键部署和多种部署模式。

## 🚀 快速开始

### 方式一：使用预构建镜像（推荐）

```bash
# 1. 下载配置文件
curl -O https://raw.githubusercontent.com/727566105/videoAll/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/727566105/videoAll/main/.env.example

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，配置数据库信息

# 3. 启动服务
docker-compose up -d

# 4. 查看状态
docker-compose ps
```

### 方式二：从源码构建

```bash
# 1. 克隆仓库
git clone https://github.com/727566105/videoAll.git
cd videoAll

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 3. 构建并启动
docker-compose up --build -d
```

## 📦 可用镜像

### 完整应用镜像
```bash
# 包含前端和后端的完整镜像
docker pull ghcr.io/727566105/videoall:latest
```

### 分离式镜像
```bash
# 后端服务
docker pull ghcr.io/727566105/videoall-backend:latest

# 前端服务
docker pull ghcr.io/727566105/videoall-frontend:latest
```

## 🔧 部署模式

### 1. 完整应用模式

使用单个容器运行前后端：

```yaml
version: '3.8'
services:
  app:
    image: ghcr.io/727566105/videoall:latest
    ports:
      - "80:80"
      - "3000:3000"
    environment:
      - POSTGRES_HOST=your-db-host
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=your-password
      - POSTGRES_DATABASE=video_all
    depends_on:
      - postgres
      - redis
```

### 2. 分离式部署（推荐）

前后端分离部署，便于扩展：

```yaml
version: '3.8'
services:
  backend:
    image: ghcr.io/727566105/videoall-backend:latest
    ports:
      - "3000:3000"
    environment:
      - POSTGRES_HOST=postgres
      # ... 其他环境变量

  frontend:
    image: ghcr.io/727566105/videoall-frontend:latest
    ports:
      - "80:80"
    depends_on:
      - backend
```

### 3. 开发模式

支持热重载的开发环境：

```bash
# 使用开发配置
docker-compose -f docker-compose.dev.yml up --build -d
```

## ⚙️ 环境变量配置

### 必需配置

```env
# 数据库配置（Docker Compose 内置）
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=video_all
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password-here

# JWT 配置
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

### 可选配置

```env
# 应用配置
NODE_ENV=production
BACKEND_PORT=3000
FRONTEND_PORT=80

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379

# 存储配置
STORAGE_ROOT_PATH=/app/media

# 镜像配置
GITHUB_REPOSITORY=727566105/videoall
IMAGE_TAG=latest
```

## 🗄️ 数据持久化

### 数据卷说明

```yaml
volumes:
  postgres_data:    # PostgreSQL 数据
  redis_data:       # Redis 数据
  media_data:       # 媒体文件存储
  logs_data:        # 应用日志
  backup_data:      # 备份文件
```

### 备份数据

```bash
# 备份数据库
docker-compose exec postgres pg_dump -U postgres video_all > backup.sql

# 备份媒体文件
docker run --rm -v videoall_media_data:/data -v $(pwd):/backup alpine tar czf /backup/media_backup.tar.gz -C /data .
```

## 🔍 监控和调试

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 健康检查

```bash
# 检查服务状态
docker-compose ps

# 测试后端 API
curl http://localhost:3000/api/v1/health

# 测试前端
curl http://localhost:80/health
```

### 进入容器调试

```bash
# 进入后端容器
docker-compose exec backend sh

# 进入前端容器
docker-compose exec frontend sh

# 进入数据库容器
docker-compose exec postgres psql -U postgres -d video_all
```

## 🚀 生产环境部署

### 1. 使用 Docker Swarm

```bash
# 初始化 Swarm
docker swarm init

# 部署服务栈
docker stack deploy -c docker-compose.yml videoall
```

### 2. 使用 Kubernetes

```yaml
# 创建 Kubernetes 部署文件
apiVersion: apps/v1
kind: Deployment
metadata:
  name: videoall-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: videoall-backend
  template:
    metadata:
      labels:
        app: videoall-backend
    spec:
      containers:
      - name: backend
        image: ghcr.io/727566105/videoall-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: POSTGRES_HOST
          value: "postgres-service"
```

### 3. 反向代理配置

#### Nginx

```nginx
upstream backend {
    server localhost:3000;
}

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:80;
    }

    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Traefik

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.videoall.rule=Host(`your-domain.com`)"
  - "traefik.http.routers.videoall.entrypoints=websecure"
```

## 🔄 CI/CD 集成

### GitHub Actions 自动部署

项目已配置 GitHub Actions，支持：

- ✅ 自动构建 Docker 镜像
- ✅ 推送到 GitHub Container Registry
- ✅ 多架构支持（AMD64/ARM64）
- ✅ 自动版本标签
- ✅ 安全扫描

### 触发构建

```bash
# 推送代码触发构建
git push origin main

# 创建版本标签触发发布
git tag v1.0.0
git push origin v1.0.0
```

### 使用特定版本

```yaml
services:
  backend:
    image: ghcr.io/727566105/videoall-backend:v1.0.0
  frontend:
    image: ghcr.io/727566105/videoall-frontend:v1.0.0
```

## 🛠️ 故障排除

### 常见问题

**1. 镜像拉取失败**
```bash
# 登录 GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 手动拉取镜像
docker pull ghcr.io/727566105/videoall:latest
```

**2. 数据库连接问题**
```bash
# 检查数据库容器
docker-compose ps postgres

# 测试连接
docker-compose exec backend node -e "console.log('DB Test')"
```

**3. 端口冲突**
```bash
# 修改端口映射
BACKEND_PORT=3001 FRONTEND_PORT=8080 docker-compose up -d
```

### 性能优化

```yaml
# 限制容器资源
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

## 📚 更多资源

- [完整部署指南](DEPLOYMENT.md)
- [API 文档](docs/api/)
- [故障排除指南](docs/troubleshooting.md)
- [GitHub 仓库](https://github.com/727566105/videoAll)

---

**快速部署，轻松使用！** 🎉
# 🚀 videoAll 快速部署指南

## 📋 一键部署

### 方式一：使用预构建镜像（推荐）

```bash
# 1. 下载配置文件
curl -O https://raw.githubusercontent.com/727566105/videoAll/feature/docker-support/docker-compose.yml
curl -O https://raw.githubusercontent.com/727566105/videoAll/feature/docker-support/.env.docker.example

# 2. 配置环境变量
cp .env.docker.example .env

# 3. 编辑数据库配置（重要！）
nano .env
# 修改 POSTGRES_HOST、POSTGRES_PASSWORD 等配置

# 4. 启动服务
docker-compose up -d

# 5. 验证部署
curl http://localhost:3000/api/v1/health
curl http://localhost:80/
```

### 方式二：从源码构建

```bash
# 1. 克隆仓库
git clone -b feature/docker-support https://github.com/727566105/videoAll.git
cd videoAll

# 2. 配置环境变量
cp .env.docker.example .env
nano .env  # 修改数据库配置

# 3. 构建并启动
docker-compose up --build -d
```

## ⚙️ 环境变量配置

### 必须修改的配置

```env
# 数据库配置
POSTGRES_HOST=你的数据库地址
POSTGRES_PASSWORD=你的数据库密码

# JWT 密钥（生产环境必须修改）
JWT_SECRET=你的超级安全密钥
```

### 可选配置

```env
# 端口配置
BACKEND_PORT=3000
FRONTEND_PORT=80

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379
```

## 🔍 验证部署

### 自动验证脚本

```bash
# Linux/Mac
./verify-deployment.sh

# Windows
verify-deployment.bat
```

### 手动验证

```bash
# 检查服务状态
docker-compose ps

# 检查后端健康状态
curl http://localhost:3000/api/v1/health

# 检查前端访问
curl http://localhost:80/

# 查看日志
docker-compose logs -f
```

## 📊 服务访问

- **前端应用**: http://localhost:80
- **后端 API**: http://localhost:3000
- **API 文档**: http://localhost:3000/api-docs
- **健康检查**: http://localhost:3000/api/v1/health

## 🔧 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 更新镜像
docker-compose pull
docker-compose up -d

# 清理数据（谨慎使用）
docker-compose down -v
```

## 🛠️ 故障排除

### 常见问题

**1. 数据库连接失败**
```bash
# 检查数据库配置
grep POSTGRES .env

# 测试数据库连接
docker-compose exec backend node -e "console.log('DB Test')"
```

**2. 端口冲突**
```bash
# 修改端口
echo "BACKEND_PORT=3001" >> .env
echo "FRONTEND_PORT=8080" >> .env
docker-compose up -d
```

**3. 镜像拉取失败**
```bash
# 手动拉取镜像
docker pull ghcr.io/727566105/videoall-backend:latest
docker pull ghcr.io/727566105/videoall-frontend:latest
```

### 查看详细日志

```bash
# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres

# 查看实时日志
docker-compose logs -f --tail=100
```

## 📚 更多资源

- [完整部署指南](DEPLOYMENT.md)
- [Docker 详细文档](README.Docker.md)
- [GitHub 仓库](https://github.com/727566105/videoAll)

---

**快速部署，轻松使用！** 🎉
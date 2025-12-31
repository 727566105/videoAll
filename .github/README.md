# 🚀 GitHub Actions CI/CD 快速开始

本项目的自动化 CI/CD 流程已完成配置，支持持续集成、Docker 镜像构建和版本发布。

## ✨ 功能特性

- ✅ **持续集成 (CI)**：自动测试、代码检查、安全扫描
- 🐳 **Docker 镜像构建**：自动构建并推送到 GHCR 和 Docker Hub
- 📦 **版本发布**：自动创建 GitHub Release 和 Docker 标签
- 🔔 **通知集成**：支持钉钉、Slack 通知
- 📊 **测试覆盖率**：自动生成测试报告
- 🔒 **安全扫描**：自动扫描代码和镜像漏洞

## 📦 工作流

### 1. CI 工作流 (.github/workflows/ci.yml)
- **触发条件**：推送代码到 `main`/`develop` 或创建 PR
- **执行任务**：后端测试、前端构建、安全扫描

### 2. Docker 构建工作流 (.github/workflows/docker-build.yml)
- **触发条件**：推送代码、推送标签、手动触发
- **执行任务**：构建 Docker 镜像、推送到镜像仓库

### 3. 版本发布工作流 (.github/workflows/release.yml)
- **触发条件**：推送版本标签、手动触发
- **执行任务**：创建 Release、发布镜像、打包发布

## 🚀 快速开始

### 1️⃣ 配置 Secrets

在 GitHub 仓库设置中添加以下 Secrets：

```bash
# 必需配置
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_token

# 可选配置（通知）
DINGTALK_WEBHOOK=https://oapi.dingtalk.com/robot/send?access_token=xxx
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx
```

### 2️⃣ 触发工作流

**自动触发 CI：**
```bash
git push origin main
```

**构建 Docker 镜像：**
```bash
git push origin main  # 推送代码
git tag v1.0.0
git push origin v1.0.0  # 推送标签触发构建
```

**手动触发：**
1. 进入 GitHub 仓库 → Actions
2. 选择工作流 → Run workflow

### 3️⃣ 使用 Docker 镜像

```bash
# 拉取镜像
docker pull ghcr.io/727566105/videoAll:latest

# 使用 Docker Compose 启动
docker-compose up -d

# 访问应用
# 前端：http://localhost:80
# 后端：http://localhost:3000
```

## 📋 版本发布

### 发布流程

```bash
# 1. 创建版本标签
git tag v1.0.0 -m "Release version 1.0.0"

# 2. 推送标签（自动触发 Release 工作流）
git push origin v1.0.0

# 3. 查看发布进度
# GitHub → Actions → 版本发布
```

### 版本号规范

遵循语义化版本 (Semantic Versioning)：
- `v1.0.0` - 正式版本
- `v1.0.0-beta.1` - 测试版本
- `v1.0.0-rc.1` - 候选版本

## 🐳 Docker 本地开发

```bash
# 复制环境变量
cp .env.docker.example .env

# 编辑配置
vim .env

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 📊 查看状态

- **工作流状态**：GitHub 仓库 → Actions 标签
- **镜像仓库**：https://github.com/727566105?tab=packages
- **Releases**：https://github.com/727566105/videoAll/releases

## 📚 详细文档

完整的配置和使用文档，请查看：[.github/DEPLOYMENT.md](.github/DEPLOYMENT.md)

## 🔧 故障排除

### 工作流失败
```bash
# 查看详细日志
GitHub → Actions → 选择工作流 → 查看日志
```

### Docker 镜像拉取失败
```bash
# 登录到 GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 登录到 Docker Hub
docker login -u USERNAME
```

### 本地构建测试
```bash
# 构建镜像
docker build -t videoall-test .

# 运行测试
docker run -p 3000:3000 videoall-test
```

## 🆘 获取帮助

- 查看 [.github/DEPLOYMENT.md](.github/DEPLOYMENT.md) 获取详细文档
- 提交 Issue 报告问题
- 查看 GitHub Actions 日志排查错误

---

**最后更新：** 2025-12-29

# GitHub Actions CI/CD 部署指南

本文档介绍如何使用 GitHub Actions 实现自动化构建、测试、发布和部署的完整流程。

## 📋 目录

- [概览](#概览)
- [前置准备](#前置准备)
- [工作流说明](#工作流说明)
- [配置 Secrets](#配置-secrets)
- [使用指南](#使用指南)
- [常见问题](#常见问题)

---

## 概览

本项目包含三个主要的 GitHub Actions 工作流：

### 1. 持续集成 (CI) - `.github/workflows/ci.yml`

**触发条件：**
- 推送代码到 `main` 或 `develop` 分支
- 创建针对 `main` 或 `develop` 分支的 Pull Request

**执行任务：**
- 后端测试和代码检查
- 前端构建和测试
- 安全漏洞扫描
- Python SDK 检查

### 2. Docker 镜像构建 - `.github/workflows/docker-build.yml`

**触发条件：**
- 推送代码到 `main` 或 `develop` 分支
- 推送版本标签（如 `v1.0.0`）
- 手动触发（workflow_dispatch）

**执行任务：**
- 构建后端、前端和完整应用的 Docker 镜像
- 推送镜像到 GitHub Container Registry (GHCR) 和 Docker Hub
- 生成镜像 SBOM（软件物料清单）
- 镜像安全扫描

### 3. 版本发布 - `.github/workflows/release.yml`

**触发条件：**
- 推送版本标签（如 `v1.0.0`）
- 手动触发

**执行任务：**
- 创建 GitHub Release
- 生成变更日志
- 构建并发布 Docker 镜像
- 构建并发布安装包
- 发送通知（钉钉、Slack）

---

## 前置准备

### 1. Docker Hub 账号（可选）

如果需要同时推送到 Docker Hub：

1. 注册账号：https://hub.docker.com/
2. 创建访问令牌：
   - 登录 Docker Hub
   - 进入 Account Settings → Security → New Access Token
   - 生成令牌并保存

### 2. GitHub Container Registry

GitHub 提供免费的容器镜像仓库：
- 仓库地址：`ghcr.io/727566105/videoAll`
- 自动使用 GitHub Token 认证，无需额外配置

### 3. 通知配置（可选）

**钉钉机器人：**
1. 在钉钉群设置中添加自定义机器人
2. 选择安全设置（建议使用关键词或签名）
3. 获取 Webhook URL

**Slack：**
1. 创建 Incoming Webhook
2. 获取 Webhook URL

---

## 配置 Secrets

在 GitHub 仓库中配置以下 Secrets：

### 必需配置

| Secret 名称 | 说明 | 获取方法 |
|------------|------|----------|
| `GITHUB_TOKEN` | GitHub Token | 自动提供，无需配置 |
| `DOCKERHUB_USERNAME` | Docker Hub 用户名 | Docker Hub 账号用户名 |
| `DOCKERHUB_TOKEN` | Docker Hub 访问令牌 | Docker Hub → Security → Access Tokens |

### 可选配置

| Secret 名称 | 说明 | 用途 |
|------------|------|------|
| `DINGTALK_WEBHOOK` | 钉钉机器人 Webhook | 发送发布通知 |
| `SLACK_WEBHOOK_URL` | Slack Webhook URL | 发送发布通知 |

### 配置步骤

1. 进入仓库设置页面
   ```
   https://github.com/727566105/videoAll/settings/secrets/actions
   ```

2. 点击 "New repository secret"

3. 填写 Secret 名称和值

4. 点击 "Add secret"

---

## 工作流说明

### CI 工作流详解

```yaml
# 触发条件
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
```

**主要任务：**

1. **后端测试**
   - 启动 PostgreSQL 数据库服务容器
   - 安装依赖并运行测试
   - 生成测试覆盖率报告
   - 上传覆盖率到 Codecov（可选）

2. **前端构建**
   - 安装依赖并运行代码检查
   - 构建生产版本
   - 上传构建产物

3. **安全扫描**
   - 使用 Trivy 扫描代码漏洞
   - 上传扫描结果到 GitHub Security

4. **Python SDK 检查**
   - 代码检查（flake8）
   - 运行单元测试

### Docker 构建工作流详解

**构建策略：**

```yaml
tags: |
  type=ref,event=branch          # 分支名
  type=ref,event=pr              # PR 编号
  type=semver,pattern={{version}} # 完整版本号（如 1.0.0）
  type=semver,pattern={{major}}.{{minor}} # 主.次版本号（如 1.0）
  type=semver,pattern={{major}}  # 主版本号（如 1）
  type=sha,prefix={{branch}}-    # commit SHA
  type=raw,value=latest          # latest 标签（仅 main 分支）
```

**镜像命名：**

- GitHub Container Registry:
  - `ghcr.io/727566105/videoAll/backend:latest`
  - `ghcr.io/727566105/videoAll/frontend:latest`
  - `ghcr.io/727566105/videoAll:latest`

- Docker Hub:
  - `docker.io/<username>/videoAll-backend:latest`
  - `docker.io/<username>/videoAll-frontend:latest`
  - `docker.io/<username>/videoAll:latest`

### 版本发布工作流详解

**版本号规范：**

遵循语义化版本 (Semantic Versioning)：
- `v1.0.0` - 主版本.次版本.补丁版本
- `v1.0.0-beta.1` - 预发布版本
- `v1.0.0-rc.1` - 候选发布版本

**生成的 Release 包含：**

1. 版本标签和 Release 说明
2. Docker 镜像（多标签）
3. 源代码压缩包
4. 变更日志（自动生成）

---

## 使用指南

### 1. 本地开发

使用 Docker Compose 启动本地开发环境：

```bash
# 复制环境变量配置
cp .env.docker.example .env

# 编辑配置
vim .env

# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 停止并清理数据
docker-compose down -v
```

### 2. 触发 CI 工作流

**自动触发：**
```bash
# 推送代码到 main 或 develop 分支
git push origin main

# 创建 PR
git checkout -b feature/new-feature
git push origin feature/new-feature
# 然后在 GitHub 上创建 PR
```

### 3. 构建 Docker 镜像

**自动构建：**
```bash
# 推送标签触发构建
git tag v1.0.0
git push origin v1.0.0
```

**手动触发：**
1. 进入 GitHub 仓库
2. 点击 "Actions" 标签
3. 选择 "Docker 镜像构建与发布" 工作流
4. 点击 "Run workflow"
5. 选择分支并配置参数

### 4. 创建版本发布

**方式一：通过标签（推荐）**
```bash
# 创建版本标签
git tag v1.0.0 -m "Release version 1.0.0"

# 推送标签
git push origin v1.0.0
```

**方式二：手动触发**
1. 进入 "Actions" → "版本发布"
2. 点击 "Run workflow"
3. 输入版本号（如 `v1.0.0`）
4. 选择是否为预发布版本

### 5. 拉取镜像

```bash
# 从 GitHub Container Registry 拉取
docker pull ghcr.io/727566105/videoAll:latest

# 从 Docker Hub 拉取
docker pull <username>/videoAll:latest

# 运行容器
docker run -d \
  --name videoall \
  -p 3000:3000 \
  -e POSTGRES_HOST=your_db_host \
  -e POSTGRES_PASSWORD=your_password \
  ghcr.io/727566105/videoAll:latest
```

### 6. 使用 Docker Compose 部署

创建 `docker-compose.prod.yml`：

```yaml
version: '3.8'

services:
  backend:
    image: ghcr.io/727566105/videoAll/backend:latest
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    ports:
      - "3000:3000"

  frontend:
    image: ghcr.io/727566105/videoAll/frontend:latest
    ports:
      - "80:80"

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

启动：
```bash
docker-compose -f docker-compose.prod.yml up -d
```

---

## 版本管理

### 分支策略

```
main (生产)
  ↑
  ├── develop (开发)
  │     ↑
  │     ├── feature/xxx (功能分支)
  │     ├── fix/xxx (修复分支)
  │     └── hotfix/xxx (紧急修复)
```

### 提交规范

使用 Conventional Commits：

```
feat: 新功能
fix: 修复问题
docs: 文档更新
style: 代码格式（不影响功能）
refactor: 重构
test: 测试相关
chore: 构建/工具链相关
```

示例：
```bash
git commit -m "feat(content): 添加批量删除功能"
git commit -m "fix(auth): 修复 JWT 令牌过期问题"
git commit -m "docs(readme): 更新部署说明"
```

### 发布流程

1. **功能开发**
   ```bash
   git checkout -b feature/new-feature
   # 开发并提交
   git push origin feature/new-feature
   # 创建 PR 到 develop
   ```

2. **合并到 develop**
   ```bash
   # PR 审查通过后合并
   git checkout develop
   git pull origin develop
   ```

3. **发布准备**
   ```bash
   git checkout -b release/v1.0.0
   # 更新版本号、更新日志
   # 创建 PR 到 main
   ```

4. **正式发布**
   ```bash
   # PR 合并后，在 main 分支创建标签
   git checkout main
   git pull origin main
   git tag v1.0.0
   git push origin v1.0.0
   ```

---

## 常见问题

### 1. CI 工作流失败

**问题：** 测试失败
```
解决方案：检查代码是否引入错误，查看详细日志
```

**问题：** 构建超时
```
解决方案：增加 timeout 设置或优化构建流程
```

### 2. Docker 镜像推送失败

**问题：** 认证失败
```
解决方案：
1. 检查 Docker Hub Token 是否正确
2. 确认 GITHUB_TOKEN 有写入权限
```

**问题：** 镜像过大
```
解决方案：
1. 使用多阶段构建（已配置）
2. 清理不必要的文件
3. 使用 .dockerignore
```

### 3. Release 创建失败

**问题：** 标签格式错误
```
解决方案：确保标签格式为 v*.*.*，如 v1.0.0
```

**问题：** 变更日志为空
```
解决方案：检查 commit message 是否符合规范
```

### 4. 镜像扫描发现漏洞

**问题：** 高危漏洞
```
解决方案：
1. 更新基础镜像版本
2. 升级依赖包版本
3. 等待上游修复
```

---

## 监控与日志

### 查看工作流状态

1. 进入 GitHub 仓库
2. 点击 "Actions" 标签
3. 查看工作流执行历史

### 查看日志

1. 点击具体的工作流运行
2. 选择要查看的任务
3. 查看详细日志

### 下载构建产物

1. 进入工作流运行页面
2. 滚动到页面底部的 "Artifacts" 部分
3. 下载所需的产物

---

## 安全最佳实践

1. **使用 Secrets 管理敏感信息**
   - 不要在代码中硬编码密码、令牌
   - 定期轮换密钥

2. **最小权限原则**
   - 仅授予必要的权限
   - 使用专用的服务账号

3. **定期扫描漏洞**
   - 自动扫描已配置
   - 修复高危漏洞

4. **镜像安全**
   - 使用官方基础镜像
   - 及时更新镜像版本
   - 使用非 root 用户运行（已配置）

5. **网络安全**
   - 使用 HTTPS
   - 配置防火墙规则
   - 使用私有网络

---

## 参考资源

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Docker 官方文档](https://docs.docker.com/)
- [语义化版本](https://semver.org/lang/zh-CN/)
- [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

---

## 支持

如有问题，请：
1. 查看本文档的"常见问题"部分
2. 检查 GitHub Actions 日志
3. 提交 Issue

---

**文档更新时间：** 2025-12-29

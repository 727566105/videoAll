# GitHub Actions CI/CD 完整配置指南

## 🎯 概述

本项目实现了完整的 GitHub Actions 自动化 CI/CD 流程，包括：

- ✅ 自动化测试和代码质量检查
- ✅ Docker 镜像构建和推送
- ✅ 安全漏洞扫描
- ✅ 自动版本发布
- ✅ 部署通知和监控
- ✅ 依赖自动更新

## 📁 文件结构

```
.github/
├── workflows/
│   ├── ci-cd.yml              # 主CI/CD流程
│   └── dependency-update.yml  # 依赖更新流程
├── ISSUE_TEMPLATE/            # Issue模板
└── PULL_REQUEST_TEMPLATE.md   # PR模板

scripts/
├── release.sh                 # 版本发布脚本
└── deploy.sh                  # 部署脚本

docker-compose.yml             # Docker编排配置
.env.example                   # 环境变量模板
Dockerfile (backend/frontend)  # Docker镜像构建文件
```

## 🔄 CI/CD 工作流程

### 1. 代码提交触发

```yaml
on:
  push:
    branches: [main, develop]
    tags: ["v*"]
  pull_request:
    branches: [main]
```

### 2. 测试阶段 (test job)

- **代码检出**: 获取最新代码
- **Node.js 环境**: 设置 Node.js 22.x 环境
- **依赖缓存**: 缓存 npm 依赖提高构建速度
- **后端测试**: 安装依赖、代码检查、运行测试
- **前端构建**: 安装依赖、代码检查、构建生产版本
- **构建产物**: 上传前端构建结果供后续使用

### 3. 镜像构建阶段 (build job)

- **多平台构建**: 支持 linux/amd64 和 linux/arm64
- **镜像标签**: 自动生成语义化标签
- **缓存优化**: 使用 GitHub Actions 缓存加速构建
- **推送到 GHCR**: 推送到 GitHub Container Registry

### 4. 安全扫描阶段 (security-scan job)

- **Trivy 扫描**: 扫描 Docker 镜像安全漏洞
- **SARIF 报告**: 生成安全报告并上传到 GitHub Security

### 5. 版本发布阶段 (release job)

- **变更日志**: 自动生成基于 Git 提交的变更日志
- **GitHub Release**: 创建正式版本发布
- **镜像信息**: 在发布说明中包含镜像标签和摘要

### 6. 通知阶段 (notify job)

- **状态通知**: 发送部署状态通知
- **Slack 集成**: 可选的 Slack 通知支持

## 🏷️ 镜像标签策略

### 自动标签生成

```yaml
tags: |
  type=ref,event=branch          # 分支名标签
  type=ref,event=pr              # PR标签
  type=semver,pattern={{version}} # 语义化版本
  type=semver,pattern={{major}}.{{minor}}
  type=semver,pattern={{major}}
  type=sha,prefix={{branch}}-    # Git SHA标签
  type=raw,value=latest,enable={{is_default_branch}}
```

### 标签示例

- `main` - 主分支最新版本
- `v1.2.3` - 具体版本号
- `1.2` - 主要版本
- `1` - 大版本
- `main-abc1234` - 分支+提交 SHA
- `latest` - 最新稳定版本

## 🔐 安全配置

### GitHub Secrets 配置

在 GitHub 仓库设置中配置以下 Secrets：

```bash
# 必需的Secrets
GITHUB_TOKEN          # 自动生成，用于GHCR推送

# 可选的Secrets
SLACK_WEBHOOK         # Slack通知webhook
DOCKER_HUB_USERNAME   # Docker Hub用户名（如果使用）
DOCKER_HUB_TOKEN      # Docker Hub访问令牌（如果使用）
```

### 权限配置

确保 GitHub Actions 具有以下权限：

```yaml
permissions:
  contents: read
  packages: write
  security-events: write
  actions: read
```

## 🚀 版本发布流程

### 自动发布

1. **创建标签**:

   ```bash
   ./scripts/release.sh 1.2.3
   ```

2. **自动触发**:

   - GitHub Actions 检测到标签推送
   - 自动构建和测试
   - 构建 Docker 镜像
   - 执行安全扫描
   - 创建 GitHub Release

3. **发布内容**:
   - 自动生成的变更日志
   - Docker 镜像信息
   - 安全扫描结果
   - 构建产物

### 手动发布

```bash
# 1. 更新版本
git tag -a v1.2.3 -m "Release version 1.2.3"

# 2. 推送标签
git push origin v1.2.3

# 3. GitHub Actions自动处理后续流程
```

## 📦 Docker 镜像管理

### 镜像仓库

- **主仓库**: GitHub Container Registry (ghcr.io)
- **备用仓库**: Docker Hub (可配置)

### 镜像命名

```bash
# 后端镜像
ghcr.io/username/videoall-backend:latest
ghcr.io/username/videoall-backend:v1.2.3

# 前端镜像
ghcr.io/username/videoall-frontend:latest
ghcr.io/username/videoall-frontend:v1.2.3
```

### 镜像使用

```bash
# 拉取最新镜像
docker pull ghcr.io/username/videoall-backend:latest

# 使用特定版本
docker pull ghcr.io/username/videoall-backend:v1.2.3
```

## 🔧 本地开发集成

### 开发环境

```bash
# 启动开发环境
docker-compose -f docker-compose.dev.yml up -d

# 查看日志
docker-compose logs -f
```

### 测试 CI/CD

```bash
# 本地测试构建
docker build -t test-backend ./backend
docker build -t test-frontend ./frontend

# 测试部署脚本
./scripts/deploy.sh --environment development
```

## 📊 监控和维护

### 构建状态监控

- **GitHub Actions 页面**: 查看构建历史和状态
- **安全扫描结果**: Security 标签页查看漏洞报告
- **镜像仓库**: Packages 页面管理镜像

### 自动化维护

- **依赖更新**: 每周一自动检查并创建 PR
- **安全扫描**: 每次构建自动执行
- **缓存清理**: 自动清理过期的构建缓存

## 🚨 故障排除

### 常见问题

#### 1. 构建失败

```bash
# 检查GitHub Actions日志
# 在仓库的Actions标签页查看详细日志

# 本地复现问题
docker build -t debug-image ./backend --no-cache
```

#### 2. 镜像推送失败

```bash
# 检查GITHUB_TOKEN权限
# 确保仓库设置中启用了包权限

# 手动测试推送
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

#### 3. 安全扫描失败

```bash
# 查看Trivy扫描结果
# 在Security标签页查看详细报告

# 本地运行安全扫描
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image your-image:tag
```

### 调试技巧

1. **启用调试日志**:

   ```yaml
   - name: Debug
     run: |
       echo "Debug information"
       env
       docker images
   ```

2. **使用 tmate 调试**:
   ```yaml
   - name: Setup tmate session
     uses: mxschmitt/action-tmate@v3
   ```

## 📈 性能优化

### 构建优化

- **并行构建**: 多个 job 并行执行
- **缓存策略**: 有效利用 GitHub Actions 缓存
- **多阶段构建**: Docker 多阶段构建减少镜像大小
- **依赖缓存**: npm 依赖缓存加速安装

### 部署优化

- **滚动更新**: 零停机部署
- **健康检查**: 确保服务正常启动
- **回滚机制**: 快速回滚到上一版本

## 🔮 扩展功能

### 可添加的功能

1. **多环境部署**: 支持 dev/staging/prod 环境
2. **性能测试**: 集成性能测试工具
3. **代码覆盖率**: 集成代码覆盖率报告
4. **自动化测试**: 端到端测试集成
5. **蓝绿部署**: 实现蓝绿部署策略

### 集成建议

1. **监控系统**: Prometheus + Grafana
2. **日志聚合**: ELK Stack 或 Loki
3. **错误追踪**: Sentry 集成
4. **API 文档**: 自动生成和部署 API 文档

## 📚 参考资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [容器安全指南](https://kubernetes.io/docs/concepts/security/)
- [CI/CD 最佳实践](https://docs.gitlab.com/ee/ci/pipelines/pipeline_efficiency.html)

---

通过这套完整的 CI/CD 配置，项目实现了从代码提交到生产部署的全自动化流程，确保了代码质量、安全性和部署的可靠性。

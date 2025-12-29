# GitHub Actions Secrets 引用问题修复

## 🐛 问题描述

在 GitHub Actions 工作流中，出现了以下错误：

```
无效的工作流程文件： .github/workflows/release.yml#L1
（行：252，列：13）：未识别的命名值：'secrets'。位于表达式中的位置 1：secrets.DINGTALK_WEBHOOK
（行：266，列：13）：未识别的命名值：'secrets'。位于表达式中的位置 1：secrets.SLACK_WEBHOOK_URL
```

## 🔍 根本原因

在 GitHub Actions 的 `if` 条件中，直接使用 `${{ secrets.SECRET_NAME }}` 来检查 secrets 是否存在是不正确的语法。

## ✅ 修复方案

### 错误的写法：

```yaml
- name: 发送钉钉通知 (可选)
  if: ${{ secrets.DINGTALK_WEBHOOK }} # ❌ 错误
```

### 正确的写法：

```yaml
- name: 发送钉钉通知 (可选)
  if: ${{ secrets.DINGTALK_WEBHOOK != '' }} # ✅ 正确
```

## 🔧 已修复的文件

### 1. `.github/workflows/release.yml`

**修复前：**

```yaml
- name: 发送钉钉通知 (可选)
  if: ${{ secrets.DINGTALK_WEBHOOK }}

- name: 发送 Slack 通知 (可选)
  if: ${{ secrets.SLACK_WEBHOOK_URL }}
```

**修复后：**

```yaml
- name: 发送钉钉通知 (可选)
  if: ${{ secrets.DINGTALK_WEBHOOK != '' }}

- name: 发送 Slack 通知 (可选)
  if: ${{ secrets.SLACK_WEBHOOK_URL != '' }}
```

### 2. `.github/workflows/ci-cd.yml`

**修复前：**

```yaml
- name: Slack Notification
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

**修复后：**

```yaml
- name: Slack Notification
  if: always() && secrets.SLACK_WEBHOOK != ''
  uses: 8398a7/action-slack@v3
  with:
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 📋 Secrets 检查的最佳实践

### 1. 检查 Secret 是否存在且不为空

```yaml
if: ${{ secrets.SECRET_NAME != '' }}
```

### 2. 检查多个条件

```yaml
if: ${{ secrets.SECRET_NAME != '' && github.event_name == 'push' }}
```

### 3. 在步骤中使用 continue-on-error

```yaml
- name: 可选通知
  if: ${{ secrets.WEBHOOK_URL != '' }}
  run: |
    curl -X POST "${{ secrets.WEBHOOK_URL }}" -d "message"
  continue-on-error: true
```

## 🔐 推荐的 Secrets 配置

在 GitHub 仓库的 Settings > Secrets and variables > Actions 中配置以下 secrets：

### 必需的 Secrets

- `GITHUB_TOKEN` - 自动生成，用于推送镜像到 GHCR

### 可选的 Secrets

- `SLACK_WEBHOOK` - Slack 通知 webhook URL
- `DINGTALK_WEBHOOK` - 钉钉通知 webhook URL
- `DOCKERHUB_USERNAME` - Docker Hub 用户名
- `DOCKERHUB_TOKEN` - Docker Hub 访问令牌

## 🧪 测试验证

修复后，可以通过以下方式验证：

1. **推送代码到分支**：

   ```bash
   git add .
   git commit -m "fix: GitHub Actions secrets reference"
   git push origin main
   ```

2. **创建测试标签**：

   ```bash
   git tag -a v0.1.0-test -m "Test release"
   git push origin v0.1.0-test
   ```

3. **检查 Actions 页面**：
   - 访问 GitHub 仓库的 Actions 标签页
   - 查看工作流是否正常运行
   - 确认没有语法错误

## 🚨 常见错误和解决方案

### 错误 1: 直接使用 secrets 作为布尔值

```yaml
# ❌ 错误
if: ${{ secrets.SECRET_NAME }}

# ✅ 正确
if: ${{ secrets.SECRET_NAME != '' }}
```

### 错误 2: 在 env 中重复定义

```yaml
# ❌ 错误 - 重复定义
with:
  webhook_url: ${{ secrets.WEBHOOK }}
env:
  WEBHOOK_URL: ${{ secrets.WEBHOOK }}

# ✅ 正确 - 只在需要的地方定义
with:
  webhook_url: ${{ secrets.WEBHOOK }}
```

### 错误 3: 忘记添加 continue-on-error

```yaml
# ❌ 可能导致工作流失败
- name: 发送通知
  run: curl -X POST "${{ secrets.WEBHOOK }}" -d "data"

# ✅ 正确 - 通知失败不影响主流程
- name: 发送通知
  run: curl -X POST "${{ secrets.WEBHOOK }}" -d "data"
  continue-on-error: true
```

## 📚 参考资源

- [GitHub Actions - Using secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [GitHub Actions - Expressions](https://docs.github.com/en/actions/learn-github-actions/expressions)
- [GitHub Actions - Contexts](https://docs.github.com/en/actions/learn-github-actions/contexts)

## ✅ 修复确认

- [x] 修复 `.github/workflows/release.yml` 中的 secrets 引用
- [x] 修复 `.github/workflows/ci-cd.yml` 中的 secrets 引用
- [x] 验证其他工作流文件的 secrets 引用
- [x] 添加 `continue-on-error: true` 到可选通知步骤
- [x] 创建修复文档和最佳实践指南

所有 GitHub Actions 工作流文件中的 secrets 引用问题已修复，现在应该可以正常运行了。

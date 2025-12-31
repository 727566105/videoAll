# GitHub 资源清理指南

本文档提供清理 GitHub 仓库资源的详细步骤。

## ✅ 已完成的清理

### 1. 删除远程分支
- ✅ 已删除 `feature/docker-support` 分支

### 2. 清理无用文件
- ✅ 已删除 72 个无用文件
- ✅ 已清理 .github/workflows_backup/ 目录

---

## 🧹 需要手动清理的 GitHub 资源

### 一、清理 GHCR 旧镜像

#### 步骤：

1. **访问 GitHub Packages**
   - 打开：https://github.com/727566105/videoAll/packages
   - 登录你的 GitHub 账号

2. **查看所有镜像版本**
   你会看到以下包：
   - `videoall-backend` - 后端镜像
   - `videoall-frontend` - 前端镜像
   - `videoall` - 完整应用镜像（旧版，可以删除）

3. **删除旧镜像版本**
   - 点击进入每个包
   - 找到右侧的 "Package versions" 或 "Versions"
   - 勾选不需要的旧版本
   - 点击 "Delete package version" 按钮
   - 确认删除

   **建议保留：**
   - ✅ 保留 `latest` 标签
   - ✅ 保留最近 2-3 个版本
   - ❌ 删除所有其他旧版本

4. **删除不需要的包**
   - `videoall` 完整应用镜像可以完全删除（已被前后端分离镜像替代）
   - 点击包页面右上角的 "Delete package"
   - 输入仓库名称确认删除

---

### 二、清理 GitHub Actions 构建记录

#### 步骤：

1. **访问 Actions 页面**
   - 打开：https://github.com/727566105/videoAll/actions
   - 你会看到所有工作流运行记录

2. **删除失败的工作流运行**
   - 点击左侧的工作流名称（如 "Build and Push Docker Images"）
   - 勾选失败或不需要的运行记录
   - 点击右上角的 "..." 菜单
   - 选择 "Delete all workflow runs"
   - 确认删除

3. **清理各个工作流**
   需要清理的工作流：
   - ✅ `Build and Push Docker Images` - 保留最近 5-10 次成功记录
   - ✅ `Simple Release` - 保留最近版本
   - ✅ `Dependency Update` - 保留最近记录
   - ❌ 删除所有已归档或失败的工作流记录

---

### 三、清理 GitHub 缓存

#### 步骤：

1. **访问 Actions 缓存**
   - 打开：https://github.com/727566105/videoAll/actions/caches
   - 或者：Actions → 左侧菜单 "Caches"

2. **删除所有缓存**
   - 点击 "Delete all caches" 按钮
   - 确认删除

   **注意：** 删除缓存后，下次构建会重新下载依赖，构建时间会变长。

---

### 四、优化建议

#### 1. 设置镜像保留策略

在 `.github/workflows/docker-build-and-push.yml` 中添加：

```yaml
# 在 build-and-push 和 build-frontend 任务中添加
- name: Clean old images
  if: github.event_name != 'pull_request'
  run: |
    # 使用 GitHub CLI 删除旧版本（保留 latest 和最近 3 个版本）
    gh auth status
    # 需要手动配置
```

#### 2. 自动清理工作流运行

在仓库设置中配置：
- Settings → Actions → Workflow runs
- Set retention period: 7 days（或其他合适的值）

#### 3. 定期清理

建议每月执行一次清理：
- 删除不需要的镜像版本
- 清理旧的 Actions 运行记录
- 清理缓存

---

### 五、验证清理结果

清理完成后，验证：

1. **检查镜像**
   ```bash
   # 查看远程镜像标签
   gh repo view --json packages
   ```

2. **检查分支**
   ```bash
   # 查看所有远程分支
   git branch -r
   # 应该看不到 feature/docker-support
   ```

3. **检查仓库大小**
   - 仓库页面底部会显示仓库大小
   - 清理后应该有所减小

---

### 六、清理脚本（可选）

如果你想使用 GitHub CLI 自动化清理，可以创建以下脚本：

```bash
#!/bin/bash
# cleanup-github.sh

# 删除旧的 Actions 运行记录
gh run list --limit 100 --json databaseId --jq '.[].databaseId' | \
  xargs -I {} gh run delete {}

# 删除所有缓存
gh cache delete --all

echo "清理完成！"
```

使用方法：
```bash
chmod +x cleanup-github.sh
./cleanup-github.sh
```

---

## 📊 清理前后对比

| 资源类型 | 清理前 | 清理后 | 节省 |
|---------|--------|--------|------|
| 远程分支 | 4 个 | 2 个 | -2 个 |
| 镜像版本 | 20+ 个 | 3-5 个 | -15+ 个 |
| Actions 记录 | 100+ 条 | 10-20 条 | -80+ 条 |
| 缓存大小 | ~5 GB | ~1 GB | -4 GB |

---

## ⚠️ 注意事项

1. **不可逆操作**
   - 删除镜像版本后无法恢复
   - 删除 Actions 记录后无法恢复
   - 删除分支后无法恢复（除非有本地备份）

2. **保留重要内容**
   - 始终保留 `latest` 标签
   - 保留最近几个稳定版本
   - 保留重要的 Release 记录

3. **权限要求**
   - 需要仓库管理员权限
   - 需要包管理权限

---

## ✅ 清理检查清单

- [ ] 删除 `feature/docker-support` 远程分支
- [ ] 删除 `videoall` 完整应用镜像
- [ ] 删除旧版本镜像（保留 latest 和最近 2-3 个版本）
- [ ] 清理失败的工作流运行记录
- [ ] 清理旧的 Actions 运行记录（保留最近 10 条）
- [ ] 清理所有缓存
- [ ] 验证清理结果

---

## 📞 需要帮助？

如果清理过程中遇到问题：

1. 查看 GitHub 官方文档：
   - [Managing packages](https://docs.github.com/en/packages/learn-github-packages)
   - [Managing GitHub Actions](https://docs.github.com/en/actions)

2. 联系仓库维护者：727566105@qq.com

---

**清理完成后，仓库将更加整洁，构建速度也会更快！**

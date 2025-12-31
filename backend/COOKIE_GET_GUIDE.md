# 抖音Cookie快速获取指南

## 🚀 快速获取方法（3种方式）

### 方法1: 自动化脚本（最推荐）⭐

**优点**: 自动化、快速、可重复使用
**时间**: 1-2分钟

#### 使用步骤：

```bash
# 1. 进入后端目录
cd backend

# 2. 运行自动化脚本
node get-douyin-cookie.js

# 3. 在打开的浏览器中扫码登录（30秒内）

# 4. 等待脚本自动获取Cookie并保存到 douyin-cookie.txt

# 5. 复制Cookie到剪贴板
cat douyin-cookie.txt | pbcopy  # Mac
type douyin-cookie.txt | clip    # Windows
```

#### 无头模式（高级用户）：

```bash
# 不显示浏览器窗口（需要预先登录过）
node get-douyin-cookie.js --headless
```

#### 脚本特点：

- ✅ 自动打开浏览器访问抖音
- ✅ 自动检测登录状态
- ✅ 自动提取所有Cookie
- ✅ 保存到文件方便复制
- ✅ 支持无头模式
- ✅ 显示关键字段验证

---

### 方法2: 浏览器开发者工具（手动方式）

**优点**: 无需额外工具
**时间**: 2-3分钟

#### Chrome/Edge浏览器：

1. **打开抖音网站**
   - 访问 https://www.douyin.com
   - 登录你的抖音账号

2. **打开开发者工具**
   - 按 `F12` 键（Windows）
   - 或 `Cmd+Option+I`（Mac）
   - 切换到 **Network** 标签

3. **获取Cookie**
   - 刷新页面
   - 点击任意请求（如第一个请求）
   - 在右侧 **Headers** 中找到 **Cookie**
   - 复制整个Cookie字符串

#### Cookie格式示例：

```
sessionid=xxx; sessionid_ss=xxx; ttwid=xxx; passport_csrf_token=xxx; __ac_nonce=xxx; __ac_signature=xxx
```

---

### 方法3: 浏览器扩展（最便捷）

**优点**: 一键导出、格式友好
**时间**: 1分钟

#### 推荐扩展：

**Chrome/Edge**:
- **EditThisCookie** - 最流行的Cookie管理器
  - 下载: https://chrome.google.com/webstore/detail/editthiscookie/
  - 使用: 打开扩展 → 导出 → 复制

**Firefox**:
- **Cookie-Editor**
  - 下载: https://addons.mozilla.org/firefox/addon/cookie-editor/
  - 使用: 打开扩展 → Export → 复制

#### 使用步骤：

1. 安装扩展
2. 访问 https://www.douyin.com 并登录
3. 点击扩展图标
4. 选择"导出"或"Export"
5. 复制Cookie字符串

---

## 📋 配置Cookie到系统

### 通过前端界面（推荐）：

1. **访问配置页面**
   ```
   http://localhost:5173/config
   ```

2. **添加Cookie**
   - 切换到"平台账号配置"标签
   - 点击"添加Cookie"按钮
   - 填写信息：
     * **平台**: 选择 `douyin`
     * **账户别名**: 例如"我的抖音账号"
     * **Cookie**: 粘贴获取的Cookie
   - 点击"保存"

3. **验证有效性**
   - 系统会自动测试Cookie
   - 显示 ✓ 有效 或 ✗ 无效

### 通过API（高级用户）：

```bash
curl -X POST http://localhost:3000/api/v1/config/platform-cookies \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "douyin",
    "account_alias": "我的抖音账号",
    "cookies": "sessionid=xxx; sessionid_ss=xxx; ttwid=xxx"
  }'
```

---

## 🔧 Cookie管理

### 查看所有Cookie

```bash
# 前端界面
访问 http://localhost:5173/config → 平台账号配置

# API
curl http://localhost:3000/api/v1/config/platform-cookies
```

### 测试Cookie有效性

```bash
# 前端界面：在Cookie列表中点击"测试"按钮

# API
curl -X POST http://localhost:3000/api/v1/config/platform-cookies/<ID>/test
```

### 更新Cookie

```bash
# 前端界面：点击"编辑"按钮，修改后保存

# API
curl -X PUT http://localhost:3000/api/v1/config/platform-cookies/<ID> \
  -H "Content-Type: application/json" \
  -d '{"cookies": "新的Cookie字符串"}'
```

---

## 📊 效果对比

| 模式 | 解析成功率 | 说明 |
|------|-----------|------|
| **无Cookie** | 50-70% | 基础模式，易被反爬虫拦截 |
| **有Cookie** | 80-95% | 认证模式，绕过大部分限制 |

---

## ⚠️ 常见问题

### Q1: Cookie有效期多久？

**A**: 通常7-30天，建议：
- 每周更新一次
- 使用活跃账号的Cookie
- 配置多个Cookie作为备份

### Q2: 如何快速复制Cookie到剪贴板？

**A**: 使用命令：

```bash
# Mac
cat backend/douyin-cookie.txt | pbcopy

# Windows
type backend\douyin-cookie.txt | clip

# Linux
cat backend/douyin-cookie.txt | xclip -selection clipboard
```

### Q3: 脚本运行失败怎么办？

**A**: 可能原因和解决方案：

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `Cannot find module 'puppeteer'` | 未安装依赖 | 运行 `npm install` |
| `Timeout` | 登录超时 | 重新运行，确保30秒内完成登录 |
| `无法打开浏览器` | 权限问题 | 添加 `--no-sandbox` 参数 |

### Q4: Cookie配置后解析仍然失败？

**A**: 检查以下几点：

1. **Cookie是否完整复制**
   - 确保复制了整个Cookie字符串
   - 不要遗漏分号和空格

2. **Cookie是否有效**
   - 在系统配置页面点击"测试"按钮
   - 重新获取Cookie

3. **视频是否可访问**
   - 尝试其他公开视频
   - 检查视频是否被删除或私密

### Q5: 如何验证Cookie被使用？

**A**: 查看后端日志：

```bash
# 查看实时日志
tail -f backend/logs/combined.log

# 看到这行说明Cookie被使用
✓ 使用douyin平台Cookie (账户: 我的抖音账号)

# 看到这行说明没有Cookie
⚠ 未找到douyin平台的有效Cookie，将使用无Cookie模式
```

---

## 🔐 安全建议

1. **使用小号**
   - 不要使用主账号
   - 专门注册小号用于解析

2. **定期更换密码**
   - 每月更换一次抖音密码
   - Cookie会自动失效

3. **不要分享Cookie**
   - Cookie等同于登录凭证
   - 分享可能导致账号被盗

4. **加密存储**
   - 系统已对Cookie进行AES加密
   - 数据库中存储的是加密后的Cookie

---

## 📚 相关文件

- `backend/get-douyin-cookie.js` - 自动化Cookie获取脚本
- `backend/debug-douyin-cookie.js` - Cookie调试工具
- `抖音Cookie快速开始.md` - 快速配置指南
- `抖音Cookie集成完成报告.md` - 完整技术文档

---

## 🎯 推荐流程

**首次使用**：
1. 使用自动化脚本获取Cookie（方法1）
2. 配置到系统
3. 测试解析功能
4. 保存脚本以便后续更新Cookie

**定期更新**：
1. 每周运行一次脚本
2. 获取新Cookie
3. 更新系统配置

**批量配置**：
1. 准备多个抖音账号
2. 分别获取Cookie
3. 配置到系统作为备份
4. 系统会自动选择最新的有效Cookie

---

**准备好了吗？选择一种方式开始获取Cookie吧！** 🚀

推荐从 **方法1（自动化脚本）** 开始，最简单快捷！

# 一键获取Cookie功能使用指南

## 功能概述

现在可以在系统配置页面直接通过"一键获取Cookie"按钮自动获取平台Cookie，无需手动复制粘贴。

**支持平台**：
- ✅ 抖音 (douyin)
- ✅ 小红书 (xiaohongshu)
- ⏳ 哔哩哔哩 (bilibili) - 计划中
- ⏳ 微博 (weibo) - 计划中

---

## 使用步骤

### 步骤1: 打开系统配置页面

访问：`http://localhost:5173/config`

### 步骤2: 切换到"平台账号配置"标签

### 步骤3: 点击"添加平台账户"按钮

### 步骤4: 填写表单

1. **平台**: 选择 `douyin` 或 `xiaohongshu`
2. **账户别名**: 例如"我的抖音账号"

### 步骤5: 点击"一键获取Cookie"按钮 ⚡

- 系统会自动打开Chrome浏览器
- 在浏览器中扫码登录对应平台
- 等待60秒，系统会自动获取Cookie并填充到表单
- 浏览器会自动关闭

### 步骤6: 点击"添加"保存

系统会自动：
- 测试Cookie有效性
- 加密存储Cookie
- 标记有效性状态

---

## 功能特点

### 优点

1. **自动化程度高** - 无需手动复制粘贴
2. **用户友好** - 一个按钮完成所有操作
3. **安全性好** - Cookie自动加密存储
4. **即时验证** - 获取后立即测试有效性

### 流程说明

```
用户点击"一键获取Cookie"
  ↓
后端启动Puppeteer浏览器
  ↓
打开对应平台登录页面
  ↓
等待用户扫码登录（60秒）
  ↓
自动提取Cookie
  ↓
填充到前端表单
  ↓
用户点击"保存"
  ↓
Cookie加密存储到数据库
```

---

## 技术实现

### 后端API

**端点**: `GET /api/v1/config/platform-cookies/auto-fetch/:platform`

**参数**:
- `platform`: 平台名称（douyin, xiaohongshu）
- `headless`: 是否使用无头模式（可选，默认false）

**响应**:
```json
{
  "message": "Cookie获取成功",
  "data": {
    "platform": "douyin",
    "cookie": "sessionid=xxx; sessionid_ss=xxx; ...",
    "length": 6455
  }
}
```

### 前端界面

**文件**: [frontend/src/pages/PlatformConfig.jsx](frontend/src/pages/PlatformConfig.jsx)

**新增功能**:
- 自动获取Cookie按钮
- 实时状态提示
- Cookie自动填充

### 后端服务

**文件**: [backend/src/services/CookieAutoFetchService.js](backend/src/services/CookieAutoFetchService.js)

**功能**:
- Puppeteer浏览器控制
- 自动登录流程管理
- Cookie提取和格式化

---

## 常见问题

### Q1: 点击"一键获取Cookie"后发生什么？

**A**:
1. 后端启动Chrome浏览器
2. 自动打开对应平台的登录页面
3. 等待60秒供用户扫码登录
4. 登录后自动提取Cookie
5. Cookie自动填充到表单

### Q2: 为什么需要等待60秒？

**A**: 这是给用户足够的时间完成扫码登录。如果登录更快，浏览器会在60秒后自动关闭。

### Q3: 如果登录失败怎么办？

**A**:
1. 关闭浏览器窗口
2. 重新点击"一键获取Cookie"按钮
3. 再次尝试登录

### Q4: 获取到的Cookie安全吗？

**A**:
- ✅ Cookie通过网络传输（HTTPS）
- ✅ Cookie使用AES加密存储到数据库
- ✅ 不在前端显示完整Cookie
- ✅ 只在需要时解密使用

### Q5: 可以批量获取多个平台的Cookie吗？

**A**: 目前需要逐个平台获取。每次添加平台账户时都可以使用"一键获取"功能。

### Q6: 支持哪些平台？

**A**:
- ✅ 抖音 (douyin)
- ✅ 小红书 (xiaohongshu)
- ⏳ 其他平台计划中

---

## 对比：手动 vs 自动

| 方式 | 所需时间 | 操作步骤 | 难度 |
|------|---------|---------|------|
| **手动获取** | 3-5分钟 | 打开浏览器 → F12 → 复制Cookie → 粘贴 | 中等 |
| **一键获取** | 1-2分钟 | 点击按钮 → 扫码登录 → 自动填充 | 简单 |

---

## 使用建议

1. **定期更新Cookie** - 建议每周更新一次
2. **使用小号** - 避免使用主账号
3. **备选方案** - 如果自动获取失败，仍然可以手动获取
4. **网络环境** - 确保网络连接稳定

---

## 故障排除

### 问题1: 点击按钮没有反应

**可能原因**:
- 后端服务未运行
- 没有管理员权限

**解决方案**:
1. 检查后端服务状态：`pm2 list`
2. 确认当前用户是管理员

### 问题2: 浏览器无法启动

**可能原因**:
- Chrome未安装
- 权限问题

**解决方案**:
1. 安装Chrome浏览器
2. 检查文件权限

### 问题3: Cookie获取失败

**可能原因**:
- 登录超时
- 网络问题
- 页面加载失败

**解决方案**:
1. 重新尝试
2. 检查网络连接
3. 使用手动方式获取Cookie

---

## 更新日志

### v1.0.0 (2025-12-26)

**新增功能**:
- ✅ 抖音平台Cookie自动获取
- ✅ 小红书平台Cookie自动获取
- ✅ 前端一键获取按钮
- ✅ 自动填充功能
- ✅ 实时状态提示

**技术改进**:
- 创建 CookieAutoFetchService 服务
- 新增 autoFetchCookie API端点
- 集成到平台配置页面

---

## 相关文件

- [backend/src/services/CookieAutoFetchService.js](backend/src/services/CookieAutoFetchService.js) - Cookie自动获取服务
- [backend/src/controllers/PlatformCookieController.js](backend/src/controllers/PlatformCookieController.js) - 平台Cookie控制器
- [frontend/src/pages/PlatformConfig.jsx](frontend/src/pages/PlatformConfig.jsx) - 平台配置页面
- [backend/get-douyin-cookie-simple.js](backend/get-douyin-cookie-simple.js) - 独立脚本（备用）

---

**准备好体验一键获取Cookie的便利了吗？** 🚀

访问 `http://localhost:5173/config` 开始使用！

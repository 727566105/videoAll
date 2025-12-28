# AI配置功能测试指南

## 🎯 功能概述

本次更新为"添加AI模型"页面带来了以下新功能：

### 1. 🔐 安全性增强
- ✅ **加密密钥配置**: 已配置安全的64字符随机密钥
- ✅ **默认密钥检测**: 自动检测并警告使用默认密钥的情况
- ✅ **密钥轮换功能**: 支持安全的密钥轮换
- ✅ **配置验证**: URL格式、API密钥格式、模型名称等全面验证

### 2. 🌐 新增国内AI提供商（4个）
- ✅ **通义千问 (qwen)** - 阿里云
- ✅ **文心一言 (wenxin)** - 百度
- ✅ **智谱AI (zhipu)** - 清言
- ✅ **DeepSeek** - 深度求索

### 3. 📦 用户体验改进
- ✅ **导入配置**: 支持从JSON文件导入配置
- ✅ **导出配置**: 支持导出配置为JSON文件（不包含敏感信息）
- ✅ **批量操作**: 支持批量启用/禁用/删除配置
- ✅ **配置复制**: 快速复制现有配置（需重新设置API密钥）
- ✅ **测试历史**: 查看配置的连接测试历史记录

### 4. ✨ 前端验证增强
- ✅ **实时验证**: 表单字段实时格式验证
- ✅ **友好错误提示**: 详细的错误信息展示

---

## 🚀 快速开始

### 1. 启动服务

**后端服务** (端口 3000):
```bash
cd backend
npm run dev
```

**前端服务** (端口 5175):
```bash
cd frontend
npm run dev
```

### 2. 访问系统

打开浏览器访问: **http://localhost:5175/**

### 3. 登录

使用现有用户登录（例如：`yangzai` 或 `updateduser`）

---

## 📋 功能测试清单

### ✅ 测试1: 密钥安全警告

**步骤：**
1. 登录后进入"添加AI模型"页面
2. 查看页面顶部

**预期结果：**
- ✅ 如果使用了默认加密密钥，会显示红色警告横幅
- ✅ 当前已配置安全密钥，不应显示警告

**API端点：** `GET /api/v1/ai-config/security/key-status`

---

### ✅ 测试2: 提供商列表

**步骤：**
1. 点击"添加配置"按钮
2. 查看提供商下拉选项

**预期结果：**
- ✅ 应显示8个提供商选项：
  1. Ollama (本地)
  2. OpenAI
  3. Anthropic (Claude)
  4. Custom (自定义)
  5. **通义千问** 🆕
  6. **文心一言** 🆕
  7. **智谱AI** 🆕
  8. **DeepSeek** 🆕

**API端点：** `GET /api/v1/ai-config/meta/providers`

---

### ✅ 测试3: 创建配置（带验证）

**步骤：**
1. 填写配置表单（选择"通义千问"）
2. 尝试输入无效的API端点（例如：`invalid-url`）
3. 尝试输入无效的JSON格式（在高级设置中）
4. 修正错误并保存

**预期结果：**
- ✅ 实时显示验证错误提示
- ✅ URL格式错误提示
- ✅ JSON格式错误提示
- ✅ 保存前进行最终验证

**API端点：** `POST /api/v1/ai-config`

---

### ✅ 测试4: 导出配置

**步骤：**
1. 在配置列表中找到某个配置
2. 点击"导出"按钮

**预期结果：**
- ✅ 下载JSON文件
- ✅ 文件包含配置信息（但不包含`api_key_encrypted`字段）
- ✅ 文件名格式：`ai-config-{配置名}.json`

**API端点：** `POST /api/v1/ai-config/export/:id`

---

### ✅ 测试5: 导入配置

**步骤：**
1. 点击"导入配置"按钮
2. 选择之前导出的JSON文件
3. 系统自动验证并导入

**预期结果：**
- ✅ 文件上传成功
- ✅ 自动验证配置格式
- ✅ 创建新配置（需重新设置API密钥）
- ✅ 显示导入成功提示

**API端点：** `POST /api/v1/ai-config/import`

---

### ✅ 测试6: 批量操作

**步骤：**
1. 在配置列表中勾选多个配置
2. 点击"批量启用"或"批量禁用"按钮
3. 点击"批量删除"按钮（需确认）

**预期结果：**
- ✅ 批量修改状态成功
- ✅ 显示确认对话框
- ✅ 操作结果提示
- ✅ 清空选择状态

**API端点：**
- `PUT /api/v1/ai-config/batch`
- `DELETE /api/v1/ai-config/batch`

---

### ✅ 测试7: 配置复制

**步骤：**
1. 在配置列表中找到某个配置
2. 点击"复制"按钮

**预期结果：**
- ✅ 创建配置副本
- ✅ 副本名称为"原配置名 - 副本"
- ✅ 不包含原配置的API密钥（需重新设置）
- ✅ 显示成功提示

**API端点：** `POST /api/v1/ai-config/:id/copy`

---

### ✅ 测试8: 测试连接（国内AI提供商）

**步骤：**
1. 创建一个通义千问配置（使用真实的API密钥）
2. 点击"测试连接"按钮
3. 查看测试结果

**预期结果：**
- ✅ 显示测试成功/失败状态
- ✅ 如果成功，显示响应时间
- ✅ 如果失败，显示错误信息

**API端点：** `POST /api/v1/ai-config/:id/test`

**测试方法：**
- `testQwenConnection()` - 通义千问
- `testWenxinConnection()` - 文心一言
- `testZhipuConnection()` - 智谱AI
- `testDeepSeekConnection()` - DeepSeek

---

### ✅ 测试9: 测试历史

**步骤：**
1. 在配置列表中找到某个已测试过的配置
2. 点击"查看历史"按钮

**预期结果：**
- ✅ 弹出Modal显示测试历史
- ✅ 显示测试时间、结果、响应时间
- ✅ 显示错误信息（如果测试失败）
- ✅ 支持分页

**API端点：** `GET /api/v1/ai-config/:id/test-history`

---

### ✅ 测试10: 密钥轮换（高级功能）

**步骤：**
1. 以admin身份登录
2. 调用密钥轮换API

**预期结果：**
- ✅ 生成新的加密密钥
- ✅ 重新加密所有API密钥
- ✅ 更新`last_rotation_at`时间戳
- ⚠️  **谨慎操作**：建议在维护窗口执行

**API端点：** `POST /api/v1/ai-config/security/rotate-key`

---

## 📊 数据库验证

### 检查新表和字段：

```sql
-- 检查 ai_test_history 表
SELECT * FROM ai_test_history LIMIT 5;

-- 检查 ai_configs 表的新字段
SELECT
    id,
    name,
    provider,
    imported_at,
    exported_at,
    last_rotation_at
FROM ai_configs
LIMIT 5;

-- 检查测试历史记录
SELECT
    ath.id,
    ac.name AS config_name,
    ath.test_result,
    ath.response_time,
    ath.error_message,
    ath.created_at
FROM ai_test_history ath
JOIN ai_configs ac ON ath.ai_config_id = ac.id
ORDER BY ath.created_at DESC
LIMIT 10;
```

---

## 🔧 API测试（使用curl）

### 1. 获取提供商列表

```bash
curl -X GET http://localhost:3000/api/v1/ai-config/meta/providers \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. 获取密钥安全状态

```bash
curl -X GET http://localhost:3000/api/v1/ai-config/security/key-status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. 创建配置（通义千问）

```bash
curl -X POST http://localhost:3000/api/v1/ai-config \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "通义千问测试",
    "provider": "qwen",
    "api_endpoint": "https://dashscope.aliyuncs.com/api/v1",
    "api_key": "sk-your-api-key",
    "model": "qwen-turbo",
    "timeout": 60000,
    "is_enabled": false
  }'
```

### 4. 测试连接

```bash
curl -X POST http://localhost:3000/api/v1/ai-config/CONFIG_ID/test \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. 导出配置

```bash
curl -X POST http://localhost:3000/api/v1/ai-config/CONFIG_ID/export \
  -H "Authorization: Bearer YOUR_TOKEN" \
  --output config.json
```

### 6. 导入配置

```bash
curl -X POST http://localhost:3000/api/v1/ai-config/import \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @config.json
```

---

## 🐛 故障排查

### 问题1: 无法看到密钥安全警告

**原因：** 已配置安全的加密密钥

**解决：** 这是正常状态，不需要显示警告

### 问题2: 配置验证失败

**检查：**
- API端点格式是否正确（http://或https://开头）
- API密钥格式是否符合提供商要求
- JSON格式是否正确

### 问题3: 批量操作按钮不显示

**检查：**
- 是否已勾选配置列表中的复选框
- 是否有admin权限

### 问题4: 测试连接失败

**检查：**
- API密钥是否正确
- API端点是否可访问
- 网络连接是否正常
- 提供商服务是否在线

---

## 📝 开发者注意事项

### 权限要求
- 普通用户：查看配置、测试连接
- Admin用户：所有操作（创建、编辑、删除、导入、导出、批量操作、密钥轮换）

### 安全性
- API密钥使用AES-256-CBC加密存储
- 导出配置不包含加密的API密钥
- 复制配置不包含原配置的API密钥
- 密钥轮换会重新加密所有API密钥

### 性能优化
- 使用TypeORM QueryBuilder进行批量操作
- 配置列表支持分页
- 测试历史支持分页

---

## ✅ 完成状态

### 已完成功能
- ✅ 配置验证服务
- ✅ 密钥轮换服务
- ✅ 测试历史实体和API
- ✅ 批量操作API（导入、导出、更新、删除、复制）
- ✅ 4个国内AI提供商支持
- ✅ 前端验证工具
- ✅ 前端UI增强（导入、导出、批量操作、历史查看）
- ✅ 加密密钥配置
- ✅ 数据库表和字段同步

### 待测试功能
- ⏳ 在浏览器中完成所有UI功能测试
- ⏳ 验证所有API端点正常工作
- ⏳ 使用真实的AI API密钥测试连接

---

## 📞 联系支持

如有问题，请查看：
- 后端日志：`backend/logs/combined.log`
- 前端控制台：浏览器开发者工具 Console
- API文档：后端Swagger（如已配置）

---

**祝测试顺利！** 🎉

# 内容解析、管理与热点发现系统 - API 文档

## 📖 文档概述

本文档面向 APP 开发团队，提供完整的后端 API 接口说明，涵盖内容解析、管理、任务调度、热搜追踪、AI 配置等所有功能。

**基础信息**：
- **API 基础路径**: `http://localhost:3000/api/v1`
- **认证方式**: JWT Token
- **数据格式**: JSON
- **字符编码**: UTF-8
- **接口总数**: 106个
- **文档版本**: v1.0.0
- **最后更新**: 2025-12-28

---

## 🚀 快速开始

### 1. 环境配置
确保后端服务已启动：
```bash
cd backend
npm install
npm run dev
```

后端服务将在 `http://localhost:3000` 启动。

### 2. 认证流程
1. 调用 `POST /api/v1/auth/login` 获取 Token
2. 在请求头中携带 Token：`Authorization: Bearer <token>`
3. Token 有效期：7天

### 3. 快速示例

**登录示例**：
```bash
curl -X POST "http://localhost:3000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "admin123"}'
```

**解析内容示例**：
```bash
curl -X POST "http://localhost:3000/api/v1/content/parse" \
  -H "Content-Type: application/json" \
  -d '{"link": "https://www.xiaohongshu.com/..."}'
```

---

## 📚 文档导航

### 📘 基础指南
- [01_快速开始](./01_快速开始.md) - 环境配置、认证流程、基础示例
- [02_认证机制详解](./02_认证机制详解.md) - JWT认证、Token管理、权限说明
- [03_错误处理与状态码](./03_错误处理与状态码.md) - HTTP状态码、错误响应格式
- [04_速率限制说明](./04_速率限制说明.md) - API调用频率限制说明

### 📕 核心模块

#### 1. 认证模块 (4个接口)
**文件**: [modules/01_认证模块.md](./modules/01_认证模块.md)

| 接口 | 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|------|
| 用户登录 | POST | `/auth/login` | ❌ | 获取 JWT Token |
| 用户退出 | POST | `/auth/logout` | ❌ | 退出登录 |
| 检查系统状态 | GET | `/auth/system-status` | ❌ | 检查是否有用户 |
| 系统初始化 | POST | `/auth/initial-setup` | ❌ | 创建第一个管理员 |

---

#### 2. 内容管理 (18个接口)
**文件**: [modules/02_内容管理.md](./modules/02_内容管理.md)

| 接口 | 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|------|
| 解析内容链接 | POST | `/content/parse` | ❌ | 解析平台内容元数据 |
| 保存内容 | POST | `/content/save` | ❌ | 保存到数据库和文件系统 |
| 下载内容 | POST | `/content/download` | ❌ | 下载媒体文件 |
| 获取内容列表 | GET | `/content/` | ❌ | 分页查询内容 |
| 获取内容详情 | GET | `/content/:id` | ❌ | 根据 ID 获取内容 |
| 删除内容 | DELETE | `/content/:id` | ❌ | 删除单条内容 |
| 批量删除 | POST | `/content/batch-delete` | ❌ | 批量删除内容 |
| 批量导出 | POST | `/content/export` | ❌ | 导出为 Excel |
| 刷新统计 | POST | `/content/:id/refresh-stats` | ❌ | 刷新互动数据 |
| 访问本地媒体 | GET | `/content/:id/local-media` | ❌ | 访问下载的文件 |
| 代理下载 | GET | `/content/proxy-download` | ❌ | 代理外部文件下载 |
| 代理图片 | GET | `/content/proxy-image` | ❌ | 代理图片显示 |
| 下载导出文件 | GET | `/content/download-export` | ❌ | 下载 Excel 文件 |
| AI 分析 | POST | `/content/:id/ai-analyze` | ❌ | 使用 AI 分析内容 |
| AI 分析状态 | GET | `/content/:id/ai-status` | ❌ | 获取分析状态 |
| AI 标签统计 | GET | `/content/ai-tags/stats` | ❌ | 获取标签统计 |

---

#### 3. 仪表盘统计 (5个接口)
**文件**: [modules/03_仪表盘统计.md](./modules/03_仪表盘统计.md)

| 接口 | 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|------|
| 获取所有数据 | GET | `/dashboard/` | ✅ | 一次性获取所有仪表盘数据 |
| 获取统计数据 | GET | `/dashboard/stats` | ✅ | 获取核心统计指标 |
| 平台分布 | GET | `/dashboard/platform-distribution` | ✅ | 内容平台分布数据 |
| 内容类型对比 | GET | `/dashboard/content-type-comparison` | ✅ | 视频与图片对比 |
| 近期趋势 | GET | `/dashboard/recent-trend` | ✅ | 近期内容趋势分析 |

---

#### 4. 用户管理 (9个接口)
**文件**: [modules/08_用户管理.md](./modules/08_用户管理.md)

| 接口 | 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|------|
| 获取当前用户 | GET | `/users/me` | ✅ | 获取个人信息 |
| 更新当前用户 | PUT | `/users/me` | ✅ | 更新个人信息 |
| 修改当前密码 | PUT | `/users/me/password` | ✅ | 修改自己的密码 |
| 获取所有用户 | GET | `/users/` | ✅ | 用户列表（管理员） |
| 创建用户 | POST | `/users/` | ✅ | 创建新用户（管理员） |
| 获取用户详情 | GET | `/users/:id` | ✅ | 用户详情（管理员） |
| 更新用户 | PUT | `/users/:id` | ✅ | 更新用户（管理员） |
| 更新用户密码 | PUT | `/users/:id/password` | ✅ | 重置密码（管理员） |
| 删除用户 | DELETE | `/users/:id` | ✅ | 删除用户（管理员） |

---

### 📙 扩展模块

#### 5. 任务管理 (11个接口)
**文件**: [modules/04_任务管理.md](./modules/04_任务管理.md)

作者监控与定时任务管理功能。

---

#### 6. 热搜管理 (13个接口)
**文件**: [modules/05_热搜管理.md](./modules/05_热搜管理.md)

多平台热搜抓取、历史查询、趋势分析。

**平台支持**：抖音、小红书、微博、哔哩哔哩

---

#### 7. 系统配置 (18个接口)
**文件**: [modules/06_系统配置.md](./modules/06_系统配置.md)

平台 Cookie 管理、系统设置、下载配置。

---

#### 8. AI 配置 (16个接口)
**文件**: [modules/07_AI配置.md](./modules/07_AI配置.md)

AI 提供商配置、API 密钥管理、模型设置。

**支持的提供商**：Ollama、OpenAI、Anthropic、Claude 等

---

#### 9. 标签管理 (8个接口)
**文件**: [modules/09_标签管理.md](./modules/09_标签管理.md)

内容标签的创建、管理、批量操作。

---

#### 10. 备份管理 (3个接口)
**文件**: [modules/10_备份管理.md](./modules/10_备份管理.md)

系统数据备份管理功能。

---

## 📊 数据模型

所有数据库实体定义和字段说明：

- [Content 实体](./data_models/Content_实体.md) - 内容数据结构
- [User 实体](./data_models/User_实体.md) - 用户数据结构
- [CrawlTask 实体](./data_models/CrawlTask_实体.md) - 任务数据结构
- [HotsearchSnapshot 实体](./data_models/HotsearchSnapshot_实体.md) - 热搜快照结构
- [AiConfig 实体](./data_models/AiConfig_实体.md) - AI配置结构
- [实体关系图与索引](./data_models/实体关系图与索引.md) - 所有实体关联关系

---

## 💡 代码示例

### Android (Kotlin + Retrofit)
📄 [完整示例](./examples/Kotlin_Retrofit.md)

```kotlin
interface VideoAllApi {
    @POST("/api/v1/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("/api/v1/content/parse")
    suspend fun parseContent(@Body request: ParseRequest): Response<ParseResponse>
}
```

### React (JavaScript/TypeScript + Axios)
📄 [完整示例](./examples/JavaScript_Axios.md)

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:3000/api/v1'
});

// 请求拦截器 - 注入 Token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### iOS (Swift + Alamofire)
📄 [完整示例](./examples/Swift_Alamofire.md)

```swift
import Alamofire

class NetworkManager {
    static let shared = NetworkManager()

    func login(email: String, password: String,
               completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let parameters = ["email": email, "password": password]
        AF.request("/api/v1/auth/login", method: .post, parameters: parameters)
            .responseDecodable(of: LoginResponse.self) { response in
                // 处理响应
            }
    }
}
```

### cURL 调试示例
📄 [完整示例](./examples/curl_命令示例.md)

### APP 集成最佳实践
📄 [完整指南](./examples/APP集成最佳实践.md)

---

## 🔧 工具与资源

### OpenAPI/Swagger 规范
📄 [openapi.yaml](./swagger/openapi.yaml)

OpenAPI 3.0 规范文件，可用于：
- 生成 Postman Collection
- 生成客户端代码（OpenAPI Generator）
- 在线文档预览（Swagger Editor）

### 相关资源
- **后端代码**: [backend/src/](../backend/src/)
- **现有文档示例**: [HOTSEARCH_API_DOCUMENTATION.md](../HOTSEARCH_API_DOCUMENTATION.md)
- **项目 README**: [README.md](../README.md)

---

## 📝 更新日志

### v1.0.0 - 2025-12-28
**初始发布**
- ✅ 完整的 103 个 API 接口文档
- ✅ 10 个功能模块文档
- ✅ 13 个数据模型文档
- ✅ Kotlin、JavaScript/TypeScript、Swift 代码示例
- ✅ OpenAPI/Swagger 规范

---

## ⚠️ 重要说明

### 认证机制
- 部分接口的认证在代码中被注释掉了，需根据实际部署情况启用
- 开发环境支持 `mock-token-` 前缀的测试 Token
- 生产环境必须使用真实的 JWT Token

### 平台支持状态
| 平台 | 状态 | 说明 |
|------|------|------|
| 小红书 | ✅ 完整支持 | 图片、视频、实况图片 |
| 抖音 | ⚠️ 基础支持 | 解析可用，下载受反爬限制 |
| 微博 | 🚧 开发中 | - |
| 哔哩哔哩 | 🚧 开发中 | - |

### 速率限制
- 默认限制：15分钟内 100 次请求
- 超限返回 429 状态码
- 建议客户端实现请求队列和指数退避

### Cookie 管理
- 平台 Cookie 可提高解析成功率
- 通过系统配置模块管理
- Cookie 已加密存储在数据库中

---

## 📞 技术支持

如有疑问，请：
1. 查看对应的模块文档
2. 参考代码示例
3. 查阅数据模型文档
4. 联系后端开发团队

---

**最后更新**: 2025-12-28
**文档维护**: 后端开发团队
**文档版本**: v1.0.0

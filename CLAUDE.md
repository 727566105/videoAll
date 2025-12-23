# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

这是一个全栈内容解析、管理与热点发现系统，为内容运营者提供完整的内容资产管理解决方案。工作流程是：**热点发现 → 精准采集 → 有序存储 → 可视化管理**。

**核心能力：**
- 解析多平台内容（小红书、抖音、微博、哔哩哔哩）
- 下载无水印媒体文件
- 作者监控与定时任务
- 热搜趋势追踪
- 内容管理与结构化文件存储
- 数据可视化看板

## 常用命令

### 后端开发
```bash
cd backend
npm install           # 安装依赖
npm run dev          # 启动开发服务器（自动重载）
npm start            # 启动生产服务器
npm test             # 运行 Jest 测试
```

### 前端开发
```bash
cd frontend
npm install          # 安装依赖
npm run dev          # 启动 Vite 开发服务器
npm run build        # 构建生产版本
npm run lint         # 运行 ESLint 检查
npm run preview      # 预览生产构建
```

### 媒体解析 SDK (Python)
```bash
cd media_parser_sdk
pip install -e .     # 以可编辑模式安装
media-parser parse <URL>              # 解析链接
media-parser download <URL> -o ./downloads  # 下载媒体
media-parser batch urls.txt -o ./downloads   # 批量处理
```

### 生产部署 (PM2)
```bash
npm install -g pm2
pm2 start src/server.js    # 启动后端
pm2 list                   # 查看进程列表
pm2 logs                   # 查看日志
pm2 restart all            # 重启所有进程
```

## 架构设计

### 项目结构

```
videoAll/
├── backend/              # Node.js/Express 后端
├── frontend/             # React 19 + Vite 前端
├── media_parser_sdk/     # Python 内容解析 SDK
├── media/                # 媒体存储目录（已忽略）
├── downloads/            # 默认下载目录
└── custom_downloads/     # 自定义下载目录
```

### 后端架构 ([backend/src/](backend/src/))

**架构模式：** MVC + Service 层

- **[controllers/](backend/src/controllers/)** - 各功能模块的请求处理器
  - `AuthController.js` - 登录、注册、密码管理
  - `ContentController.js` - 内容解析与增删改查
  - `TaskController.js` - 定时任务管理
  - `HotSearchController.js` - 热搜抓取与查询
  - `DashboardController.js` - 统计分析
  - `ConfigController.js` - 用户、Cookie、系统设置

- **[entity/](backend/src/entity/)** - TypeORM 实体定义（PostgreSQL 模型）
  - `Content.js` - 已存储内容元数据
  - `CrawlTask.js` - 定时爬取任务
  - `HotSearch.js` - 热搜记录

- **[models/](backend/src/models/)** - Mongoose Schema（MongoDB 模型）

- **[services/](backend/src/services/)** - 业务逻辑层
  - 平台特定解析器和下载器
  - 基于 node-cron 的任务调度
  - 基于 node-cache 的缓存管理

- **[middleware/](backend/src/middleware/)** - 认证（JWT）、验证、错误处理

- **[routes/](backend/src/routes/)** - 按功能分组的 API 路由

**关键集成：** 后端通过子进程或 CLI 命令调用 Python `media_parser_sdk` 进行实际内容解析。

### 前端架构 ([frontend/src/](frontend/src/))

**架构模式：** 组件化 + React Router

- **[pages/](frontend/src/pages/)** - 页面组件（Dashboard、ContentParsing、ContentManagement、TaskManagement、HotSearch、SystemConfig）
- **[components/](frontend/src/components/)** - 可复用 UI 组件
- **[services/](frontend/src/services/)** - API 客户端封装（基于 axios）
- **[config/](frontend/src/config/)** - API 端点、主题定义

**UI 框架：** Ant Design - 使用 `App.useApp()` 获取 message、modal、appContext

### 媒体解析 SDK 架构 ([media_parser_sdk/](media_parser_sdk/))

**架构模式：** 插件式解析器

- **[core/](media_parser_sdk/core/)** - 基础解析器类、平台检测
- **[parsers/](media_parser_sdk/parsers/)** - 平台特定实现（xiaohongshu、douyin）
- **[models/](media_parser_sdk/models/)** - 数据模型（MediaInfo、Platform、MediaType 枚举）
- **[cli/](media_parser_sdk/cli/)** - 命令行接口

**扩展方式：** 添加新平台：
1. 在 `parsers/` 中创建继承 `BaseParser` 的新解析器类
2. 实现 `is_supported_url()` 和 `parse()` 方法
3. 在 `MediaParser` 中注册解析器

## 关键技术细节

### 多数据库配置
- **MongoDB** (Mongoose) - 主数据存储
- **PostgreSQL** (TypeORM) - 实体辅助存储
- 连接配置在 `.env` 文件中

### 认证流程
1. POST `/api/v1/auth/login` → 返回 JWT 令牌
2. 请求头携带 `Authorization: Bearer <token>`
3. 受保护路由使用 `authMiddleware.js` 验证
4. 默认管理员：`admin@example.com` / `admin123`

### 文件存储结构
```
media/
└── <平台>/                      # xiaohongshu、douyin 等
    └── <作者>_<标题>_<ID>/       # 单个内容文件夹
        ├── media_info.json      # 元数据
        ├── *.jpg, *.mp4, *.mov  # 已下载的媒体文件
```

### 内容解析流程
1. 前端：用户通过内容解析页面提交 URL
2. 后端：`ContentController.parse()` 验证 URL
3. 后端：调用 `media_parser_sdk`（Python）进行解析
4. 后端：下载媒体文件到结构化存储目录
5. 后端：保存元数据到数据库
6. 前端：在内容管理页面展示结果

### 定时任务
- 使用 `node-cron` 进行任务调度
- 任务存储在 `CrawlTask` 实体中
- 支持频率：每小时、每天、每周
- 日志存储在 `backend/logs/`

### 环境变量 (.env)
关键变量：
- `PORT`、`NODE_ENV` - 服务器配置
- `MONGODB_URI` - MongoDB 连接字符串
- `JWT_SECRET`、`JWT_EXPIRES_IN` - 认证配置
- `STORAGE_ROOT_PATH` - 媒体存储路径（默认：`./media`）
- `LOG_LEVEL` - 日志级别
- `RATE_LIMIT_*` - API 速率限制

### API 基础路径模式
所有后端 API 遵循：`/api/v1/<资源>`

## 平台支持状态

| 平台 | 状态 | 说明 |
|------|------|------|
| 小红书 | ✅ 完整支持 | 图片、视频、实况图片 |
| 抖音 | ⚠️ 基础支持 | 解析可用，下载受反爬限制 |
| 微博 | 🚧 开发中 | |
| 哔哩哔哩 | 🚧 开发中 | |

## 重要说明

- **Cookie 管理：** 平台 Cookie（存储在数据库中）可提高解析成功率。通过系统配置 → Cookie Management 进行配置
- **速率限制：** API 内置速率限制（通过 `.env` 配置）
- **日志记录：** Winston 日志输出到 `backend/logs/combined.log` 和 `backend/logs/error.log`
- **媒体清理：** 删除内容时仅移除数据库记录，媒体文件需手动清理
- **热搜抓取：** 定时热搜抓取自动运行，数据存储在 `HotSearch` 实体中
- **主题系统：** 前端通过 Ant Design ConfigProvider 支持浅色/深色模式

## 测试

```bash
# 后端
cd backend
npm test                 # 运行 Jest 测试

# 前端
cd frontend
npm test                 # 运行前端测试
```

## Git 工作流

- `main` - 生产分支
- `develop` - 开发分支
- `feature/xxx` - 功能分支
- 提交格式：`type(scope): description`（例如：`feat(content): 新增批量删除功能`）

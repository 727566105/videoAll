# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

**安装：**
```bash
cd media_parser_sdk
pip install -e .     # 以可编辑模式安装
```

**命令行使用（通过 wrapper.py）：**
```bash
# 基础解析
python wrapper.py parse <URL>

# 下载媒体
python wrapper.py download <URL> <output_dir>

# 小红书笔记解析（增强功能）
python wrapper.py xiaohongshu_note <URL>

# 小红书作者信息
python wrapper.py xiaohongshu_author <URL> [--cookie "你的Cookie"]

# 小红书作者所有笔记
python wrapper.py xiaohongshu_author_notes <URL> [max_notes] [--cookie "你的Cookie"]

# 抖音视频解析
python wrapper.py douyin_video <URL> [--cookie "你的Cookie"]

# 哔哩哔哩视频解析
python wrapper.py bilibili_video <URL> [--cookie "你的Cookie"] [--quality "1080P"]

# 查看 Cookie 获取帮助
python wrapper.py --cookie-help
```

**重要提示：**
- Cookie 是可选参数，但能显著提高解析成功率
- 使用 `--cookie` 参数传递平台 Cookie（格式：`"a1=...; a2=..."`）
- 小红书作者笔记解析支持设置 `max_notes` 限制获取数量
- 哔哩哔哩支持通过 `--quality` 选择清晰度（默认 1080P）

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

**关键集成：** 后端通过 `ParseService.js` 调用 Python `wrapper.py` 进行实际内容解析。返回 JSON 格式的媒体信息。

### 前端架构 ([frontend/src/](frontend/src/))

**架构模式：** 组件化 + React Router

- **[pages/](frontend/src/pages/)** - 页面组件（Dashboard、ContentParsing、ContentManagement、TaskManagement、HotSearch、SystemConfig）
- **[components/](frontend/src/components/)** - 可复用 UI 组件
- **[services/](frontend/src/services/)** - API 客户端封装（基于 axios）
- **[config/](frontend/src/config/)** - API 端点、主题定义

**UI 框架：** Ant Design - 使用 `App.useApp()` 获取 message、modal、appContext

**技术栈细节：**
- React 19.2.0 + Vite 7.2.4
- Ant Design 6.1.1 + Ant Design Charts 2.6.6
- React Router DOM 7.11.0
- Axios 1.13.2（HTTP 客户端）
- 支持 ESBuild 快速构建

### 媒体解析 SDK 架构 ([media_parser_sdk/](media_parser_sdk/))

**架构模式：** 插件式解析器

- **[core/](media_parser_sdk/core/)** - 基础解析器类、平台检测
- **[parsers/](media_parser_sdk/parsers/)** 或 **[platforms/](media_parser_sdk/platforms/)** - 平台特定实现
  - `xiaohongshu_enhanced.py` - 小红书增强解析器（支持笔记、作者、作者笔记列表）
  - `douyin_enhanced.py` - 抖音增强解析器
  - `bilibili_enhanced.py` - 哔哩哔哩增强解析器
- **[models/](media_parser_sdk/models/)** - 数据模型（MediaInfo、Platform、MediaType 枚举）
- **[wrapper.py](media_parser_sdk/wrapper.py)** - 命令行包装器，后端通过此文件调用 Python 解析功能

**扩展方式：** 添加新平台：
1. 在 `platforms/` 中创建增强解析器类
2. 在 `wrapper.py` 中添加包装函数
3. 在 `main()` 函数中注册新命令
4. 更新后端 `ParseService.js` 以支持新平台调用

## 关键技术细节

### 多数据库配置
- **MongoDB** (Mongoose) - 主数据存储，用于内容、任务、热搜等核心数据
- **PostgreSQL** (TypeORM) - 实体辅助存储，用于结构化数据查询和报表
- 连接配置在 `backend/.env` 文件中：
  ```env
  MONGODB_URI=mongodb://localhost:27017/video_all
  ```

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
1. **前端**：用户通过内容解析页面提交 URL
2. **后端**：`ContentController.parse()` 验证 URL 和平台类型
3. **后端**：`ParseService.js` 调用 Python `wrapper.py` 执行解析
4. **Python SDK**：
   - 识别平台类型
   - 调用对应平台的增强解析器
   - 提取媒体信息（标题、作者、下载链接等）
   - 返回 JSON 格式的解析结果
5. **后端**：
   - 下载媒体文件到结构化存储目录
   - 生成封面图（使用 OCR 提取文字）
   - 保存元数据到 MongoDB 和 PostgreSQL
6. **前端**：在内容管理页面展示结果

### OCR 文字识别配置
- **配置文件**：`backend/src/config/ocr.config.js`
- **支持语言**：中文简体 + 英文（`chi_sim+eng`）
- **关键参数**：
  - `timeout: 30000` - 单张图片 30 秒超时
  - `maxConcurrency: 3` - 最多 3 个并发 OCR 任务
  - `confidenceThreshold: 0.6` - 置信度阈值
  - 图片预处理：灰度化、对比度标准化、尺寸调整（最大 1920x1080）

### 定时任务
- 使用 `node-cron` 进行任务调度
- 任务存储在 `CrawlTask` 实体中
- 支持频率：每小时、每天、每周
- 日志存储在 `backend/logs/`

### 环境变量配置

**后端 (backend/.env)：**
```env
# 服务器配置
PORT=3000
NODE_ENV=development
HTTPS_ENABLED=false

# 数据库配置
MONGODB_URI=mongodb://localhost:27017/video_all

# JWT 配置
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d

# 加密配置
ENCRYPTION_KEY=your_encryption_key_here

# 存储配置
STORAGE_TYPE=local
STORAGE_ROOT_PATH=./media

# 备份配置
BACKUP_DIR=./backups
BACKUP_RETENTION_DAYS=7

# 日志配置
LOG_LEVEL=info

# 密码加密
PASSWORD_SALT_ROUNDS=10
```

**前端 (frontend/.env)：**
```env
# 凭证加密密钥
VITE_CREDENTIAL_SECRET_KEY=your-secret-key-here-change-in-production
# 生成方法：node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### API 基础路径模式
所有后端 API 遵循：`/api/v1/<资源>`

## 平台支持状态

| 平台 | 状态 | 说明 |
|------|------|------|
| 小红书 | ✅ 完整支持 | 图片、视频、实况图片，无水印下载，作者信息解析 |
| 抖音 | ⚠️ 基础支持 | 视频信息解析，下载受反爬限制（建议配置 Cookie） |
| 微博 | 🚧 开发中 | |
| 哔哩哔哩 | ⚠️ 基础支持 | 视频解析，支持多清晰度选择（需要 Cookie） |

## 重要说明

### Cookie 管理
- **作用**：平台 Cookie 可显著提高解析成功率，特别是对于抖音和哔哩哔哩
- **配置方式**：通过系统配置 → Cookie Management 进行配置
- **获取方法**：运行 `python wrapper.py --cookie-help` 查看详细帮助
- **存储**：Cookie 加密存储在数据库中

### 性能与缓存
- **缓存策略**：使用 node-cache 缓存核心数据（内容列表、仪表盘数据、热搜数据）
- **速率限制**：API 内置速率限制（通过 `.env` 配置）
- **日志记录**：Winston 日志输出到 `backend/logs/combined.log` 和 `backend/logs/error.log`

### 文件管理
- **媒体清理**：删除内容时仅移除数据库记录，媒体文件需手动清理
- **文件存储**：按照平台/作者/标题的结构化存储
- **封面生成**：自动从第一张图片生成封面，使用 OCR 提取文字

### 安全特性
- **JWT 认证**：基于令牌的身份验证
- **密码加密**：bcryptjs 密码哈希（ rounds: 10）
- **Cookie 加密**：平台 Cookie 安全存储
- **HTTPS 支持**：生产环境建议启用（配置 `HTTPS_ENABLED=true`）

### 热门功能
- **热搜抓取**：定时热搜抓取自动运行，数据存储在 `HotSearch` 实体中
- **主题系统**：前端通过 Ant Design ConfigProvider 支持浅色/深色模式
- **数据备份**：定期备份数据库到 `backups/` 目录（保留 7 天）

## 测试

```bash
# 后端
cd backend
npm test                 # 运行 Jest 测试

# 前端
cd frontend
npm test                 # 运行前端测试
```

## 调试与故障排除

### 查看日志
```bash
# 开发环境（实时日志）
cd backend
npm run dev              # 控制台输出日志

# 生产环境（PM2 日志）
pm2 logs                 # 查看所有日志
pm2 logs video-all       # 查看特定应用日志
tail -f backend/logs/combined.log    # 查看 Winston 日志
```

### 常见问题

**1. 解析失败**
- 检查平台 Cookie 是否有效（系统配置 → Cookie Management）
- 查看后端日志获取详细错误信息
- 确认 URL 格式正确
- 尝试手动运行 Python wrapper 测试：`python wrapper.py xiaohongshu_note <URL>`

**2. 监控任务未执行**
- 检查任务状态是否为"启用"
- 查看任务执行日志（任务管理 → 查看日志）
- 确认后端服务正常运行：`pm2 list`
- 检查 cron 表达式是否正确

**3. 下载失败**
- 检查存储路径权限：`ls -la media/`
- 确认磁盘空间充足：`df -h`
- 检查网络连接
- 查看后端错误日志：`tail -f backend/logs/error.log`

**4. 前端构建失败**
- 清除 node_modules 和重新安装：
  ```bash
  cd frontend
  rm -rf node_modules package-lock.json
  npm install
  ```
- 检查 Node.js 版本：`node --version`（建议 >= 16.0.0）

**5. 数据库连接失败**
- 确认 MongoDB 服务运行：`mongosh --eval "db.version()"`
- 检查 `backend/.env` 中的 `MONGODB_URI` 配置
- 检查 PostgreSQL 连接（如果使用）

**6. OCR 识别失败或慢**
- 检查 OCR 配置：`backend/src/config/ocr.config.js`
- 调整并发数：`maxConcurrency: 3` → 降低到 1-2
- 增加超时时间：`timeout: 30000` → 增加到 60000

### 性能优化建议

**后端优化：**
- 启用缓存（node-cache）减少数据库查询
- 增加数据库索引（Content 模型的常用查询字段）
- 调整 OCR 并发数和超时配置
- 使用 PM2 集群模式：`pm2 start src/server.js -i max`

**前端优化：**
- 使用虚拟滚动处理大量数据
- 图片懒加载（已集成）
- 代码分割和按需加载
- 启用 Vite 的生产构建优化

**数据库优化：**
- 定期清理过期热搜数据（超过 30 天）
- 定期清理备份文件（超过 7 天）
- 为 Content 表添加复合索引：
  - `{ platform: 1, created_at: -1 }`
  - `{ author: 1, created_at: -1 }`

## Git 工作流

### 分支策略
- `main` - 生产分支，保持稳定
- `develop` - 开发分支，集成最新功能
- `feature/xxx` - 功能分支，从 develop 分出
- `fix/xxx` - 修复分支，从 develop 分出

### 提交规范
使用语义化提交信息：
- `feat(content): 新增批量删除功能`
- `fix(auth): 修复 JWT 令牌过期问题`
- `docs(readme): 更新安装说明`
- `style(ui): 优化按钮样式`
- `refactor(parser): 重构解析逻辑`
- `test(content): 添加内容管理测试`
- `chore(deps): 更新依赖版本`

### 开发工作流
1. 从 `develop` 创建功能分支：`git checkout -b feature/新功能`
2. 开发并提交代码：`git commit -m "feat(scope): description"`
3. 推送到远程：`git push origin feature/新功能`
4. 创建 Pull Request 到 `develop`
5. 代码审查通过后合并
6. 定期将 `develop` 合并到 `main` 发布

## 快速参考

### 启动开发环境
```bash
# 终端 1：启动后端
cd backend
npm run dev

# 终端 2：启动前端
cd frontend
npm run dev

# 访问：http://localhost:5173（前端） + http://localhost:3000（后端 API）
```

### 重置开发环境
```bash
# 后端
cd backend
rm -rf node_modules package-lock.json
npm install

# 前端
cd frontend
rm -rf node_modules package-lock.json dist
npm install

# Python SDK
cd media_parser_sdk
pip uninstall media-parser-sdk
pip install -e .
```

### 检查服务状态
```bash
# MongoDB
mongosh --eval "db.version()"

# 后端服务
curl http://localhost:3000/api/v1/health

# PM2 进程
pm2 list

# 端口占用
lsof -i :3000  # 后端
lsof -i :5173  # 前端（Vite）
```

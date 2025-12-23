# 小红书博主笔记自动下载器

一个功能完整的 Python 脚本，用于自动下载小红书博主的所有笔记（图片、视频）。

## 功能特点

- ✅ 自动获取博主所有笔记
- ✅ 下载高清图片和视频
- ✅ 按博主名称自动创建文件夹
- ✅ 保存完整的笔记元数据（JSON格式）
- ✅ 支持 Cookie 认证，获取完整内容
- ✅ 下载进度实时显示
- ✅ 自动生成下载报告
- ✅ 支持配置文件和命令行参数

## 快速开始

### 方式1：使用命令行参数

```bash
# 基本用法
python xiaohongshu_downloader.py "https://www.xiaohongshu.com/user/profile/用户ID"

# 指定 Cookie
python xiaohongshu_downloader.py <URL> --cookie "你的Cookie"

# 限制下载数量
python xiaohongshu_downloader.py <URL> --max-notes 10

# 指定输出目录
python xiaohongshu_downloader.py <URL> --output ./my_downloads
```

### 方式2：使用配置文件

1. 编辑 `config.json` 文件：

```json
{
  "url": "https://www.xiaohongshu.com/user/profile/用户ID",
  "cookie": "你的Cookie",
  "output_dir": "downloads",
  "delay": 0.5,
  "max_notes": null
}
```

2. 运行脚本：

```bash
python xiaohongshu_downloader.py --config
```

## 如何获取 Cookie

**为什么需要 Cookie？**

小红书为了防止爬虫，用户主页返回的笔记卡片中不包含完整信息（高清图片、视频下载链接）。提供 Cookie 后，可以获取完整的笔记内容。

**获取步骤：**

1. 打开浏览器，访问 https://www.xiaohongshu.com
2. 登录你的小红书账号
3. 按 `F12` 打开开发者工具
4. 切换到 `Network`（网络）标签
5. 刷新页面，点击任意请求
6. 在右侧 `Request Headers` 中找到 `Cookie`
7. 复制整个 Cookie 字符串

**Cookie 格式示例：**

```
a1=xxx; webId=xxx; web_session=xxx; ...
```

## 下载文件结构

```
downloads/
└── <博主名称>/
    ├── notes_data.json           # 完整笔记数据（含博主信息）
    ├── download_report.json      # 下载报告
    ├── 01_笔记标题/
    │   ├── metadata.json         # 笔记元数据
    │   ├── cover.jpg             # 封面图片
    │   ├── image_1.jpg           # 图片1
    │   ├── image_2.jpg           # 图片2
    │   └── video_1.mp4           # 视频1
    ├── 02_笔记标题/
    │   └── ...
    └── ...
```

## 命令行参数说明

```
positional arguments:
  url                   博主主页URL

options:
  -h, --help            显示帮助信息
  --cookie, -c COOKIE   小红书 Cookie
  --output, -o OUTPUT   输出目录（默认：downloads）
  --max-notes, -n MAX_NOTES
                        最大下载笔记数
  --delay, -d DELAY     请求延迟（秒，默认：0.5）
  --config              使用配置文件
```

## 使用示例

### 示例1：下载前10条笔记

```bash
python xiaohongshu_downloader.py \
  "https://www.xiaohongshu.com/user/profile/5e2abfc10000000001008b79" \
  --cookie "你的Cookie" \
  --max-notes 10
```

### 示例2：下载到指定目录

```bash
python xiaohongshu_downloader.py \
  <URL> \
  --cookie "你的Cookie" \
  --output ./小红书下载
```

### 示例3：调整请求延迟

```bash
python xiaohongshu_downloader.py \
  <URL> \
  --cookie "你的Cookie" \
  --delay 1.0
```

## 配置文件说明

`config.json` 文件格式：

```json
{
  "url": "博主主页URL",
  "cookie": "小红书 Cookie",
  "output_dir": "下载目录",
  "delay": 0.5,
  "max_notes": null,
  "_comment": {
    "url": "例如：https://www.xiaohongshu.com/user/profile/xxx",
    "cookie": "从浏览器开发者工具中获取",
    "output_dir": "默认：downloads",
    "delay": "请求延迟（秒），避免请求过快被限制",
    "max_notes": "null表示全部，10表示只下载前10条"
  }
}
```

## 常见问题

### Q: 为什么下载的笔记显示"页面不见了"？

A: 可能的原因：
- Cookie 已过期（需重新获取）
- 笔记已被作者删除
- 笔记被设置为私密
- 账号被限制访问

### Q: Cookie 会过期吗？

A: 会。如果频繁出现解析失败，请重新获取 Cookie。

### Q: 可以不使用 Cookie 吗？

A: 可以，但只能获取笔记卡片信息（标题、封面、点赞数），无法获取高清图片和视频下载链接。

### Q: 如何避免被限制？

A:
- 增加请求延迟（`--delay` 参数）
- 使用小号进行测试
- 定期更换 Cookie

## 依赖要求

- Python 3.7+
- httpx
- pydantic
- requests

## 注意事项

1. **Cookie 安全**：Cookie 包含你的登录信息，请勿泄露给他人
2. **请求频率**：默认有 0.5 秒的请求延迟，避免被限制
3. **仅供学习**：请遵守小红书的服务条款，仅供个人学习使用

## 技术实现

脚本基于 `media_parser_sdk` 框架开发，使用以下技术：
- `XiaohongshuEnhancedParser` - 小红书增强解析器
- `requests` - HTTP 请求
- `json` - 数据存储
- `argparse` - 命令行参数解析

## 文件说明

| 文件 | 说明 |
|------|------|
| `xiaohongshu_downloader.py` | 主脚本文件 |
| `config.json` | 配置文件 |
| `XIAOHONGSHU_DOWNLOADER_README.md` | 使用文档 |

## 更新日志

### v1.0.0 (2025-12-24)
- ✅ 初始版本发布
- ✅ 支持博主主页笔记下载
- ✅ 支持 Cookie 认证
- ✅ 支持配置文件和命令行参数
- ✅ 自动生成下载报告

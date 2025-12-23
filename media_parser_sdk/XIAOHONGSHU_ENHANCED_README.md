# 小红书增强解析器 - 使用说明

## 功能概述

基于 media_parser_sdk 框架开发的小红书增强解析器，支持以下功能：

### ✅ 已实现功能

| 功能 | 说明 | 状态 |
|------|------|------|
| 用户资料获取 | 获取用户昵称、头像、粉丝数等基本信息 | ✅ 完整实现 |
| 笔记卡片列表 | 获取用户笔记的标题、封面、点赞数等预览信息 | ✅ 完整实现 |
| 单个笔记详情 | 通过笔记URL获取完整图片、视频下载链接 | ✅ 完整实现 |
| Cookie 支持 | 支持通过 Cookie 获取完整笔记信息 | ✅ 完整实现 |

### ⚠️ 重要提示

**获取用户主页的完整笔记信息需要提供 Cookie**

- **无 Cookie**：只能获取笔记卡片信息（标题、封面、点赞数）
- **有 Cookie**：可以获取完整的笔记信息（高清图片、视频下载链接）

## Cookie 获取指南

### 为什么需要 Cookie？

小红书为了防止爬虫，在用户主页返回的笔记卡片中不包含 `noteId` 字段。提供 Cookie 后，可以获取更完整的笔记信息。

### 如何获取 Cookie？

1. 打开浏览器，访问 https://www.xiaohongshu.com
2. 登录你的小红书账号
3. 按 `F12` 打开开发者工具
4. 切换到 `Network`（网络）标签
5. 刷新页面，点击任意请求
6. 在右侧 `Request Headers` 中找到 `Cookie`
7. 复制整个 Cookie 字符串

### 查看帮助

```bash
python wrapper.py --cookie-help
```

## 使用方法

### 方式1：命令行（wrapper.py）

```bash
cd media_parser_sdk

# 查看 Cookie 获取帮助
python wrapper.py --cookie-help

# 获取用户资料
python wrapper.py xiaohongshu_author "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b"

# 获取用户笔记（无 Cookie，仅卡片数据）
python wrapper.py xiaohongshu_author_notes "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b" 10

# 获取用户笔记（有 Cookie，完整数据）
python wrapper.py xiaohongshu_author_notes "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b" 10 --cookie "你的Cookie"

# 解析单个笔记（获取完整信息）
python wrapper.py xiaohongshu_note "https://www.xiaohongshu.com/explore/6948f1b6000000001e033c84"
```

### 方式2：Python代码

```python
from media_parser_sdk.platforms.xiaohongshu_enhanced import (
    extract_xiaohongshu_author_sync,
    extract_xiaohongshu_author_notes_sync,
    extract_xiaohongshu_note_sync
)

# ===== 无 Cookie 方式（仅卡片数据） =====
result = extract_xiaohongshu_author_notes_sync(
    "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b",
    max_notes=10,
    fetch_detail=False  # 不获取详情，仅卡片数据
)

if result.success:
    data = result.data
    for note in data['notes']:
        print(f"标题: {note['title']}")
        print(f"点赞: {note['interaction_stats']['like_count']}")
        print(f"封面: {note['cover_image']['url']}")

# ===== 有 Cookie 方式（完整数据） =====
cookie = "a1=...; a2=...; ..."  # 你的 Cookie

result = extract_xiaohongshu_author_notes_sync(
    "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b",
    max_notes=10,
    fetch_detail=True,
    cookie=cookie  # 提供 Cookie
)

if result.success:
    data = result.data
    for note in data['notes']:
        print(f"标题: {note['title']}")
        print(f"图片: {len(note.get('images', []))} 张")
        print(f"视频: {len(note.get('videos', []))} 个")
        for img in note.get('images', []):
            print(f"  {img['url']}")

# ===== 解析单个笔记 =====
result = extract_xiaohongshu_note_sync("https://www.xiaohongshu.com/explore/6948f1b6000000001e033c84")
if result.success:
    note = result.data
    print(f"标题: {note['title']}")
    print(f"图片: {len(note['images'])} 张")
    print(f"视频: {len(note['videos'])} 个")
```

## 返回数据格式

### 用户资料

```json
{
  "user_id": "67fdd54d000000000a03f27b",
  "nickname": "娜娜",
  "avatar_url": "https://...",
  "xiaohongshu_id": "26736621021",
  "ip_location": "广西",
  "signature": "还没有简介",
  "followers_count": 10,
  "following_count": 0,
  "total_likes_received": 10,
  "profile_url": "https://..."
}
```

### 笔记列表（卡片数据 - 无 Cookie）

```json
{
  "author_profile": { ... },
  "notes": [
    {
      "note_id": "",
      "title": "也太好看啦",
      "type": "normal",
      "author": { ... },
      "cover_image": { "url": "https://..." },
      "interaction_stats": { "like_count": 10 },
      "source_url": "",
      "has_detail": false
    }
  ],
  "total_notes": 9,
  "extracted_notes": 9,
  "has_more": false,
  "extraction_stats": {
    "cards_found": 9,
    "successfully_parsed": 0,
    "fallback_to_cards": 9
  }
}
```

### 笔记列表（完整数据 - 有 Cookie）

```json
{
  "author_profile": { ... },
  "notes": [
    {
      "note_id": "6948f1b6000000001e033c84",
      "title": "笔记标题",
      "content": "笔记内容",
      "type": "normal",
      "author": { ... },
      "images": [
        { "url": "https://..." }
      ],
      "videos": [
        { "url": "https://..." }
      ],
      "cover_image": { "url": "https://..." },
      "interaction_stats": {
        "like_count": 100,
        "collect_count": 50,
        "comment_count": 10,
        "share_count": 5
      },
      "tags": ["标签1", "标签2"],
      "publish_time": "2024-01-01T12:00:00",
      "source_url": "https://...",
      "has_detail": true
    }
  ],
  "total_notes": 9,
  "extracted_notes": 9,
  "extraction_stats": {
    "cards_found": 9,
    "successfully_parsed": 9,
    "fallback_to_cards": 0
  }
}
```

## 运行输出示例

### 无 Cookie 时的提示

```
⚠️  未提供 Cookie，无法获取完整的笔记信息（高清图片、视频下载链接）
⚠️  将仅返回笔记卡片信息（标题、封面、点赞数）
💡 提示：提供 Cookie 可获取完整信息
   获取方式：浏览器 F12 -> Network -> 复制 Request Header 中的 Cookie
   使用方式：parse_author_notes_sync(url, cookie='你的Cookie')

INFO: 开始提取博主笔记: ...
INFO: Cookie 状态: ✗ 未提供
```

### 有 Cookie 时的输出

```
INFO: 开始提取博主笔记: ...
INFO: Cookie 状态: ✓ 已提供
INFO: 找到 9 条笔记卡片，总数: 9
INFO: 处理笔记 1/9: 6948f1b6000000001e033c84
INFO:   ✓ 成功解析笔记详情: 也太好看啦
```

## 文件结构

```
media_parser_sdk/
├── media_parser_sdk/
│   ├── platforms/
│   │   ├── xiaohongshu.py              # 基础笔记解析器
│   │   └── xiaohongshu_enhanced.py     # 增强解析器（用户主页、笔记集合）
│   └── models/
│       └── xiaohongshu_models.py       # 数据模型定义
├── wrapper.py                          # CLI命令行工具
└── XIAOHONGSHU_ENHANCED_README.md      # 本文档
```

## 依赖

- Python 3.7+
- httpx
- pydantic

## 注意事项

1. **Cookie 安全**：
   - Cookie 包含你的登录信息，请勿泄露给他人
   - 建议使用小号进行测试
   - 定期更换 Cookie

2. **请求频率**：
   - 解析器内置了1秒的请求延迟，避免请求过快被限制
   - 大量抓取时建议增加延迟时间

3. **Cookie 过期**：
   - Cookie 可能会过期，过期后需重新获取
   - 如果频繁出现解析失败，请检查 Cookie 是否有效

4. **xsec_token**：
   - URL中的 `xsec_token` 参数可以提高成功率
   - 如果有 Cookie，可以忽略此参数

## 测试

运行测试脚本：

```bash
python test-xiaohongshu-enhanced.py
```

测试脚本会测试以下功能：
1. 获取用户资料
2. 获取笔记卡片列表（不获取详情）
3. 获取笔记详情（需要 Cookie）
4. 使用解析器类

## 常见问题

### Q: 为什么无法获取笔记的完整信息？

A: 小红书在用户主页返回的笔记卡片中不包含 `noteId` 字段，这是反爬虫措施。需要提供 Cookie 才能获取完整信息。

### Q: Cookie 在哪里获取？

A: 浏览器 F12 -> Network -> 复制 Request Header 中的 Cookie。详见 `python wrapper.py --cookie-help`

### Q: Cookie 会过期吗？

A: 会。如果频繁出现解析失败，请重新获取 Cookie。

### Q: 可以不使用 Cookie 吗？

A: 可以，但只能获取笔记卡片信息（标题、封面、点赞数），无法获取高清图片和视频下载链接。

## 未来改进方向

1. **API接口支持**：研究小红书内部API，获取完整笔记列表
2. **自动Cookie刷新**：支持自动刷新过期的Cookie
3. **分页加载**：支持加载用户的全部笔记（当前只能获取首页显示的笔记）
4. **异步支持**：提供异步版本的API

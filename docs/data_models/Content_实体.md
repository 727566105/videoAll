# Content 实体文档

## 📋 实体概述

Content（内容实体）存储从各平台解析和下载的内容元数据。

**表名**: `contents`
**主键**: `id` (UUID)
**索引**: `IDX_CONTENT_PLATFORM_CONTENT_ID` (platform + content_id 唯一索引)

---

## 字段说明

### 基本信息字段

| 字段名 | 类型 | 长度 | 必填 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| id | uuid | - | ✅ | auto | 主键 |
| platform | varchar | 20 | ✅ | - | 平台标识（xiaohongshu、douyin等） |
| content_id | varchar | 100 | ✅ | - | 内容唯一ID（平台提供） |
| title | varchar | 500 | ✅ | - | 内容标题 |
| author | varchar | 100 | ✅ | - | 作者名称 |
| description | text | - | ❌ | '' | 内容描述 |
| media_type | varchar | 10 | ✅ | - | 媒体类型（video/image） |
| file_path | varchar | 500 | ✅ | - | 文件存储路径 |
| cover_url | varchar | 500 | ✅ | - | 封面URL |

### 媒体资源字段

| 字段名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| all_images | text | ❌ | null | 所有图片URL（JSON数组） |
| all_videos | text | ❌ | null | 所有视频URL（JSON数组） |

### 来源信息字段

| 字段名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| source_url | varchar | 500 | ✅ | - | 来源URL |
| source_type | int | - | ✅ | 1 | 来源类型（1-单链接/2-任务） |

### 统计数据字段

| 字段名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| like_count | int | ❌ | 0 | 点赞数 |
| collect_count | int | ❌ | 0 | 收藏数 |
| comment_count | int | ❌ | 0 | 评论数 |
| share_count | int | ❌ | 0 | 分享数 |
| view_count | int | ❌ | 0 | 浏览数 |
| publish_time | timestamp | ❌ | null | 发布时间 |

### 状态字段

| 字段名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| is_missing | boolean | ❌ | false | 内容是否已消失 |

### 系统字段

| 字段名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| created_at | timestamp | - | CURRENT_TIMESTAMP | 创建时间 |

---

## 枚举值说明

### platform（平台）

| 值 | 说明 |
|----|------|
| xiaohongshu | 小红书 |
| douyin | 抖音 |
| weibo | 微博 |
| bilibili | 哔哩哔哩 |

### media_type（媒体类型）

| 值 | 说明 |
|----|------|
| video | 视频 |
| image | 图片（含实况照片） |

### source_type（来源类型）

| 值 | 说明 |
|----|------|
| 1 | 单链接解析 |
| 2 | 监控任务采集 |

---

## 关联关系

- **多对一** → CrawlTask: 内容可以关联到爬取任务（task_id）
- **一对多** → AiAnalysisResult: 一个内容可以有多个AI分析结果
- **多对多** ↔ Tag: 通过 ContentTag 关联表

---

## JSON字段格式

### all_images

```json
[
  "https://example.com/image1.jpg",
  "https://example.com/image2.jpg"
]
```

### all_videos

```json
[
  "https://example.com/video1.mp4",
  "https://example.com/video2.mp4"
]
```

---

## 索引说明

### IDX_CONTENT_PLATFORM_CONTENT_ID

**类型**: 唯一索引  
**字段**: `platform` + `content_id`  
**作用**: 防止重复抓取同一内容

---

## 示例数据

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "platform": "xiaohongshu",
  "content_id": "64f123abc",
  "title": "美食探店",
  "author": "美食达人",
  "description": "推荐一家超好吃的餐厅",
  "media_type": "video",
  "file_path": "/media/xiaohongshu/作者_标题_ID/",
  "cover_url": "https://...",
  "all_images": "[\"https://...\", \"https://...\"]",
  "all_videos": "[\"https://...\"]",
  "source_url": "https://www.xiaohongshu.com/explore/12345678",
  "source_type": 1,
  "like_count": 1234,
  "collect_count": 567,
  "comment_count": 89,
  "share_count": 45,
  "view_count": 10000,
  "publish_time": "2025-12-28T10:00:00.000Z",
  "is_missing": false,
  "created_at": "2025-12-28T12:00:00.000Z"
}
```

---

## 相关文档

- [内容管理模块](../modules/02_内容管理.md)
- [CrawlTask 实体](./CrawlTask_实体.md)

---

**最后更新**: 2025-12-28

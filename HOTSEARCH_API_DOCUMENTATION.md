# 热搜 API 文档

## Phase 2 新增端点

### 1. 获取四平台实时热搜（合并接口）

**端点**: `GET /api/v1/hotsearch/all`

**认证**: ✅ 需要

**描述**: 一次性获取抖音、小红书、微博、B站的实时热搜数据

**响应示例**:
```json
{
  "message": "获取四平台热搜成功",
  "data": {
    "douyin": {
      "success": true,
      "data": [
        {
          "rank": 1,
          "keyword": "热点关键词",
          "heat": 1234567,
          "trend": "上升",
          "url": "https://www.douyin.com/search/...",
          "category": "娱乐"
        }
      ],
      "itemCount": 50,
      "lastUpdate": "2025-12-28T12:27:14.123Z"
    },
    "xiaohongshu": { ... },
    "weibo": { ... },
    "bilibili": { ... }
  },
  "timestamp": "2025-12-28T12:27:14.123Z"
}
```

**缓存**: 15分钟

---

### 2. 历史热搜查询（高级筛选）

**端点**: `GET /api/v1/hotsearch/history`

**认证**: ✅ 需要

**查询参数**:
| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| platforms | string | 否 | all | 平台列表，逗号分隔或 "all" |
| startDate | string | 否 | 7天前 | 开始日期 (YYYY-MM-DD) |
| endDate | string | 否 | 今天 | 结束日期 (YYYY-MM-DD) |
| minRank | number | 否 | - | 最小排名 |
| maxRank | number | 否 | - | 最大排名 |
| keyword | string | 否 | - | 关键词搜索 |
| category | string | 否 | - | 分类筛选 |
| sortBy | string | 否 | capture_date | 排序字段 (capture_date/heat/rank) |
| sortOrder | string | 否 | DESC | 排序方向 (ASC/DESC) |
| page | number | 否 | 1 | 页码 |
| pageSize | number | 否 | 20 | 每页数量 |

**响应示例**:
```json
{
  "message": "查询成功",
  "data": [
    {
      "rank": 1,
      "keyword": "热点关键词",
      "heat": 1234567,
      "trend": "上升",
      "platform": "douyin",
      "captureDate": "2025-12-28",
      "category": "娱乐"
    }
  ],
  "pagination": {
    "total": 1000,
    "page": 1,
    "pageSize": 20,
    "totalPages": 50
  }
}
```

---

### 3. 跨平台热搜对比

**端点**: `GET /api/v1/hotsearch/compare`

**认证**: ✅ 需要

**查询参数**:
| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| date | string | 否 | 今天 | 对比日期 (YYYY-MM-DD) |

**响应示例**:
```json
{
  "message": "对比分析成功",
  "data": {
    "date": "2025-12-28",
    "commonKeywords": [
      {
        "keyword": "共同热点",
        "platforms": ["douyin", "xiaohongshu", "weibo"],
        "ranks": {
          "douyin": 1,
          "xiaohongshu": 3,
          "weibo": 2
        },
        "heats": {
          "douyin": 1234567,
          "xiaohongshu": 987654,
          "weibo": 1111111
        }
      }
    ],
    "stats": {
      "totalUnique": 180,
      "commonCount": 25,
      "platformSpecific": {
        "douyin": 35,
        "xiaohongshu": 42,
        "weibo": 28,
        "bilibili": 50
      }
    }
  }
}
```

---

### 4. 热搜数据分析

**端点**: `GET /api/v1/hotsearch/analysis`

**认证**: ✅ 需要

**查询参数**:
| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| platform | string | 否 | - | 平台名称（不提供则分析所有平台） |
| date | string | 否 | 今天 | 分析日期 (YYYY-MM-DD) |
| days | number | 否 | 7 | 分析天数（用于趋势分析） |

**响应示例**:
```json
{
  "message": "数据分析成功",
  "data": {
    "date": "2025-12-28",
    "platform": "all",
    "heatDistribution": [
      { "range": "Top 1-10", "heat": 12345678 },
      { "range": "Top 11-20", "heat": 8765432 }
    ],
    "categoryDistribution": [
      { "category": "娱乐", "count": 35 },
      { "category": "综合", "count": 25 }
    ],
    "trendDistribution": [
      { "trend": "上升", "count": 15 },
      { "trend": "下降", "count": 10 },
      { "trend": "持平", "count": 20 },
      { "trend": "新晋", "count": 5 }
    ]
  }
}
```

---

### 5. 关键词历史趋势

**端点**: `GET /api/v1/hotsearch/keywords/:keyword`

**认证**: ✅ 需要

**路径参数**:
| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| keyword | string | ✅ | 关键词 |

**查询参数**:
| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| startDate | string | 否 | 7天前 | 开始日期 (YYYY-MM-DD) |
| endDate | string | 否 | 今天 | 结束日期 (YYYY-MM-DD) |

**响应示例**:
```json
{
  "message": "获取关键词趋势成功",
  "data": {
    "keyword": "春节",
    "startDate": "2025-12-21",
    "endDate": "2025-12-28",
    "trends": [
      {
        "date": "2025-12-28",
        "platform": "douyin",
        "rank": 1,
        "heat": 1234567,
        "trend": "上升"
      }
    ],
    "appearances": 15
  }
}
```

---

### 6. 手动刷新所有热搜（管理员）

**端点**: `POST /api/v1/hotsearch/refresh`

**认证**: ✅ 需要 (仅管理员)

**描述**: 手动触发所有平台的热搜数据采集

**响应示例**:
```json
{
  "message": "刷新所有热搜成功",
  "data": [
    {
      "platform": "douyin",
      "success": true,
      "data": [...]
    }
  ]
}
```

---

### 7. 采集统计和健康状态（管理员）

**端点**: `GET /api/v1/hotsearch/stats`

**认证**: ✅ 需要 (仅管理员)

**描述**: 获取最近7天的采集成功率统计

**响应示例**:
```json
{
  "message": "获取采集统计成功",
  "data": {
    "period": "最近7天",
    "platformStats": {
      "douyin": {
        "successCount": 25,
        "expectedCount": 28,
        "successRate": "89.29%"
      },
      "xiaohongshu": { ... },
      "weibo": { ... },
      "bilibili": { ... }
    },
    "healthStatus": "healthy"
  }
}
```

**健康状态**:
- `healthy`: 所有平台成功率 ≥ 80%
- `warning`: 至少一个平台成功率 < 80%

---

## 现有端点

### 获取平台列表
`GET /api/v1/hotsearch/platforms`

### 获取指定平台热搜
`GET /api/v1/hotsearch/:platform?date=YYYY-MM-DD`

### 获取平台趋势
`GET /api/v1/hotsearch/:platform/trends?days=7`

### 采集指定平台热搜
`POST /api/v1/hotsearch/:platform`

### 采集所有平台热搜
`POST /api/v1/hotsearch`

### 一键解析热搜内容
`POST /api/v1/hotsearch/parse`

### 获取关联内容
`GET /api/v1/hotsearch/related?keyword=xxx&platform=xxx`

---

## 缓存策略

| 端点 | 缓存时长 | 缓存键格式 |
|------|---------|-----------|
| GET /all | 15分钟 | `hotsearch:all:latest` |
| GET /:platform | 15分钟 | `hotsearch:{platform}:latest` |
| GET /:platform?date=xxx | 30分钟 | `hotsearch:{platform}:{date}` |
| GET /:platform/trends | 1小时 | `hotsearch:trends:{platform}:{days}` |
| GET /history | 30分钟 | 动态生成 |
| GET /compare | 30分钟 | `hotsearch:compare:{date}` |
| GET /analysis | 无缓存 | - |
| GET /keywords/:keyword | 1小时 | `hotsearch:keyword:{keyword}` |
| GET /stats | 5分钟 | `hotsearch:stats` |

---

## 错误码

| 状态码 | 含义 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 403 | 无权限（管理员专用接口） |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 数据结构

### HotsearchItem
```typescript
{
  rank: number;           // 排名 (1-50)
  keyword: string;        // 关键词
  heat: number;           // 热度值
  trend: string;          // 趋势：上升/下降/持平/新晋/普通
  url: string;            // 搜索链接
  category?: string;      // 可选：分类
}
```

### PlatformHotsearch
```typescript
{
  success: boolean;       // 是否成功
  data: HotsearchItem[];  // 热搜数据
  itemCount: number;      // 数据条数
  lastUpdate: Date;       // 最后更新时间
  error?: string;         // 错误信息（如果失败）
}
```

---

## 使用示例

### 获取所有平台实时热搜
```bash
curl -X GET "http://localhost:3000/api/v1/hotsearch/all" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 查询最近7天的历史热搜（Top10）
```bash
curl -X GET "http://localhost:3000/api/v1/hotsearch/history?platforms=all&minRank=1&maxRank=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 跨平台对比（指定日期）
```bash
curl -X GET "http://localhost:3000/api/v1/hotsearch/compare?date=2025-12-28" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 查询关键词趋势
```bash
curl -X GET "http://localhost:3000/api/v1/hotsearch/keywords/春节?startDate=2025-12-20&endDate=2025-12-28" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 手动刷新所有热搜（管理员）
```bash
curl -X POST "http://localhost:3000/api/v1/hotsearch/refresh" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

**最后更新**: 2025-12-28
**版本**: v2.0 (Phase 2 Complete)

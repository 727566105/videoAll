# React (JavaScript/TypeScript + Axios) 代码示例

## 📋 概述

本文档提供 React 平台使用 JavaScript/TypeScript 和 Axios 框架调用 API 的完整示例。

---

## 1. 安装依赖

```bash
npm install axios
```

---

## 2. API 客户端配置

### Axios 实例配置

```javascript
// src/services/api.js
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:3000/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// 请求拦截器 - 注入 Token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器 - 统一错误处理
api.interceptors.response.use(
  (response) => {
    return response.data;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Token过期，清除并跳转登录
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

---

## 3. API 方法封装

### 认证 API

```javascript
// src/services/auth.js
import api from './api';

export const authApi = {
  // 登录
  login: (username, password) => 
    api.post('/auth/login', { username, password }),
  
  // 登出
  logout: () => 
    api.post('/auth/logout'),
  
  // 获取当前用户
  getCurrentUser: () => 
    api.get('/users/me'),
  
  // 修改密码
  changePassword: (currentPassword, newPassword) =>
    api.put('/users/me/password', { currentPassword, newPassword })
};
```

### 内容 API

```javascript
// src/services/content.js
import api from './api';

export const contentApi = {
  // 解析内容
  parse: (link) => 
    api.post('/content/parse', { link }),
  
  // 获取内容列表
  getList: (params) => 
    api.get('/content/', { params }),
  
  // 获取内容详情
  getById: (id) => 
    api.get(`/content/${id}`),
  
  // 删除内容
  delete: (id) => 
    api.delete(`/content/${id}`),
  
  // 批量删除
  batchDelete: (ids) => 
    api.post('/content/batch-delete', { ids }),
  
  // 刷新统计
  refreshStats: (id) => 
    api.post(`/content/${id}/refresh-stats`)
};
```

### 仪表盘 API

```javascript
// src/services/dashboard.js
import api from './api';

export const dashboardApi = {
  // 获取所有数据
  getAll: () => 
    api.get('/dashboard/'),
  
  // 获取统计数据
  getStats: () => 
    api.get('/dashboard/stats'),
  
  // 获取平台分布
  getPlatformDistribution: () => 
    api.get('/dashboard/platform-distribution'),
  
  // 获取近期趋势
  getRecentTrend: () => 
    api.get('/dashboard/recent-trend')
};
```

---

## 4. React Hooks 封装

### useAuth Hook

```javascript
// src/hooks/useAuth.js
import { useState, useEffect } from 'react';
import { authApi } from '../services/auth';

export const useAuth = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      const token = localStorage.getItem('token');
      if (!token) {
        setLoading(false);
        return;
      }

      try {
        const response = await authApi.getCurrentUser();
        setUser(response.data);
      } catch (error) {
        localStorage.removeItem('token');
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, []);

  const login = async (username, password) => {
    const response = await authApi.login(username, password);
    const { user, token } = response.data;
    
    localStorage.setItem('token', token);
    setUser(user);
    return user;
  };

  const logout = async () => {
    await authApi.logout();
    localStorage.removeItem('token');
    setUser(null);
  };

  return {
    user,
    loading,
    isAuthenticated: !!user,
    login,
    logout
  };
};
```

### useContent Hook

```javascript
// src/hooks/useContent.js
import { useState, useEffect } from 'react';
import { contentApi } from '../services/content';

export const useContent = (params = {}) => {
  const [contents, setContents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);

  const fetchContents = async (page = 1) => {
    setLoading(true);
    try {
      const response = await contentApi.getList({
        ...params,
        page,
        page_size: 20
      });
      
      setContents(response.data.list);
      setTotal(response.data.total);
    } catch (error) {
      console.error('获取内容列表失败:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContents();
  }, []);

  return {
    contents,
    loading,
    total,
    fetchContents
  };
};
```

---

## 5. 完整使用示例

### 登录页面

```javascript
// src/pages/Login.jsx
import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const { login } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      await login(username, password);
      window.location.href = '/dashboard';
    } catch (error) {
      alert('登录失败: ' + error.message);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        placeholder="用户名"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="密码"
      />
      <button type="submit">登录</button>
    </form>
  );
};
```

### 内容列表页面

```javascript
// src/pages/ContentList.jsx
import React from 'react';
import { useContent } from '../hooks/useContent';

const ContentList = () => {
  const { contents, loading, fetchContents } = useContent();

  if (loading) return <div>加载中...</div>;

  return (
    <div>
      <h1>内容列表</h1>
      <ul>
        {contents.map((content) => (
          <li key={content.id}>
            <h3>{content.title}</h3>
            <p>作者: {content.author}</p>
            <p>平台: {content.platform}</p>
          </li>
        ))}
      </ul>
    </div>
  );
};
```

---

## 6. TypeScript 类型定义

```typescript
// src/types/api.d.ts
interface User {
  id: string;
  username: string;
  email?: string;
  role: 'admin' | 'operator';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface Content {
  id: string;
  title: string;
  author: string;
  platform: string;
  media_type: 'video' | 'image';
  cover_url: string;
  like_count: number;
  created_at: string;
}

interface ApiResponse<T> {
  message: string;
  data: T;
}

interface PaginatedResponse<T> {
  message: string;
  data: {
    list: T[];
    total: number;
    page: number;
    page_size: number;
  };
}
```

---

**最后更新**: 2025-12-28

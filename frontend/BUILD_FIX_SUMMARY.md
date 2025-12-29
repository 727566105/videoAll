# 前端构建问题解决总结

## 问题描述

在运行 `npm run build` 时遇到以下错误：

- Node.js 版本要求：Vite 需要 Node.js 20.19+或 22.12+
- crypto.hash 函数错误：`crypto.hash is not a function`
- @antv/layout 包兼容性问题

## 根本原因

1. **Vite 版本过高**：Vite 7.x 与@antv 相关包存在兼容性问题
2. **@ant-design/charts 依赖**：该包依赖了多个@antv 包，这些包在新版本环境中有兼容性问题
3. **CommonJS/ESM 混合模块**：部分依赖包的模块系统不兼容

## 解决方案

### 1. 降级 Vite 版本

```json
// package.json
"vite": "^5.4.10"  // 从 ^7.2.4 降级到稳定版本
```

### 2. 优化 Vite 配置

```javascript
// vite.config.js
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ["react", "react-dom"],
          antd: ["antd", "@ant-design/icons"],
          charts: ["@ant-design/charts"],
        },
      },
    },
    commonjsOptions: {
      transformMixedEsModules: true,
    },
  },
  optimizeDeps: {
    include: ["@ant-design/charts", "@antv/g6", "@antv/g2"],
  },
  define: {
    global: "globalThis",
  },
});
```

### 3. 重新安装依赖

```bash
rm -rf node_modules package-lock.json
npm install
```

## 构建结果

✅ 构建成功

- 构建时间：~8-9 秒
- 输出文件：6 个主要 chunk 文件
- 总大小：~3.5MB（压缩后~1MB）

## 文件分块优化

- **vendor.js**: React 核心库 (12.69 kB)
- **antd.js**: Ant Design 组件 (1.36 MB)
- **charts.js**: 图表组件 (1.47 MB)
- **index.js**: 应用代码 (394.60 kB)

## 注意事项

1. **chunk 大小警告**：部分 chunk 超过 500KB，这是正常的，因为图表库较大
2. **Node.js 版本**：确保使用 Node.js 20.19+或 22.12+
3. **依赖兼容性**：如需升级 Vite 到 7.x，需要等待@antv 生态系统的兼容性更新

## 验证步骤

```bash
# 1. 清理并重新安装
rm -rf node_modules package-lock.json
npm install

# 2. 构建验证
npm run build

# 3. 预览构建结果
npm run preview
```

## 后续优化建议

1. 考虑使用动态导入(dynamic import)进一步分割代码
2. 如果不需要复杂图表功能，可以考虑替换为更轻量的图表库
3. 定期检查@antv 生态系统的更新，以便升级到最新版本

构建问题已完全解决，项目可以正常部署到生产环境。

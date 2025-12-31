# 🔧 Docker 构建故障排除指南

## 📋 常见构建问题及解决方案

### 1. Rollup 架构兼容性问题

**错误信息**:
```
Error: Cannot find module @rollup/rollup-linux-x64-musl
```

**原因**: Rollup 在 Alpine Linux (musl) 环境中需要特定的二进制文件

**解决方案**:
1. ✅ 在 `package.json` 中明确添加所需的 Rollup 平台包
2. ✅ 安装构建依赖: `python3`, `make`, `g++`
3. ✅ 使用 `--verbose` 模式安装依赖

### 2. npm 依赖安装失败

**错误信息**:
```
npm error code EBADPLATFORM
npm error notsup Unsupported platform
```

**解决方案**:
```dockerfile
# 安装构建依赖
RUN apk add --no-cache python3 make g++

# 使用详细模式安装
RUN npm cache clean --force && \
    npm install --verbose && \
    npm cache clean --force
```

### 3. 多架构构建问题

**错误信息**:
```
ERROR: failed to solve: process "/dev/.buildkit_qemu_emulator /bin/sh -c ..."
```

**解决方案**:
- 暂时只构建 AMD64 架构
- 等 ARM64 兼容性问题解决后再启用多架构

### 4. 内存不足问题

**错误信息**:
```
JavaScript heap out of memory
```

**解决方案**:
```dockerfile
# 增加 Node.js 内存限制
ENV NODE_OPTIONS="--max-old-space-size=4096"
```

## 🛠️ 调试工具和命令

### 本地构建测试

```bash
# 测试前端构建
cd frontend
npm install --verbose
npm run build

# 测试后端构建
cd backend
npm install --omit=dev
```

### Docker 构建调试

```bash
# 构建时显示详细输出
docker build --progress=plain --no-cache -t test-image .

# 进入失败的构建阶段调试
docker run -it --rm node:22-alpine sh
```

### 检查依赖兼容性

```bash
# 检查 Rollup 平台支持
npm info @rollup/rollup-linux-x64-musl

# 检查当前平台
node -e "console.log(process.platform, process.arch)"
```

## 📊 构建性能优化

### 1. 使用构建缓存

```dockerfile
# 利用 Docker 层缓存
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
```

### 2. 多阶段构建优化

```dockerfile
# 只复制必要的文件到生产镜像
COPY --from=builder /app/dist /usr/share/nginx/html
```

### 3. 减少镜像大小

```dockerfile
# 清理不必要的文件
RUN npm cache clean --force && \
    rm -rf /tmp/* /var/tmp/*
```

## 🔍 常用调试命令

### 检查构建环境

```bash
# 检查 Node.js 版本
node --version
npm --version

# 检查系统架构
uname -m
cat /etc/os-release

# 检查可用内存
free -h
```

### 检查 Docker 环境

```bash
# 检查 Docker 版本
docker --version
docker-compose --version

# 检查 Docker 系统信息
docker system info

# 清理 Docker 缓存
docker system prune -a
```

### 检查网络连接

```bash
# 测试 npm 仓库连接
npm ping

# 测试 Docker Hub 连接
docker pull hello-world
```

## 📝 构建日志分析

### 关键日志信息

1. **依赖安装阶段**:
   - 查找 `npm install` 输出
   - 注意 `WARN` 和 `ERROR` 消息

2. **构建阶段**:
   - 查找 `vite build` 输出
   - 注意内存使用情况

3. **Docker 构建阶段**:
   - 查找 `RUN` 命令输出
   - 注意文件复制和权限问题

### 日志收集命令

```bash
# 保存构建日志
docker build . 2>&1 | tee build.log

# 分析失败的构建
docker build --progress=plain . > build.log 2>&1
```

## 🚀 成功构建检查清单

### 构建前检查

- [ ] Node.js 版本 >= 22
- [ ] Docker 版本 >= 20.10
- [ ] 足够的磁盘空间 (>5GB)
- [ ] 稳定的网络连接

### 依赖检查

- [ ] `package.json` 包含所需的 Rollup 平台包
- [ ] `.npmrc` 配置正确
- [ ] 没有版本冲突的依赖

### 构建检查

- [ ] 本地构建成功
- [ ] Docker 构建成功
- [ ] 镜像大小合理 (<500MB)
- [ ] 健康检查通过

## 📞 获取帮助

如果遇到无法解决的问题：

1. **收集信息**:
   - 完整的错误日志
   - 系统环境信息
   - Docker 版本信息

2. **创建 Issue**:
   - 访问 [GitHub Issues](https://github.com/727566105/videoAll/issues)
   - 提供详细的错误信息和复现步骤

3. **本地调试**:
   - 使用 `test-docker-build.sh` 脚本
   - 逐步排查问题

---

**记住**: 构建问题通常是环境或依赖问题，耐心调试总能找到解决方案！🔧✨
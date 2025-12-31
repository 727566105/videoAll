@echo off
setlocal enabledelayedexpansion

REM 本地构建前端脚本 (Windows 版本)
REM 避免 Docker 构建中的复杂依赖问题

echo 🏗️ 本地构建前端
echo ================
echo.

REM 检查 Node.js 环境
echo [STEP] 检查 Node.js 环境
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js 未安装
    pause
    exit /b 1
)

npm --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm 未安装
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i

echo [INFO] Node.js 版本: %NODE_VERSION%
echo [INFO] npm 版本: %NPM_VERSION%

REM 进入前端目录
cd frontend

REM 清理旧的构建
echo [STEP] 清理旧的构建文件
if exist dist rmdir /s /q dist
if exist node_modules rmdir /s /q node_modules
if exist package-lock.json del package-lock.json

REM 安装依赖
echo [STEP] 安装依赖
echo [INFO] 正在安装 npm 依赖...
npm install
if errorlevel 1 (
    echo [ERROR] ❌ 依赖安装失败
    pause
    exit /b 1
) else (
    echo [INFO] ✅ 依赖安装成功
)

REM 构建项目
echo [STEP] 构建前端项目
echo [INFO] 正在构建前端...
npm run build
if errorlevel 1 (
    echo [ERROR] ❌ 前端构建失败
    pause
    exit /b 1
) else (
    echo [INFO] ✅ 前端构建成功
)

REM 检查构建结果
if exist dist (
    echo [INFO] 构建产物内容:
    dir dist
) else (
    echo [ERROR] 构建产物目录不存在
    pause
    exit /b 1
)

echo.
echo 🎉 前端构建完成！
echo.
echo 📋 接下来可以：
echo 1. 使用简化 Dockerfile 构建镜像:
echo    docker build -f Dockerfile.simple -t videoall-frontend .
echo 2. 或者直接使用 dist 目录部署到 nginx
echo.

pause
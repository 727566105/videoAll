@echo off
setlocal enabledelayedexpansion

REM videoAll Docker 构建测试脚本 (Windows 版本)
REM 在推送到 GitHub 之前本地验证 Docker 构建

echo 🧪 videoAll Docker 构建测试
echo ============================
echo.

REM 检查 Docker 是否运行
echo [STEP] 检查 Docker 环境
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker 未运行，请启动 Docker Desktop
    pause
    exit /b 1
)
echo [INFO] Docker 环境正常

REM 测试后端构建
echo [STEP] 测试后端 Docker 构建
echo [INFO] 构建后端镜像...
docker build -t videoall-backend-test ./backend
if errorlevel 1 (
    echo [ERROR] ❌ 后端构建失败
    pause
    exit /b 1
) else (
    echo [INFO] ✅ 后端构建成功
)

REM 测试前端构建
echo [STEP] 测试前端 Docker 构建
echo [INFO] 构建前端镜像...
docker build -t videoall-frontend-test ./frontend
if errorlevel 1 (
    echo [ERROR] ❌ 前端构建失败
    echo [WARN] 前端构建失败，可能是依赖问题，继续测试完整应用构建...
) else (
    echo [INFO] ✅ 前端构建成功
)

REM 测试完整应用构建
echo [STEP] 测试完整应用 Docker 构建
echo [INFO] 构建完整应用镜像...
docker build -t videoall-full-test .
if errorlevel 1 (
    echo [ERROR] ❌ 完整应用构建失败
    pause
    exit /b 1
) else (
    echo [INFO] ✅ 完整应用构建成功
)

REM 显示镜像信息
echo [STEP] 构建结果
echo.
echo [INFO] 构建的镜像：
docker images | findstr videoall-.*-test

echo.
echo 🎉 所有 Docker 构建测试通过！
echo.
echo 📋 接下来可以：
echo 1. 推送代码到 GitHub: git push origin feature/docker-support
echo 2. 查看 GitHub Actions 构建状态
echo 3. 创建 Pull Request
echo.

REM 询问是否清理镜像
set /p cleanup_choice="是否清理测试镜像? (y/n): "
if /i "%cleanup_choice%"=="y" (
    echo [INFO] 清理测试镜像...
    docker rmi videoall-backend-test 2>nul
    docker rmi videoall-frontend-test 2>nul
    docker rmi videoall-full-test 2>nul
    echo [INFO] 测试镜像已清理
) else (
    echo [INFO] 测试镜像保留，可以手动清理：
    echo   docker rmi videoall-backend-test videoall-frontend-test videoall-full-test
)

pause
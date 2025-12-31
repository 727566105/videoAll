@echo off
setlocal enabledelayedexpansion

REM videoAll 部署验证脚本 (Windows 版本)
REM 此脚本帮助验证 Docker 部署是否成功

echo 🔍 videoAll 部署验证向导
echo ==========================
echo.

REM 检查 Docker 是否安装
echo [STEP] 检查 Docker 环境
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker 未安装，请先安装 Docker Desktop
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose 未安装，请先安装 Docker Compose
    pause
    exit /b 1
)

echo [INFO] Docker 环境检查通过

REM 检查环境变量文件
echo [STEP] 检查环境变量配置
if not exist ".env" (
    echo [WARN] .env 文件不存在，正在创建...
    if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo [INFO] .env 文件已从模板创建
        echo [WARN] 请编辑 .env 文件配置数据库信息
    ) else (
        echo [ERROR] .env.example 文件不存在
        pause
        exit /b 1
    )
) else (
    echo [INFO] .env 文件存在
)

REM 检查服务状态
echo [STEP] 检查服务状态
docker-compose ps | findstr "Up" >nul 2>&1
if errorlevel 1 (
    echo [WARN] 没有运行中的服务
) else (
    echo [INFO] 发现运行中的服务
    docker-compose ps
)

REM 询问是否启动服务
set /p start_choice="是否要启动服务? (y/n): "
if /i "%start_choice%"=="y" (
    goto start_services
) else (
    echo [INFO] 跳过服务启动
    goto end
)

:start_services
echo [STEP] 启动 Docker 服务
echo [INFO] 正在启动服务...
docker-compose up -d

echo [INFO] 等待服务启动...
timeout /t 30 /nobreak >nul

echo [INFO] 服务状态：
docker-compose ps

REM 验证服务健康状态
echo [STEP] 验证服务健康状态

REM 检查后端健康状态
echo [INFO] 检查后端服务...
curl -f http://localhost:3000/api/v1/health >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ❌ 后端服务异常
    echo [INFO] 后端日志：
    docker-compose logs --tail=20 backend
) else (
    echo [INFO] ✅ 后端服务正常
)

REM 检查前端服务
echo [INFO] 检查前端服务...
curl -f http://localhost:80/ >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ❌ 前端服务异常
    echo [INFO] 前端日志：
    docker-compose logs --tail=20 frontend
) else (
    echo [INFO] ✅ 前端服务正常
)

REM 检查数据库连接
echo [INFO] 检查数据库连接...
docker-compose exec -T postgres pg_isready -U postgres >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ❌ 数据库连接异常
    echo [INFO] 数据库日志：
    docker-compose logs --tail=20 postgres
) else (
    echo [INFO] ✅ 数据库连接正常
)

REM 显示访问信息
echo.
echo 🎉 部署验证完成！
echo.
echo 📋 服务访问地址：
echo    前端应用: http://localhost:80
echo    后端 API: http://localhost:3000
echo    API 文档: http://localhost:3000/api-docs
echo    健康检查: http://localhost:3000/api/v1/health
echo.
echo 🔧 管理命令：
echo    查看日志: docker-compose logs -f
echo    重启服务: docker-compose restart
echo    停止服务: docker-compose down
echo    更新镜像: docker-compose pull ^&^& docker-compose up -d
echo.
echo 📚 更多信息：
echo    部署文档: DEPLOYMENT.md
echo    Docker 指南: README.Docker.md
echo.

:end
pause
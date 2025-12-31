@echo off
setlocal enabledelayedexpansion

REM videoAll Docker 分支设置脚本 (Windows 版本)
REM 此脚本帮助您创建新的 Docker 分支并推送到 GitHub

echo 🚀 videoAll Docker 分支设置向导
echo ==================================
echo.

REM 检查是否在正确的目录
if not exist "package.json" if not exist "docker-compose.yml" (
    echo [ERROR] 请在 videoAll 项目根目录下运行此脚本
    pause
    exit /b 1
)

REM 检查 Git 是否已初始化
if not exist ".git" (
    echo [INFO] 正在初始化 Git 仓库...
    git init
    echo [INFO] Git 仓库已初始化
)

REM 获取分支名称
set /p branch_name="请输入新分支名称 (默认: docker-support): "
if "%branch_name%"=="" set branch_name=docker-support

echo [INFO] 开始设置 Docker 分支: %branch_name%
echo.

REM 检查是否有未提交的更改
git diff-index --quiet HEAD -- >nul 2>&1
if errorlevel 1 (
    echo [WARN] 检测到未提交的更改
    echo 请选择操作：
    echo 1^) 提交所有更改
    echo 2^) 暂存更改
    echo 3^) 取消操作
    set /p choice="请输入选择 (1-3): "
    
    if "!choice!"=="1" (
        git add .
        set /p commit_msg="请输入提交信息: "
        git commit -m "!commit_msg!"
    ) else if "!choice!"=="2" (
        git stash
        echo [INFO] 更改已暂存
    ) else if "!choice!"=="3" (
        echo [ERROR] 操作已取消
        pause
        exit /b 1
    ) else (
        echo [ERROR] 无效选择
        pause
        exit /b 1
    )
)

REM 创建新分支
echo [STEP] 创建新分支: %branch_name%
git show-ref --verify --quiet refs/heads/%branch_name% >nul 2>&1
if not errorlevel 1 (
    echo [WARN] 分支 '%branch_name%' 已存在
    set /p switch_branch="是否切换到该分支? (y/n): "
    if /i "!switch_branch!"=="y" (
        git checkout %branch_name%
    )
) else (
    git checkout -b %branch_name%
    echo [INFO] 分支 '%branch_name%' 已创建并切换
)

REM 添加 Docker 相关文件
echo [STEP] 添加 Docker 相关文件到 Git
git add .github/
git add .dockerignore
git add docker-compose*.yml
git add DEPLOYMENT.md
git add README.Docker.md
git add setup-docker-branch.sh
git add setup-docker-branch.bat
git add backend/Dockerfile
git add frontend/Dockerfile
git add frontend/docker/
git add Dockerfile
git add docker-entrypoint.sh
echo [INFO] Docker 相关文件已添加到 Git

REM 提交更改
echo [STEP] 提交 Docker 配置更改
git diff --cached --quiet >nul 2>&1
if not errorlevel 1 (
    echo [WARN] 没有需要提交的更改
) else (
    git commit -m "feat: 添加完整的 Docker 化支持和 CI/CD 流程

- 添加多阶段 Dockerfile 构建
- 配置 GitHub Actions 自动构建和发布
- 支持 GHCR 镜像仓库
- 添加开发和生产环境 docker-compose 配置
- 完善部署文档和使用指南
- 支持多架构镜像构建 (AMD64/ARM64)
- 添加健康检查和监控配置"
    echo [INFO] 更改已提交
)

REM 设置远程仓库
echo [STEP] 配置远程仓库
git remote | findstr "origin" >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('git remote get-url origin') do set current_remote=%%i
    echo [INFO] 当前远程仓库: !current_remote!
    
    set /p change_remote="是否要更改远程仓库地址? (y/n): "
    if /i "!change_remote!"=="y" (
        set /p repo_url="请输入新的 GitHub 仓库地址 (https://github.com/username/repo.git): "
        git remote set-url origin "!repo_url!"
        echo [INFO] 远程仓库地址已更新
    )
) else (
    set /p repo_url="请输入 GitHub 仓库地址 (https://github.com/username/repo.git): "
    git remote add origin "!repo_url!"
    echo [INFO] 远程仓库已添加
)

REM 推送分支
echo [STEP] 推送分支到 GitHub
echo [INFO] 正在推送分支 '%branch_name%' 到远程仓库...

git push -u origin %branch_name%
if not errorlevel 1 (
    echo [INFO] 分支推送成功！
    
    REM 获取远程仓库信息
    for /f "tokens=*" %%i in ('git remote get-url origin') do set remote_url=%%i
    
    echo.
    echo 🎉 恭喜！Docker 分支已成功创建并推送到 GitHub
    echo.
    echo 📋 接下来的步骤：
    echo 1. 访问 GitHub 仓库查看分支
    echo 2. 创建 Pull Request 将 '%branch_name%' 合并到主分支
    echo 3. 合并后，GitHub Actions 将自动构建 Docker 镜像
    echo 4. 镜像将发布到 GitHub Container Registry
    echo.
    echo 🐳 使用 Docker 部署：
    echo    docker-compose up -d
    echo.
    echo 📚 查看部署文档：
    echo    - DEPLOYMENT.md
    echo    - README.Docker.md
    
) else (
    echo [ERROR] 分支推送失败
    echo [INFO] 请检查：
    echo [INFO] 1. GitHub 仓库地址是否正确
    echo [INFO] 2. 是否有推送权限
    echo [INFO] 3. 网络连接是否正常
    pause
    exit /b 1
)

echo.
echo [INFO] 设置完成！
pause
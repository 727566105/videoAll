#!/bin/bash

# videoAll Docker 分支设置脚本
# 此脚本帮助您创建新的 Docker 分支并推送到 GitHub

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查 Git 是否已初始化
check_git() {
    if [ ! -d ".git" ]; then
        log_error "当前目录不是 Git 仓库"
        log_info "正在初始化 Git 仓库..."
        git init
        log_info "Git 仓库已初始化"
    fi
}

# 检查是否有未提交的更改
check_uncommitted_changes() {
    if ! git diff-index --quiet HEAD --; then
        log_warn "检测到未提交的更改"
        echo "请选择操作："
        echo "1) 提交所有更改"
        echo "2) 暂存更改"
        echo "3) 取消操作"
        read -p "请输入选择 (1-3): " choice
        
        case $choice in
            1)
                git add .
                read -p "请输入提交信息: " commit_msg
                git commit -m "$commit_msg"
                ;;
            2)
                git stash
                log_info "更改已暂存"
                ;;
            3)
                log_error "操作已取消"
                exit 1
                ;;
            *)
                log_error "无效选择"
                exit 1
                ;;
        esac
    fi
}

# 创建新分支
create_branch() {
    local branch_name="$1"
    
    log_step "创建新分支: $branch_name"
    
    if git show-ref --verify --quiet refs/heads/$branch_name; then
        log_warn "分支 '$branch_name' 已存在"
        read -p "是否切换到该分支? (y/n): " switch_branch
        if [ "$switch_branch" = "y" ] || [ "$switch_branch" = "Y" ]; then
            git checkout $branch_name
        fi
    else
        git checkout -b $branch_name
        log_info "分支 '$branch_name' 已创建并切换"
    fi
}

# 添加 Docker 相关文件
add_docker_files() {
    log_step "添加 Docker 相关文件到 Git"
    
    # 确保所有 Docker 相关文件都被跟踪
    git add .github/
    git add .dockerignore
    git add docker-compose*.yml
    git add DEPLOYMENT.md
    git add README.Docker.md
    git add setup-docker-branch.sh
    git add backend/Dockerfile
    git add frontend/Dockerfile
    git add frontend/docker/
    git add Dockerfile
    git add docker-entrypoint.sh
    
    log_info "Docker 相关文件已添加到 Git"
}

# 提交更改
commit_changes() {
    log_step "提交 Docker 配置更改"
    
    if git diff --cached --quiet; then
        log_warn "没有需要提交的更改"
        return
    fi
    
    local commit_message="feat: 添加完整的 Docker 化支持和 CI/CD 流程

- 添加多阶段 Dockerfile 构建
- 配置 GitHub Actions 自动构建和发布
- 支持 GHCR 镜像仓库
- 添加开发和生产环境 docker-compose 配置
- 完善部署文档和使用指南
- 支持多架构镜像构建 (AMD64/ARM64)
- 添加健康检查和监控配置"

    git commit -m "$commit_message"
    log_info "更改已提交"
}

# 设置远程仓库
setup_remote() {
    log_step "配置远程仓库"
    
    # 检查是否已有远程仓库
    if git remote | grep -q "origin"; then
        local current_remote=$(git remote get-url origin)
        log_info "当前远程仓库: $current_remote"
        
        read -p "是否要更改远程仓库地址? (y/n): " change_remote
        if [ "$change_remote" = "y" ] || [ "$change_remote" = "Y" ]; then
            read -p "请输入新的 GitHub 仓库地址 (https://github.com/username/repo.git): " repo_url
            git remote set-url origin "$repo_url"
            log_info "远程仓库地址已更新"
        fi
    else
        read -p "请输入 GitHub 仓库地址 (https://github.com/username/repo.git): " repo_url
        git remote add origin "$repo_url"
        log_info "远程仓库已添加"
    fi
}

# 推送分支
push_branch() {
    local branch_name="$1"
    
    log_step "推送分支到 GitHub"
    
    log_info "正在推送分支 '$branch_name' 到远程仓库..."
    
    if git push -u origin "$branch_name"; then
        log_info "分支推送成功！"
        
        # 获取远程仓库信息
        local remote_url=$(git remote get-url origin)
        local repo_path=$(echo "$remote_url" | sed 's/.*github\.com[:/]\([^.]*\)\.git/\1/')
        
        echo ""
        echo "🎉 恭喜！Docker 分支已成功创建并推送到 GitHub"
        echo ""
        echo "📋 接下来的步骤："
        echo "1. 访问 GitHub 仓库: https://github.com/$repo_path"
        echo "2. 创建 Pull Request 将 '$branch_name' 合并到主分支"
        echo "3. 合并后，GitHub Actions 将自动构建 Docker 镜像"
        echo "4. 镜像将发布到: ghcr.io/$repo_path"
        echo ""
        echo "🐳 使用 Docker 部署："
        echo "   docker-compose up -d"
        echo ""
        echo "📚 查看部署文档："
        echo "   - DEPLOYMENT.md"
        echo "   - README.Docker.md"
        
    else
        log_error "分支推送失败"
        log_info "请检查："
        log_info "1. GitHub 仓库地址是否正确"
        log_info "2. 是否有推送权限"
        log_info "3. 网络连接是否正常"
        exit 1
    fi
}

# 主函数
main() {
    echo "🚀 videoAll Docker 分支设置向导"
    echo "=================================="
    echo ""
    
    # 获取分支名称
    read -p "请输入新分支名称 (默认: docker-support): " branch_name
    branch_name=${branch_name:-docker-support}
    
    log_info "开始设置 Docker 分支: $branch_name"
    echo ""
    
    # 执行步骤
    check_git
    check_uncommitted_changes
    create_branch "$branch_name"
    add_docker_files
    commit_changes
    setup_remote
    push_branch "$branch_name"
    
    echo ""
    log_info "设置完成！"
}

# 检查是否在正确的目录
if [ ! -f "package.json" ] && [ ! -f "docker-compose.yml" ]; then
    log_error "请在 videoAll 项目根目录下运行此脚本"
    exit 1
fi

# 运行主函数
main "$@"
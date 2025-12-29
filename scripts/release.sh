#!/bin/bash

# 版本发布脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数定义
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    log_error "请提供版本号参数"
    echo "用法: $0 <version> [--dry-run]"
    echo "示例: $0 1.2.3"
    echo "      $0 1.2.3 --dry-run  # 预览模式，不实际执行"
    exit 1
fi

VERSION=$1
DRY_RUN=false

if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
    log_warning "运行在预览模式，不会实际执行操作"
fi

# 验证版本号格式
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "版本号格式不正确，应该是 x.y.z 格式"
    exit 1
fi

# 检查是否在git仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "当前目录不是git仓库"
    exit 1
fi

# 检查工作区是否干净
if [ -n "$(git status --porcelain)" ]; then
    log_error "工作区有未提交的更改，请先提交或暂存"
    git status --short
    exit 1
fi

# 检查是否在main分支
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    log_warning "当前不在main分支 (当前: $CURRENT_BRANCH)"
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
fi

# 获取最新代码
log_info "获取最新代码..."
if [ "$DRY_RUN" = false ]; then
    git fetch origin
    git pull origin $CURRENT_BRANCH
fi

# 更新版本号
log_info "更新版本号到 $VERSION..."

if [ "$DRY_RUN" = false ]; then
    # 更新后端package.json
    if [ -f "backend/package.json" ]; then
        sed -i.bak "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" backend/package.json
        rm backend/package.json.bak
        log_success "已更新 backend/package.json"
    fi

    # 更新前端package.json
    if [ -f "frontend/package.json" ]; then
        sed -i.bak "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" frontend/package.json
        rm frontend/package.json.bak
        log_success "已更新 frontend/package.json"
    fi

    # 更新docker-compose.yml中的镜像标签
    if [ -f "docker-compose.yml" ]; then
        sed -i.bak "s/IMAGE_TAG=.*/IMAGE_TAG=$VERSION/" .env.example
        rm .env.example.bak 2>/dev/null || true
        log_success "已更新 .env.example"
    fi
else
    log_info "预览: 将更新版本号到 $VERSION"
fi

# 生成变更日志
log_info "生成变更日志..."
CHANGELOG_FILE="CHANGELOG.md"
TEMP_CHANGELOG="temp_changelog.md"

# 获取上一个标签
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
    log_info "从 $LAST_TAG 到当前的变更:"
    
    # 生成变更日志
    echo "# Changelog" > $TEMP_CHANGELOG
    echo "" >> $TEMP_CHANGELOG
    echo "## [$VERSION] - $(date +%Y-%m-%d)" >> $TEMP_CHANGELOG
    echo "" >> $TEMP_CHANGELOG
    
    # 按类型分类提交
    echo "### 🚀 新功能" >> $TEMP_CHANGELOG
    git log $LAST_TAG..HEAD --pretty=format:"- %s (%h)" --grep="feat:" --grep="feature:" >> $TEMP_CHANGELOG || true
    echo "" >> $TEMP_CHANGELOG
    
    echo "### 🐛 Bug修复" >> $TEMP_CHANGELOG
    git log $LAST_TAG..HEAD --pretty=format:"- %s (%h)" --grep="fix:" --grep="bugfix:" >> $TEMP_CHANGELOG || true
    echo "" >> $TEMP_CHANGELOG
    
    echo "### 📚 文档更新" >> $TEMP_CHANGELOG
    git log $LAST_TAG..HEAD --pretty=format:"- %s (%h)" --grep="docs:" >> $TEMP_CHANGELOG || true
    echo "" >> $TEMP_CHANGELOG
    
    echo "### 🔧 其他更改" >> $TEMP_CHANGELOG
    git log $LAST_TAG..HEAD --pretty=format:"- %s (%h)" --invert-grep --grep="feat:" --grep="fix:" --grep="docs:" >> $TEMP_CHANGELOG || true
    echo "" >> $TEMP_CHANGELOG
    
    # 如果存在旧的CHANGELOG，追加到后面
    if [ -f "$CHANGELOG_FILE" ]; then
        echo "" >> $TEMP_CHANGELOG
        cat $CHANGELOG_FILE >> $TEMP_CHANGELOG
    fi
    
    if [ "$DRY_RUN" = false ]; then
        mv $TEMP_CHANGELOG $CHANGELOG_FILE
        log_success "已生成变更日志"
    else
        log_info "预览变更日志:"
        cat $TEMP_CHANGELOG
        rm $TEMP_CHANGELOG
    fi
else
    log_info "这是首次发布，跳过变更日志生成"
fi

# 提交更改
if [ "$DRY_RUN" = false ]; then
    log_info "提交版本更新..."
    git add .
    git commit -m "chore: bump version to $VERSION"
    
    # 创建标签
    log_info "创建标签 v$VERSION..."
    git tag -a "v$VERSION" -m "Release version $VERSION"
    
    # 推送到远程
    log_info "推送到远程仓库..."
    git push origin $CURRENT_BRANCH
    git push origin "v$VERSION"
    
    log_success "版本 $VERSION 发布完成!"
    log_info "GitHub Actions将自动构建和发布Docker镜像"
    log_info "查看构建状态: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
else
    log_info "预览模式完成，没有实际执行任何操作"
fi
#!/bin/bash

# AI配置功能测试 - 快速启动脚本

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     AI配置功能测试 - 服务启动脚本                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查后端服务
echo -e "${BLUE}📡 检查后端服务...${NC}"
if lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务已运行 (端口 3000)${NC}"
else
    echo -e "${YELLOW}⚠️  后端服务未运行，正在启动...${NC}"
    cd backend
    npm run dev > /tmp/backend.log 2>&1 &
    echo "   后端服务正在启动，请等待几秒钟..."
    sleep 5
    cd ..
fi

echo ""

# 2. 检查前端服务
echo -e "${BLUE}🌐 检查前端服务...${NC}"
if lsof -i :5173 > /dev/null 2>&1 || lsof -i :5174 > /dev/null 2>&1 || lsof -i :5175 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 前端服务已运行${NC}"
    FRONTEND_PORT=$(lsof -i :5173 -t > /dev/null 2>&1 && echo "5173" || (lsof -i :5174 -t > /dev/null 2>&1 && echo "5174" || echo "5175"))
else
    echo -e "${YELLOW}⚠️  前端服务未运行，正在启动...${NC}"
    cd frontend
    npm run dev > /tmp/frontend.log 2>&1 &
    echo "   前端服务正在启动，请等待几秒钟..."
    sleep 5
    cd ..
    FRONTEND_PORT="5175"
fi

echo ""

# 3. 检查数据库连接
echo -e "${BLUE}🗄️  检查数据库连接...${NC}"
cd backend
DB_CHECK=$(node -e "
const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://wangxuyang:@localhost:5432/video_all'
});
client.connect().then(() => {
  console.log('connected');
  client.end();
}).catch(() => {
  console.log('failed');
});
" 2>/dev/null)

if [ "$DB_CHECK" = "connected" ]; then
    echo -e "${GREEN}✅ PostgreSQL数据库连接正常${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL数据库连接失败${NC}"
fi
cd ..

echo ""

# 4. 显示访问信息
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     服务状态                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ 所有服务已就绪！${NC}"
echo ""
echo "🌐 访问地址："
echo "   前端: http://localhost:${FRONTEND_PORT}/"
echo "   后端: http://localhost:3000/"
echo "   健康: http://localhost:3000/health"
echo ""
echo "📋 下一步操作："
echo "   1. 在浏览器中打开前端地址"
echo "   2. 使用现有用户登录（例如：yangzai）"
echo "   3. 进入'添加AI模型'页面"
echo "   4. 测试新功能"
echo ""
echo "📖 详细测试指南: AI_CONFIG_TEST_GUIDE.md"
echo ""
echo "🔧 后端日志: tail -f backend/logs/combined.log"
echo "🔧 前端日志: tail -f /tmp/frontend.log"
echo ""
echo "╚════════════════════════════════════════════════════════════╝"

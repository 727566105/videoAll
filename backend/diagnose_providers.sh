#!/bin/bash

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     AI配置提供商问题诊断                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. 检查后端服务
echo "📡 检查后端服务..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务未运行"
    echo "   请执行: cd backend && npm run dev"
    exit 1
fi

echo ""

# 2. 检查前端服务
echo "🌐 检查前端服务..."
FRONTEND_PORT=""
if lsof -i :5173 > /dev/null 2>&1; then
    FRONTEND_PORT="5173"
elif lsof -i :5174 > /dev/null 2>&1; then
    FRONTEND_PORT="5174"
elif lsof -i :5175 > /dev/null 2>&1; then
    FRONTEND_PORT="5175"
fi

if [ -n "$FRONTEND_PORT" ]; then
    echo "✅ 前端服务运行正常 (端口 $FRONTEND_PORT)"
else
    echo "❌ 前端服务未运行"
    echo "   请执行: cd frontend && npm run dev"
    exit 1
fi

echo ""

# 3. 检查路由配置
echo "🔍 检查路由配置..."
ROUTE_FILE="backend/src/routes/aiConfig.js"
if grep -q "元数据路由（必须在 /:id 之前定义）" "$ROUTE_FILE"; then
    echo "✅ 路由顺序已修复"
else
    echo "❌ 路由顺序可能有问题"
    echo "   请检查 backend/src/routes/aiConfig.js 文件"
fi

echo ""

# 4. 测试API端点（不需要认证的）
echo "🧪 测试API端点..."

echo "  1. 测试健康检查..."
HEALTH_CHECK=$(curl -s http://localhost:3000/health)
if echo "$HEALTH_CHECK" | grep -q "ok"; then
    echo "     ✅ 健康检查通过"
else
    echo "     ❌ 健康检查失败"
fi

echo "  2. 测试提供商列表（无token）..."
PROVIDERS_NO_TOKEN=$(curl -s http://localhost:3000/api/v1/ai-config/meta/providers)
if echo "$PROVIDERS_NO_TOKEN" | grep -q "Unauthorized"; then
    echo "     ⚠️  需要认证（正常）"
else
    echo "     ❓ 意外响应: $PROVIDERS_NO_TOKEN"
fi

echo ""

# 5. 检查数据库
echo "🗄️  检查数据库连接..."
cd backend
DB_CHECK=$(node -e "
const { AppDataSource } = require('./src/data-source');
(async () => {
  try {
    await AppDataSource.initialize();
    console.log('connected');
    await AppDataSource.destroy();
  } catch (e) {
    console.log('failed');
  }
})()" 2>/dev/null)

if [ "$DB_CHECK" = "connected" ]; then
    echo "✅ 数据库连接正常"
else
    echo "❌ 数据库连接失败"
fi
cd ..

echo ""

# 6. 查看后端日志中的错误
echo "📋 检查后端日志..."
if [ -f "backend/logs/error.log" ]; then
    ERROR_COUNT=$(tail -n 50 backend/logs/error.log | wc -l)
    echo "   最近50行错误日志中有 $ERROR_COUNT 条记录"
    if [ $ERROR_COUNT -gt 0 ]; then
        echo "   最后一条错误:"
        tail -n 1 backend/logs/error.log
    fi
else
    echo "   ⚠️  错误日志文件不存在"
fi

echo ""

# 7. 诊断总结和建议
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     诊断结果                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 前端访问: http://localhost:$FRONTEND_PORT/"
echo ""
echo "📋 排查步骤:"
echo "   1. 打开浏览器访问前端地址"
echo "   2. 登录系统（使用现有用户）"
echo "   3. 打开浏览器开发者工具（F12）"
echo "   4. 切换到 Network 标签"
echo "   5. 刷新页面并访问'添加AI模型'页面"
echo "   6. 查找 '/ai-config/meta/providers' 请求"
echo "   7. 检查该请求的："
echo "      - Request Headers (是否包含 Authorization: Bearer ...)"
echo "      - Response Status (应该是 200)"
echo "      - Response Data (应该包含 8 个提供商)"
echo ""
echo "💡 如果看到 401 Unauthorized:"
echo "   - 说明未登录或token过期，请重新登录"
echo ""
echo "💡 如果看到 200 但提供商数量不对:"
echo "   - 检查 Response Data 中的数据"
echo "   - 查看浏览器 Console 是否有错误"
echo ""
echo "💡 如果请求失败:"
echo "   - 查看后端日志: tail -f backend/logs/combined.log"
echo "   - 查看错误日志: tail -f backend/logs/error.log"
echo ""
echo "╚════════════════════════════════════════════════════════════╝"

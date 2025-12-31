#!/bin/bash

echo "统计各模块接口数量:"
echo "================================="
echo ""

total=0

# 认证模块 (auth.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/auth.js | wc -l)
echo "认证模块: $count 个接口"
total=$((total + count))

# 内容管理 (content.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/content.js | wc -l)
echo "内容管理: $count 个接口"
total=$((total + count))

# 仪表盘统计
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/dashboard.js | wc -l)
echo "仪表盘统计: $count 个接口"
total=$((total + count))

# 用户管理 (users.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/users.js | wc -l)
echo "用户管理: $count 个接口"
total=$((total + count))

# 任务管理 (tasks.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/tasks.js | wc -l)
echo "任务管理: $count 个接口"
total=$((total + count))

# 热搜管理 (hotsearch.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/hotsearch.js | wc -l)
echo "热搜管理: $count 个接口"
total=$((total + count))

# 系统配置
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/config.js | wc -l)
echo "系统配置: $count 个接口"
total=$((total + count))

# AI配置 (aiConfig.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/aiConfig.js | wc -l)
echo "AI配置: $count 个接口"
total=$((total + count))

# 标签管理 (tags.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/tags.js | wc -l)
echo "标签管理: $count 个接口"
total=$((total + count))

# 备份管理 (backup.js)
count=$(grep -E "router\.(get|post|put|delete|patch)" backend/src/routes/backup.js | wc -l)
echo "备份管理: $count 个接口"
total=$((total + count))

echo ""
echo "================================="
echo "总计: $total 个接口"

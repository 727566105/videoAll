#!/bin/bash
# 批量替换 ContentParsing.jsx 中的硬编码颜色

FILE="/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/ContentParsing.jsx"

# 备份文件
cp "$FILE" "$FILE.bak"

# 使用 sed 进行替换
# 注意：macOS 的 sed 需要使用 '' 作为分隔符

# 1. 替换颜色值为 token 引用
sed -i '' "s/color: '#999'/color: token.colorTextQuaternary/g" "$FILE"
sed -i '' "s/color: '#666'/color: token.colorTextTertiary/g" "$FILE"
sed -i '' "s/color: '#1890ff'/color: token.colorPrimary/g" "$FILE"
sed -i '' "s/color: '#ff4d4f'/color: token.colorError/g" "$FILE"
sed -i '' "s/color: '#52c41a'/color: token.colorSuccess/g"
sed -i '' "s/color: '#108ee9'/color: token.colorPrimary/g" "$FILE"
sed -i '' "s/color: '#87d068'/color: token.colorSuccess/g" "$FILE"

# 2. 替换背景色
sed -i '' "s/backgroundColor: '#f0f0f0'/backgroundColor: token.colorFillQuaternary/g" "$FILE"
sed -i '' "s/backgroundColor: '#f5f5f5'/backgroundColor: token.colorFillTertiary/g" "$FILE"
sed -i '' "s/backgroundColor: '#fafafa'/backgroundColor: token.colorFillSecondary/g" "$FILE"
sed -i '' "s/backgroundColor: '#fff'/backgroundColor: token.colorBgContainer/g" "$FILE"
sed -i '' "s/backgroundColor: '#ffffff'/backgroundColor: token.colorBgContainer/g" "$FILE"
sed -i '' "s/backgroundColor: '#f6ffed'/backgroundColor: '\${token.colorSuccess}10'/g" "$FILE"

# 3. 替换边框颜色
sed -i '' "s/border: '1px solid #d9d9d9'/border: \`1px solid \${token.colorBorder}\`/g" "$FILE"
sed -i '' "s/border: '1px solid #b7eb8f'/border: \`1px solid \${token.colorSuccess}\`/g" "$FILE"
sed -i '' "s/border: '2px solid #e8e8e8'/border: \`2px solid \${token.colorBorderSecondary}\`/g" "$FILE"
sed -i '' "s/borderColor = '#e8e8e8'/borderColor = token.colorBorderSecondary/g" "$FILE"

# 4. 特殊处理 - 进度条渐变
sed -i '' "s/'0%': '#108ee9'/'0%': token.colorPrimary/g" "$FILE"
sed -i '' "s/'100%': '#87d068'/'100%': token.colorSuccess/g" "$FILE"

echo "✅ ContentParsing.jsx 颜色替换完成"
echo "备份文件: $FILE.bak"

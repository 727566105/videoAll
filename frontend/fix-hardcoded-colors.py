#!/usr/bin/env python3
"""
批量替换前端页面中的硬编码颜色为主题Token
"""
import re
import sys
from pathlib import Path

# 颜色映射表
COLOR_REPLACEMENTS = {
    # 文本颜色
    r"color: '#999'": 'color: token.colorTextQuaternary',
    r"color: '#666'": 'color: token.colorTextTertiary',
    r"color: '#333'": 'color: token.colorTextSecondary',
    r"color: '#000'": 'color: token.colorText',
    r"color: '#1890ff'": 'color: token.colorPrimary',
    r"color: '#1677ff'": 'color: token.colorPrimary',
    r"color: '#40a9ff'": 'color: token.colorPrimary',  # dark theme
    r"color: '#ff4d4f'": 'color: token.colorError',
    r"color: '#52c41a'": 'color: token.colorSuccess',
    r"color: '#faad14'": 'color: token.colorWarning',
    r"color: '#108ee9'": 'color: token.colorPrimary',
    r"color: '#87d068'": 'color: token.colorSuccess',
    r"color: '#fff'": 'color: token.colorBgElevated',
    r"color: '#ffffff'": 'color: token.colorBgElevated',

    # 背景颜色
    r"backgroundColor: '#f0f0f0'": 'backgroundColor: token.colorFillQuaternary',
    r"backgroundColor: '#f5f5f5'": 'backgroundColor: token.colorFillTertiary',
    r"backgroundColor: '#fafafa'": 'backgroundColor: token.colorFillSecondary',
    r"backgroundColor: '#fff'": 'backgroundColor: token.colorBgContainer',
    r"backgroundColor: '#ffffff'": 'backgroundColor: token.colorBgContainer',
    r"backgroundColor: '#f6ffed'": "backgroundColor: `${token.colorSuccess}10`",
    r"backgroundColor: '#e6f7ff'": "backgroundColor: `${token.colorPrimary}10`",

    # 边框颜色
    r"border: '1px solid #d9d9d9'": 'border: `1px solid ${token.colorBorder}`',
    r"border: '1px solid #b7eb8f'": 'border: `1px solid ${token.colorSuccess}`',
    r"border: '1px solid #91d5ff'": 'border: `1px solid ${token.colorPrimary}`',
    r"border: '2px solid #e8e8e8'": 'border: `2px solid ${token.colorBorderSecondary}`',
    r"borderColor = '#e8e8e8'": 'borderColor = token.colorBorderSecondary',
    r"borderColor = '#1890ff'": 'borderColor = token.colorPrimary',

    # 阴影
    r"boxShadow: '0 2px 8px rgba\(0, 0, 0, 0\.15\)'": 'boxShadow: token.boxShadowSecondary',
    r"boxShadow: '0 4px 12px rgba\(0, 0, 0, 0\.15\)'": 'boxShadow: token.boxShadowSecondary',

    # 进度条渐变
    r"'0%': '#108ee9'": "'0%': token.colorPrimary",
    r"'100%': '#87d068'": "'100%': token.colorSuccess",
}

def fix_file(file_path: Path):
    """修复单个文件中的硬编码颜色"""
    print(f"处理文件: {file_path}")

    # 读取文件
    content = file_path.read_text(encoding='utf-8')
    original_content = content

    # 应用所有替换规则
    for pattern, replacement in COLOR_REPLACEMENTS.items():
        content = re.sub(pattern, replacement, content)

    # 检查是否有变化
    if content != original_content:
        # 备份原文件
        backup_path = file_path.with_suffix(file_path.suffix + '.bak')
        backup_path.write_text(original_content, encoding='utf-8')
        print(f"  ✅ 已备份到: {backup_path}")

        # 写入修复后的内容
        file_path.write_text(content, encoding='utf-8')
        print(f"  ✅ 修复完成")
        return True
    else:
        print(f"  ℹ️  无需修复")
        return False

def main():
    """主函数"""
    # 需要修复的文件列表
    files_to_fix = [
        'ContentParsing.jsx',
        'ContentManagement.jsx',
        'SystemConfig.jsx',
        'TaskManagement.jsx',
    ]

    base_path = Path('/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages')

    fixed_count = 0
    for filename in files_to_fix:
        file_path = base_path / filename
        if file_path.exists():
            if fix_file(file_path):
                fixed_count += 1
        else:
            print(f"⚠️  文件不存在: {file_path}")

    print(f"\n✨ 总计修复 {fixed_count}/{len(files_to_fix)} 个文件")

if __name__ == '__main__':
    main()

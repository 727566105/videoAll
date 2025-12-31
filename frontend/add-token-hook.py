#!/usr/bin/env python3
"""
为修复的文件添加 token 声明
"""
import re
from pathlib import Path

def add_token_declaration(file_path: Path):
    """为组件添加 token 声明"""
    print(f"处理: {file_path}")

    content = file_path.read_text(encoding='utf-8')

    # 检查是否已有 token 声明
    if 'const { token } = App.useApp()' in content:
        print(f"  ℹ️  已存在 token 声明，跳过")
        return

    # 检查是否已导入 App
    if 'App' not in content or 'import' not in content:
        print(f"  ⚠️  未找到 App 导入")
        return

    # 查找组件函数定义（箭头函数）
    # 匹配模式：const ComponentName = () => {
    pattern = r"(const\s+\w+\s*=\s*\(\)\s*=>\s*\{)"
    match = re.search(pattern, content)

    if match:
        # 在组件函数定义后添加 token 声明
        insert_pos = match.end()
        indent = "  "
        token_decl = f"\n{indent}const {{ token }} = App.useApp();"

        content = content[:insert_pos] + token_decl + content[insert_pos:]

        file_path.write_text(content, encoding='utf-8')
        print(f"  ✅ 已添加 token 声明")
    else:
        print(f"  ⚠️  未找到组件函数定义")

def main():
    files = [
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/ContentParsing.jsx',
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/ContentManagement.jsx',
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/SystemConfig.jsx',
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/TaskManagement.jsx',
    ]

    for file_path in files:
        add_token_declaration(Path(file_path))

if __name__ == '__main__':
    main()

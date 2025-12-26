#!/usr/bin/env python3
"""
为所有 token 访问添加可选链操作符
"""
import re
from pathlib import Path

def fix_token_access(file_path: Path):
    """修复文件中的 token 访问"""
    print(f"处理文件: {file_path}")

    content = file_path.read_text(encoding='utf-8')
    original_content = content

    # 替换所有 token.xxx 为 token?.xxx
    # 但排除已经是 token?.xxx 的情况
    content = re.sub(r'\btoken\.', 'token?.', content)

    # 检查是否有变化
    if content != original_content:
        # 备份原文件
        backup_path = file_path.with_suffix(file_path.suffix + '.bak2')
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
    files = [
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/ContentParsing.jsx',
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/ContentManagement.jsx',
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/SystemConfig.jsx',
        '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/frontend/src/pages/TaskManagement.jsx',
    ]

    fixed_count = 0
    for file_path in files:
        path = Path(file_path)
        if path.exists():
            if fix_token_access(path):
                fixed_count += 1
        else:
            print(f"⚠️  文件不存在: {file_path}")

    print(f"\n✨ 总计修复 {fixed_count}/{len(files)} 个文件")

if __name__ == '__main__':
    main()

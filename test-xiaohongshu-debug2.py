#!/usr/bin/env python3
import sys
sys.path.insert(0, '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/media_parser_sdk')

import re
import json
import httpx

# 使用一个有效的链接进行测试
test_url = "https://www.xiaohongshu.com/explore/6754051d0000000012006887"

print(f"测试链接: {test_url}\n")

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Referer": "https://www.xiaohongshu.com/",
}

with httpx.Client(headers=headers, timeout=15, follow_redirects=True) as client:
    response = client.get(test_url)
    html = response.text

# 检查是否有 __INITIAL_STATE__
initial_state_pattern = re.compile(r'window\.__INITIAL_STATE__\s*=\s*(.+?)(?=</script>)', re.DOTALL)
initial_state_match = initial_state_pattern.search(html)

if initial_state_match:
    print("✅ 找到 __INITIAL_STATE__")

    initial_state_str = initial_state_match.group(1).strip()
    if initial_state_str.endswith(';'):
        initial_state_str = initial_state_str[:-1]

    print(f"原始 JSON 长度: {len(initial_state_str)}")

    # 尝试修复 JSON
    fixed_str = re.sub(r'\bundefined\b', 'null', initial_state_str)
    fixed_str = re.sub(r',(\s*[}\]])', r'\1', fixed_str)
    fixed_str = re.sub(r'//.*?\n', '\n', fixed_str)
    fixed_str = re.sub(r'/\*.*?\*/', '', fixed_str, flags=re.DOTALL)

    print(f"修复后 JSON 长度: {len(fixed_str)}")

    # 尝试解析修复后的 JSON
    try:
        initial_state = json.loads(fixed_str)
        print("✅ 修复后 JSON 解析成功")
        print(f"顶层键: {list(initial_state.keys())}")

        # 查找 note 数据
        note = initial_state.get("note", {})
        print(f"\nnote 对象键: {list(note.keys())}")

        note_detail_map = note.get("noteDetailMap", {})
        print(f"noteDetailMap 长度: {len(note_detail_map)}")

        if note_detail_map:
            note_id = next(iter(note_detail_map.keys()), None)
            print(f"第一个 note_id: {note_id}")

            if note_id:
                note_detail = note_detail_map[note_id]
                note_data = note_detail.get("note", {})

                if note_data:
                    print(f"\n✅ 找到 note_data!")
                    print(f"note_data 键: {list(note_data.keys())}")

                    # 检查统计数据
                    print(f"\n📊 检查统计数据字段:")
                    print(f"  likedCount: {note_data.get('likedCount')}")
                    print(f"  collectedCount: {note_data.get('collectedCount')}")
                    print(f"  commentCount: {note_data.get('commentCount')}")
                    print(f"  shareCount: {note_data.get('shareCount')}")
                    print(f"  viewCount: {note_data.get('viewCount')}")
                    print(f"  time: {note_data.get('time')}")
                else:
                    print("\n❌ note_detail 中没有 note 字段")
                    print(f"note_detail 键: {list(note_detail.keys()) if isinstance(note_detail, dict) else type(note_detail)}")
        else:
            print("\n❌ noteDetailMap 为空")
            # 打印整个 note 对象来了解结构
            print(f"note 对象内容: {json.dumps(note, ensure_ascii=False)[:500]}...")

    except json.JSONDecodeError as e:
        print(f"❌ 修复后 JSON 解析仍然失败: {e}")
        print(f"错误位置: {e.pos}")

        # 打印错误位置附近的内容
        if e.pos:
            start = max(0, e.pos - 50)
            end = min(len(fixed_str), e.pos + 50)
            print(f"错误附近内容: {repr(fixed_str[start:end])}")
else:
    print("❌ 没有找到 __INITIAL_STATE__")

# 检查页面标题
title_match = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE)
if title_match:
    print(f"\n页面标题: {title_match.group(1)}")

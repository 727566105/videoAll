#!/usr/bin/env python3
import sys
sys.path.insert(0, '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/media_parser_sdk')

import re
import json
import httpx

test_url = "https://www.xiaohongshu.com/explore/6754051d0000000012006887"

print(f"测试链接: {test_url}\n")

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Referer": "https://www.xiaohongshu.com/",
}

with httpx.Client(headers=headers, timeout=15, follow_redirects=True) as client:
    response = client.get(test_url)
    html = response.text

initial_state_pattern = re.compile(r'window\.__INITIAL_STATE__\s*=\s*(.+?)(?=</script>)', re.DOTALL)
initial_state_match = initial_state_pattern.search(html)

if initial_state_match:
    initial_state_str = initial_state_match.group(1).strip()
    if initial_state_str.endswith(';'):
        initial_state_str = initial_state_str[:-1]

    fixed_str = re.sub(r'\bundefined\b', 'null', initial_state_str)
    fixed_str = re.sub(r',(\s*[}\]])', r'\1', fixed_str)
    fixed_str = re.sub(r'//.*?\n', '\n', fixed_str)
    fixed_str = re.sub(r'/\*.*?\*/', '', fixed_str, flags=re.DOTALL)

    initial_state = json.loads(fixed_str)

    note = initial_state.get("note", {})
    note_detail_map = note.get("noteDetailMap", {})

    print(f"noteDetailMap 内容:")
    for note_id, note_detail in note_detail_map.items():
        print(f"\n  note_id: {note_id}")
        print(f"  note_detail 类型: {type(note_detail)}")

        if isinstance(note_detail, dict):
            note_data = note_detail.get("note")
            print(f"  note_data 类型: {type(note_data)}")

            if note_data is None:
                print(f"  ❌ note_data 是 None")
            elif isinstance(note_data, dict):
                is_empty = len(note_data) == 0
                print(f"  note_data 是否为空: {is_empty}")
                print(f"  note_data 长度: {len(note_data)}")
                if not is_empty:
                    print(f"  note_data 键: {list(note_data.keys())}")
                    print(f"  note_data 内容: {json.dumps(note_data, ensure_ascii=False, indent=2)[:500]}")
            else:
                print(f"  note_data 值: {note_data}")

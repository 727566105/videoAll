#!/usr/bin/env python3
import sys
sys.path.insert(0, '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/media_parser_sdk')

import re
import json
import httpx

test_url = 'https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b/69421f8f000000001b0337f8?xsec_token=ABuUN8WdK15ZUt4kkqr0s4Wc0CNEoeHnWCalxsftOn2ok=&xsec_source=pc_user'

print(f"分析链接: {test_url}\n")

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

    print(f"noteDetailMap 长度: {len(note_detail_map)}")

    for note_id, note_detail in note_detail_map.items():
        print(f"\nnote_id: {note_id}")

        if isinstance(note_detail, dict):
            note_data = note_detail.get("note")

            if note_data and isinstance(note_data, dict):
                print(f"\n✅ note_data 键: {list(note_data.keys())}")

                # 检查所有可能的统计数据字段
                print(f"\n🔍 检查所有可能的统计字段:")
                stats_fields = [
                    'likedCount', 'liked_count', 'likeCount', 'like_count',
                    'collectedCount', 'collected_count', 'collectCount', 'collect_count',
                    'commentCount', 'comment_count',
                    'shareCount', 'share_count',
                    'viewCount', 'view_count',
                    'interactInfo', 'interaction_info'
                ]

                for field in stats_fields:
                    value = note_data.get(field)
                    if value is not None:
                        print(f"  ✅ {field}: {value}")

                # 打印 note_data 的前几个字段来了解结构
                print(f"\n📋 note_data 前10个字段:")
                for i, (key, value) in enumerate(list(note_data.items())[:10]):
                    if isinstance(value, (str, int, float, bool, type(None))):
                        print(f"  {key}: {value}")
                    elif isinstance(value, list):
                        print(f"  {key}: [list, 长度={len(value)}]")
                    elif isinstance(value, dict):
                        print(f"  {key}: {{dict, 键={list(value.keys())[:5]}}}")
                    else:
                        print(f"  {key}: {type(value)}")

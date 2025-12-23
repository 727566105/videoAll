#!/usr/bin/env python3
import sys
sys.path.insert(0, '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/media_parser_sdk')

import re
import json
import httpx
from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser

# 使用一个有效的链接进行测试
test_url = "https://www.xiaohongshu.com/explore/6754051d0000000012006887"

print(f"测试链接: {test_url}\n")

parser = XiaohongshuParser()

# 获取 HTML
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

    try:
        initial_state = json.loads(initial_state_str)
        print(f"✅ JSON 解析成功")
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
            else:
                print("\n❌ noteDetailMap 为空")
        else:
            print("\n❌ 没有 noteDetailMap")

    except json.JSONDecodeError as e:
        print(f"❌ JSON 解析失败: {e}")
else:
    print("❌ 没有找到 __INITIAL_STATE__")

# 检查页面标题
title_match = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE)
if title_match:
    print(f"\n页面标题: {title_match.group(1)}")

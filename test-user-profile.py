#!/usr/bin/env python3
"""
测试小红书用户主页解析
"""
import re
import json
import httpx
from typing import List, Dict, Optional
from datetime import datetime

def test_user_profile(url: str):
    """测试用户主页解析"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Referer": "https://www.xiaohongshu.com/",
        "Accept-Language": "zh-CN,zh;q=0.9"
    }

    print(f"正在请求用户主页: {url}")
    print("=" * 80)

    try:
        with httpx.Client(headers=headers, timeout=30, follow_redirects=True) as client:
            response = client.get(url)
            response.raise_for_status()
            html = response.text

            print(f"✓ 成功获取HTML，长度: {len(html)} 字符\n")

            # 尝试提取window.__INITIAL_STATE__
            initial_state_pattern = re.compile(r'window\.__INITIAL_STATE__\s*=\s*(.+?)(?=</script>)', re.DOTALL)
            initial_state_match = initial_state_pattern.search(html)

            if initial_state_match:
                print("✓ 找到 window.__INITIAL_STATE__")
                initial_state_str = initial_state_match.group(1).strip()
                if initial_state_str.endswith(';'):
                    initial_state_str = initial_state_str[:-1]

                initial_state = parse_and_analyze(initial_state_str)
                if initial_state:
                    return initial_state
            else:
                print("✗ 未找到 window.__INITIAL_STATE__")

            # 尝试查找其他可能的数据
            print("\n尝试查找其他数据源...")
            print("-" * 80)

            # 查找所有script标签中的JSON数据
            script_pattern = re.compile(r'<script[^>]*>(.+?)</script>', re.DOTALL)
            scripts = script_pattern.findall(html)
            print(f"找到 {len(scripts)} 个 script 标签")

            # 查找可能包含笔记数据的script
            for i, script in enumerate(scripts):
                if 'note' in script.lower() or 'user' in script.lower():
                    print(f"Script {i} 包含 'note' 或 'user' 关键字")
                    if len(script) < 500:
                        print(f"  内容预览: {script[:200]}...")

    except Exception as e:
        print(f"✗ 请求失败: {e}")
        import traceback
        traceback.print_exc()


def parse_and_analyze(initial_state_str: str) -> Optional[dict]:
    """解析并分析initial_state"""

    try:
        initial_state = json.loads(initial_state_str)
        print("✓ 成功解析 JSON（直接）\n")
    except json.JSONDecodeError as e:
        print(f"✗ JSON解析失败: {e}")
        print(f"错误位置附近的内容: {initial_state_str[max(0, e.pos-100):e.pos+100]}")
        print("尝试修复JSON...")

        # 尝试修复JSON
        fixed_str = re.sub(r'\bundefined\b', 'null', initial_state_str)
        fixed_str = re.sub(r',(\s*[}\]])', r'\1', fixed_str)
        fixed_str = re.sub(r'//.*?\n', '\n', fixed_str)
        fixed_str = re.sub(r'/\*.*?\*/', '', fixed_str, flags=re.DOTALL)

        try:
            initial_state = json.loads(fixed_str)
            print("✓ 修复后成功解析 JSON\n")
        except json.JSONDecodeError as e2:
            print(f"✗ 修复后仍然解析失败: {e2}")
            return None

    # 保存完整的initial_state以便分析
    try:
        with open('user_profile_initial_state.json', 'w', encoding='utf-8') as f:
            json.dump(initial_state, f, ensure_ascii=False, indent=2)
        print("✓ 已保存完整的 initial_state 到 user_profile_initial_state.json\n")
    except Exception as save_err:
        print(f"⚠ 保存文件失败: {save_err}\n")

    # 分析数据结构
    print("数据结构分析:")
    print("-" * 80)
    for key in list(initial_state.keys())[:20]:  # 只显示前20个key
        value = initial_state[key]
        if isinstance(value, dict):
            print(f"  {key}: (dict, {len(value)} keys)")
        elif isinstance(value, list):
            print(f"  {key}: (list, {len(value)} items)")
        else:
            print(f"  {key}: {type(value).__name__}")
    print()

    # 尝试提取用户信息
    user_info = extract_user_info(initial_state)
    if user_info:
        print("用户信息:")
        print("-" * 80)
        for key, value in user_info.items():
            print(f"  {key}: {value}")
        print()

    # 尝试提取笔记列表
    notes = extract_notes(initial_state)
    if notes:
        print(f"✓ 找到 {len(notes)} 条笔记:")
        print("-" * 80)
        for i, note in enumerate(notes[:10], 1):  # 只显示前10条
            print(f"\n笔记 {i}:")
            print(f"  ID: {note.get('id')}")
            print(f"  标题: {note.get('title')[:50] if note.get('title') else 'N/A'}...")
            print(f"  类型: {note.get('type')}")
            print(f"  点赞: {note.get('liked_count')}")
            print(f"  收藏: {note.get('collected_count')}")
            print(f"  发布时间: {note.get('time')}")

            # 显示媒体信息
            images = note.get('images', [])
            videos = note.get('videos', [])
            if images:
                print(f"  图片: {len(images)} 张")
            if videos:
                print(f"  视频: {len(videos)} 个")

        if len(notes) > 10:
            print(f"\n... 还有 {len(notes) - 10} 条笔记")

    return initial_state


def extract_user_info(initial_state: dict) -> Dict:
    """从initial_state中提取用户信息"""
    user_info = {}

    # 常见的用户信息路径
    paths = [
        ('user', 'userProfileMap'),
        ('user',),
    ]

    for path in paths:
        current = initial_state
        for key in path:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                current = None
                break

        if current and isinstance(current, dict):
            # 尝试找到用户数据
            if 'userProfileMap' in str(current):
                for profile_key, profile_value in current.items():
                    if isinstance(profile_value, dict) and 'user' in profile_value:
                        user = profile_value['user']
                        user_info['nickname'] = user.get('nickname')
                        user_info['user_id'] = user.get('userId') or user.get('webId')
                        user_info['desc'] = user.get('desc')
                        user_info['follows'] = user.get('follows')
                        user_info['fans'] = user.get('fans')
                        user_info['interaction'] = user.get('interaction')
                        break
            elif isinstance(current, dict) and 'nickname' in current:
                user_info['nickname'] = current.get('nickname')
                user_info['user_id'] = current.get('userId') or current.get('webId')
                user_info['desc'] = current.get('desc')
                user_info['follows'] = current.get('follows')
                user_info['fans'] = current.get('fans')

        if user_info:
            break

    return user_info


def extract_notes(initial_state: dict) -> List[Dict]:
    """从initial_state中提取笔记列表"""
    notes = []
    seen_ids = set()

    # 递归搜索笔记数据
    def search_for_notes(data, path=""):
        if isinstance(data, dict):
            # 检查是否是笔记列表
            if 'notes' in data or 'noteList' in data:
                note_list = data.get('notes') or data.get('noteList')
                if isinstance(note_list, list):
                    for item in note_list:
                        if isinstance(item, dict):
                            note = extract_note_info(item)
                            if note and note.get('id') not in seen_ids:
                                seen_ids.add(note.get('id'))
                                notes.append(note)

            # 检查是否是单个笔记
            if 'noteId' in data or ('id' in data and 'title' in data):
                note = extract_note_info(data)
                if note and note.get('id') not in seen_ids:
                    seen_ids.add(note.get('id'))
                    notes.append(note)

            # 递归搜索
            for key, value in data.items():
                if key not in ['raw_data']:  # 跳过可能很大的字段
                    search_for_notes(value, f"{path}.{key}" if path else key)

        elif isinstance(data, list):
            for item in data:
                search_for_notes(item, path)

    search_for_notes(initial_state)
    return notes


def extract_note_info(note_data: dict) -> Optional[Dict]:
    """从笔记数据中提取信息"""
    if not isinstance(note_data, dict):
        return None

    note_info = {}

    # 提取ID
    note_info['id'] = note_data.get('id') or note_data.get('noteId') or note_data.get('note_id')
    note_info['title'] = note_data.get('title') or note_data.get('desc', '')
    note_info['type'] = note_data.get('type', 'normal')
    note_info['liked_count'] = note_data.get('likedCount') or note_data.get('liked_count') or 0
    note_info['collected_count'] = note_data.get('collectedCount') or note_data.get('collected_count') or 0
    note_info['comment_count'] = note_data.get('commentCount') or note_data.get('comment_count') or 0
    note_info['share_count'] = note_data.get('shareCount') or note_data.get('share_count') or 0
    note_info['time'] = note_data.get('time') or note_data.get('publishTime') or note_data.get('publish_time')

    # 提取媒体信息
    images = []
    videos = []

    image_list = note_data.get('imageList', [])
    if isinstance(image_list, list):
        for img in image_list:
            if isinstance(img, dict):
                url = img.get('urlDefault') or img.get('url') or img.get('urlPre')
                if url:
                    images.append(url)

    video = note_data.get('video')
    if video and isinstance(video, dict):
        stream = video.get('stream', {})
        h264 = stream.get('h264', [])
        if isinstance(h264, list):
            for item in h264:
                if isinstance(item, dict):
                    master_url = item.get('masterUrl')
                    if master_url:
                        videos.append(master_url)

    note_info['images'] = images
    note_info['videos'] = videos

    return note_info if note_info.get('id') else None


if __name__ == '__main__':
    # 测试用户主页URL
    url = "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b?xsec_token=AB_dvy9rzCaq9UiN_lSZb-9PIO7Tv29jOzdyKSObkM3uM=&xsec_source=pc_note&m_source=pwa"

    result = test_user_profile(url)

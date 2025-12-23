#!/usr/bin/env python3
"""
测试小红书增强解析器功能
"""
import sys
import json
from pathlib import Path

# 添加SDK路径
sys.path.insert(0, str(Path(__file__).parent / "media_parser_sdk"))

from media_parser_sdk.platforms.xiaohongshu_enhanced import (
    XiaohongshuEnhancedParser,
    extract_xiaohongshu_author_sync,
    extract_xiaohongshu_author_notes_sync
)


def test_author_profile():
    """测试获取用户资料"""
    print("=" * 80)
    print("测试1: 获取用户资料")
    print("=" * 80)

    url = "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b?xsec_token=AB_dvy9rzCaq9UiN_lSZb-9PIO7Tv29jOzdyKSObkM3uM=&xsec_source=pc_note&m_source=pwa"

    result = extract_xiaohongshu_author_sync(url)

    if result.success:
        print(f"✓ 成功获取用户资料")
        print(json.dumps(result.data, indent=2, ensure_ascii=False))
    else:
        print(f"✗ 失败: {result.error_message}")

    print()


def test_author_notes_cards_only():
    """测试获取用户笔记（仅卡片数据）"""
    print("=" * 80)
    print("测试2: 获取用户笔记（仅卡片，不获取详情）")
    print("=" * 80)

    url = "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b?xsec_token=AB_dvy9rzCaq9UiN_lSZb-9PIO7Tv29jOzdyKSObkM3uM=&xsec_source=pc_note&m_source=pwa"

    result = extract_xiaohongshu_author_notes_sync(url, max_notes=3, fetch_detail=False)

    if result.success:
        data = result.data
        print(f"✓ 成功获取笔记列表")
        print(f"用户: {data['author_profile']['nickname']}")
        print(f"总笔记数: {data['total_notes']}")
        print(f"已提取: {data['extracted_notes']}")
        print(f"\n笔记列表:")
        for i, note in enumerate(data['notes'], 1):
            detail_status = "✓ 详细" if note.get('has_detail') else "○ 卡片"
            print(f"  {i}. {detail_status} {note['title']} - 点赞: {note['interaction_stats']['like_count']}")
    else:
        print(f"✗ 失败: {result.error_message}")

    print()


def test_author_notes_with_detail():
    """测试获取用户笔记（包含详细信息）"""
    print("=" * 80)
    print("测试3: 获取用户笔记（包含详细信息，仅取前2条）")
    print("=" * 80)

    url = "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b?xsec_token=AB_dvy9rzCaq9UiN_lSZb-9PIO7Tv29jOzdyKSObkM3uM=&xsec_source=pc_note&m_source=pwa"

    result = extract_xiaohongshu_author_notes_sync(url, max_notes=2, fetch_detail=True)

    if result.success:
        data = result.data
        print(f"✓ 成功获取笔记列表（含详情）")
        print(f"用户: {data['author_profile']['nickname']}")
        print(f"已提取: {data['extracted_notes']}/{data['total_notes']}")
        print(f"统计: 成功解析 {data['extraction_stats']['successfully_parsed']} 条，卡片数据 {data['extraction_stats']['fallback_to_cards']} 条")
        print(f"\n笔记列表:")

        for i, note in enumerate(data['notes'], 1):
            detail_status = "✓ 详细" if note.get('has_detail') else "○ 卡片"
            print(f"\n  {i}. {detail_status} {note['title']}")
            print(f"     类型: {note['type']}")
            print(f"     点赞: {note['interaction_stats']['like_count']}")
            print(f"     图片: {len(note.get('images', []))} 张")
            print(f"     视频: {len(note.get('videos', []))} 个")
            if note.get('images'):
                print(f"     示例图片: {note['images'][0]['url'][:60]}...")
            if note.get('videos'):
                print(f"     示例视频: {note['videos'][0]['url'][:60]}...")
    else:
        print(f"✗ 失败: {result.error_message}")

    print()


def test_parser_class():
    """测试解析器类"""
    print("=" * 80)
    print("测试4: 使用解析器类")
    print("=" * 80)

    parser = XiaohongshuEnhancedParser()

    url = "https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b"

    # 测试获取笔记
    result = parser.parse_author_notes_sync(url, max_notes=2, fetch_detail=False)

    if result.success:
        data = result.data
        print(f"✓ 解析器工作正常")
        print(f"用户: {data['author_profile']['nickname']}")
        print(f"笔记数: {data['extracted_notes']}")
        for note in data['notes']:
            print(f"  - {note['title']}")
    else:
        print(f"✗ 失败: {result.error_message}")

    print()


def main():
    """运行所有测试"""
    print("\n小红书增强解析器功能测试")
    print("=" * 80)
    print()

    # 测试1: 用户资料
    test_author_profile()

    # 测试2: 笔记卡片（不获取详情）
    test_author_notes_cards_only()

    # 测试3: 笔记详情
    test_author_notes_with_detail()

    # 测试4: 解析器类
    test_parser_class()

    print("=" * 80)
    print("测试完成!")


if __name__ == "__main__":
    main()

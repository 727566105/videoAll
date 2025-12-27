#!/usr/bin/env python3
"""
测试小红书实况图片解析功能

依赖: 需要提供有效的 Cookie
"""
import sys
import json

def test_without_cookie():
    """测试不带 Cookie 的解析"""
    print("=" * 60)
    print("测试1: 不带 Cookie 解析 (可能失败实况图片)")
    print("=" * 60)

    from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser

    # 使用示例 URL（如果不是实况图片，需要替换为实况图片 URL）
    test_url = "https://www.xiaohongshu.com/explore/xxxxxxxx"

    parser = XiaohongshuParser()
    try:
        result = parser.parse(test_url)
        if result:
            print(f"✓ 解析成功!")
            print(f"  标题: {result.title}")
            print(f"  作者: {result.author}")
            print(f"  类型: {result.media_type}")
            print(f"  是否有实况: {result.has_live_photo}")
            print(f"  图片数: {len(result.download_urls.images)}")
            print(f"  实况数: {len(result.download_urls.live)}")
            if result.download_urls.live:
                print(f"  实况URL: {result.download_urls.live}")
        else:
            print("✗ 解析失败")
    except Exception as e:
        print(f"✗ 错误: {e}")

def test_with_cookie(cookie):
    """测试带 Cookie 的解析"""
    print("\n" + "=" * 60)
    print("测试2: 带 Cookie 解析 (应该成功)")
    print("=" * 60)

    from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser

    # 使用示例 URL（如果不是实况图片，需要替换为实况图片 URL）
    test_url = "https://www.xiaohongshu.com/explore/xxxxxxxx"

    parser = XiaohongshuParser(cookie=cookie)
    try:
        result = parser.parse(test_url)
        if result:
            print(f"✓ 解析成功!")
            print(f"  标题: {result.title}")
            print(f"  作者: {result.author}")
            print(f"  类型: {result.media_type}")
            print(f"  是否有实况: {result.has_live_photo}")
            print(f"  图片数: {len(result.download_urls.images)}")
            print(f"  实况数: {len(result.download_urls.live)}")
            if result.download_urls.live:
                print(f"  实况URL: {result.download_urls.live}")

            # 保存调试信息
            debug_info = {
                "url": test_url,
                "title": result.title,
                "author": result.author,
                "media_type": str(result.media_type),
                "has_live_photo": result.has_live_photo,
                "images": result.download_urls.images,
                "live_photos": result.download_urls.live,
                "raw_data": str(result.raw_data)[:500] + "..." if result.raw_data else None
            }

            with open("live_photo_debug.json", "w", encoding="utf-8") as f:
                json.dump(debug_info, f, ensure_ascii=False, indent=2)
            print(f"\n✓ 调试信息已保存到 live_photo_debug.json")
        else:
            print("✗ 解析失败")
    except Exception as e:
        print(f"✗ 错误: {e}")
        import traceback
        traceback.print_exc()

def main():
    if len(sys.argv) < 3:
        print("使用方法: python test_live_photo.py <小红书URL> [Cookie]")
        print("")
        print("示例:")
        print("  python test_live_photo.py 'https://www.xiaohongshu.com/explore/xxx'")
        print("  python test_live_photo.py 'https://www.xiaohongshu.com/explore/xxx' 'a1=xxx; a2=xxx'")
        sys.exit(1)

    url = sys.argv[1]
    cookie = sys.argv[2] if len(sys.argv) > 2 else None

    print(f"测试 URL: {url}")
    print(f"Cookie: {'已提供' if cookie else '未提供'}")

    from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser

    parser = XiaohongshuParser(cookie=cookie)
    try:
        result = parser.parse(url)
        if result:
            print("\n" + "✓" * 30)
            print("解析成功!")
            print("✓" * 30)
            print(f"  标题: {result.title}")
            print(f"  作者: {result.author}")
            print(f"  类型: {result.media_type}")
            print(f"  是否有实况: {result.has_live_photo}")
            print(f"  图片数: {len(result.download_urls.images)}")
            print(f"  实况数: {len(result.download_urls.live)}")

            if result.download_urls.live:
                print(f"\n  🎬 实况图片 URL:")
                for i, url in enumerate(result.download_urls.live, 1):
                    print(f"    {i}. {url}")

            if result.download_urls.images:
                print(f"\n  📷 普通图片 URL:")
                for i, url in enumerate(result.download_urls.images[:3], 1):
                    print(f"    {i}. {url}{'...' if len(result.download_urls.images) > 3 else ''}")

            # 保存完整结果
            output = {
                "success": True,
                "data": {
                    "note_id": result.note_id,
                    "title": result.title,
                    "author": result.author,
                    "content": result.description,
                    "media_type": str(result.media_type),
                    "has_live_photo": result.has_live_photo,
                    "images": result.download_urls.images,
                    "live_photos": result.download_urls.live,
                    "interaction_stats": {
                        "like_count": result.like_count,
                        "collect_count": result.collect_count,
                        "comment_count": result.comment_count
                    }
                }
            }

            with open("live_photo_result.json", "w", encoding="utf-8") as f:
                json.dump(output, f, ensure_ascii=False, indent=2)
            print(f"\n✓ 完整结果已保存到 live_photo_result.json")
        else:
            print("✗ 解析失败: 返回结果为空")
    except Exception as e:
        print(f"✗ 解析出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

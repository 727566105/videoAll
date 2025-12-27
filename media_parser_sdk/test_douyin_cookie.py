#!/usr/bin/env python3
"""
快速测试抖音解析器（带Cookie）
"""

import sys
import json

# 测试链接
test_url = "https://www.douyin.com/video/7587637524178554161"

print("=" * 70)
print("抖音解析器快速测试")
print("=" * 70)
print(f"\n测试链接: {test_url}")
print()

# 检查是否有Cookie参数
if len(sys.argv) > 1 and sys.argv[1] == "--cookie":
    if len(sys.argv) > 2:
        cookie = sys.argv[2]
        print(f"✓ 使用Cookie: {cookie[:50]}...")
    else:
        print("✗ 错误: --cookie 参数后需要提供Cookie值")
        print()
        print("用法: python3 test_douyin_cookie.py --cookie \"你的Cookie\"")
        sys.exit(1)
else:
    cookie = None
    print("⚠ 未提供Cookie，解析可能失败（遇到验证页面）")
    print()

print("-" * 70)

# 导入解析器
try:
    from media_parser_sdk.platforms.douyin_enhanced import DouyinEnhancedParser

    # 创建解析器
    parser = DouyinEnhancedParser(cookie=cookie)

    # 测试解析
    print("\n开始解析...")
    media_info = parser.parse(test_url)

    if media_info:
        print("\n" + "=" * 70)
        print("✅ 解析成功！")
        print("=" * 70)
        print(f"\n标题: {media_info.title}")
        print(f"作者: {media_info.author}")
        print(f"描述: {media_info.description or '无'}")
        print(f"\n统计数据:")
        print(f"  - 点赞: {media_info.like_count or 0}")
        print(f"  - 评论: {media_info.comment_count or 0}")
        print(f"  - 分享: {media_info.share_count or 0}")
        print(f"  - 播放: {media_info.view_count or 0}")
        print(f"\n媒体文件:")
        print(f"  - 视频数: {len(media_info.download_urls.video)}")
        print(f"  - 图片数: {len(media_info.download_urls.images)}")

        if media_info.download_urls.video:
            print(f"\n视频链接:")
            for idx, url in enumerate(media_info.download_urls.video[:3], 1):
                print(f"  {idx}. {url[:80]}...")

        if media_info.tags:
            print(f"\n标签: {', '.join(media_info.tags[:5])}")

        print("\n" + "=" * 70)
    else:
        print("\n" + "=" * 70)
        print("❌ 解析失败")
        print("=" * 70)
        print("\n可能原因:")
        print("1. 链接格式不正确")
        print("2. 视频已被删除或设为私密")
        print("3. 遇到反爬虫验证（需要Cookie）")
        print("4. Cookie已过期或无效")
        print("\n建议:")
        print("- 使用Cookie重试: python3 test_douyin_cookie.py --cookie \"你的Cookie\"")

except Exception as e:
    print("\n" + "=" * 70)
    print("❌ 解析出错")
    print("=" * 70)
    print(f"\n错误信息: {str(e)}")
    print(f"\n错误类型: {type(e).__name__}")
    print("\n建议:")
    print("- 检查是否安装了所有依赖")
    print("- 使用Cookie重试")
    print("- 查看完整错误信息（不加 --cookie 参数）")

print()

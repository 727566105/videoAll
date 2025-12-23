#!/usr/bin/env python3
import sys
import json
import asyncio
from media_parser_sdk import parse_url, download_media

# 导入增强功能
from media_parser_sdk.platforms.xiaohongshu_enhanced import (
    extract_xiaohongshu_note_sync,
    extract_xiaohongshu_author_sync,
    extract_xiaohongshu_author_notes_sync
)

# 便捷函数包装
def extract_xiaohongshu_note_sync_wrapper(url, cookie=None):
    """提取小红书笔记信息 - 包装函数"""
    return extract_xiaohongshu_note_sync(url)

def extract_xiaohongshu_author_sync_wrapper(url, cookie=None):
    """提取小红书博主资料 - 包装函数"""
    return extract_xiaohongshu_author_sync(url, cookie=cookie)

def extract_xiaohongshu_author_notes_sync_wrapper(url, max_notes=None, cookie=None):
    """提取小红书博主所有笔记 - 包装函数"""
    return extract_xiaohongshu_author_notes_sync(url, max_notes=max_notes, fetch_detail=True, cookie=cookie)


def show_cookie_help():
    """显示 Cookie 获取帮助"""
    help_text = """
╔══════════════════════════════════════════════════════════════════════════════╗
║                        小红书 Cookie 获取指南                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

为什么需要 Cookie？
  获取用户主页的完整笔记信息（高清图片、视频下载链接）需要提供 Cookie

如何获取 Cookie？
  1. 打开浏览器，访问 https://www.xiaohongshu.com
  2. 登录你的小红书账号
  3. 按 F12 打开开发者工具
  4. 切换到 Network（网络）标签
  5. 刷新页面，点击任意请求
  6. 在右侧 Request Headers 中找到 Cookie
  7. 复制整个 Cookie 字符串

使用方式：
  python wrapper.py xiaohongshu_author_notes <URL> [max_notes] --cookie "你的Cookie"

示例：
  python wrapper.py xiaohongshu_author_notes \\
    "https://www.xiaohongshu.com/user/profile/xxx" \\
    10 \\
    --cookie "a1=...; a2=...; ..."

注意事项：
  - Cookie 包含敏感信息，请妥善保管
  - Cookie 可能会过期，过期后需重新获取
  - 建议使用小号进行测试

╔══════════════════════════════════════════════════════════════════════════════╗
"""
    print(help_text, file=sys.stderr)


def main():
    """媒体解析SDK命令行包装器

    命令格式:
    python wrapper.py parse <url>
    python wrapper.py download <url> <output_dir>
    python wrapper.py xiaohongshu_note <url>
    python wrapper.py xiaohongshu_author <url> [--cookie "你的Cookie"]
    python wrapper.py xiaohongshu_author_notes <url> [max_notes] [--cookie "你的Cookie"]
    python wrapper.py --cookie-help
    """
    if len(sys.argv) < 2:
        print(json.dumps({"error": "缺少命令参数"}))
        sys.exit(1)

    command = sys.argv[1]

    # 显示 Cookie 帮助
    if command == "--cookie-help" or command == "-h":
        show_cookie_help()
        sys.exit(0)

    # 解析通用参数
    cookie = None
    if "--cookie" in sys.argv:
        idx = sys.argv.index("--cookie")
        if idx + 1 < len(sys.argv):
            cookie = sys.argv[idx + 1]
            # 从参数列表中移除 cookie 相关参数
            sys.argv.pop(idx + 1)
            sys.argv.pop(idx)

    if command == "parse":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "缺少URL参数"}))
            sys.exit(1)
        url = sys.argv[2]
        try:
            media_info = parse_url(url)
            result = {
                "platform": media_info.platform,
                "title": media_info.title,
                "author": media_info.author,
                "media_type": media_info.media_type,
                "note_id": media_info.note_id,
                "url": media_info.url,
                "download_urls": {
                    "images": media_info.download_urls.images or [],
                    "video": media_info.download_urls.video or [],
                    "live": media_info.download_urls.live or [],
                    "audio": media_info.download_urls.audio or []
                },
                "description": media_info.description or "",
                "tags": media_info.tags or [],
                "resource_count": media_info.resource_count,
                "cover_url": media_info.cover_url or "",
                "has_live_photo": media_info.has_live_photo,
                "like_count": media_info.like_count,
                "collect_count": media_info.collect_count,
                "comment_count": media_info.comment_count,
                "share_count": media_info.share_count,
                "view_count": media_info.view_count,
                "publish_time": media_info.publish_time.isoformat() if media_info.publish_time else None
            }
            print(json.dumps(result, ensure_ascii=False))
        except Exception as e:
            print(json.dumps({"error": str(e)}, ensure_ascii=False))

    elif command == "download":
        if len(sys.argv) < 4:
            print(json.dumps({"error": "缺少URL或输出目录参数"}))
            sys.exit(1)
        url = sys.argv[2]
        output_dir = sys.argv[3]
        try:
            success = asyncio.run(download_media(url, output_dir=output_dir))
            print(json.dumps({"success": success}))
        except Exception as e:
            print(json.dumps({"error": str(e)}, ensure_ascii=False))

    elif command == "xiaohongshu_note":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "缺少URL参数"}))
            sys.exit(1)
        url = sys.argv[2]
        try:
            result = extract_xiaohongshu_note_sync_wrapper(url, cookie)
            if result.success:
                print(json.dumps({
                    "success": True,
                    "result_type": result.result_type,
                    "data": result.data
                }, ensure_ascii=False, default=str))
            else:
                print(json.dumps({
                    "success": False,
                    "error": result.error_message
                }, ensure_ascii=False))
        except Exception as e:
            print(json.dumps({"error": str(e)}, ensure_ascii=False))

    elif command == "xiaohongshu_author":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "缺少URL参数"}))
            sys.exit(1)
        url = sys.argv[2]
        try:
            result = extract_xiaohongshu_author_sync_wrapper(url, cookie)
            if result.success:
                print(json.dumps({
                    "success": True,
                    "result_type": result.result_type,
                    "data": result.data
                }, ensure_ascii=False, default=str))
            else:
                print(json.dumps({
                    "success": False,
                    "error": result.error_message
                }, ensure_ascii=False))
        except Exception as e:
            print(json.dumps({"error": str(e)}, ensure_ascii=False))

    elif command == "xiaohongshu_author_notes":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "缺少URL参数"}))
            sys.exit(1)
        url = sys.argv[2]
        max_notes = None
        if len(sys.argv) >= 4:
            try:
                max_notes = int(sys.argv[3])
            except ValueError:
                # 如果第3个参数不是数字，可能是 --cookie 选项
                if not sys.argv[3].startswith("--"):
                    print(json.dumps({"error": "max_notes参数必须是整数"}))
                    sys.exit(1)

        try:
            result = extract_xiaohongshu_author_notes_sync_wrapper(url, max_notes, cookie)
            if result.success:
                print(json.dumps({
                    "success": True,
                    "result_type": result.result_type,
                    "data": result.data
                }, ensure_ascii=False, default=str))
            else:
                print(json.dumps({
                    "success": False,
                    "error": result.error_message
                }, ensure_ascii=False))
        except Exception as e:
            print(json.dumps({"error": str(e)}, ensure_ascii=False))

    else:
        print(json.dumps({"error": f"未知命令: {command}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()

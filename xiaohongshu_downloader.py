#!/usr/bin/env python3
"""
小红书博主笔记自动下载器

功能：
- 自动获取博主所有笔记（图片、视频）
- 按博主名称创建文件夹
- 保存完整的笔记元数据
- 支持Cookie认证

使用方法：
    python xiaohongshu_downloader.py <博主主页URL>

配置文件：
    - config.json: 包含 Cookie 和下载配置
"""
import os
import sys
import json
import time
import argparse
import requests
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

# 添加 SDK 路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'media_parser_sdk'))

from media_parser_sdk.platforms.xiaohongshu_enhanced import XiaohongshuEnhancedParser


class XiaohongshuDownloader:
    """小红书博主笔记下载器"""

    def __init__(self, cookie: str = None, output_dir: str = "downloads", delay: float = 0.5):
        """
        初始化下载器

        Args:
            cookie: 小红书 Cookie
            output_dir: 下载目录
            delay: 请求延迟（秒）
        """
        self.cookie = cookie
        self.output_dir = Path(output_dir)
        self.delay = delay

        # 初始化解析器
        self.parser = XiaohongshuEnhancedParser(cookie=cookie) if cookie else XiaohongshuEnhancedParser()

        # 下载统计
        self.stats = {
            "start_time": datetime.now().isoformat(),
            "total_notes": 0,
            "successful": 0,
            "failed": 0,
            "total_images": 0,
            "total_videos": 0,
            "total_covers": 0,
            "notes": []
        }

        # HTTP 请求头
        self.download_headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            "Referer": "https://www.xiaohongshu.com/"
        }

    def sanitize_filename(self, name: str) -> str:
        """清理文件名中的非法字符"""
        invalid_chars = '<>:"/\\|?*'
        for char in invalid_chars:
            name = name.replace(char, '_')
        return name.strip()

    def download_file(self, url: str, filepath: str) -> Tuple[bool, Optional[str]]:
        """
        下载文件

        Args:
            url: 下载链接
            filepath: 保存路径

        Returns:
            (是否成功, 错误信息)
        """
        try:
            response = requests.get(url, headers=self.download_headers, timeout=30)
            response.raise_for_status()

            # 确保目录存在
            os.makedirs(os.path.dirname(filepath), exist_ok=True)

            with open(filepath, 'wb') as f:
                f.write(response.content)

            return True, None
        except Exception as e:
            return False, str(e)

    def download_author_notes(self, author_url: str, max_notes: Optional[int] = None) -> Dict:
        """
        下载博主所有笔记

        Args:
            author_url: 博主主页URL
            max_notes: 最大下载笔记数，None表示全部

        Returns:
            下载结果统计
        """
        print("="*60)
        print("小红书博主笔记下载器")
        print("="*60)
        print(f"博主链接: {author_url}")
        print(f"Cookie: {'✓ 已提供' if self.cookie else '✗ 未提供'}")
        print(f"最大笔记数: {max_notes if max_notes else '全部'}")
        print(f"下载目录: {self.output_dir}")
        print("="*60)

        # 获取博主信息和笔记列表
        print("\n[1/3] 获取博主信息...")
        result = self.parser.parse_author_notes_sync(
            author_url,
            max_notes=max_notes,
            fetch_detail=True
        )

        if not result.success:
            print(f"❌ 获取失败: {result.error_message}")
            return self.stats

        data = result.data
        author = data.get('author_profile', {})
        notes = data.get('notes', [])

        author_name = author.get('nickname', '未知作者')
        author_id = author.get('user_id', 'unknown')

        print(f"✓ 博主: {author_name}")
        print(f"✓ 笔记总数: {len(notes)}")

        # 创建博主文件夹
        author_dir = self.output_dir / self.sanitize_filename(author_name)
        author_dir.mkdir(parents=True, exist_ok=True)

        # 保存完整的笔记数据
        notes_json_path = author_dir / "notes_data.json"
        with open(notes_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✓ 已保存: {notes_json_path.name}")

        # 下载媒体文件
        print(f"\n[2/3] 下载媒体文件...")
        self.stats["total_notes"] = len(notes)

        for idx, note in enumerate(notes, 1):
            note_id = note.get('note_id', f'unknown_{idx}')
            title = note.get('title', f'笔记_{idx}')

            print(f"\n[{idx}/{len(notes)}] {title}")
            print(f"  note_id: {note_id}")

            # 创建笔记文件夹
            note_folder_name = f"{idx:02d}_{self.sanitize_filename(title[:30])}"
            note_dir = author_dir / note_folder_name
            note_dir.mkdir(exist_ok=True)

            # 保存笔记元数据
            metadata_path = note_dir / "metadata.json"
            with open(metadata_path, 'w', encoding='utf-8') as f:
                json.dump(note, f, ensure_ascii=False, indent=2)

            note_stats = {
                "note_id": note_id,
                "title": title,
                "folder": str(note_dir),
                "images": [],
                "videos": [],
                "cover": None
            }

            # 下载封面
            cover_image = note.get('cover_image', {})
            if cover_image and cover_image.get('url'):
                cover_url = cover_image['url']
                # 转换为 HTTPS
                if cover_url.startswith('http://'):
                    cover_url = cover_url.replace('http://', 'https://', 1)

                cover_path = note_dir / "cover.jpg"
                success, error = self.download_file(cover_url, str(cover_path))
                if success:
                    print(f"  ✓ 封面已保存")
                    note_stats["cover"] = str(cover_path)
                    self.stats["total_covers"] += 1
                else:
                    print(f"  ✗ 封面下载失败: {error}")

            # 下载图片
            images = note.get('images', [])
            if images:
                print(f"  图片: {len(images)} 张")
                for img_idx, img in enumerate(images, 1):
                    img_url = img.get('url')
                    if not img_url:
                        continue

                    # 获取文件扩展名
                    ext = '.jpg'
                    if '.png' in img_url:
                        ext = '.png'
                    elif '.webp' in img_url:
                        ext = '.webp'

                    img_path = note_dir / f"image_{img_idx}{ext}"
                    success, error = self.download_file(img_url, str(img_path))
                    if success:
                        note_stats["images"].append(str(img_path))
                        self.stats["total_images"] += 1

                    # 进度显示
                    if len(images) <= 5:
                        print(f"    [{img_idx}/{len(images)}] ✓" if success else f"    [{img_idx}/{len(images)}] ✗")
                    elif img_idx % 5 == 0 or img_idx == len(images):
                        print(f"    [{img_idx}/{len(images)}] ✓" if success else f"    [{img_idx}/{len(images)}] ✗")
            else:
                print(f"  图片: 0 张")

            # 下载视频
            videos = note.get('videos', [])
            if videos:
                print(f"  视频: {len(videos)} 个")
                for vid_idx, vid in enumerate(videos, 1):
                    vid_url = vid.get('url')
                    if not vid_url:
                        continue

                    vid_path = note_dir / f"video_{vid_idx}.mp4"
                    success, error = self.download_file(vid_url, str(vid_path))
                    if success:
                        note_stats["videos"].append(str(vid_path))
                        self.stats["total_videos"] += 1
                        print(f"    [{vid_idx}/{len(videos)}] ✓" if success else f"    [{vid_idx}/{len(videos)}] ✗")
            else:
                print(f"  视频: 0 个")

            # 判断是否成功
            if len(images) > 0 or len(videos) > 0:
                self.stats["successful"] += 1
            else:
                self.stats["failed"] += 1

            self.stats["notes"].append(note_stats)

            # 延迟避免请求过快
            if idx < len(notes):
                time.sleep(self.delay)

        # 保存下载报告
        print(f"\n[3/3] 生成报告...")
        self.stats["end_time"] = datetime.now().isoformat()

        report_path = author_dir / "download_report.json"
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(self.stats, f, ensure_ascii=False, indent=2)

        # 打印总结
        print("\n" + "="*60)
        print("下载完成！")
        print("="*60)
        print(f"保存位置: {author_dir}")
        print(f"笔记总数: {self.stats['total_notes']}")
        print(f"成功下载: {self.stats['successful']}")
        print(f"无内容/失败: {self.stats['failed']}")
        print(f"封面图片: {self.stats['total_covers']}")
        print(f"高清图片: {self.stats['total_images']}")
        print(f"视频文件: {self.stats['total_videos']}")
        print(f"\n报告文件: {report_path.name}")
        print("="*60)

        return self.stats


def load_config(config_file: str = "config.json") -> Dict:
    """加载配置文件"""
    config_path = Path(config_file)

    if config_path.exists():
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    else:
        # 创建默认配置
        default_config = {
            "cookie": "",
            "output_dir": "downloads",
            "delay": 0.5,
            "max_notes": None
        }
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, ensure_ascii=False, indent=2)
        print(f"✓ 已创建配置文件: {config_file}")
        print(f"  请编辑配置文件，填入你的 Cookie")
        return default_config


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='小红书博主笔记自动下载器',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例：

1. 下载指定博主的所有笔记：
   python xiaohongshu_downloader.py https://www.xiaohongshu.com/user/profile/xxx

2. 使用配置文件：
   python xiaohongshu_downloader.py --config

3. 指定 Cookie：
   python xiaohongshu_downloader.py <URL> --cookie "your_cookie_here"

4. 限制下载数量：
   python xiaohongshu_downloader.py <URL> --max-notes 10

5. 指定输出目录：
   python xiaohongshu_downloader.py <URL> --output ./my_downloads

获取 Cookie 方法：
1. 打开浏览器访问 https://www.xiaohongshu.com
2. 登录账号
3. 按 F12 打开开发者工具
4. 切换到 Network 标签
5. 刷新页面，点击任意请求
6. 在右侧 Request Headers 中找到 Cookie
7. 复制整个 Cookie 字符串
        """
    )

    parser.add_argument('url', nargs='?', help='博主主页URL')
    parser.add_argument('--cookie', '-c', help='小红书 Cookie')
    parser.add_argument('--output', '-o', default='downloads', help='输出目录（默认：downloads）')
    parser.add_argument('--max-notes', '-n', type=int, help='最大下载笔记数')
    parser.add_argument('--delay', '-d', type=float, default=0.5, help='请求延迟（秒，默认：0.5）')
    parser.add_argument('--config', action='store_true', help='使用配置文件')

    args = parser.parse_args()

    # 加载配置
    if args.config:
        config = load_config()
        cookie = config.get('cookie') or args.cookie
        output_dir = config.get('output_dir', args.output)
        delay = config.get('delay', args.delay)
        max_notes = config.get('max_notes')

        # 从配置或命令行获取 URL
        url = config.get('url') or args.url
        if not url:
            print("❌ 错误：请在配置文件中设置 url 或通过命令行参数传入")
            print("   配置文件：config.json")
            print("   示例：python xiaohongshu_downloader.py <URL> --config")
            return
    else:
        cookie = args.cookie
        output_dir = args.output
        delay = args.delay
        max_notes = args.max_notes
        url = args.url

    # 检查 URL
    if not url:
        parser.print_help()
        print("\n❌ 错误：请提供博主主页URL")
        print("   示例：python xiaohongshu_downloader.py https://www.xiaohongshu.com/user/profile/xxx")
        return

    # 检查 Cookie
    if not cookie:
        print("⚠️  警告：未提供 Cookie")
        print("   无 Cookie 时只能获取笔记卡片信息（标题、封面、点赞数）")
        print("   有 Cookie 时可以获取完整的高清图片和视频下载链接")
        print("\n💡 提示：使用 --cookie 参数或编辑 config.json 文件提供 Cookie")
        print("")
        response = input("是否继续？(y/N): ")
        if response.lower() != 'y':
            print("已取消")
            return

    # 创建下载器并执行下载
    downloader = XiaohongshuDownloader(
        cookie=cookie,
        output_dir=output_dir,
        delay=delay
    )

    try:
        downloader.download_author_notes(url, max_notes=max_notes)
    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断下载")
    except Exception as e:
        print(f"\n\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()

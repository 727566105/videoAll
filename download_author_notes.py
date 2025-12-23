#!/usr/bin/env python3
"""
下载小红书博主的所有笔记（包括图片和视频）
"""
import os
import json
import time
import requests
from pathlib import Path
from media_parser_sdk.platforms.xiaohongshu_enhanced import XiaohongshuEnhancedParser

# 清理文件名中的非法字符
def sanitize_filename(name):
    """清理文件名中的非法字符"""
    invalid_chars = '<>:"/\\|?*'
    for char in invalid_chars:
        name = name.replace(char, '_')
    return name.strip()

# 下载文件
def download_file(url, filepath, headers=None):
    """下载文件到指定路径"""
    try:
        if headers is None:
            headers = {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                "Referer": "https://www.xiaohongshu.com/"
            }

        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()

        # 确保目录存在
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        with open(filepath, 'wb') as f:
            f.write(response.content)

        return True, None
    except Exception as e:
        return False, str(e)

def main():
    # 读取配置
    with open('up.md', 'r') as f:
        author_url = f.read().strip()

    with open('xhs.md', 'r') as f:
        cookie = f.read().strip()

    print(f"博主链接: {author_url}")
    print(f"Cookie: {'已提供' if cookie else '未提供'}")

    # 初始化解析器
    parser = XiaohongshuEnhancedParser(cookie=cookie)

    # 获取博主信息和笔记列表
    print("\n开始获取博主信息...")
    result = parser.parse_author_notes_sync(author_url, max_notes=50, fetch_detail=True)

    if not result.success:
        print(f"获取失败: {result.error_message}")
        return

    data = result.data
    author = data.get('author_profile', {})
    notes = data.get('notes', [])

    author_name = author.get('nickname', '未知作者')
    print(f"\n博主: {author_name}")
    print(f"笔记总数: {len(notes)}")

    # 创建下载目录
    base_dir = Path("downloads") / sanitize_filename(author_name)
    base_dir.mkdir(parents=True, exist_ok=True)

    # 保存完整的笔记数据
    notes_json_path = base_dir / "notes_data.json"
    with open(notes_json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\n保存笔记数据: {notes_json_path}")

    # 下载统计
    download_stats = {
        "total_notes": len(notes),
        "successful": 0,
        "failed": 0,
        "total_images": 0,
        "total_videos": 0,
        "notes": []
    }

    # 下载每个笔记的媒体文件
    for idx, note in enumerate(notes, 1):
        note_id = note.get('note_id', f'unknown_{idx}')
        title = note.get('title', f'笔记_{idx}')
        note_type = note.get('type', 'unknown')

        print(f"\n[{idx}/{len(notes)}] 处理: {title}")
        print(f"  note_id: {note_id}")
        print(f"  类型: {note_type}")

        # 创建笔记文件夹
        note_folder_name = f"{idx:02d}_{sanitize_filename(title[:30])}"
        note_dir = base_dir / note_folder_name
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
            "videos": []
        }

        # 下载封面
        cover_image = note.get('cover_image', {})
        if cover_image and cover_image.get('url'):
            cover_url = cover_image['url']
            cover_path = note_dir / "cover.jpg"
            print(f"  下载封面...")
            success, error = download_file(cover_url, str(cover_path))
            if success:
                print(f"    ✓ 封面已保存")
                note_stats["cover"] = str(cover_path)
            else:
                print(f"    ✗ 封面下载失败: {error}")

        # 下载图片
        images = note.get('images', [])
        print(f"  图片数: {len(images)}")
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
            print(f"    下载图片 {img_idx}/{len(images)}...")
            success, error = download_file(img_url, str(img_path))
            if success:
                print(f"      ✓ 已保存: {img_path.name}")
                note_stats["images"].append(str(img_path))
                download_stats["total_images"] += 1
            else:
                print(f"      ✗ 下载失败: {error}")

        # 下载视频
        videos = note.get('videos', [])
        print(f"  视频数: {len(videos)}")
        for vid_idx, vid in enumerate(videos, 1):
            vid_url = vid.get('url')
            if not vid_url:
                continue

            vid_path = note_dir / f"video_{vid_idx}.mp4"
            print(f"    下载视频 {vid_idx}/{len(videos)}...")
            success, error = download_file(vid_url, str(vid_path))
            if success:
                print(f"      ✓ 已保存: {vid_path.name}")
                note_stats["videos"].append(str(vid_path))
                download_stats["total_videos"] += 1
            else:
                print(f"      ✗ 下载失败: {error}")

        # 如果笔记没有详细内容，标记为失败
        if len(images) == 0 and len(videos) == 0:
            print(f"  ⚠️  笔记无媒体内容（可能已删除或私密）")
            download_stats["failed"] += 1
        else:
            download_stats["successful"] += 1

        download_stats["notes"].append(note_stats)

        # 延迟避免请求过快
        time.sleep(0.5)

    # 保存下载报告
    report_path = base_dir / "download_report.json"
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(download_stats, f, ensure_ascii=False, indent=2)

    # 打印总结
    print("\n" + "="*60)
    print("下载完成!")
    print("="*60)
    print(f"保存位置: {base_dir}")
    print(f"笔记总数: {download_stats['total_notes']}")
    print(f"成功: {download_stats['successful']}")
    print(f"失败/无内容: {download_stats['failed']}")
    print(f"图片总数: {download_stats['total_images']}")
    print(f"视频总数: {download_stats['total_videos']}")
    print(f"\n报告文件: {report_path}")

if __name__ == "__main__":
    main()

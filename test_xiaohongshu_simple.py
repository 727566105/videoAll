#!/usr/bin/env python3

import sys
import os
# 添加正确的SDK路径
sys.path.insert(0, '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/media_parser_sdk')

# 导入必要的模块
from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser
from media_parser_sdk.models.media_info import DownloadUrls, MediaType

def test_xiaohongshu_video_classification():
    """"测试小红书视频URL是否被正确分类为视频类型"""
    print("🧪 Testing Xiaohongshu video classification fix...")
    
    # 创建解析器实例
    parser = XiaohongshuParser()
    
    # 场景1: 同时存在视频和图片URL (小红书视频帖子的典型情况)
    download_urls = DownloadUrls(
        video=["https://example.com/video.mp4"],  # 视频URL
        images=["https://example.com/cover.jpg"]  # 封面图片URL
    )
    
    # 调用修复后的媒体类型判断方法
    media_type = parser._determine_media_type({}, download_urls)
    print(f"✅ Media type with video + image URLs: {media_type}")
    
    # 场景2: 只有图片URL，没有视频URL
    download_urls_images_only = DownloadUrls(
        video=[],  # 没有视频
        images=["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
    )
    
    media_type_images = parser._determine_media_type({}, download_urls_images_only)
    print(f"✅ Media type with only images: {media_type_images}")
    
    # 验证修复是否成功
    if media_type == MediaType.VIDEO and media_type_images == MediaType.IMAGE:
        print("🎉 修复成功! 小红书视频被正确识别为视频类型，图片仍然识别为图片类型")
        return True
    else:
        print("❌ 修复失败! 视频被识别为: {media_type}, 图片被识别为: {media_type_images}")
        return False

if __name__ == "__main__":
    success = test_xiaohongshu_video_classification()
    sys.exit(0 if success else 1)
#!/usr/bin/env python3
"""
测试小红书视频URL媒体类型判断修复
"""

import sys
import os

# 确保可以导入 SDK
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from media_parser_sdk import MediaParser
from media_parser_sdk.models.media_info import MediaType

def test_xiaohongshu_video_classification():
    """测试小红书视频URL是否被正确分类为视频类型"""
    print("🧪 测试小红书视频URL分类...")
    
    # 创建解析器实例
    parser = MediaParser()
    
    # 测试一个模拟的小红书视频URL
    test_url = "https://www.xiaohongshu.com/explore/123456789"
    
    try:
        # 模拟媒体数据，模拟同时有视频和图片URL的情况
        from media_parser_sdk.models.media_info import DownloadUrls, Platform
        
        # 创建包含视频和图片的下载链接对象
        download_urls = DownloadUrls(
            video=["https://example.com/video.mp4"],  # 视频URL
            images=["https://example.com/cover.jpg"]  # 同时存在封面图片URL
        )
        
        # 模拟小红书解析器的媒体类型判断
        from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser
        
        xhs_parser = XiaohongshuParser()
        
        # 调用媒体类型判断方法，模拟有视频和图片的情况
        media_type = xhs_parser._determine_media_type({}, download_urls)
        
        print(f"✅ 媒体类型判断结果: {media_type}")
        
        # 验证结果
        if media_type == MediaType.VIDEO:
            print("✅ PASS: 小红书视频被正确识别为视频类型！")
            return True
        else:
            print(f"❌ FAIL: 小红书视频被错误识别为: {media_type}")
            return False
            
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_xiaohongshu_image_classification():
    """测试小红书图片URL是否仍被正确分类为图片类型"""
    print("\n🧪 测试小红书图片URL分类...")
    
    from media_parser_sdk.models.media_info import DownloadUrls
    from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser
    from media_parser_sdk.models.media_info import MediaType
    
    xhs_parser = XiaohongshuParser()
    
    # 只包含图片URL，没有视频URL
    download_urls = DownloadUrls(
        video=[],  # 没有视频
        images=["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
    )
    
    media_type = xhs_parser._determine_media_type({}, download_urls)
    print(f"✅ 媒体类型判断结果: {media_type}")
    
    if media_type == MediaType.IMAGE:
        print("✅ PASS: 小红书图片被正确识别为图片类型！")
        return True
    else:
        print(f"❌ FAIL: 小红书图片被错误识别为: {media_type}")
        return False

def main():
    """主测试函数"""
    print("🚀 开始测试小红书媒体类型判断修复...\n")
    
    # 运行测试
    test_results = [
        test_xiaohongshu_video_classification(),
        test_xiaohongshu_image_classification()
    ]
    
    print("\n📊 测试结果汇总:")
    print(f"✅ 通过: {test_results.count(True)}")
    print(f"❌ 失败: {test_results.count(False)}")
    
    if all(test_results):
        print("\n🎉 所有测试通过！小红书视频URL修复成功！")
        sys.exit(0)
    else:
        print("\n❌ 测试失败，请检查修复代码！")
        sys.exit(1)

if __name__ == "__main__":
    main()

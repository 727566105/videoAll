#!/usr/bin/env python3
"""
抖音平台增强解析器 - 集成 X-Bogus 签名
"""

import re
import json
import random
import time
from typing import Optional, List, Dict, Any
from datetime import datetime
import httpx

from ..core.base_parser import BaseParser
from ..models.media_info import MediaInfo, MediaType, Platform, DownloadUrls
from ..exceptions import ParseError, NetworkError
from ..utils.xbogus import XBogus


class DouyinEnhancedParser(BaseParser):
    """抖音平台增强解析器

    特性：
    - 集成 X-Bogus 签名算法
    - 支持 Cookie 认证
    - 完整元数据提取（点赞、评论、分享、播放量）
    - 视频和图集下载链接提取
    """

    # 抖音API端点
    API_ENDPOINTS = {
        "aweme_detail": "https://www.douyin.com/aweme/v1/web/aweme/detail/",
        "aweme_post": "https://www.douyin.com/aweme/v1/web/aweme/post/",
    }

    def __init__(self, logger=None, cookie: str = None):
        """
        初始化抖音增强解析器

        Args:
            logger: 日志记录器
            cookie: 抖音Cookie（可选，提高解析成功率）
        """
        super().__init__(logger)
        self.cookie = cookie
        self.has_cookie = bool(cookie)

        # 初始化X-Bogus签名生成器
        self.xbogus_generator = XBogus()

        # 请求头配置
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Referer": "https://www.douyin.com/",
        }

        # 添加Cookie
        if self.cookie:
            self.headers["Cookie"] = self.cookie
            self.log_info("✓ Cookie已配置")
        else:
            self.log_warning("✗ 未提供Cookie，部分功能受限")

    def is_supported_url(self, url: str) -> bool:
        """检查是否支持该URL"""
        return any(domain in url.lower() for domain in [
            "douyin.com",
            "tiktok.com",
            "iesdouyin.com"
        ])

    def parse(self, url: str) -> Optional[MediaInfo]:
        """
        解析抖音链接

        Args:
            url: 抖音视频/图集链接

        Returns:
            MediaInfo: 媒体信息对象

        Raises:
            ParseError: 解析失败
        """
        try:
            self.validate_url(url)
            self.log_info(f"开始解析抖音链接: {url}")

            # 提取视频ID
            aweme_id = self._extract_aweme_id(url)
            if not aweme_id:
                raise ParseError(f"无法从链接中提取视频ID: {url}")

            self.log_info(f"✓ 提取到视频ID: {aweme_id}")

            # 构建API URL并生成X-Bogus签名
            api_url = self._build_api_url(aweme_id)
            self.log_debug(f"API URL: {api_url}")

            # 获取视频数据
            video_data = self._fetch_video_data(api_url)

            # 提取媒体信息
            media_data = self._extract_media_info(video_data, url)

            # 构建MediaInfo对象
            media_info = MediaInfo(
                platform=Platform.DOUYIN,
                title=media_data.get("title", "抖音视频"),
                author=media_data.get("author", "未知作者"),
                media_type=media_data.get("media_type", MediaType.VIDEO),
                note_id=aweme_id,
                url=url,
                download_urls=media_data.get("download_urls", DownloadUrls()),
                description=media_data.get("description"),
                tags=media_data.get("tags", []),
                cover_url=media_data.get("cover_url"),
                # 统计信息
                like_count=media_data.get("like_count"),
                comment_count=media_data.get("comment_count"),
                share_count=media_data.get("share_count"),
                view_count=media_data.get("view_count"),
                # 原始数据
                raw_data=video_data,
            )

            self.log_info(f"✓ 解析成功: {media_info.title}")
            return media_info

        except (ParseError, NetworkError) as e:
            raise e
        except Exception as e:
            raise ParseError(f"抖音链接解析失败: {str(e)}", url=url, platform="douyin")

    def _extract_aweme_id(self, url: str) -> Optional[str]:
        """
        从URL中提取视频ID

        Args:
            url: 抖音链接

        Returns:
            str: 视频ID
        """
        # 从/video/路径中提取
        video_match = re.search(r'/video/(\d+)', url)
        if video_match:
            return video_match.group(1)

        # 从modal_id参数中提取
        modal_match = re.search(r'modal_id=(\d+)', url)
        if modal_match:
            return modal_match.group(1)

        # 从share_id参数中提取
        share_match = re.search(r'share_id=(\d+)', url)
        if share_match:
            return share_match.group(1)

        return None

    def _build_api_url(self, aweme_id: str) -> str:
        """
        构建API URL并添加X-Bogus签名

        Args:
            aweme_id: 视频ID

        Returns:
            str: 完整的API URL（包含签名）
        """
        # 基础参数
        params = {
            "aweme_id": aweme_id,
            "aid": "6383",
            "device_platform": "webapp",
            "version_code": "170400",
            "version_name": "17.4.0",
        }

        # 构建URL路径
        url_path = f"{self.API_ENDPOINTS['aweme_detail']}?{self._dict_to_url_params(params)}"

        # 生成X-Bogus签名
        try:
            _, x_bogus, _ = self.xbogus_generator.getXBogus(url_path)
            full_url = f"{url_path}&X-Bogus={x_bogus}"
            return full_url
        except Exception as e:
            self.log_warning(f"X-Bogus签名生成失败: {str(e)}，使用未签名URL")
            return url_path

    def _dict_to_url_params(self, params: Dict[str, Any]) -> str:
        """将字典转换为URL参数字符串"""
        return "&".join([f"{k}={v}" for k, v in params.items()])

    def _fetch_video_data(self, api_url: str) -> Dict[str, Any]:
        """
        获取视频数据

        Args:
            api_url: API URL

        Returns:
            dict: 视频数据

        Raises:
            NetworkError: 网络请求失败
        """
        try:
            with httpx.Client(headers=self.headers, timeout=15, follow_redirects=True) as client:
                response = client.get(api_url)
                response.raise_for_status()

                # 检查响应
                if response.status_code != 200:
                    raise NetworkError(f"API请求失败: {response.status_code}")

                # 尝试解析JSON
                try:
                    data = response.json()
                except json.JSONDecodeError:
                    # 如果不是JSON，可能是HTML页面
                    if len(response.text) < 10000 or "验证" in response.text:
                        raise NetworkError("检测到反爬虫验证页面")
                    raise NetworkError("响应不是有效的JSON格式")

                # 检查业务状态码
                if data.get("status_code") != 0:
                    error_msg = data.get("status_msg", "未知错误")
                    raise NetworkError(f"API返回错误: {error_msg}")

                return data

        except httpx.HTTPError as e:
            raise NetworkError(f"网络请求失败: {str(e)}")

    def _extract_media_info(self, video_data: Dict[str, Any], url: str) -> Dict[str, Any]:
        """
        从API响应中提取媒体信息

        Args:
            video_data: API响应数据
            url: 原始URL

        Returns:
            dict: 提取的媒体信息
        """
        media_info = {
            "title": "抖音视频",
            "author": "未知作者",
            "description": "",
            "media_type": MediaType.VIDEO,
            "cover_url": "",
            "tags": [],
            "like_count": 0,
            "comment_count": 0,
            "share_count": 0,
            "view_count": 0,
            "download_urls": DownloadUrls(),
        }

        try:
            # 提取aweme_detail
            aweme_detail = video_data.get("aweme_detail", {})
            if not aweme_detail:
                self.log_warning("未找到aweme_detail数据")
                return media_info

            # 提取标题和描述
            desc = aweme_detail.get("desc", "")
            if desc:
                media_info["title"] = desc[:100]  # 限制标题长度
                media_info["description"] = desc

            # 提取作者信息
            author_info = aweme_detail.get("author", {})
            if author_info:
                media_info["author"] = author_info.get("nickname", "未知作者")

            # 提取统计数据
            statistics = aweme_detail.get("statistics", {})
            if statistics:
                media_info["like_count"] = statistics.get("digg_count", 0)
                media_info["comment_count"] = statistics.get("comment_count", 0)
                media_info["share_count"] = statistics.get("share_count", 0)
                media_info["view_count"] = statistics.get("play_count", 0)

            # 提取标签
            text_extra = aweme_detail.get("text_extra", [])
            if text_extra:
                media_info["tags"] = [
                    item.get("hashtag_name", "")
                    for item in text_extra
                    if item.get("hashtag_name")
                ]

            # 提取封面
            video_cover = aweme_detail.get("video", {}).get("cover", {})
            if video_cover:
                url_list = video_cover.get("url_list", [])
                if url_list:
                    media_info["cover_url"] = url_list[0]

            # 提取下载链接
            download_urls = self._extract_download_urls(aweme_detail)
            media_info["download_urls"] = download_urls

            # 判断媒体类型
            if download_urls.images:
                media_info["media_type"] = MediaType.IMAGE
            elif download_urls.video:
                media_info["media_type"] = MediaType.VIDEO

            self.log_info(f"✓ 提取媒体信息成功: {media_info['title']}")

        except Exception as e:
            self.log_error(f"提取媒体信息失败: {str(e)}")

        return media_info

    def _extract_download_urls(self, aweme_detail: Dict[str, Any]) -> DownloadUrls:
        """
        提取下载链接

        Args:
            aweme_detail: aweme详情数据

        Returns:
            DownloadUrls: 下载链接对象
        """
        download_urls = DownloadUrls()

        try:
            # 提取视频下载链接
            video_data = aweme_detail.get("video", {})
            if video_data:
                # play_addr - 播放地址（有水印）
                play_addr = video_data.get("play_addr", {}).get("url_list", [])
                # download_addr - 下载地址（无水印）
                download_addr = video_data.get("download_addr", {}).get("url_list", [])

                # 优先使用download_addr（无水印）
                if download_addr:
                    download_urls.video = self._clean_video_urls(download_addr)
                    self.log_info(f"✓ 提取到 {len(download_urls.video)} 个无水印视频链接")
                elif play_addr:
                    download_urls.video = self._clean_video_urls(play_addr)
                    self.log_info(f"✓ 提取到 {len(download_urls.video)} 个视频链接（可能有水印）")

            # 提取图集图片链接
            images = aweme_detail.get("images", [])
            if images:
                image_urls = []
                for image in images:
                    url_list = image.get("url_list", [])
                    if url_list:
                        # 选择最高质量的图片
                        image_urls.append(url_list[0])

                download_urls.images = image_urls
                self.log_info(f"✓ 提取到 {len(download_urls.images)} 张图片")

        except Exception as e:
            self.log_error(f"提取下载链接失败: {str(e)}")

        return download_urls

    def _clean_video_urls(self, url_list: List[str]) -> List[str]:
        """
        清理视频URL，去除水印参数

        Args:
            url_list: 原始URL列表

        Returns:
            list: 清理后的URL列表
        """
        cleaned_urls = []
        seen = set()  # 去重

        for url in url_list:
            if not url:
                continue

            # 去除水印相关参数
            clean_url = url.replace("playwm", "play")  # 去除水印标记

            # 去重
            if clean_url not in seen:
                seen.add(clean_url)
                cleaned_urls.append(clean_url)

        return cleaned_urls


if __name__ == "__main__":
    # 测试代码
    import logging

    logging.basicConfig(level=logging.INFO)

    # 测试URL
    test_url = "https://www.douyin.com/video/7300000000000000000"

    parser = DouyinEnhancedParser()
    media_info = parser.parse(test_url)

    if media_info:
        print(f"标题: {media_info.title}")
        print(f"作者: {media_info.author}")
        print(f"点赞: {media_info.like_count}")
        print(f"评论: {media_info.comment_count}")
        print(f"视频数量: {len(media_info.download_urls.video)}")
        print(f"图片数量: {len(media_info.download_urls.images)}")

#!/usr/bin/env python3
"""
哔哩哔哩平台增强解析器 - 集成 WBI 签名
"""

import re
import json
import time
from typing import Optional, List, Dict, Any
from datetime import datetime
from urllib.parse import urlencode, urlparse
import httpx

from ..core.base_parser import BaseParser
from ..models.media_info import MediaInfo, MediaType, Platform, DownloadUrls
from ..exceptions import ParseError, NetworkError


class BilibiliEnhancedParser(BaseParser):
    """哔哩哔哩平台增强解析器

    特性：
    - 集成 WBI 签名算法
    - 支持 Cookie 认证
    - 完整元数据提取（标题、UP主、播放量、弹幕数、投币数等）
    - 多清晰度视频下载链接（1080P+/1080P/720P/480P/360P）
    - 支持多种URL格式（bvid、av号、b23.tv短链接）
    """

    # B站API端点
    API_ENDPOINTS = {
        "video_info": "https://api.bilibili.com/x/web-interface/view",
        "video_streams": "https://api.bilibili.com/x/player/wbi/playurl",
        "video_parts": "https://api.bilibili.com/x/player/pagelist",
    }

    # 清晰度参数映射
    QUALITY_MAP = {
        "1080P+": 116,  # 超清
        "1080P": 112,   # 高清
        "720P": 80,     # 清晰
        "480P": 64,     # 标清
        "360P": 32,     # 流畅
    }

    # 清晰度名称映射
    QUALITY_NAMES = {
        116: "1080P+",
        112: "1080P",
        80: "720P",
        64: "480P",
        32: "360P",
    }

    def __init__(self, logger=None, cookie: str = None):
        """
        初始化哔哩哔哩增强解析器

        Args:
            logger: 日志记录器
            cookie: 哔哩哔哩Cookie（可选，提高解析成功率）
        """
        super().__init__(logger)
        self.cookie = cookie
        self.has_cookie = bool(cookie)

        # 请求头配置
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Referer": "https://www.bilibili.com/",
            "Origin": "https://www.bilibili.com",
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
            "bilibili.com",
            "b23.tv",
            "bilibili.cn"
        ])

    def parse(self, url: str, preferred_quality: str = "1080P") -> Optional[MediaInfo]:
        """
        解析哔哩哔哩链接

        Args:
            url: 哔哩哔哩视频链接
            preferred_quality: 首选清晰度（1080P+/1080P/720P/480P/360P）

        Returns:
            MediaInfo: 媒体信息对象

        Raises:
            ParseError: 解析失败
        """
        try:
            self.validate_url(url)
            self.log_info(f"开始解析哔哩哔哩链接: {url}")

            # 提取视频ID
            video_id = self._extract_video_id(url)
            if not video_id:
                raise ParseError(f"无法从链接中提取视频ID: {url}")

            self.log_info(f"✓ 提取到视频ID: bvid={video_id.get('bvid')}, avid={video_id.get('avid')}")

            # 获取视频基础信息
            video_info = self._fetch_video_info(video_id["bvid"])

            # 检查响应状态
            if video_info.get("code") != 0:
                error_msg = self._get_error_message(video_info.get("code"))
                raise ParseError(error_msg)

            self.log_info("✓ 获取视频基础信息成功")

            # 提取视频分P信息
            parts_info = self._fetch_video_parts(video_id["bvid"])
            if parts_info.get("code") == 0 and parts_info.get("data"):
                first_cid = parts_info["data"][0]["cid"]
                self.log_info(f"✓ 获取视频分P信息成功，共{len(parts_info['data'])}个分P")
            else:
                # 从video_info中获取cid
                first_cid = video_info["data"].get("cid")
                self.log_warning("无法获取分P信息，使用主视频cid")

            # 获取多清晰度视频流
            video_streams = self._fetch_video_streams(
                video_id["bvid"],
                first_cid,
                preferred_quality
            )

            # 提取媒体信息
            media_data = self._extract_media_info(
                video_info["data"],
                video_streams,
                url
            )

            # 构建MediaInfo对象
            media_info = MediaInfo(
                platform=Platform.BILIBILI,
                title=media_data.get("title", "哔哩哔哩视频"),
                author=media_data.get("author", "未知UP主"),
                media_type=media_data.get("media_type", MediaType.VIDEO),
                note_id=video_id.get("bvid"),
                url=url,
                download_urls=media_data.get("download_urls", DownloadUrls()),
                description=media_data.get("description"),
                tags=media_data.get("tags", []),
                cover_url=media_data.get("cover_url"),
                # 统计信息
                like_count=media_data.get("like_count"),
                collect_count=media_data.get("collect_count"),  # 收藏数
                comment_count=media_data.get("comment_count"),
                share_count=media_data.get("share_count"),
                view_count=media_data.get("view_count"),
                danmaku_count=media_data.get("danmaku_count"),  # 弹幕数
                coin_count=media_data.get("coin_count"),  # 投币数
                # 时间信息
                publish_time=media_data.get("publish_time"),
                # 视频时长（秒）
                duration=media_data.get("duration"),
                # 原始数据
                raw_data=video_info,
            )

            self.log_info(f"✓ 解析成功: {media_info.title}")
            return media_info

        except (ParseError, NetworkError) as e:
            raise e
        except Exception as e:
            raise ParseError(f"哔哩哔哩链接解析失败: {str(e)}", url=url, platform="bilibili")

    def _extract_video_id(self, url: str) -> Optional[Dict[str, str]]:
        """
        从URL中提取视频ID

        Args:
            url: 哔哩哔哩链接

        Returns:
            dict: 包含bvid和avid的字典
        """
        # 处理b23.tv短链接
        if "b23.tv" in url:
            return self._resolve_short_url(url)

        video_id = {"bvid": None, "avid": None}

        # 提取BV号（bvid）
        bvid_match = re.search(r'(BV[\w]+)', url, re.IGNORECASE)
        if bvid_match:
            video_id["bvid"] = bvid_match.group(1)

        # 提取av号（avid）
        avid_match = re.search(r'av(\d+)', url)
        if avid_match:
            video_id["avid"] = avid_match.group(1)

        # 如果只有avid，需要通过API获取bvid
        if video_id["avid"] and not video_id["bvid"]:
            # 这里可以调用API转换，暂时返回avid
            return video_id

        # 如果只有bvid，直接返回
        if video_id["bvid"]:
            return video_id

        return None

    def _resolve_short_url(self, url: str) -> Optional[Dict[str, str]]:
        """
        解析b23.tv短链接

        Args:
            url: 短链接

        Returns:
            dict: 包含bvid和avid的字典
        """
        try:
            with httpx.Client(headers=self.headers, timeout=10, follow_redirects=True) as client:
                response = client.get(url)
                final_url = str(response.url)

                self.log_info(f"短链接解析为: {final_url}")

                # 从最终URL中提取ID
                return self._extract_video_id(final_url)

        except Exception as e:
            self.log_error(f"短链接解析失败: {str(e)}")
            return None

    def _fetch_video_info(self, bvid: str) -> Dict[str, Any]:
        """
        获取视频基础信息

        Args:
            bvid: 视频BV号

        Returns:
            dict: API响应数据
        """
        url = f"{self.API_ENDPOINTS['video_info']}?bvid={bvid}"

        try:
            with httpx.Client(headers=self.headers, timeout=15) as client:
                response = client.get(url)
                response.raise_for_status()

                data = response.json()
                return data

        except httpx.HTTPError as e:
            raise NetworkError(f"获取视频信息失败: {str(e)}")

    def _fetch_video_parts(self, bvid: str) -> Dict[str, Any]:
        """
        获取视频分P信息

        Args:
            bvid: 视频BV号

        Returns:
            dict: API响应数据
        """
        url = f"{self.API_ENDPOINTS['video_parts']}?bvid={bvid}"

        try:
            with httpx.Client(headers=self.headers, timeout=15) as client:
                response = client.get(url)
                response.raise_for_status()

                data = response.json()
                return data

        except httpx.HTTPError as e:
            self.log_warning(f"获取分P信息失败: {str(e)}")
            return {}

    def _fetch_video_streams(
        self,
        bvid: str,
        cid: int,
        preferred_quality: str
    ) -> Dict[str, Any]:
        """
        获取多清晰度视频流

        Args:
            bvid: 视频BV号
            cid: 视频分P的cid
            preferred_quality: 首选清晰度

        Returns:
            dict: 视频流数据
        """
        # 获取首选清晰度的qn值
        preferred_qn = self.QUALITY_MAP.get(preferred_quality, 112)

        # 构建请求参数
        params = {
            "bvid": bvid,
            "cid": cid,
            "qn": preferred_qn,
            "fnval": 0,   # 0=FLV格式（音视频合一）, 16=DASH格式（音视频分离）
            "fnver": 0,
            "fourk": 1,   # 是否支持4K
            "oice": 0,    # FLV格式参数
        }

        # 生成WBI签名
        signed_params = self._generate_wbi_signature(params)

        # 构建完整URL
        url = f"{self.API_ENDPOINTS['video_streams']}?{signed_params}"

        try:
            with httpx.Client(headers=self.headers, timeout=15) as client:
                response = client.get(url)
                response.raise_for_status()

                data = response.json()

                # 检查是否需要降级清晰度
                if data.get("code") == 0:
                    self.log_info(f"✓ 获取视频流成功，清晰度: {preferred_quality}")
                    return data
                else:
                    # 尝试降级清晰度
                    return self._try_fallback_quality(bvid, cid, preferred_quality)

        except httpx.HTTPError as e:
            self.log_warning(f"获取视频流失败: {str(e)}")
            return {}

    def _try_fallback_quality(
        self,
        bvid: str,
        cid: int,
        preferred_quality: str
    ) -> Dict[str, Any]:
        """
        尝试降级清晰度

        Args:
            bvid: 视频BV号
            cid: 视频分P的cid
            preferred_quality: 首选清晰度

        Returns:
            dict: 视频流数据
        """
        quality_priority = ["1080P", "720P", "480P", "360P"]

        # 从首选清晰度之后开始尝试
        start_index = quality_priority.index(preferred_quality) if preferred_quality in quality_priority else 0

        for quality in quality_priority[start_index + 1:]:
            self.log_info(f"尝试降级到 {quality}...")

            qn = self.QUALITY_MAP[quality]
            params = {
                "bvid": bvid,
                "cid": cid,
                "qn": qn,
                "fnval": 16,
                "fnver": 0,
                "fourk": 1,
            }

            signed_params = self._generate_wbi_signature(params)
            url = f"{self.API_ENDPOINTS['video_streams']}?{signed_params}"

            try:
                with httpx.Client(headers=self.headers, timeout=15) as client:
                    response = client.get(url)
                    data = response.json()

                    if data.get("code") == 0:
                        self.log_info(f"✓ 使用降级清晰度: {quality}")
                        return data

            except Exception as e:
                self.log_warning(f"降级到 {quality} 失败: {str(e)}")
                continue

        return {}

    def _generate_wbi_signature(self, params: dict) -> str:
        """
        生成WBI签名

        Args:
            params: 请求参数

        Returns:
            str: 包含w_rid签名的查询字符串
        """
        try:
            # 导入WBI签名生成器
            import sys
            import os

            # 添加 crawlers 路径
            crawlers_path = os.path.join(os.path.dirname(__file__), "../../../douyin_tiktok_service/crawlers")
            sys.path.insert(0, os.path.abspath(crawlers_path))

            from crawlers.bilibili.web import wrid

            # 添加时间戳
            params["wts"] = int(time.time())

            # 过滤特殊字符
            filtered_params = {
                k: ''.join(filter(lambda c: c not in "!'()*", str(v)))
                for k, v in params.items()
            }

            # 排序参数
            sorted_params = dict(sorted(filtered_params.items()))

            # 序列化查询字符串
            query = urlencode(sorted_params)

            # 生成w_rid签名
            w_rid = wrid.get_wrid(query)

            # 添加签名到参数
            sorted_params["w_rid"] = w_rid

            # 返回完整查询字符串
            return urlencode(sorted_params)

        except Exception as e:
            self.log_warning(f"WBI签名生成失败: {str(e)}，使用未签名请求")
            return urlencode(params)

    def _extract_media_info(
        self,
        video_data: Dict[str, Any],
        video_streams: Dict[str, Any],
        url: str
    ) -> Dict[str, Any]:
        """
        从API响应中提取媒体信息

        Args:
            video_data: 视频基础信息
            video_streams: 视频流信息
            url: 原始URL

        Returns:
            dict: 提取的媒体信息
        """
        media_info = {
            "title": "哔哩哔哩视频",
            "author": "未知UP主",
            "description": "",
            "media_type": MediaType.VIDEO,
            "cover_url": "",
            "tags": [],
            "like_count": 0,
            "collect_count": 0,
            "comment_count": 0,
            "share_count": 0,
            "view_count": 0,
            "danmaku_count": 0,
            "coin_count": 0,
            "duration": 0,
            "publish_time": None,
            "download_urls": DownloadUrls(),
        }

        try:
            # 提取标题
            title = video_data.get("title", "")
            if title:
                media_info["title"] = title[:100]

            # 提取描述
            desc = video_data.get("desc", "")
            if desc:
                media_info["description"] = desc

            # 提取作者信息
            owner = video_data.get("owner", {})
            if owner:
                media_info["author"] = owner.get("name", "未知UP主")

            # 提取统计数据
            stat = video_data.get("stat", {})
            if stat:
                media_info["like_count"] = stat.get("like", 0)
                media_info["collect_count"] = stat.get("favorite", 0)
                media_info["comment_count"] = stat.get("reply", 0)
                media_info["share_count"] = stat.get("share", 0)
                media_info["view_count"] = stat.get("view", 0)
                media_info["danmaku_count"] = stat.get("danmaku", 0)
                media_info["coin_count"] = stat.get("coin", 0)

            # 提取视频时长（秒）
            duration = video_data.get("duration", 0)
            if duration:
                media_info["duration"] = duration

            # 提取发布时间
            pubdate = video_data.get("pubdate", 0)
            if pubdate:
                media_info["publish_time"] = datetime.fromtimestamp(pubdate)

            # 提取封面
            pic = video_data.get("pic", "")
            if pic:
                media_info["cover_url"] = pic

            # 提取标签
            tname = video_data.get("tname", "")
            if tname:
                media_info["tags"].append(tname)

            # 提取视频下载链接
            if video_streams.get("code") == 0:
                download_urls = self._extract_video_urls(video_streams["data"])
                media_info["download_urls"] = download_urls

            self.log_info(f"✓ 提取媒体信息成功: {media_info['title']}")

        except Exception as e:
            self.log_error(f"提取媒体信息失败: {str(e)}")

        return media_info

    def _extract_video_urls(self, stream_data: Dict[str, Any]) -> DownloadUrls:
        """
        从视频流数据中提取下载链接

        Args:
            stream_data: 视频流数据

        Returns:
            DownloadUrls: 下载链接对象
        """
        download_urls = DownloadUrls()

        try:
            # 优先提取FLV格式（包含音视频的单一文件，兼容性好）
            durl = stream_data.get("durl", [])
            if durl:
                for segment in durl:
                    url = segment.get("url")
                    if url:
                        download_urls.video.append(url)
                        self.log_info(f"✓ 提取到FLV格式视频流（共{len(durl)}个分段）")
                        break  # 只添加第一个分段
                # FLV格式已经包含音视频，不需要单独提取音频
                if download_urls.video:
                    return download_urls

            # 如果没有FLV格式，尝试提取DASH格式（视频和音频分离）
            dash = stream_data.get("dash", {})
            if dash:
                # 提取视频流
                videos = dash.get("video", [])
                for video in videos:
                    video_url = video.get("baseUrl") or video.get("base_url")
                    if video_url:
                        quality_id = video.get("id", 0)
                        quality_name = self.QUALITY_NAMES.get(quality_id, f"未知({quality_id})")
                        self.log_info(f"✓ 提取到 {quality_name} DASH视频流")

                        # 只添加最高清晰度的视频
                        if not download_urls.video:
                            download_urls.video.append(video_url)

                # 提取音频流
                audios = dash.get("audio", [])
                for audio in audios:
                    audio_url = audio.get("baseUrl") or audio.get("base_url")
                    if audio_url:
                        download_urls.audio.append(audio_url)
                        self.log_info("✓ 提取到DASH音频流")
                        break  # 只添加一个音频

        except Exception as e:
            self.log_error(f"提取视频链接失败: {str(e)}")

        return download_urls

    def _get_error_message(self, code: int) -> str:
        """
        获取错误码对应的错误信息

        Args:
            code: 错误码

        Returns:
            str: 错误信息
        """
        error_messages = {
            -400: "请求参数错误",
            -404: "视频不存在或已删除",
            -412: "风控拦截，请稍后重试",
            -352: "需要验证码，请添加Cookie",
            62031: "未登录，请添加Cookie",
            -403: "无访问权限",
        }

        return error_messages.get(code, f"未知错误 (错误码: {code})")


if __name__ == "__main__":
    # 测试代码
    import logging

    logging.basicConfig(level=logging.INFO)

    # 测试URL
    test_url = "https://www.bilibili.com/video/BV1xx411c7mD"

    parser = BilibiliEnhancedParser()
    media_info = parser.parse(test_url)

    if media_info:
        print(f"标题: {media_info.title}")
        print(f"UP主: {media_info.author}")
        print(f"播放量: {media_info.view_count}")
        print(f"弹幕数: {media_info.danmaku_count}")
        print(f"投币数: {media_info.coin_count}")
        print(f"视频数量: {len(media_info.download_urls.video)}")

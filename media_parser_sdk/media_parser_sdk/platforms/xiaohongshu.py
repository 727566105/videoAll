#!/usr/bin/env python3
"""
小红书平台解析器
"""

import re
import json
from typing import Optional
import httpx

from ..core.base_parser import BaseParser
from ..models.media_info import MediaInfo, MediaType, Platform, DownloadUrls
from ..exceptions import ParseError, NetworkError


class XiaohongshuParser(BaseParser):
    """小红书平台解析器"""

    def __init__(self, logger=None, cookie: str = None):
        """
        初始化小红书解析器

        Args:
            logger: 日志记录器
            cookie: 小红书Cookie（可选，有助于提高解析成功率，尤其是实况图片）
        """
        super().__init__(logger)
        self.cookie = cookie
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://www.xiaohongshu.com/",
            "Accept-Language": "zh-CN,zh;q=0.9"
        }
        if cookie:
            self.headers["Cookie"] = cookie
    
    def is_supported_url(self, url: str) -> bool:
        """检查是否支持该URL"""
        return any(domain in url.lower() for domain in ["xiaohongshu.com", "xhslink.com"])
    
    def parse(self, url: str) -> Optional[MediaInfo]:
        """解析小红书链接"""
        try:
            self.validate_url(url)
            
            # 获取网页HTML
            html = self._get_html(url)
            
            # 提取媒体信息
            media_data = self._extract_media_info(html)
            if not media_data:
                raise ParseError("无法提取媒体信息", url=url, platform="xiaohongshu")
            
            # 获取下载链接
            download_urls = self._get_download_urls(media_data)
            
            # 构建MediaInfo对象
            media_info = MediaInfo(
                platform=Platform.XIAOHONGSHU,
                title=media_data.get("title", "小红书笔记"),
                author=media_data.get("author", "未知作者"),
                media_type=self._determine_media_type(media_data, download_urls),
                note_id=media_data.get("note_id"),
                download_urls=download_urls,
                description=media_data.get("description"),
                tags=media_data.get("tags", []),
                has_live_photo=media_data.get("has_live_photo", False),
                raw_data=media_data.get("raw_data", {}),
                # 统计数据
                like_count=media_data.get("like_count"),
                collect_count=media_data.get("collect_count"),
                comment_count=media_data.get("comment_count"),
                share_count=media_data.get("share_count"),
                view_count=media_data.get("view_count"),
                # 发布时间
                publish_time=media_data.get("publish_time"),
                url=url
            )
            
            return media_info
            
        except NetworkError as e:
            raise e
        except ParseError as e:
            raise e
        except Exception as e:
            raise ParseError(f"小红书链接解析失败: {str(e)}", url=url, platform="xiaohongshu")
    
    def _get_html(self, url: str) -> str:
        """获取网页HTML内容"""
        try:
            # 保留原始 URL 的所有参数
            self.log_debug(f"请求 URL: {url}")
            self.log_debug(f"Cookie 状态: {'已提供' if self.cookie else '未提供'}")

            # 增强请求头，模拟真实浏览器
            enhanced_headers = self.headers.copy()
            enhanced_headers.update({
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
                "Accept-Encoding": "gzip, deflate, br",
                "Cache-Control": "max-age=0",
                "Sec-Ch-Ua": '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
                "Sec-Ch-Ua-Mobile": "?0",
                "Sec-Ch-Ua-Platform": '"macOS"',
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "none",
                "Sec-Fetch-User": "?1",
                "Upgrade-Insecure-Requests": "1",
            })

            with httpx.Client(headers=enhanced_headers, timeout=15, follow_redirects=True) as client:
                response = client.get(url)

                # 检查响应状态
                if response.status_code == 403:
                    self.log_warning("收到 403 禁止访问，可能需要有效的 Cookie")
                elif response.status_code == 404:
                    self.log_warning("页面不存在或需要登录")

                response.raise_for_status()

                # 检查是否是错误页面
                html_lower = response.text.lower()
                if "你访问的页面不见了" in response.text or "页面找不到" in response.text:
                    self.log_error("获取到错误页面：页面不存在或需要登录")
                    if not self.cookie:
                        self.log_warning("💡 提示：提供 Cookie 可能能解决这个问题")
                        self.log_warning("   获取方式：浏览器 F12 -> Network -> 复制 Request Header 中的 Cookie")
                    raise NetworkError(f"页面访问受限（可能需要提供 Cookie）", url=url)

                return response.text
        except httpx.HTTPError as e:
            self.log_error(f"网络请求失败: {str(e)}")
            raise NetworkError(f"网络请求失败: {str(e)}", url=url)
    
    def _extract_media_info(self, html: str) -> Optional[dict]:
        """从HTML中提取媒体信息"""
        try:
            media_data = {
                "title": "小红书笔记",
                "author": "未知作者",
                "note_id": None,
                "has_live_photo": False,
                "raw_data": {}
            }
            
            # 提取window.__INITIAL_STATE__脚本数据
            initial_state_pattern = re.compile(r'window\.__INITIAL_STATE__\s*=\s*(.+?)(?=</script>)', re.DOTALL)
            initial_state_match = initial_state_pattern.search(html)
            
            if initial_state_match:
                initial_state_str = initial_state_match.group(1).strip()
                if initial_state_str.endswith(';'):
                    initial_state_str = initial_state_str[:-1]
                
                try:
                    initial_state = json.loads(initial_state_str)
                    media_data["raw_data"] = initial_state
                    
                    if self._parse_initial_state(initial_state, media_data):
                        return media_data
                except json.JSONDecodeError as e:
                    self.log_debug(f"__INITIAL_STATE__解析失败: {str(e)}")
                    
                    # 尝试修复JSON解析问题
                    try:
                        fixed_str = re.sub(r'\bundefined\b', 'null', initial_state_str)
                        fixed_str = re.sub(r',(\s*[}\]])', r'\1', fixed_str)
                        fixed_str = re.sub(r'//.*?\n', '\n', fixed_str)
                        fixed_str = re.sub(r'/\*.*?\*/', '', fixed_str, flags=re.DOTALL)
                        
                        initial_state = json.loads(fixed_str)
                        media_data["raw_data"] = initial_state
                        
                        if self._parse_initial_state(initial_state, media_data):
                            return media_data
                    except json.JSONDecodeError as e2:
                        self.log_debug(f"修复后仍然解析失败: {str(e2)}")
            
            # 备用方法：通过meta标签分析
            title_match = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE)
            if title_match:
                media_data["title"] = title_match.group(1).replace(" - 小红书", "")

            # 检查是否是错误页面
            if "你访问的页面不见了" in html or "页面找不到" in html:
                self.log_error("获取到错误页面：页面不存在或需要登录")
                self.log_warning(f"页面标题: {media_data.get('title')}")
                if not self.cookie:
                    self.log_warning("💡 提示：提供 Cookie 可能能解决这个问题")
                    self.log_warning("   获取方式：浏览器 F12 -> Network -> 复制 Request Header 中的 Cookie")
                    self.log_warning("   使用方式：XiaohongshuParser(cookie='你的Cookie')")

            return media_data
            
        except Exception as e:
            self.log_error(f"提取媒体信息失败: {str(e)}")
            return None
    
    def _parse_initial_state(self, initial_state: dict, media_data: dict) -> bool:
        """从__INITIAL_STATE__中解析详细媒体信息"""
        try:
            note = initial_state.get("note", {})
            note_detail_map = note.get("noteDetailMap", {})
            
            if note_detail_map:
                note_id = next(iter(note_detail_map.keys()), None)
                if note_id:
                    note_detail = note_detail_map[note_id]
                    note_data = note_detail.get("note", {})
                    
                    if note_data:
                        media_data["title"] = note_data.get("title", media_data["title"])
                        media_data["note_id"] = note_data.get("noteId", note_id)
                        media_data["description"] = note_data.get("desc", "")
                        
                        # 提取用户信息
                        user_data = note_data.get("user", {})
                        if isinstance(user_data, dict):
                            media_data["author"] = user_data.get("nickname", media_data["author"])
                        
                        # 检查是否有实况图片（增强逻辑）
                        media_data["has_live_photo"] = False
                        image_list = note_data.get("imageList", [])
                        if image_list:
                            for img in image_list:
                                # 检查多种实况图片的表示方式
                                if img.get("livePhoto") or img.get("live_photo") or img.get("livephoto"):
                                    media_data["has_live_photo"] = True
                                    break
                        
                        # 提取标签
                        tag_list = note_data.get("tagList", [])
                        media_data["tags"] = [tag.get("name", "") for tag in tag_list if tag.get("name")]

                        # 提取统计数据 - 小红书数据在 interactInfo 对象中
                        interact_info = note_data.get("interactInfo", {})

                        # 从 interactInfo 中提取（新版本数据结构）
                        if interact_info:
                            # 尝试从 interactInfo 获取，值可能是字符串需要转换为整数
                            media_data["like_count"] = self._safe_int(interact_info.get("likedCount"))
                            media_data["collect_count"] = self._safe_int(interact_info.get("collectedCount"))
                            media_data["comment_count"] = self._safe_int(interact_info.get("commentCount"))
                            media_data["share_count"] = self._safe_int(interact_info.get("shareCount"))
                        else:
                            # 备用：从 note_data 根级别获取（旧版本数据结构）
                            media_data["like_count"] = self._safe_int(note_data.get("likedCount") or note_data.get("like_count"))
                            media_data["collect_count"] = self._safe_int(note_data.get("collectedCount") or note_data.get("collect_count"))
                            media_data["comment_count"] = self._safe_int(note_data.get("commentCount") or note_data.get("comment_count"))
                            media_data["share_count"] = self._safe_int(note_data.get("shareCount") or note_data.get("share_count"))

                        # viewCount 通常不在 interactInfo 中，从根级别获取
                        media_data["view_count"] = self._safe_int(note_data.get("viewCount") or note_data.get("view_count"))

                        # 记录提取的统计数据
                        self.log_info(f"提取统计数据 - 点赞:{media_data['like_count']}, 收藏:{media_data['collect_count']}, 评论:{media_data['comment_count']}")

                        # 提取发布时间（小红书使用毫秒级时间戳）
                        publish_time = note_data.get("time") or note_data.get("publishTime") or note_data.get("publish_time")
                        if publish_time:
                            try:
                                from datetime import datetime
                                if isinstance(publish_time, (int, float)):
                                    # 毫秒级时间戳转换
                                    media_data["publish_time"] = datetime.fromtimestamp(publish_time / 1000)
                                    self.log_info(f"提取发布时间: {media_data['publish_time']}")
                                elif isinstance(publish_time, str):
                                    # ISO格式字符串
                                    media_data["publish_time"] = datetime.fromisoformat(publish_time.replace('Z', '+00:00'))
                                    self.log_info(f"提取发布时间: {media_data['publish_time']}")
                            except Exception as e:
                                self.log_debug(f"发布时间解析失败: {publish_time}, 错误: {e}")

                        # 保存完整的note数据，用于后续下载链接提取
                        media_data["note_data"] = note_data
                        return True
            
            # 备选方案：检查其他可能的note数据位置
            try:
                # 检查noteDetailMap的其他可能结构
                if isinstance(initial_state, dict):
                    # 遍历整个initial_state，寻找可能的note数据
                    for key, value in initial_state.items():
                        if isinstance(value, dict):
                            if "imageList" in value:
                                # 可能是直接的note数据
                                media_data["note_data"] = value
                                # 检查是否有实况图片
                                media_data["has_live_photo"] = False
                                image_list = value.get("imageList", [])
                                for img in image_list:
                                    if img.get("livePhoto") or img.get("live_photo") or img.get("livephoto"):
                                        media_data["has_live_photo"] = True
                                        break
                                return True
            except Exception as e:
                self.log_debug(f"备选方案解析失败: {str(e)}")
            
            return False
        except Exception as e:
            self.log_debug(f"解析__INITIAL_STATE__详细信息失败: {str(e)}")
            return False

    def _safe_int(self, value) -> int:
        """安全地将值转换为整数"""
        if value is None:
            return 0
        if isinstance(value, int):
            return value
        if isinstance(value, str):
            try:
                return int(value)
            except ValueError:
                return 0
        if isinstance(value, float):
            return int(value)
        return 0

    def _get_download_urls(self, media_data: dict) -> DownloadUrls:
        """获取下载链接"""
        download_urls = DownloadUrls()

        try:
            # 从note_data中提取媒体URL
            note_data = media_data.get("note_data")
            if note_data:
                self._extract_urls_from_note_data(note_data, download_urls)

            # 从raw_data中搜索所有可能的媒体链接
            raw_data = media_data.get("raw_data", {})
            if raw_data:
                self._extract_all_urls_from_data(raw_data, download_urls)

            # 最终去重：使用规范化URL进行去重（去除所有查询参数）
            download_urls.video = self._deduplicate_urls(download_urls.video)
            download_urls.images = self._deduplicate_urls(download_urls.images)
            download_urls.live = self._deduplicate_urls(download_urls.live)

            self.log_debug(f"去重后: 视频{len(download_urls.video)}个, 图片{len(download_urls.images)}张, 实况{len(download_urls.live)}个")

            return download_urls

        except Exception as e:
            self.log_error(f"获取下载链接失败: {str(e)}")
            return download_urls

    def _deduplicate_urls(self, url_list: list) -> list:
        """URL去重 - 使用基础URL（去除查询参数）进行比较"""
        seen = set()
        result = []

        for url in url_list:
            # 提取基础URL（去除查询参数和片段）
            base_url = url.split('?')[0].split('#')[0]

            if base_url not in seen:
                seen.add(base_url)
                result.append(url)
            else:
                self.log_debug(f"去除重复URL: {url}")

        return result
    
    def _extract_urls_from_note_data(self, note_data: dict, download_urls: DownloadUrls) -> None:
        """从note_data中提取媒体URL"""
        try:
            self.log_debug(f"开始从note_data提取URL")
            
            # 处理视频数据
            if note_data.get("type") == "video" or "video" in note_data:
                video_data = note_data.get("video")
                if video_data:
                    self.log_debug(f"找到视频数据: {video_data.keys()}")
                    # 支持新老两种视频数据结构
                    h264_data = None
                    if "stream" in video_data:
                        h264_data = video_data.get("stream", {}).get("h264")
                    elif "media" in video_data:
                        h264_data = video_data.get("media", {}).get("stream", {}).get("h264")
                    elif "videoUrl" in video_data:
                        # 直接的视频URL字段
                        video_url = video_data.get("videoUrl")
                        if video_url:
                            clean_url = self.clean_url(video_url)
                            download_urls.video.append(clean_url)
                            self.log_debug(f"提取到直接视频URL: {clean_url}")
                    
                    if h264_data and isinstance(h264_data, list):
                        for h264_item in h264_data:
                            if isinstance(h264_item, dict):
                                master_url = h264_item.get("masterUrl")
                                if master_url:
                                    clean_url = self.clean_url(master_url)
                                    download_urls.video.append(clean_url)
                                    self.log_debug(f"提取到H264视频URL: {clean_url}")
            
            # 处理图片数据
            image_list = note_data.get("imageList")
            if image_list and isinstance(image_list, list):
                self.log_debug(f"找到图片列表，长度: {len(image_list)}")
                for i, image_item in enumerate(image_list):
                    if isinstance(image_item, dict):
                        self.log_debug(f"处理图片 {i+1}: {list(image_item.keys())}")
                        
                        # 提取静态图片URL
                        image_url = None
                        
                        # 优先从infoList中获取高质量图片
                        info_list = image_item.get("infoList", [])
                        if isinstance(info_list, list):
                            for info in info_list:
                                if isinstance(info, dict):
                                    scene = info.get("imageScene", "")
                                    url = info.get("url", "")
                                    if scene == "WB_DFT" and url:
                                        image_url = url
                                        break
                                    elif scene == "WB_PRV" and url and not image_url:
                                        image_url = url
                        
                        # 备用字段
                        if not image_url:
                            image_url = (image_item.get("urlDefault") or 
                                        image_item.get("url") or 
                                        image_item.get("urlPre") or
                                        image_item.get("urlList", [{}])[0].get("url", ""))
                        
                        if image_url:
                            clean_url = self.clean_url(image_url)
                            download_urls.images.append(clean_url)
                            self.log_debug(f"提取到图片URL: {clean_url}")
                        
                        # 提取实况图片的视频URL（增强逻辑）
                        live_photo = image_item.get("livePhoto") or image_item.get("live_photo") or image_item.get("livephoto")

                        # 新增：检查更多可能的字段
                        if not live_photo:
                            # 检查 infoList 中是否有实况图片信息
                            info_list = image_item.get("infoList", [])
                            if info_list:
                                for info in info_list:
                                    if isinstance(info, dict):
                                        # 检查各种可能的实况图片标记
                                        if info.get("livePhoto") or info.get("live_photo"):
                                            live_photo = info
                                            self.log_debug(f"从 infoList 找到实况图片数据")
                                            break

                        if live_photo:
                            self.log_debug(f"找到实况图片数据: {live_photo}")
                            if isinstance(live_photo, dict):
                                # 尝试多种可能的视频URL字段
                                video_url = (live_photo.get("videoUrl") or
                                            live_photo.get("video_url") or
                                            live_photo.get("url") or
                                            live_photo.get("video") or
                                            live_photo.get("media") or
                                            live_photo.get("stream"))

                                if video_url:
                                    # video_url 可能是一个对象，需要进一步处理
                                    if isinstance(video_url, dict):
                                        self.log_debug(f"实况图片URL是字典类型，尝试提取: {list(video_url.keys())}")
                                        # 尝试从对象中提取实际的 URL
                                        video_url = (video_url.get("masterUrl") or
                                                    video_url.get("url") or
                                                    video_url.get("defaultUrl"))

                                    if video_url and isinstance(video_url, str):
                                        clean_url = self.clean_url(video_url)
                                        if clean_url not in download_urls.live:
                                            download_urls.live.append(clean_url)
                                            self.log_info(f"✓ 成功提取实况图片URL: {clean_url}")
                                    else:
                                        self.log_debug(f"实况图片URL不是字符串类型: {type(video_url)}, 值: {video_url}")
                                else:
                                    self.log_debug(f"livePhoto对象中的字段: {list(live_photo.keys())}")
                            elif isinstance(live_photo, str):
                                # 实况图片可能直接是字符串URL
                                clean_url = self.clean_url(live_photo)
                                if clean_url not in download_urls.live:
                                    download_urls.live.append(clean_url)
                                    self.log_info(f"✓ 成功提取实况图片URL（字符串）: {clean_url}")
                        else:
                            # 调试信息：记录图片项的所有字段，帮助识别新的数据结构
                            self.log_debug(f"图片项字段: {list(image_item.keys())}")
        
        except Exception as e:
            self.log_debug(f"从note_data提取URL失败: {str(e)}")
            import traceback
            self.log_debug(traceback.format_exc())
    
    def _extract_all_urls_from_data(self, data: dict, download_urls: DownloadUrls) -> None:
        """从数据中提取所有可能的媒体URL"""
        try:
            data_str = json.dumps(data)
            
            # 匹配所有媒体链接
            media_pattern = re.compile(r'"(https?://[^"]+?\.(mp4|jpg|png|webp|mov|gif)[^"]*)"')
            media_matches = media_pattern.findall(data_str)
            
            for match in media_matches:
                url = match[0]
                ext = match[1]
                
                clean_url = self.clean_url(url)
                
                # 特殊处理MOV格式，通常是实况图片
                if ext == "mov":
                    if clean_url not in download_urls.live:
                        download_urls.live.append(clean_url)
                        self.log_debug(f"从raw_data提取到实况图片URL: {clean_url}")
                elif ext == "mp4":
                    if clean_url not in download_urls.video:
                        download_urls.video.append(clean_url)
                        self.log_debug(f"从raw_data提取到视频URL: {clean_url}")
                else:
                    if clean_url not in download_urls.images:
                        download_urls.images.append(clean_url)
                        self.log_debug(f"从raw_data提取到图片URL: {clean_url}")
            
            # 专门搜索livePhoto相关的URL
            live_photo_pattern = re.compile(r'livePhoto[^\"]*"(https?://[^\"]+?\.(mov|mp4)[^\"]*)"', re.DOTALL | re.IGNORECASE)
            live_photo_matches = live_photo_pattern.findall(data_str)
            
            for match in live_photo_matches:
                url = match[0]
                ext = match[1]
                clean_url = self.clean_url(url)
                
                if clean_url not in download_urls.live:
                    download_urls.live.append(clean_url)
                    self.log_debug(f"从livePhoto相关内容提取到实况图片URL: {clean_url}")
        
        except Exception as e:
            self.log_debug(f"提取所有URL失败: {str(e)}")
            import traceback
            self.log_debug(traceback.format_exc())
    
    def _determine_media_type(self, media_data: dict, download_urls: DownloadUrls) -> MediaType:
        """确定媒体类型"""
        # 检查是否有实况图片
        if media_data.get("has_live_photo") or download_urls.live:
            return MediaType.LIVE_PHOTO
        
        # 检查是否有视频（但没有实况图片）
        if download_urls.video and not download_urls.images:
            return MediaType.VIDEO
        
        # 默认为图片类型
        return MediaType.IMAGE
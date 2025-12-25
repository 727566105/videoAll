#!/usr/bin/env python3
"""
小红书增强解析器 - 支持用户主页和笔记集合功能
"""

import re
import json
import time
from typing import Optional, List, Dict, Any
from urllib.parse import urlparse, parse_qs, urlencode
from datetime import datetime

try:
    import httpx
except ImportError:
    httpx = None

from ..core.base_parser import BaseParser
from ..models.media_info import MediaInfo, MediaType, Platform, DownloadUrls
from ..exceptions import ParseError, NetworkError

# 导入数据模型
try:
    from ..models.xiaohongshu_models import (
        NoteInfo, AuthorInfo, AuthorProfile, AuthorNotesCollection,
        InteractionStats, MediaResource, VideoResource, NoteType, XiaohongshuExtractResult
    )
except ImportError:
    # 简化版本的数据模型
    from pydantic import BaseModel
    from enum import Enum

    class NoteType(str, Enum):
        NORMAL = "normal"
        VIDEO = "video"
        LIVE_PHOTO = "live_photo"
        CAROUSEL = "carousel"

    class XiaohongshuExtractResult(BaseModel):
        success: bool
        result_type: str
        data: Optional[Dict[str, Any]] = None
        error_message: Optional[str] = None


class XiaohongshuEnhancedParser(BaseParser):
    """小红书增强解析器 - 支持用户主页和笔记集合

    注意：获取用户主页的完整笔记信息需要提供 Cookie
    """

    def __init__(self, logger=None, cookie: str = None):
        """
        初始化解析器

        Args:
            logger: 日志记录器
            cookie: 小红书 Cookie，用于获取完整的笔记信息
                    获取方式：浏览器开发者工具 -> Network -> 复制 Cookie
        """
        super().__init__(logger)
        self.cookie = cookie
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://www.xiaohongshu.com/",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        }
        if cookie:
            self.headers["Cookie"] = cookie
            self.has_cookie = True
        else:
            self.has_cookie = False

        self.request_delay = 1.0
        self.base_url = "https://www.xiaohongshu.com"

        # 导入单个笔记解析器，用于获取笔记详情
        try:
            from .xiaohongshu import XiaohongshuParser
            self.note_parser = XiaohongshuParser(logger=logger)
            if cookie:
                # 如果提供了 Cookie，也设置到 note_parser 中
                self.note_parser.headers = self.note_parser.headers.copy()
                self.note_parser.headers["Cookie"] = cookie
        except ImportError:
            self.note_parser = None
            self.log_warning("无法导入XiaohongshuParser，笔记详情功能可能不可用")

    def is_supported_url(self, url: str) -> bool:
        """检查是否支持该URL"""
        return any(domain in url.lower() for domain in ["xiaohongshu.com", "xhslink.com"])

    def parse(self, url: str) -> Optional[MediaInfo]:
        """解析媒体链接 - BaseParser抽象方法实现"""
        # 判断URL类型
        if "/user/profile/" in url or "/user/profile/" in url:
            # 用户主页
            result = self.parse_author_profile_sync(url)
            if result.success and result.data:
                # 转换为 MediaInfo（使用第一条笔记作为代表）
                notes = result.data.get("notes", [])
                if notes:
                    return self._note_to_media_info(notes[0], url)
        else:
            # 单个笔记，使用默认解析器
            if self.note_parser:
                return self.note_parser.parse(url)
        return None

    def parse_author_profile_sync(self, url: str) -> XiaohongshuExtractResult:
        """同步版本：提取博主资料"""
        try:
            self.log_info(f"开始解析博主主页: {url}")

            # 提取用户ID
            user_id = self._extract_user_id_from_profile_url(url)
            if not user_id:
                return XiaohongshuExtractResult(
                    success=False,
                    result_type="author_profile",
                    error_message="无法从URL中提取用户ID"
                )

            # 获取用户主页HTML
            html = self._get_html(url)
            if not html:
                return XiaohongshuExtractResult(
                    success=False,
                    result_type="author_profile",
                    error_message="无法获取用户主页内容"
                )

            # 解析用户信息
            author_profile = self._parse_user_profile_html(html, user_id, url)
            if not author_profile:
                return XiaohongshuExtractResult(
                    success=False,
                    result_type="author_profile",
                    error_message="无法解析用户资料"
                )

            return XiaohongshuExtractResult(
                success=True,
                result_type="author_profile",
                data=author_profile
            )

        except Exception as e:
            self.log_error(f"解析博主主页失败: {str(e)}")
            return XiaohongshuExtractResult(
                success=False,
                result_type="author_profile",
                error_message=str(e)
            )

    def parse_author_notes_sync(
        self,
        url: str,
        max_notes: Optional[int] = None,
        fetch_detail: bool = True
    ) -> XiaohongshuExtractResult:
        """
        同步版本：提取博主所有笔记

        Args:
            url: 用户主页URL
            max_notes: 最大提取笔记数，None表示全部
            fetch_detail: 是否获取每条笔记的详细信息（包括高清图片/视频）

        注意：
            - 获取完整的笔记信息需要提供 Cookie
            - 无 Cookie 时只能获取笔记卡片信息（标题、封面、点赞数等）
            - 有 Cookie 时可以获取完整的高清图片和视频下载链接
        """
        try:
            # Cookie 提示
            if fetch_detail and not self.has_cookie:
                self.log_warning("⚠️  未提供 Cookie，无法获取完整的笔记信息（高清图片、视频下载链接）")
                self.log_warning("⚠️  将仅返回笔记卡片信息（标题、封面、点赞数）")
                self.log_warning("💡 提示：提供 Cookie 可获取完整信息")
                self.log_warning("   获取方式：浏览器 F12 -> Network -> 复制 Request Header 中的 Cookie")
                self.log_warning("   使用方式：parse_author_notes_sync(url, cookie='你的Cookie')")

            self.log_info(f"开始提取博主笔记: {url}, max_notes={max_notes}, fetch_detail={fetch_detail}")
            self.log_info(f"Cookie 状态: {'✓ 已提供' if self.has_cookie else '✗ 未提供'}")

            # 提取用户ID
            user_id = self._extract_user_id_from_profile_url(url)
            if not user_id:
                return XiaohongshuExtractResult(
                    success=False,
                    result_type="author_notes",
                    error_message="无法从URL中提取用户ID"
                )

            # 获取用户主页HTML
            html = self._get_html(url)
            if not html:
                return XiaohongshuExtractResult(
                    success=False,
                    result_type="author_notes",
                    error_message="无法获取用户主页内容"
                )

            # 解析用户信息和笔记卡片
            user_data = self._parse_user_page_html(html, user_id, url)
            if not user_data:
                return XiaohongshuExtractResult(
                    success=False,
                    result_type="author_notes",
                    error_message="无法解析用户页面"
                )

            note_cards = user_data.get("note_cards", [])
            author_info = user_data.get("author_info", {})
            total_notes_count = user_data.get("total_notes_count", len(note_cards))

            self.log_info(f"找到 {len(note_cards)} 条笔记卡片，总数: {total_notes_count}")

            # 如果需要获取详细信息，使用单个笔记解析器
            detailed_notes = []
            extracted_count = 0

            for i, card in enumerate(note_cards):
                if max_notes and extracted_count >= max_notes:
                    break

                note_id = card.get("note_id")
                self.log_info(f"处理笔记 {i+1}/{len(note_cards)}: {note_id or '无ID'}")

                if fetch_detail and note_id:
                    # 构造笔记URL并解析
                    note_url = f"{self.base_url}/explore/{note_id}"
                    try:
                        time.sleep(self.request_delay)  # 避免请求过快
                        media_info = self.note_parser.parse(note_url) if self.note_parser else None

                        if media_info:
                            # 将 MediaInfo 转换为笔记数据格式
                            note_data = self._media_info_to_note_dict(media_info, card)
                            detailed_notes.append(note_data)
                            extracted_count += 1
                            self.log_info(f"  ✓ 成功解析笔记详情: {media_info.title}")
                        else:
                            # 降级：使用卡片数据
                            detailed_notes.append(self._note_card_to_dict(card, author_info))
                            extracted_count += 1
                            self.log_info(f"  ⚠ 无法解析详情，使用卡片数据")
                    except Exception as e:
                        self.log_error(f"  ✗ 解析笔记详情失败: {e}")
                        # 降级：使用卡片数据
                        detailed_notes.append(self._note_card_to_dict(card, author_info))
                        extracted_count += 1
                else:
                    # 不获取详情，直接使用卡片数据
                    detailed_notes.append(self._note_card_to_dict(card, author_info))
                    extracted_count += 1

            result = {
                "author_profile": author_info,
                "notes": detailed_notes,
                "total_notes": total_notes_count,
                "extracted_notes": extracted_count,
                "has_more": max_notes and extracted_count >= max_notes,
                "extraction_stats": {
                    "cards_found": len(note_cards),
                    "successfully_parsed": sum(1 for n in detailed_notes if n.get("has_detail")),
                    "fallback_to_cards": sum(1 for n in detailed_notes if not n.get("has_detail"))
                }
            }

            self.log_info(f"提取完成: 共 {extracted_count} 条笔记")

            return XiaohongshuExtractResult(
                success=True,
                result_type="author_notes",
                data=result
            )

        except Exception as e:
            self.log_error(f"提取博主笔记失败: {str(e)}")
            import traceback
            self.log_error(traceback.format_exc())
            return XiaohongshuExtractResult(
                success=False,
                result_type="author_notes",
                error_message=str(e)
            )

    def _extract_user_id_from_profile_url(self, url: str) -> Optional[str]:
        """从用户主页URL中提取用户ID"""
        patterns = [
            r"/user/profile/([a-f0-9]+)",
            r"user/profile/([a-f0-9]+)",
        ]

        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)

        return None

    def _get_html(self, url: str) -> Optional[str]:
        """获取网页HTML内容"""
        if not httpx:
            raise NetworkError("需要安装 httpx 库")

        try:
            with httpx.Client(headers=self.headers, timeout=30, follow_redirects=True) as client:
                response = client.get(url)
                response.raise_for_status()
                return response.text
        except httpx.HTTPError as e:
            self.log_error(f"网络请求失败: {e}")
            return None

    def _parse_user_page_html(self, html: str, user_id: str, url: str) -> Optional[Dict]:
        """解析用户页面HTML，提取用户信息和笔记卡片"""
        try:
            # 提取window.__INITIAL_STATE__
            initial_state_pattern = re.compile(r'window\.__INITIAL_STATE__\s*=\s*(.+?)(?=</script>)', re.DOTALL)
            initial_state_match = initial_state_pattern.search(html)

            if not initial_state_match:
                self.log_error("未找到 window.__INITIAL_STATE__")
                return None

            initial_state_str = initial_state_match.group(1).strip()
            if initial_state_str.endswith(';'):
                initial_state_str = initial_state_str[:-1]

            # 修复并解析JSON
            initial_state_str = re.sub(r'\bundefined\b', 'null', initial_state_str)
            initial_state_str = re.sub(r',(\s*[}\]])', r'\1', initial_state_str)
            initial_state = json.loads(initial_state_str)

            # 提取用户信息
            user_data = initial_state.get("user", {})
            user_page_data = user_data.get("userPageData", {})
            basic_info = user_page_data.get("basicInfo", {})
            interactions = user_page_data.get("interactions", [])

            author_info = {
                "user_id": user_id,
                "nickname": basic_info.get("nickname", ""),
                "avatar_url": basic_info.get("images") or basic_info.get("imageb", ""),
                "xiaohongshu_id": basic_info.get("redId", ""),
                "ip_location": basic_info.get("ipLocation", ""),
                "signature": basic_info.get("desc", ""),
                "followers_count": self._parse_count(interactions, "fans"),
                "following_count": self._parse_count(interactions, "follows"),
                "total_likes_received": self._parse_count(interactions, "interaction"),
                "profile_url": url
            }

            # 提取笔记卡片
            user_notes = user_data.get("notes", [])
            note_cards = []

            if user_notes and len(user_notes) > 0:
                # user_notes[0] 是实际的笔记列表
                notes_list = user_notes[0] if isinstance(user_notes[0], list) else []
                self.log_info(f"从 user.notes[0] 找到 {len(notes_list)} 条笔记")

                for item in notes_list:
                    if isinstance(item, dict):
                        note_card = item.get("noteCard")
                        if note_card:
                            card_data = {
                                "note_id": note_card.get("noteId", ""),
                                "title": note_card.get("displayTitle", ""),
                                "type": note_card.get("type", "normal"),
                                "cover_url": note_card.get("cover", {}).get("urlDefault", ""),
                                "xsec_token": note_card.get("xsecToken", ""),
                                "liked_count": self._safe_int(note_card.get("interactInfo", {}).get("likedCount")),
                                "user_id": note_card.get("user", {}).get("userId", ""),
                                "user_nickname": note_card.get("user", {}).get("nickname", ""),
                                "user_avatar": note_card.get("user", {}).get("avatar", ""),
                            }
                            note_cards.append(card_data)

            return {
                "author_info": author_info,
                "note_cards": note_cards,
                "total_notes_count": len(note_cards)
            }

        except json.JSONDecodeError as e:
            self.log_error(f"JSON解析失败: {e}")
            return None
        except Exception as e:
            self.log_error(f"解析用户页面失败: {e}")
            import traceback
            self.log_error(traceback.format_exc())
            return None

    def _parse_user_profile_html(self, html: str, user_id: str, url: str) -> Optional[Dict]:
        """解析用户资料（简化版本，直接调用 _parse_user_page_html）"""
        user_data = self._parse_user_page_html(html, user_id, url)
        if user_data:
            return user_data.get("author_info")
        return None

    def _parse_count(self, interactions: List[Dict], count_type: str) -> int:
        """从互动数据中解析数量"""
        for item in interactions:
            if item.get("type") == count_type:
                count_str = item.get("count", "0")
                if isinstance(count_str, str):
                    # 处理 "10+" 这种格式
                    count_str = count_str.replace("+", "")
                return self._safe_int(count_str)
        return 0

    def _safe_int(self, value) -> int:
        """安全地将值转换为整数"""
        if value is None:
            return 0
        if isinstance(value, int):
            return value
        if isinstance(value, str):
            try:
                return int(value.replace("+", "").replace("10+", "10"))
            except ValueError:
                return 0
        if isinstance(value, float):
            return int(value)
        return 0

    def _note_card_to_dict(self, card: Dict, author_info: Dict) -> Dict:
        """将笔记卡片转换为字典"""
        return {
            "note_id": card.get("note_id"),
            "title": card.get("title"),
            "type": card.get("type"),
            "author": {
                "user_id": author_info.get("user_id"),
                "nickname": author_info.get("nickname"),
                "avatar_url": author_info.get("avatar_url")
            },
            "cover_image": {
                "url": card.get("cover_url")
            },
            "interaction_stats": {
                "like_count": card.get("liked_count", 0)
            },
            "source_url": f"{self.base_url}/explore/{card.get('note_id')}" if card.get("note_id") else "",
            "has_detail": False
        }

    def _media_info_to_note_dict(self, media_info: MediaInfo, card: Dict) -> Dict:
        """将 MediaInfo 转换为笔记字典"""
        # 安全地获取 media_type 的值（处理枚举和字符串两种情况）
        media_type_value = media_info.media_type.value if hasattr(media_info.media_type, 'value') else str(media_info.media_type)

        return {
            "note_id": media_info.note_id or card.get("note_id"),
            "title": media_info.title or card.get("title"),
            "content": media_info.description or "",
            "type": media_type_value,
            "author": {
                "user_id": card.get("user_id"),
                "nickname": media_info.author or card.get("user_nickname"),
                "avatar_url": card.get("user_avatar")
            },
            "images": [{"url": url} for url in (media_info.download_urls.images or [])],
            "videos": [{"url": url} for url in (media_info.download_urls.video or [])],
            "cover_image": {"url": media_info.cover_url or card.get("cover_url")},
            "interaction_stats": {
                "like_count": media_info.like_count or card.get("liked_count", 0),
                "collect_count": media_info.collect_count or 0,
                "comment_count": media_info.comment_count or 0,
                "share_count": media_info.share_count or 0,
                "view_count": media_info.view_count or 0
            },
            "tags": media_info.tags or [],
            "publish_time": media_info.publish_time.isoformat() if media_info.publish_time else None,
            "source_url": media_info.url,
            "has_detail": True,
            "has_live_photo": media_info.has_live_photo
        }

    def _note_to_media_info(self, note_data: Dict, url: str) -> Optional[MediaInfo]:
        """将笔记数据转换为 MediaInfo"""
        try:
            download_urls = DownloadUrls()

            # 处理图片
            for img in note_data.get("images", []):
                if isinstance(img, dict) and img.get("url"):
                    download_urls.images.append(img["url"])
                elif isinstance(img, str):
                    download_urls.images.append(img)

            # 处理视频
            for video in note_data.get("videos", []):
                if isinstance(video, dict) and video.get("url"):
                    download_urls.video.append(video["url"])
                elif isinstance(video, str):
                    download_urls.video.append(video)

            # 确定媒体类型
            media_type = MediaType.IMAGE
            if download_urls.video:
                media_type = MediaType.VIDEO
            elif note_data.get("has_live_photo"):
                media_type = MediaType.LIVE_PHOTO

            # 互动数据
            interaction_stats = note_data.get("interaction_stats", {})

            return MediaInfo(
                platform=Platform.XIAOHONGSHU,
                title=note_data.get("title", ""),
                author=note_data.get("author", {}).get("nickname", ""),
                media_type=media_type,
                note_id=note_data.get("note_id"),
                url=url,
                download_urls=download_urls,
                description=note_data.get("content", ""),
                tags=note_data.get("tags", []),
                resource_count=len(download_urls.images) + len(download_urls.video),
                cover_url=note_data.get("cover_image", {}).get("url") or download_urls.images[0] if download_urls.images else None,
                has_live_photo=note_data.get("has_live_photo", False),
                like_count=interaction_stats.get("like_count", 0),
                collect_count=interaction_stats.get("collect_count", 0),
                comment_count=interaction_stats.get("comment_count", 0),
                share_count=interaction_stats.get("share_count", 0),
                view_count=interaction_stats.get("view_count", 0)
            )
        except Exception as e:
            self.log_error(f"转换笔记数据失败: {e}")
            return None

    # 日志方法
    def log_info(self, message: str):
        if self.logger:
            self.logger.info(f"[XiaohongshuEnhanced] {message}")
        else:
            print(f"INFO: {message}")

    def log_warning(self, message: str):
        if self.logger:
            self.logger.warning(f"[XiaohongshuEnhanced] {message}")
        else:
            print(f"WARNING: {message}")

    def log_error(self, message: str):
        if self.logger:
            self.logger.error(f"[XiaohongshuEnhanced] {message}")
        else:
            print(f"ERROR: {message}")

    def log_debug(self, message: str):
        if self.logger:
            self.logger.debug(f"[XiaohongshuEnhanced] {message}")
        else:
            print(f"DEBUG: {message}")


# 便捷函数
def extract_xiaohongshu_note_sync(url: str) -> XiaohongshuExtractResult:
    """同步版本：提取小红书笔记信息"""
    parser = XiaohongshuEnhancedParser()

    # 使用单个笔记解析器
    if parser.note_parser:
        try:
            media_info = parser.note_parser.parse(url)
            if media_info:
                # 安全地获取 media_type 的值（处理枚举和字符串两种情况）
                media_type_value = media_info.media_type.value if hasattr(media_info.media_type, 'value') else str(media_info.media_type)

                return XiaohongshuExtractResult(
                    success=True,
                    result_type="note",
                    data={
                        "note_id": media_info.note_id,
                        "title": media_info.title,
                        "content": media_info.description or "",  # 添加描述字段
                        "author": {"nickname": media_info.author},
                        "images": [{"url": i} for i in (media_info.download_urls.images or [])],
                        "videos": [{"url": v} for v in (media_info.download_urls.video or [])],
                        "live_photos": [{"url": l} for l in (media_info.download_urls.live or [])],
                        "interaction_stats": {
                            "like_count": media_info.like_count,
                            "collect_count": media_info.collect_count,
                            "comment_count": media_info.comment_count,
                            "share_count": media_info.share_count
                        },
                        "media_type": media_type_value,
                        "source_url": url
                    }
                )
        except Exception as e:
            return XiaohongshuExtractResult(
                success=False,
                result_type="note",
                error_message=str(e)
            )

    return XiaohongshuExtractResult(
        success=False,
        result_type="note",
        error_message="笔记解析功能不可用"
    )


def extract_xiaohongshu_author_sync(url: str, cookie: str = None) -> XiaohongshuExtractResult:
    """同步版本：提取小红书博主资料

    Args:
        url: 用户主页URL
        cookie: 小红书 Cookie（可选）
    """
    parser = XiaohongshuEnhancedParser(cookie=cookie)
    return parser.parse_author_profile_sync(url)


def extract_xiaohongshu_author_notes_sync(
    url: str,
    max_notes: int = None,
    fetch_detail: bool = True,
    cookie: str = None
) -> XiaohongshuExtractResult:
    """同步版本：提取小红书博主所有笔记

    Args:
        url: 用户主页URL
        max_notes: 最大提取笔记数，None表示全部
        fetch_detail: 是否获取每条笔记的详细信息（包括高清图片/视频）
        cookie: 小红书 Cookie（推荐提供，用于获取完整笔记信息）

    注意：
        获取完整的笔记信息（高清图片、视频下载链接）需要提供 Cookie
        获取方式：浏览器 F12 -> Network -> 复制 Request Header 中的 Cookie
    """
    parser = XiaohongshuEnhancedParser(cookie=cookie)
    return parser.parse_author_notes_sync(url, max_notes=max_notes, fetch_detail=fetch_detail)

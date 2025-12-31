#!/usr/bin/env python3
"""
哔哩哔哩增强解析器单元测试
"""

import pytest
import sys
import os

# 添加SDK路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from media_parser_sdk.platforms.bilibili_enhanced import BilibiliEnhancedParser
from media_parser_sdk.models.media_info import Platform, MediaType
from media_parser_sdk.exceptions import ParseError, NetworkError


class TestBilibiliEnhancedParser:
    """哔哩哔哩增强解析器测试类"""

    @pytest.fixture
    def parser(self):
        """创建解析器实例"""
        return BilibiliEnhancedParser()

    def test_is_supported_url_valid(self, parser):
        """测试支持的URL格式"""
        # 标准链接
        assert parser.is_supported_url("https://www.bilibili.com/video/BV1xx411c7mD") is True
        assert parser.is_supported_url("https://bilibili.com/video/av12345") is True

        # 短链接
        assert parser.is_supported_url("https://b23.tv/abc123") is True

        # 不支持的链接
        assert parser.is_supported_url("https://www.youtube.com/watch?v=xxx") is False
        assert parser.is_supported_url("https://www.douyin.com/video/xxx") is False

    def test_extract_video_id_bvid(self, parser):
        """测试从URL中提取BV号"""
        # 标准BV号链接
        result = parser._extract_video_id("https://www.bilibili.com/video/BV1xx411c7mD")
        assert result is not None
        assert result["bvid"] == "BV1xx411c7mD"

        # 包含参数的链接
        result = parser._extract_video_id("https://www.bilibili.com/video/BV1yy411c7XE?p=2")
        assert result is not None
        assert result["bvid"] == "BV1yy411c7XE"

    def test_extract_video_id_avid(self, parser):
        """测试从URL中提取av号"""
        result = parser._extract_video_id("https://www.bilibili.com/video/av12345")
        assert result is not None
        assert result["avid"] == "12345"

    def test_extract_video_id_invalid(self, parser):
        """测试无效URL"""
        result = parser._extract_video_id("https://www.bilibili.com/")
        assert result is None

    def test_quality_map(self, parser):
        """测试清晰度映射"""
        assert parser.QUALITY_MAP["1080P+"] == 116
        assert parser.QUALITY_MAP["1080P"] == 112
        assert parser.QUALITY_MAP["720P"] == 80
        assert parser.QUALITY_MAP["480P"] == 64
        assert parser.QUALITY_MAP["360P"] == 32

    def test_quality_names(self, parser):
        """测试清晰度名称映射"""
        assert parser.QUALITY_NAMES[116] == "1080P+"
        assert parser.QUALITY_NAMES[112] == "1080P"
        assert parser.QUALITY_NAMES[80] == "720P"
        assert parser.QUALITY_NAMES[64] == "480P"
        assert parser.QUALITY_NAMES[32] == "360P"

    def test_get_error_message(self, parser):
        """测试错误码映射"""
        assert "参数错误" in parser._get_error_message(-400)
        assert "不存在" in parser._get_error_message(-404)
        assert "风控" in parser._get_error_message(-412)
        assert "验证码" in parser._get_error_message(-352)
        assert "未登录" in parser._get_error_message(62031)

    def test_validate_url_valid(self, parser):
        """测试URL验证 - 有效URL"""
        # 不应该抛出异常
        parser.validate_url("https://www.bilibili.com/video/BV1xx411c7mD")

    def test_validate_url_invalid(self, parser):
        """测试URL验证 - 无效URL"""
        with pytest.raises(ParseError):
            parser.validate_url("")

        with pytest.raises(ParseError):
            parser.validate_url("not a url")

        with pytest.raises(ParseError):
            parser.validate_url("https://www.youtube.com/watch?v=xxx")

    def test_wbi_signature_generation(self, parser):
        """测试WBI签名生成"""
        params = {
            "bvid": "BV1xx411c7mD",
            "cid": 123456,
            "qn": 112,
        }

        signature = parser._generate_wbi_signature(params)

        # 检查签名包含必要的参数
        assert "bvid" in signature
        assert "cid" in signature
        assert "qn" in signature
        assert "wts" in signature  # 时间戳

        # 注意：w_rid生成依赖于wrid.py模块，如果导入失败，签名可能不包含w_rid
        # 这里只验证基础功能

    def test_clean_filename(self, parser):
        """测试文件名清理"""
        # 继承自BaseParser的方法
        cleaned = parser.clean_filename("视频:测试/标题|file*name?.mp4")
        assert "/" not in cleaned
        assert "\\" not in cleaned
        assert ":" not in cleaned
        assert "|" not in cleaned
        assert "*" not in cleaned
        assert "?" not in cleaned

    def test_platform_detection(self, parser):
        """测试平台检测"""
        # 通过is_supported_url间接测试
        assert parser.is_supported_url("bilibili.com/video/BV1xx411c7mD")
        assert parser.is_supported_url("b23.tv/abc123")


class TestBilibiliIntegration:
    """集成测试 - 需要网络连接"""

    @pytest.fixture
    def parser(self):
        """创建解析器实例"""
        return BilibiliEnhancedParser()

    @pytest.mark.integration
    def test_parse_real_video(self, parser):
        """测试解析真实视频（集成测试）"""
        # 使用一个公开的B站视频链接
        # 注意：这个测试可能会因为网络问题或API变更而失败
        test_url = "https://www.bilibili.com/video/BV1GJ411x7h7"

        try:
            result = parser.parse(test_url)

            # 验证返回结果
            assert result is not None
            assert result.platform == Platform.BILIBILI
            assert result.media_type == MediaType.VIDEO
            assert result.title is not None
            assert result.author is not None
            assert result.note_id is not None

            # 验证统计数据
            assert result.view_count is not None
            assert result.like_count is not None
            assert result.danmaku_count is not None  # 弹幕数
            assert result.coin_count is not None  # 投币数

        except (NetworkError, ParseError) as e:
            # 网络错误或API错误，跳过测试
            pytest.skip(f"网络或API错误: {str(e)}")

    @pytest.mark.integration
    def test_parse_with_cookie(self, parser):
        """测试使用Cookie解析（集成测试）"""
        # 这个测试需要有效的Cookie，通常在CI/CD中跳过
        pytest.skip("需要有效Cookie")

    @pytest.mark.integration
    def test_quality_fallback(self, parser):
        """测试清晰度降级（集成测试）"""
        test_url = "https://www.bilibili.com/video/BV1GJ411x7h7"

        try:
            # 尝试获取1080P+视频
            result = parser.parse(test_url, preferred_quality="1080P+")

            # 如果失败，应该自动降级
            assert result is not None

        except (NetworkError, ParseError) as e:
            pytest.skip(f"网络或API错误: {str(e)}")


if __name__ == "__main__":
    # 运行测试
    pytest.main([__file__, "-v", "-s"])

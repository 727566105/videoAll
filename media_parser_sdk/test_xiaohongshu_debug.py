#!/usr/bin/env python3
"""
小红书链接调试工具

用于诊断小红书链接解析问题，输出详细信息
"""
import sys
import json
import logging

def debug_xiaohongshu_url(url, cookie=None):
    """调试小红书URL"""
    print("=" * 80)
    print("小红书链接调试工具")
    print("=" * 80)
    print(f"URL: {url}")
    print(f"Cookie: {'已提供' if cookie else '未提供'}")
    print()

    # 设置详细日志
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser

    parser = XiaohongshuParser(cookie=cookie)

    try:
        print("开始请求HTML...")
        html = parser._get_html(url)
        print(f"✓ HTML获取成功 (长度: {len(html)})")

        # 检查是否是错误页面
        if "你访问的页面不见了" in html or "页面找不到" in html:
            print("\n⚠️  警告: 获取到错误页面")
            print("   可能原因：")
            print("   1. 笔记已删除或设为私密")
            print("   2. 需要提供有效的 Cookie")
            print("   3. xsec_token 已过期")
            return

        # 提取 INITIAL_STATE
        print("\n提取 window.__INITIAL_STATE__...")
        import re
        initial_state_pattern = re.compile(r'window\.__INITIAL_STATE__\s*=\s*(.+?)(?=</script>)', re.DOTALL)
        initial_state_match = initial_state_pattern.search(html)

        if initial_state_match:
            print("✓ 找到 window.__INITIAL_STATE__")
            initial_state_str = initial_state_match.group(1).strip()
            if initial_state_str.endswith(';'):
                initial_state_str = initial_state_str[:-1]

            # 修复并解析
            try:
                import json
                fixed_str = re.sub(r'\bundefined\b', 'null', initial_state_str)
                fixed_str = re.sub(r',(\s*[}\]])', r'\1', fixed_str)
                initial_state = json.loads(fixed_str)

                print("✓ INITIAL_STATE 解析成功")

                # 输出结构预览
                print("\n数据结构预览:")
                print(f"  顶层键: {list(initial_state.keys())}")

                if "note" in initial_state:
                    note_data = initial_state["note"]
                    print(f"  note 键: {list(note_data.keys())}")

                    # 查找实况图片相关数据
                    def find_live_photos(obj, path=""):
                        """递归查找实况图片数据"""
                        results = []

                        if isinstance(obj, dict):
                            for key, value in obj.items():
                                new_path = f"{path}.{key}" if path else key
                                if "live" in key.lower():
                                    results.append((new_path, value))
                                    print(f"  Found: {new_path} = {type(value)}")
                                elif isinstance(value, (dict, list)):
                                    results.extend(find_live_photos(value, new_path))
                        elif isinstance(obj, list):
                            for i, item in enumerate(obj):
                                if isinstance(item, (dict, list)):
                                    results.extend(find_live_photos(item, f"{path}[{i}]"))

                        return results

                    print("\n搜索实况图片相关字段:")
                    live_photo_data = find_live_photos(initial_state)
                    print(f"  共找到 {len(live_photo_data)} 个可能的实况图片字段")

                    # 保存原始数据用于分析
                    with open("xiaohongshu_debug_initial_state.json", "w", encoding="utf-8") as f:
                        json.dump(initial_state, f, ensure_ascii=False, indent=2)
                    print(f"\n✓ 完整原始数据已保存到 xiaohongshu_debug_initial_state.json")

            except Exception as e:
                print(f"✗ INITIAL_STATE 解析失败: {e}")
                import traceback
                traceback.print_exc()
        else:
            print("✗ 未找到 window.__INITIAL_STATE__")
            print("\n可能的 HTML 内容预览:")
            print(html[:500])

        # 尝试完整解析
        print("\n" + "=" * 80)
        print("尝试完整解析...")
        print("=" * 80)
        try:
            result = parser.parse(url)
            if result:
                print(f"\n✓ 解析成功!")
                print(f"  标题: {result.title}")
                print(f"  作者: {result.author}")
                print(f"  类型: {result.media_type}")
                print(f"  是否有实况: {result.has_live_photo}")
                print(f"  图片数: {len(result.download_urls.images)}")
                print(f"  实况数: {len(result.download_urls.live)}")

                if result.download_urls.live:
                    print(f"\n  🎬 实况图片 URL:")
                    for i, url in enumerate(result.download_urls.live, 1):
                        print(f"    {i}. {url}")

                # 保存解析结果
                with open("xiaohongshu_debug_result.json", "w", encoding="utf-8") as f:
                    json.dump(result.to_dict(), f, ensure_ascii=False, indent=2)
                print(f"\n✓ 解析结果已保存到 xiaohongshu_debug_result.json")
            else:
                print("\n✗ 解析失败: 返回结果为空")
        except Exception as e:
            print(f"\n✗ 解析出错: {e}")
            import traceback
            traceback.print_exc()

    except Exception as e:
        print(f"\n✗ 调试失败: {e}")
        import traceback
        traceback.print_exc()

def main():
    if len(sys.argv) < 2:
        print("使用方法: python test_xiaohongshu_debug.py <URL> [Cookie]")
        print("")
        print("示例:")
        print("  python test_xiaohongshu_debug.py 'https://www.xiaohongshu.com/explore/xxx'")
        print("  python test_xiaohongshu_debug.py 'https://www.xiaohongshu.com/explore/xxx' 'a1=xxx; a2=xxx'")
        sys.exit(1)

    url = sys.argv[1]
    cookie = sys.argv[2] if len(sys.argv) > 2 else None

    debug_xiaohongshu_url(url, cookie)

if __name__ == "__main__":
    main()

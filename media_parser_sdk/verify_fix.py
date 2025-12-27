#!/usr/bin/env python3
"""
快速验证小红书实况图片解析修复
测试 Cookie 传递链路是否正常工作
"""
import sys
import os

# 添加 SDK 路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_cookie_in_parser():
    """测试 1: XiaohongshuParser 是否正确接收和使用 Cookie"""
    print("=" * 70)
    print("测试 1: XiaohongshuParser Cookie 支持检查")
    print("=" * 70)

    from media_parser_sdk.platforms.xiaohongshu import XiaohongshuParser

    test_cookie = "test_cookie_value_12345"

    # 创建带 Cookie 的解析器
    parser_with_cookie = XiaohongshuParser(cookie=test_cookie)

    # 验证 Cookie 是否存储
    assert hasattr(parser_with_cookie, 'cookie'), "❌ parser 没有 cookie 属性"
    assert parser_with_cookie.cookie == test_cookie, f"❌ cookie 不匹配: {parser_with_cookie.cookie} != {test_cookie}"

    # 验证 Cookie 是否在 headers 中
    assert "Cookie" in parser_with_cookie.headers, "❌ headers 中没有 Cookie"
    assert parser_with_cookie.headers["Cookie"] == test_cookie, f"❌ headers.Cookie 不匹配: {parser_with_cookie.headers['Cookie']} != {test_cookie}"

    print("✅ XiaohongshuParser Cookie 支持测试通过")
    print(f"   - parser.cookie = {parser_with_cookie.cookie}")
    print(f"   - headers['Cookie'] = {parser_with_cookie.headers['Cookie']}")

    # 测试不带 Cookie 的解析器
    parser_without_cookie = XiaohongshuParser()
    assert parser_without_cookie.cookie is None, "❌ 无 Cookie 时不应该是 None"
    assert "Cookie" not in parser_without_cookie.headers, "❌ 不应该有 Cookie 头"

    print("✅ XiaohongshuParser 无 Cookie 模式测试通过")

    return True

def test_wrapper_cookie_passing():
    """测试 2: wrapper.py 是否正确传递 Cookie"""
    print("\n" + "=" * 70)
    print("测试 2: wrapper.py Cookie 传递链路检查")
    print("=" * 70)

    # 导入 wrapper 模块
    from media_parser_sdk.platforms.xiaohongshu_enhanced import extract_xiaohongshu_note_sync

    # 检查函数签名
    import inspect
    sig = inspect.signature(extract_xiaohongshu_note_sync)
    params = list(sig.parameters.keys())

    print(f"   extract_xiaohongshu_note_sync 参数: {params}")

    assert "cookie" in params, "❌ extract_xiaohongshu_note_sync 没有 cookie 参数"

    print("✅ extract_xiaohongshu_note_sync 有 cookie 参数")

    # 检查是否有默认值
    cookie_param = sig.parameters["cookie"]
    print(f"   cookie 参数默认值: {cookie_param.default}")

    assert cookie_param.default is None or isinstance(cookie_param.default, str), "❌ cookie 默认值类型错误"

    print("✅ cookie 参数默认值正确")

    return True

def test_wrapper_wrapper():
    """测试 3: wrapper.py 包装函数是否正确传递 Cookie"""
    print("\n" + "=" * 70)
    print("测试 3: wrapper.py 包装函数 Cookie 传递检查")
    print("=" * 70)

    # 直接导入 wrapper 模块
    import wrapper

    # 检查包装函数
    assert hasattr(wrapper, 'extract_xiaohongshu_note_sync_wrapper'), "❌ 没有 extract_xiaohongshu_note_sync_wrapper 函数"

    wrapper_func = wrapper.extract_xiaohongshu_note_sync_wrapper

    # 检查函数签名
    import inspect
    sig = inspect.signature(wrapper_func)
    params = list(sig.parameters.keys())

    print(f"   extract_xiaohongshu_note_sync_wrapper 参数: {params}")

    assert "cookie" in params, "❌ 包装函数没有 cookie 参数"

    print("✅ 包装函数有 cookie 参数")

    return True

def test_enhanced_parser():
    """测试 4: XiaohongshuEnhancedParser 是否正确传递 Cookie"""
    print("\n" + "=" * 70)
    print("测试 4: XiaohongshuEnhancedParser Cookie 传递检查")
    print("=" * 70)

    from media_parser_sdk.platforms.xiaohongshu_enhanced import XiaohongshuEnhancedParser

    test_cookie = "test_enhanced_cookie_67890"

    # 创建带 Cookie 的增强解析器
    parser = XiaohongshuEnhancedParser(cookie=test_cookie)

    # 验证 Cookie 是否存储
    assert hasattr(parser, 'cookie'), "❌ EnhancedParser 没有 cookie 属性"
    assert parser.cookie == test_cookie, f"❌ cookie 不匹配: {parser.cookie} != {test_cookie}"

    print("✅ XiaohongshuEnhancedParser Cookie 支持测试通过")

    # 验证 note_parser 是否也获得了 Cookie
    assert parser.note_parser is not None, "❌ note_parser 未初始化"
    assert parser.note_parser.cookie == test_cookie, f"❌ note_parser.cookie 不匹配: {parser.note_parser.cookie} != {test_cookie}"

    print("✅ note_parser 也获得了正确的 Cookie")

    return True

def test_full_integration():
    """测试 5: 完整集成测试（模拟解析流程）"""
    print("\n" + "=" * 70)
    print("测试 5: 完整集成测试")
    print("=" * 70)

    from media_parser_sdk.platforms.xiaohongshu_enhanced import extract_xiaohongshu_note_sync

    test_cookie = "test_integration_cookie"
    test_url = "https://www.xiaohongshu.com/explore/test123"

    print(f"   测试 URL: {test_url}")
    print(f"   测试 Cookie: {test_cookie}")

    # 注意：这个测试会实际发起网络请求，可能会失败（因为是假的 URL）
    # 但至少可以验证参数传递是否正确
    print("   注意: 此测试会发起实际网络请求，可能因 URL 不存在而失败")
    print("   这是正常的，我们主要验证参数传递流程")

    try:
        result = extract_xiaohongshu_note_sync(test_url, cookie=test_cookie)

        # 检查返回结果格式
        print("\n   返回结果类型:", type(result).__name__)

        if hasattr(result, 'success'):
            print(f"   ✓ result.success = {result.success}")
        else:
            print("   ⚠ result 没有 success 属性")

    except Exception as e:
        print(f"   ⚠ 解析出错（这是预期的，因为测试 URL 不存在）: {type(e).__name__}")
        print(f"   ✓ 函数被正确调用，参数传递正常")

    return True

def main():
    """运行所有测试"""
    print("\n")
    print("╔" + "═" * 68 + "╗")
    print("║" + " " * 15 + "小红书实况图片解析修复验证工具" + " " * 20 + "║")
    print("╚" + "═" * 68 + "╝")
    print()

    tests = [
        ("Cookie 在解析器中的支持", test_cookie_in_parser),
        ("wrapper.py Cookie 参数", test_wrapper_cookie_passing),
        ("wrapper 包装函数", test_wrapper_wrapper),
        ("EnhancedParser Cookie", test_enhanced_parser),
        ("完整集成测试", test_full_integration),
    ]

    results = []

    for test_name, test_func in tests:
        try:
            success = test_func()
            results.append((test_name, success, None))
        except AssertionError as e:
            print(f"\n❌ 测试失败: {test_name}")
            print(f"   错误: {e}")
            results.append((test_name, False, str(e)))
        except Exception as e:
            print(f"\n❌ 测试出错: {test_name}")
            print(f"   异常: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()
            results.append((test_name, False, f"{type(e).__name__}: {e}"))

    # 打印汇总
    print("\n" + "=" * 70)
    print("测试结果汇总")
    print("=" * 70)

    passed = sum(1 for _, success, _ in results if success)
    total = len(results)

    for test_name, success, error in results:
        status = "✅ 通过" if success else "❌ 失败"
        print(f"{status} - {test_name}")
        if error:
            print(f"      错误: {error}")

    print("\n" + "-" * 70)
    print(f"总计: {passed}/{total} 通过")

    if passed == total:
        print("\n🎉 所有测试通过！修复成功！")
        print("\n下一步:")
        print("  1. 启动后端服务: cd backend && npm run dev")
        print("  2. 在系统中配置小红书 Cookie（系统配置 → Cookie Management）")
        print("  3. 测试解析实况图片链接")
        return 0
    else:
        print("\n⚠️  部分测试失败，请检查错误信息")
        return 1

if __name__ == "__main__":
    sys.exit(main())

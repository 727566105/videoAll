#!/usr/bin/env node
/**
 * 抖音Cookie调试工具
 * 用于诊断Cookie测试失败的具体原因
 */

const axios = require('axios');

// 从命令行参数获取Cookie
const cookie = process.argv[2];

if (!cookie) {
  console.log('❌ 错误: 请提供Cookie作为参数');
  console.log('\n用法:');
  console.log('  node debug-douyin-cookie.js "你的Cookie字符串"');
  console.log('\n示例:');
  console.log('  node debug-douyin-cookie.js "sessionid=xxx; sessionid_ss=xxx; ttwid=xxx"');
  process.exit(1);
}

console.log('='.repeat(70));
console.log('抖音Cookie调试工具');
console.log('='.repeat(70));
console.log(`\n测试Cookie: ${cookie.substring(0, 50)}...`);
console.log();

// 测试配置
const tests = [
  {
    name: '测试1: 个人信息API（原测试）',
    url: 'https://www.douyin.com/aweme/v1/web/aweme/personal/',
    expected: 'status_code',
    method: 'GET'
  },
  {
    name: '测试2: 用户信息API',
    url: 'https://www.douyin.com/aweme/v1/web/aweme/detail/?aweme_id=7587637524178554161',
    expected: 'aweme_detail',
    method: 'GET'
  },
  {
    name: '测试3: 首页API',
    url: 'https://www.douyin.com/',
    expected: 'RENDER_DATA',
    method: 'GET'
  }
];

// 运行所有测试
async function runAllTests() {
  const headers = {
    'Cookie': cookie,
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Referer': 'https://www.douyin.com/'
  };

  for (const test of tests) {
    console.log('-'.repeat(70));
    console.log(test.name);
    console.log('-'.repeat(70));
    console.log(`URL: ${test.url}`);

    try {
      const response = await axios.get(test.url, {
        headers,
        timeout: 10000,
        validateStatus: () => true, // 不抛出HTTP错误
        maxRedirects: 5 // 允许重定向
      });

      console.log(`状态码: ${response.status}`);
      console.log(`Content-Type: ${response.headers['content-type']}`);

      // 分析响应内容
      const responseText = typeof response.data === 'string' ? response.data : JSON.stringify(response.data);

      // 检查是否包含预期内容
      const hasExpected = responseText.includes(test.expected);
      console.log(`预期内容 "${test.expected}": ${hasExpected ? '✓ 找到' : '✗ 未找到'}`);

      // 显示响应的前500个字符
      console.log(`\n响应内容预览:`);
      console.log(responseText.substring(0, 500));

      // 检查是否是验证页面
      if (responseText.includes('验证') || responseText.includes('verification')) {
        console.log('\n⚠️ 检测到验证页面，Cookie可能无效或IP被封禁');
      }

      // 检查是否包含错误信息
      if (responseText.includes('error') || responseText.includes('错误')) {
        console.log('\n⚠️ 响应包含错误信息');
      }

      // 判断测试结果
      if (response.status === 200 && hasExpected) {
        console.log('\n✅ 测试通过 - Cookie有效');
      } else if (response.status === 200) {
        console.log('\n⚠️ 状态码正常但未找到预期内容');
      } else {
        console.log(`\n❌ 测试失败 - HTTP ${response.status}`);
      }

    } catch (error) {
      console.log(`\n❌ 请求失败: ${error.message}`);
      if (error.code === 'ECONNREFUSED') {
        console.log('提示: 网络连接被拒绝，请检查网络');
      } else if (error.code === 'ETIMEDOUT') {
        console.log('提示: 请求超时，可能是网络问题或服务器响应慢');
      }
    }

    console.log();
  }

  // Cookie格式分析
  console.log('='.repeat(70));
  console.log('Cookie格式分析');
  console.log('='.repeat(70));

  const cookieParts = cookie.split(';').map(p => p.trim());
  console.log(`\nCookie包含 ${cookieParts.length} 个字段:`);

  const importantFields = ['sessionid', 'sessionid_ss', 'ttwid', 'passport_csrf_token', '__ac_nonce', '__ac_signature'];

  cookieParts.forEach((part, index) => {
    const [name, value] = part.split('=');
    const isImportant = importantFields.some(field => name.includes(field));
    const marker = isImportant ? ' ⭐' : '';
    const valuePreview = value ? `${value.substring(0, 20)}...` : '(空)';
    console.log(`  ${index + 1}. ${name}${marker}: ${valuePreview}`);
  });

  // 检查关键字段
  console.log('\n关键字段检查:');
  importantFields.forEach(field => {
    const hasField = cookieParts.some(part => part.startsWith(field));
    console.log(`  ${hasField ? '✓' : '✗'} ${field}`);
  });

  // 建议
  console.log('\n' + '='.repeat(70));
  console.log('建议');
  console.log('='.repeat(70));
  console.log(`
1. 如果所有测试都失败:
   - Cookie可能已过期，请重新获取
   - Cookie格式可能不完整，确保复制完整的Cookie字符串
   - IP可能被抖音标记，尝试更换网络环境

2. 如果Cookie格式检查缺少关键字段:
   - 确保登录了抖音账号
   - 在浏览器开发者工具中找到完整的Cookie
   - 尝试使用移动版抖音网站获取Cookie

3. 如果测试2或3通过但测试1失败:
   - 这是正常的，Cookie仍然可用
   - 原测试URL可能需要额外参数

4. Cookie通常有效期7-30天，需要定期更新
  `);

  console.log('\n调试完成！');
  console.log('='.repeat(70));
}

// 运行测试
runAllTests().catch(error => {
  console.error('调试工具运行失败:', error);
  process.exit(1);
});

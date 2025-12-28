/**
 * 测试提供商API
 */
const fetch = require('node-fetch');

async function testProvidersAPI() {
  try {
    // 1. 不带token调用（应该失败）
    console.log('测试1: 不带token调用 /meta/providers');
    const res1 = await fetch('http://localhost:3000/api/v1/ai-config/meta/providers');
    console.log('状态:', res1.status);
    const data1 = await res1.json();
    console.log('响应:', JSON.stringify(data1, null, 2));
    console.log('');

    // 2. 先登录获取token
    console.log('测试2: 登录获取token');
    const loginRes = await fetch('http://localhost:3000/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'yangzai',
        password: 'yangzai'
      })
    });

    const loginData = await loginRes.json();
    console.log('登录响应:', JSON.stringify(loginData, null, 2));

    if (!loginData.success || !loginData.data || !loginData.data.token) {
      console.log('\n❌ 登录失败，无法继续测试');
      return;
    }

    const token = loginData.data.token;
    console.log('');

    // 3. 带token调用提供商API
    console.log('测试3: 带token调用 /meta/providers');
    const res2 = await fetch('http://localhost:3000/api/v1/ai-config/meta/providers', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log('状态:', res2.status);
    const data2 = await res2.json();
    console.log('响应:', JSON.stringify(data2, null, 2));

    if (data2.success && data2.data) {
      console.log('\n✅ 成功！提供商数量:', data2.data.length);
      console.log('\n提供商列表:');
      data2.data.forEach(p => {
        console.log(`  - ${p.name} (${p.id})`);
      });
    }
  } catch (error) {
    console.error('❌ 错误:', error.message);
  }
}

testProvidersAPI();

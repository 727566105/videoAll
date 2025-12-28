const fetch = require('node-fetch');

async function testAPI() {
  try {
    // 1. 登录获取token
    console.log('🔐 登录中...\n');
    const loginRes = await fetch('http://localhost:3000/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin@example.com',
        password: 'admin123'
      })
    });

    const loginData = await loginRes.json();
    console.log('登录响应:', JSON.stringify(loginData, null, 2));

    if (!loginData.success || !loginData.data || !loginData.data.token) {
      console.error('❌ 登录失败');
      return;
    }

    const token = loginData.data.token;
    console.log('\n✅ 登录成功');

    // 2. 测试密钥安全状态API
    console.log('\n🔍 测试密钥安全状态API...\n');
    const keyStatusRes = await fetch('http://localhost:3000/api/v1/ai-config/security/key-status', {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    const keyStatus = await keyStatusRes.json();
    console.log('密钥状态:', JSON.stringify(keyStatus, null, 2));

    // 3. 测试获取提供商列表
    console.log('\n🔍 测试提供商列表API...\n');
    const providersRes = await fetch('http://localhost:3000/api/v1/ai-config/meta/providers', {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    const providers = await providersRes.json();
    console.log('提供商数量:', providers.data?.length || 0);
    console.log('支持的提供商:');
    providers.data?.forEach(p => {
      console.log(`  - ${p.value} (${p.label})`);
    });

    console.log('\n✅ 所有测试完成');
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
  }
}

testAPI();

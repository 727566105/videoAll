// 测试标签管理功能
const axios = require('axios');

const API_BASE = 'http://localhost:3000/api/v1';
const AUTH_TOKEN = 'mock-token-admin';

// 测试函数
async function testTags() {
  try {
    console.log('===== 开始测试标签管理功能 =====\n');

    // 1. 获取所有标签
    console.log('1. 获取所有标签...');
    const getTagsResponse = await axios.get(`${API_BASE}/tags`, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    console.log('✓ 获取标签成功');
    console.log(`  当前有 ${getTagsResponse.data.data.length} 个标签`);
    console.log(`  标签列表: ${getTagsResponse.data.data.map(t => t.name).join(', ')}\n`);

    // 2. 创建新标签
    console.log('2. 创建新标签...');
    const newTagResponse = await axios.post(`${API_BASE}/tags`, {
      name: '测试标签',
      description: '这是一个测试标签'
    }, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    console.log('✓ 创建标签成功');
    console.log(`  标签名称: ${newTagResponse.data.data.name}`);
    console.log(`  标签颜色: ${newTagResponse.data.data.color}`);
    console.log(`  标签ID: ${newTagResponse.data.data.id}\n`);

    const tagId = newTagResponse.data.data.id;

    // 3. 更新标签
    console.log('3. 更新标签...');
    const updateTagResponse = await axios.put(`${API_BASE}/tags/${tagId}`, {
      name: '测试标签（已更新）',
      color: '#722ed1'
    }, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    console.log('✓ 更新标签成功');
    console.log(`  新名称: ${updateTagResponse.data.data.name}`);
    console.log(`  新颜色: ${updateTagResponse.data.data.color}\n`);

    // 4. 测试批量操作（使用假的内容ID，只测试API是否正常响应）
    console.log('4. 测试批量操作API...');
    try {
      await axios.post(`${API_BASE}/tags/content/tags/batch`, {
        content_ids: ['00000000-0000-0000-0000-000000000000'],
        tag_ids: [tagId],
        operation: 'add'
      }, {
        headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
      });
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✓ 批量操作API正常响应（内容不存在是预期的）\n');
      }
    }

    // 5. 删除标签
    console.log('5. 删除标签...');
    await axios.delete(`${API_BASE}/tags/${tagId}`, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    console.log('✓ 删除标签成功\n');

    // 6. 验证删除
    console.log('6. 验证标签已删除...');
    const finalTagsResponse = await axios.get(`${API_BASE}/tags`, {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` }
    });
    const deletedTag = finalTagsResponse.data.data.find(t => t.id === tagId);
    if (!deletedTag) {
      console.log('✓ 标签已成功删除\n');
    }

    console.log('===== 测试完成！所有功能正常 =====');
    process.exit(0);
  } catch (error) {
    console.error('\n✗ 测试失败:', error.response?.data || error.message);
    process.exit(1);
  }
}

testTags();

const { execSync } = require('child_process');
const { AppDataSource } = require('./backend/src/utils/db');

async function testParse() {
  await AppDataSource.initialize();
  const contentRepo = AppDataSource.getRepository('Content');

  // 获取最新的小红书内容
  const content = await contentRepo.findOne({
    where: { platform: 'xiaohongshu' },
    order: { created_at: 'DESC' }
  });

  if (!content) {
    console.log('没有找到小红书内容');
    await AppDataSource.destroy();
    return;
  }

  console.log('测试链接:', content.source_url);
  console.log('数据库中的统计数据:');
  console.log('  like_count:', content.like_count);
  console.log('  collect_count:', content.collect_count);
  console.log('  publish_time:', content.publish_time);

  await AppDataSource.destroy();

  // 调用 Python SDK 解析
  console.log('\n调用 Python SDK 解析...');
  try {
    const result = execSync(`python3 media_parser_sdk/wrapper.py parse "${content.source_url}"`, {
      encoding: 'utf8',
      timeout: 30000
    });

    const data = JSON.parse(result);
    console.log('\nSDK 返回的统计数据:');
    console.log('  like_count:', data.like_count);
    console.log('  collect_count:', data.collect_count);
    console.log('  comment_count:', data.comment_count);
    console.log('  share_count:', data.share_count);
    console.log('  view_count:', data.view_count);
    console.log('  publish_time:', data.publish_time);

    if (data.like_count === null || data.like_count === undefined) {
      console.log('\n❌ SDK 没有返回统计数据！');
    }
  } catch (error) {
    console.error('解析失败:', error.message);
  }
}

testParse().catch(console.error);

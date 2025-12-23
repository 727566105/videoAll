const { execSync } = require('child_process');

// 测试几个小红书链接
const testUrls = [
  'https://www.xiaohongshu.com/explore/6754051d0000000012006887',
  'https://www.xiaohongshu.com/explore/6751e8b0000000001203ee58'
];

async function testParse(url) {
  console.log('\n========================================');
  console.log('测试链接:', url);
  console.log('========================================');

  try {
    const result = execSync(`python3 media_parser_sdk/wrapper.py parse "${url}"`, {
      encoding: 'utf8',
      timeout: 30000,
      cwd: '/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll'
    });

    const data = JSON.parse(result);

    console.log('\n✅ 解析成功！');
    console.log('标题:', data.title);
    console.log('作者:', data.author);
    console.log('媒体类型:', data.media_type);

    console.log('\n📊 统计数据:');
    console.log('  like_count:', data.like_count);
    console.log('  collect_count:', data.collect_count);
    console.log('  comment_count:', data.comment_count);
    console.log('  share_count:', data.share_count);
    console.log('  view_count:', data.view_count);

    console.log('\n⏰ 时间数据:');
    console.log('  publish_time:', data.publish_time);

    // 检查是否有统计数据
    const hasStats = data.like_count !== null && data.like_count !== undefined &&
                      data.collect_count !== null && data.collect_count !== undefined;

    if (!hasStats) {
      console.log('\n❌ 问题：SDK 没有返回统计数据！');
    } else if (data.like_count === 0 && data.collect_count === 0) {
      console.log('\n⚠️  警告：统计数据都是 0，可能是：');
      console.log('    1. 链接确实没有互动数据');
      console.log('    2. SDK 提取逻辑有问题');
    } else {
      console.log('\n✅ 统计数据正常！');
    }

  } catch (error) {
    console.error('\n❌ 解析失败:', error.message);
  }
}

async function main() {
  for (const url of testUrls) {
    await testParse(url);
  }
}

main().catch(console.error);

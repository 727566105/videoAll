const { execSync } = require('child_process');

const testUrl = 'https://www.xiaohongshu.com/user/profile/67fdd54d000000000a03f27b/69421f8f000000001b0337f8?xsec_token=ABuUN8WdK15ZUt4kkqr0s4Wc0CNEoeHnWCalxsftOn2ok=&xsec_source=pc_user';

console.log('测试用户主页链接:');
console.log(testUrl);
console.log('\n这个链接格式是: /user/profile/用户ID/笔记ID\n');

try {
  const result = execSync(`python3 media_parser_sdk/wrapper.py parse "${testUrl}"`, {
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

  console.log('\n🔗 媒体资源:');
  console.log('  视频数:', data.download_urls?.video?.length || 0);
  console.log('  图片数:', data.download_urls?.images?.length || 0);

} catch (error) {
  console.error('\n❌ 解析失败:', error.message);
}

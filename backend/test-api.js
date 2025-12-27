const { AppDataSource } = require('./src/utils/db');

async function testDownloadSettingsController() {
  try {
    console.log('开始测试下载设置API...\n');

    // 连接数据库
    await AppDataSource.initialize();
    console.log('✓ 数据库连接成功');

    // 模拟控制器逻辑
    const PlatformCookie = AppDataSource.getRepository('PlatformCookie');

    console.log('\n执行查询...');
    const cookies = await PlatformCookie.find({
      where: { is_valid: true },
      order: { platform: 'ASC', created_at: 'DESC' }
    });

    console.log(`✓ 查询成功，返回 ${cookies.length} 条记录`);

    // 聚合设置
    const platformSettings = {};
    const seenPlatforms = new Set();

    cookies.forEach(cookie => {
      if (!seenPlatforms.has(cookie.platform)) {
        seenPlatforms.add(cookie.platform);

        if (cookie.preferences && cookie.preferences[cookie.platform]) {
          platformSettings[cookie.platform] = cookie.preferences[cookie.platform];
        } else {
          platformSettings[cookie.platform] = {
            preferred_quality: '1080P',
            auto_fallback: true
          };
        }
      }
    });

    console.log('\n✓ 聚合成功');
    console.log('返回数据:', JSON.stringify({
      message: '获取下载设置成功',
      data: platformSettings
    }, null, 2));

    await AppDataSource.destroy();
    console.log('\n✓ 测试完成');
    process.exit(0);
  } catch (error) {
    console.error('\n✗ 错误:', error.message);
    console.error('堆栈:', error.stack);
    process.exit(1);
  }
}

testDownloadSettingsController();

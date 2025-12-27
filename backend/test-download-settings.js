const { AppDataSource } = require('./src/utils/db');

async function testDownloadSettings() {
  try {
    console.log('开始测试...\n');

    // 连接数据库
    await AppDataSource.initialize();
    console.log('✓ 数据库连接成功');

    // 查询平台Cookie
    const PlatformCookie = AppDataSource.getRepository('PlatformCookie');
    const cookies = await PlatformCookie.find({
      where: { is_valid: true },
      order: { platform: 'ASC', created_at: 'DESC' }
    });

    console.log(`\n✓ 查询到 ${cookies.length} 个有效的Cookie配置`);

    // 聚合设置
    const platformSettings = {};
    const seenPlatforms = new Set();

    cookies.forEach(cookie => {
      if (!seenPlatforms.has(cookie.platform)) {
        seenPlatforms.add(cookie.platform);
        console.log(`\n平台: ${cookie.platform}`);
        console.log(`  preferences: ${JSON.stringify(cookie.preferences)}`);

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

    console.log(`\n✓ 最终设置: ${JSON.stringify(platformSettings, null, 2)}`);

    await AppDataSource.destroy();
    console.log('\n✓ 测试完成');
  } catch (error) {
    console.error('\n✗ 错误:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

testDownloadSettings();

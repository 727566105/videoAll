#!/usr/bin/env node
/**
 * 抖音Cookie自动获取工具
 * 使用Puppeteer自动化浏览器，快速获取抖音Cookie
 *
 * 用法:
 *   node get-douyin-cookie.js
 *   node get-douyin-cookie.js --headless    # 无头模式（不显示浏览器窗口）
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  douyinUrl: 'https://www.douyin.com',
  timeout: 60000, // 60秒超时
  waitTime: 5000, // 等待5秒让页面加载完成
  headless: false, // 默认显示浏览器窗口
  outputFile: path.join(__dirname, 'douyin-cookie.txt')
};

// 解析命令行参数
const args = process.argv.slice(2);
if (args.includes('--headless')) {
  CONFIG.headless = true;
}
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
抖音Cookie自动获取工具

用法:
  node get-douyin-cookie.js                # 显示浏览器窗口（推荐）
  node get-douyin-cookie.js --headless     # 无头模式
  node get-douyin-cookie.js --help         # 显示帮助

说明:
  1. 脚本会自动打开抖音网站
  2. 请在30秒内完成扫码登录
  3. 登录成功后，脚本会自动获取Cookie
  4. Cookie会保存到 douyin-cookie.txt 文件中

注意事项:
  - 首次使用建议使用默认模式（显示浏览器窗口）
  - 请确保在30秒内完成登录，否则会超时
  - Cookie有效期通常为7-30天
  - 建议使用小号登录，避免主号风险
  `);
  process.exit(0);
}

/**
 * 获取抖音Cookie
 */
async function getDouyinCookie() {
  console.log('='.repeat(70));
  console.log('抖音Cookie自动获取工具');
  console.log('='.repeat(70));
  console.log(`
模式: ${CONFIG.headless ? '无头模式' : '显示浏览器窗口'}
超时: ${CONFIG.timeout / 1000}秒
输出: ${CONFIG.outputFile}
  `);

  let browser;
  try {
    // 启动浏览器
    console.log('🚀 正在启动浏览器...');
    browser = await puppeteer.launch({
      headless: CONFIG.headless,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process'
      ]
    });

    const page = await browser.newPage();

    // 设置视口大小
    await page.setViewport({
      width: 1280,
      height: 800,
      isMobile: false
    });

    // 设置User-Agent
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    console.log('✓ 浏览器启动成功');
    console.log('🌐 正在打开抖音网站...');

    // 访问抖音网站
    await page.goto(CONFIG.douyinUrl, {
      waitUntil: 'networkidle2',
      timeout: CONFIG.timeout
    });

    console.log('✓ 抖音网站已打开');
    console.log('\n' + '='.repeat(70));
    console.log('⚠️  请在浏览器中完成扫码登录（30秒内）');
    console.log('='.repeat(70));
    console.log(`
提示:
  - 使用抖音APP扫描页面上的二维码
  - 确认登录
  - 等待页面跳转到首页
    `);

    // 等待用户登录（检测URL变化或特定元素）
    console.log('⏳ 等待登录完成...\n');

    // 等待页面加载完成
    await page.waitForTimeout(CONFIG.waitTime);

    // 尝试检测是否登录成功
    let isLoggedIn = false;
    let attempts = 0;
    const maxAttempts = 6; // 最多等待30秒

    while (!isLoggedIn && attempts < maxAttempts) {
      attempts++;

      try {
        // 检查是否有登录按钮（未登录状态）
        const loginButton = await page.$('.login-btn');

        if (!loginButton) {
          // 没有登录按钮，可能已经登录
          // 检查是否有用户信息元素
          const userInfo = await page.$('.user-info, .avatar, [data-e2e="nav-user-header"]');

          if (userInfo || attempts >= 3) {
            isLoggedIn = true;
            console.log('✅ 检测到登录成功！');
          }
        } else {
          if (attempts < maxAttempts) {
            console.log(`⏳ 等待登录... (${attempts * 5}s)`);
            await page.waitForTimeout(5000);
          }
        }
      } catch (error) {
        // 忽略错误，继续等待
        if (attempts < maxAttempts) {
          await page.waitForTimeout(5000);
        }
      }
    }

    if (!isLoggedIn) {
      console.log('\n⚠️  未能自动检测登录状态，继续获取Cookie...');
    }

    // 等待额外时间确保Cookie完全加载
    await page.waitForTimeout(3000);

    // 获取Cookie
    console.log('\n🍪 正在获取Cookie...');
    const cookies = await page.cookies();

    // 转换为Cookie字符串格式
    const cookieString = cookies
      .map(cookie => {
        let str = `${cookie.name}=${cookie.value}`;
        if (cookie.domain) str += `; Domain=${cookie.domain}`;
        if (cookie.path) str += `; Path=${cookie.path}`;
        if (cookie.httpOnly) str += '; HttpOnly';
        if (cookie.secure) str += '; Secure';
        if (cookie.sameSite) str += `; SameSite=${cookie.sameSite}`;
        return str;
      })
      .join('; ');

    // 只获取名称和值的简化格式（更适合配置到系统）
    const simplifiedCookieString = cookies
      .map(cookie => `${cookie.name}=${cookie.value}`)
      .join('; ');

    console.log(`✓ 成功获取 ${cookies.length} 个Cookie`);

    // 显示关键字段
    console.log('\n关键字段:');
    const importantFields = ['sessionid', 'sessionid_ss', 'ttwid', 'passport_csrf_token', '__ac_nonce', '__ac_signature'];

    importantFields.forEach(field => {
      const found = cookies.find(c => c.name.includes(field));
      if (found) {
        const valuePreview = found.value ? `${found.value.substring(0, 15)}...` : '(空)';
        console.log(`  ✓ ${field}: ${valuePreview}`);
      } else {
        console.log(`  ✗ ${field}: 未找到`);
      }
    });

    // 保存到文件
    fs.writeFileSync(CONFIG.outputFile, simplifiedCookieString, 'utf8');
    console.log(`\n✓ Cookie已保存到: ${CONFIG.outputFile}`);

    // 显示Cookie预览
    console.log('\nCookie预览（前200字符）:');
    console.log(simplifiedCookieString.substring(0, 200) + '...');

    console.log('\n' + '='.repeat(70));
    console.log('✅ Cookie获取完成！');
    console.log('='.repeat(70));
    console.log(`
下一步:
  1. 复制 ${CONFIG.outputFile} 中的Cookie
  2. 访问 http://localhost:5173/config
  3. 切换到"平台账号配置"标签
  4. 点击"添加Cookie"
  5. 平台选择"抖音"
  6. 粘贴Cookie
  7. 点击"保存"

命令行快速配置:
  cat douyin-cookie.txt | pbcopy  # Mac复制到剪贴板
  type douyin-cookie.txt | clip   # Windows复制到剪贴板
    `);

    // 关闭浏览器
    console.log('\n⏳ 3秒后自动关闭浏览器...');
    await page.waitForTimeout(3000);
    await browser.close();

    return simplifiedCookieString;

  } catch (error) {
    console.error('\n❌ 获取Cookie失败:', error.message);

    if (error.message.includes('timeout')) {
      console.log('\n提示: 登录超时，请重试并确保在30秒内完成登录');
    }

    if (browser) {
      await browser.close();
    }

    process.exit(1);
  }
}

// 运行
getDouyinCookie().catch(error => {
  console.error('脚本运行失败:', error);
  process.exit(1);
});

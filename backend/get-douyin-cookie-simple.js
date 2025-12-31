#!/usr/bin/env node
/**
 * 抖音Cookie快速获取脚本（简化版）
 * 使用系统Chrome浏览器，更稳定
 *
 * 用法:
 *   node get-douyin-cookie-simple.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  douyinUrl: 'https://www.douyin.com',
  timeout: 90000, // 90秒超时
  outputFile: path.join(__dirname, 'douyin-cookie.txt')
};

/**
 * 获取抖音Cookie
 */
async function getDouyinCookie() {
  console.log('='.repeat(70));
  console.log('抖音Cookie快速获取工具');
  console.log('='.repeat(70));
  console.log(`
说明:
  1. 脚本会自动打开Chrome浏览器
  2. 请在浏览器中扫码登录抖音
  3. 登录后按回车键继续，或等待60秒自动继续
  4. Cookie将自动保存到文件
  `);

  let browser;
  try {
    // 查找系统Chrome路径
    let executablePath = undefined;

    // macOS Chrome路径
    const macChromePaths = [
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Chromium.app/Contents/MacOS/Chromium'
    ];

    // 检查Chrome是否存在
    for (const chromePath of macChromePaths) {
      if (fs.existsSync(chromePath)) {
        executablePath = chromePath;
        console.log(`✓ 找到Chrome: ${chromePath}`);
        break;
      }
    }

    // 启动浏览器配置
    const launchOptions = {
      headless: false,
      executablePath,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-blink-features=AutomationControlled'
      ],
      defaultViewport: {
        width: 1280,
        height: 800,
        isMobile: false
      }
    };

    console.log('🚀 正在启动Chrome浏览器...\n');

    browser = await puppeteer.launch(launchOptions);
    const page = await browser.newPage();

    // 设置User-Agent，避免被检测为机器人
    await page.setUserAgent(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // 设置额外的HTTP头
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    });

    console.log('✓ 浏览器启动成功');
    console.log('🌐 正在打开抖音网站...\n');

    // 访问抖音
    await page.goto(CONFIG.douyinUrl, {
      waitUntil: 'networkidle2',
      timeout: CONFIG.timeout
    });

    console.log('✓ 抖音网站已打开');
    console.log('\n' + '='.repeat(70));
    console.log('⚠️  请在浏览器中完成扫码登录');
    console.log('='.repeat(70));
    console.log(`
提示:
  - 使用抖音APP扫描页面上的二维码
  - 确认登录
  - 登录成功后，脚本会自动继续（60秒后自动继续）
    `);

    console.log('⏳ 等待登录...\n');

    // 等待60秒让用户登录
    await page.waitForTimeout(60000);

    // 再次访问确保Cookie完全加载
    console.log('🔄 刷新页面以确保Cookie完全加载...');
    await page.reload({ waitUntil: 'networkidle2', timeout: CONFIG.timeout });
    await page.waitForTimeout(3000);

    // 获取Cookie
    console.log('\n🍪 正在获取Cookie...\n');

    const cookies = await page.cookies();

    if (cookies.length === 0) {
      throw new Error('未获取到任何Cookie，请确保已登录');
    }

    // 转换为简化格式（名称=值; 名称=值）
    const cookieString = cookies
      .map(cookie => `${cookie.name}=${cookie.value}`)
      .join('; ');

    console.log(`✓ 成功获取 ${cookies.length} 个Cookie\n`);

    // 显示关键字段
    console.log('关键字段检查:');
    const importantFields = [
      'sessionid',
      'sessionid_ss',
      'ttwid',
      'passport_csrf_token',
      '__ac_nonce',
      '__ac_signature'
    ];

    let foundImportantCount = 0;
    importantFields.forEach(field => {
      const found = cookies.find(c => c.name === field || c.name.includes(field));
      if (found) {
        foundImportantCount++;
        const valuePreview = found.value ? `${found.value.substring(0, 12)}...` : '(空)';
        console.log(`  ✓ ${field}: ${valuePreview}`);
      } else {
        console.log(`  ⚠ ${field}: 未找到`);
      }
    });

    // 保存到文件
    fs.writeFileSync(CONFIG.outputFile, cookieString, 'utf8');
    console.log(`\n✓ Cookie已保存到: ${CONFIG.outputFile}`);

    // 显示Cookie预览
    console.log('\nCookie预览（前150字符）:');
    console.log(cookieString.substring(0, 150) + '...\n');

    // 检查关键字段数量
    if (foundImportantCount < 3) {
      console.log('⚠️  警告: 关键字段较少，Cookie可能不完整');
      console.log('   建议: 重新获取并确保完成登录\n');
    } else {
      console.log('✅ Cookie质量良好！');
    }

    console.log('\n' + '='.repeat(70));
    console.log('✅ Cookie获取完成！');
    console.log('='.repeat(70));

    // 显示下一步操作
    console.log(`
下一步操作:

1️⃣  复制Cookie到剪贴板:
   cat douyin-cookie.txt | pbcopy

2️⃣  访问配置页面:
   http://localhost:5173/config

3️⃣  添加Cookie:
   - 切换到"平台账号配置"标签
   - 点击"添加Cookie"
   - 平台选择"抖音"
   - 粘贴Cookie
   - 点击"保存"

4️⃣  测试解析:
   访问 http://localhost:5173/parsing
   输入抖音视频链接测试
    `);

    console.log('\n⏳ 5秒后自动关闭浏览器...');
    await page.waitForTimeout(5000);

    await browser.close();
    console.log('✓ 浏览器已关闭\n');

    // 自动复制到剪贴板（Mac）
    try {
      const { execSync } = require('child_process');
      execSync(`cat "${CONFIG.outputFile}" | pbcopy`);
      console.log('✅ Cookie已自动复制到剪贴板！');
      console.log('   直接粘贴到配置页面即可\n');
    } catch (error) {
      console.log('提示: 可以手动运行以下命令复制Cookie:');
      console.log('  cat douyin-cookie.txt | pbcopy\n');
    }

    return cookieString;

  } catch (error) {
    console.error('\n❌ 获取Cookie失败:', error.message);

    if (error.message.includes('net::ERR_CONNECTION_REFUSED')) {
      console.log('\n提示: 无法连接到抖音，请检查网络连接');
    } else if (error.message.includes('timeout')) {
      console.log('\n提示: 页面加载超时，请重试');
    } else if (error.message.includes('Failed to launch')) {
      console.log('\n提示: Chrome浏览器启动失败');
      console.log('   请确保已安装Chrome浏览器');
      console.log('   或使用手动方式获取Cookie（见下方）');
    }

    if (browser) {
      try {
        await browser.close();
      } catch (e) {
        // 忽略关闭错误
      }
    }

    console.log('\n' + '='.repeat(70));
    console.log('备选方案: 手动获取Cookie');
    console.log('='.repeat(70));
    console.log(`
1. 打开Chrome浏览器
2. 访问 https://www.douyin.com
3. 登录抖音账号
4. 按F12打开开发者工具
5. 切换到Network标签
6. 刷新页面
7. 点击任意请求
8. 在Headers中找到Cookie并复制
9. 访问 http://localhost:5173/config 配置Cookie
    `);

    process.exit(1);
  }
}

// 运行
getDouyinCookie().catch(error => {
  console.error('脚本运行失败:', error);
  process.exit(1);
});

const puppeteer = require('puppeteer');

/**
 * Cookie自动获取服务
 * 使用Puppeteer自动化浏览器获取平台Cookie
 */
class CookieAutoFetchService {
  /**
   * 获取抖音Cookie
   * @param {Object} options - 配置选项
   * @param {number} options.timeout - 超时时间（毫秒），默认60000
   * @param {boolean} options.headless - 是否使用无头模式，默认false
   * @returns {Promise<string>} Cookie字符串
   */
  static async getDouyinCookie(options = {}) {
    const {
      timeout = 60000,
      headless = false
    } = options;

    let browser;

    try {
      // 查找系统Chrome路径
      let executablePath = undefined;

      const macChromePaths = [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Chromium.app/Contents/MacOS/Chromium'
      ];

      for (const chromePath of macChromePaths) {
        const fs = require('fs');
        if (fs.existsSync(chromePath)) {
          executablePath = chromePath;
          break;
        }
      }

      // 启动浏览器
      browser = await puppeteer.launch({
        headless,
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
      });

      const page = await browser.newPage();

      // 设置User-Agent
      await page.setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      );

      // 设置额外的HTTP头
      await page.setExtraHTTPHeaders({
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      });

      // 访问抖音
      await page.goto('https://www.douyin.com', {
        waitUntil: 'networkidle2',
        timeout
      });

      // 等待用户登录
      await page.waitForTimeout(60000);

      // 刷新页面确保Cookie完全加载
      await page.reload({ waitUntil: 'networkidle2', timeout });
      await page.waitForTimeout(3000);

      // 获取Cookie
      const cookies = await page.cookies();

      if (cookies.length === 0) {
        throw new Error('未获取到任何Cookie，请确保已登录');
      }

      // 转换为简化格式
      const cookieString = cookies
        .map(cookie => `${cookie.name}=${cookie.value}`)
        .join('; ');

      await browser.close();

      return cookieString;

    } catch (error) {
      if (browser) {
        try {
          await browser.close();
        } catch (e) {
          // 忽略关闭错误
        }
      }
      throw error;
    }
  }

  /**
   * 获取小红书Cookie
   * @param {Object} options - 配置选项
   * @returns {Promise<string>} Cookie字符串
   */
  static async getXiaohongshuCookie(options = {}) {
    const {
      timeout = 60000,
      headless = false
    } = options;

    let browser;

    try {
      const fs = require('fs');
      let executablePath = undefined;

      const macChromePaths = [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Chromium.app/Contents/MacOS/Chromium'
      ];

      for (const chromePath of macChromePaths) {
        if (fs.existsSync(chromePath)) {
          executablePath = chromePath;
          break;
        }
      }

      browser = await puppeteer.launch({
        headless,
        executablePath,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage'
        ],
        defaultViewport: {
          width: 1280,
          height: 800
        }
      });

      const page = await browser.newPage();

      await page.setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      );

      await page.goto('https://www.xiaohongshu.com', {
        waitUntil: 'networkidle2',
        timeout
      });

      // 等待用户登录
      await page.waitForTimeout(60000);

      // 刷新页面
      await page.reload({ waitUntil: 'networkidle2', timeout });
      await page.waitForTimeout(3000);

      const cookies = await page.cookies();

      if (cookies.length === 0) {
        throw new Error('未获取到任何Cookie');
      }

      const cookieString = cookies
        .map(cookie => `${cookie.name}=${cookie.value}`)
        .join('; ');

      await browser.close();

      return cookieString;

    } catch (error) {
      if (browser) {
        try {
          await browser.close();
        } catch (e) {
          // 忽略
        }
      }
      throw error;
    }
  }

  /**
   * 根据平台获取Cookie
   * @param {string} platform - 平台名称 (douyin, xiaohongshu, bilibili, weibo, kuaishou)
   * @param {Object} options - 配置选项
   * @returns {Promise<string>} Cookie字符串
   */
  static async getCookieByPlatform(platform, options = {}) {
    switch (platform.toLowerCase()) {
      case 'douyin':
        return await this.getDouyinCookie(options);
      case 'xiaohongshu':
        return await this.getXiaohongshuCookie(options);
      default:
        throw new Error(`暂不支持自动获取 ${platform} 平台的Cookie`);
    }
  }
}

module.exports = CookieAutoFetchService;

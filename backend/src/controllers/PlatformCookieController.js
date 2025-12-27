const { AppDataSource } = require('../utils/db');
const EncryptionService = require('../utils/encryption');
const axios = require('axios');
const CookieAutoFetchService = require('../services/CookieAutoFetchService');

class PlatformCookieController {
  // Get all platform cookies
  static async getPlatformCookies(req, res) {
    try {
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');
      
      const cookies = await platformCookieRepository.find({
        order: { created_at: 'DESC' }
      });
      
      // Remove sensitive cookie data from response
      const safeCookies = cookies.map(cookie => ({
        id: cookie.id,
        platform: cookie.platform,
        account_alias: cookie.account_alias,
        is_valid: cookie.is_valid,
        last_checked_at: cookie.last_checked_at,
        created_at: cookie.created_at
      }));
      
      res.status(200).json({
        message: '获取成功',
        data: safeCookies
      });
    } catch (error) {
      console.error('Get platform cookies error:', error);
      res.status(500).json({ message: '获取平台Cookie失败' });
    }
  }

  // Create platform cookie
  static async createPlatformCookie(req, res) {
    try {
      const { platform, account_alias, cookies } = req.body;
      
      if (!platform || !account_alias || !cookies) {
        return res.status(400).json({ message: '请提供完整的平台信息' });
      }
      
      // Encrypt cookies
      const encryptedCookies = EncryptionService.encrypt(cookies);
      
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');
      
      // Check if platform + account_alias combination already exists
      const existingCookie = await platformCookieRepository.findOne({
        where: { platform, account_alias }
      });
      
      if (existingCookie) {
        return res.status(400).json({ message: '该平台的账户别名已存在' });
      }
      
      // Create new platform cookie
      const platformCookie = platformCookieRepository.create({
        platform,
        account_alias,
        cookies_encrypted: encryptedCookies,
        is_valid: true, // Will be validated later
        last_checked_at: new Date(),
        created_at: new Date()
      });
      
      await platformCookieRepository.save(platformCookie);
      
      // Test cookie validity
      const isValid = await PlatformCookieController.testCookieValidity(platform, cookies);
      
      // Update validity status
      platformCookie.is_valid = isValid;
      platformCookie.last_checked_at = new Date();
      await platformCookieRepository.save(platformCookie);
      
      res.status(201).json({
        message: '平台Cookie创建成功',
        data: {
          id: platformCookie.id,
          platform: platformCookie.platform,
          account_alias: platformCookie.account_alias,
          is_valid: platformCookie.is_valid,
          last_checked_at: platformCookie.last_checked_at,
          created_at: platformCookie.created_at
        }
      });
    } catch (error) {
      console.error('Create platform cookie error:', error);
      res.status(500).json({ message: '创建平台Cookie失败' });
    }
  }

  // Update platform cookie
  static async updatePlatformCookie(req, res) {
    try {
      const { id } = req.params;
      const { platform, account_alias, cookies } = req.body;
      
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');
      
      const platformCookie = await platformCookieRepository.findOne({ where: { id } });
      if (!platformCookie) {
        return res.status(404).json({ message: '平台Cookie不存在' });
      }
      
      // Check if platform + account_alias combination already exists (excluding current record)
      if (platform && account_alias) {
        const existingCookie = await platformCookieRepository.findOne({
          where: { platform, account_alias }
        });
        
        if (existingCookie && existingCookie.id !== id) {
          return res.status(400).json({ message: '该平台的账户别名已存在' });
        }
      }
      
      // Update fields
      if (platform) platformCookie.platform = platform;
      if (account_alias) platformCookie.account_alias = account_alias;
      if (cookies) {
        platformCookie.cookies_encrypted = EncryptionService.encrypt(cookies);
        
        // Test new cookie validity
        const isValid = await PlatformCookieController.testCookieValidity(platform || platformCookie.platform, cookies);
        platformCookie.is_valid = isValid;
        platformCookie.last_checked_at = new Date();
      }
      
      await platformCookieRepository.save(platformCookie);
      
      res.status(200).json({
        message: '平台Cookie更新成功',
        data: {
          id: platformCookie.id,
          platform: platformCookie.platform,
          account_alias: platformCookie.account_alias,
          is_valid: platformCookie.is_valid,
          last_checked_at: platformCookie.last_checked_at,
          created_at: platformCookie.created_at
        }
      });
    } catch (error) {
      console.error('Update platform cookie error:', error);
      res.status(500).json({ message: '更新平台Cookie失败' });
    }
  }

  // Delete platform cookie
  static async deletePlatformCookie(req, res) {
    try {
      const { id } = req.params;
      
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');
      
      const platformCookie = await platformCookieRepository.findOne({ where: { id } });
      if (!platformCookie) {
        return res.status(404).json({ message: '平台Cookie不存在' });
      }
      
      await platformCookieRepository.delete(id);
      
      res.status(200).json({ message: '平台Cookie删除成功' });
    } catch (error) {
      console.error('Delete platform cookie error:', error);
      res.status(500).json({ message: '删除平台Cookie失败' });
    }
  }

  // Test platform cookie validity
  static async testPlatformCookieById(req, res) {
    try {
      const { id } = req.params;
      
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');
      
      const platformCookie = await platformCookieRepository.findOne({ where: { id } });
      if (!platformCookie) {
        return res.status(404).json({ message: '平台Cookie不存在' });
      }
      
      // Decrypt cookies
      const cookies = EncryptionService.decrypt(platformCookie.cookies_encrypted);
      
      // Test cookie validity
      const isValid = await PlatformCookieController.testCookieValidity(platformCookie.platform, cookies);
      
      // Update validity status
      platformCookie.is_valid = isValid;
      platformCookie.last_checked_at = new Date();
      await platformCookieRepository.save(platformCookie);
      
      res.status(200).json({
        message: isValid ? 'Cookie有效' : 'Cookie无效',
        success: isValid,
        data: {
          id: platformCookie.id,
          platform: platformCookie.platform,
          account_alias: platformCookie.account_alias,
          is_valid: platformCookie.is_valid,
          last_checked_at: platformCookie.last_checked_at
        }
      });
    } catch (error) {
      console.error('Test platform cookie error:', error);
      res.status(500).json({ message: '测试平台Cookie失败' });
    }
  }

  // Test cookie validity for a specific platform
  static async testCookieValidity(platform, cookies) {
    try {
      let testUrl;
      let expectedContent;
      let customHeaders = {};

      // Define test URLs and expected content for each platform
      switch (platform) {
        case 'xiaohongshu':
          testUrl = 'https://www.xiaohongshu.com/api/sns/web/v1/user/selfinfo';
          expectedContent = 'success';
          break;
        case 'douyin':
          // 使用抖音首页作为测试端点，更可靠
          testUrl = 'https://www.douyin.com/';
          expectedContent = 'RENDER_DATA';
          customHeaders = {
            'Referer': 'https://www.douyin.com/',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
          };
          break;
        case 'bilibili':
          testUrl = 'https://api.bilibili.com/x/web-interface/nav';
          expectedContent = 'isLogin';
          break;
        case 'weibo':
          testUrl = 'https://weibo.com/ajax/config';
          expectedContent = 'data';
          break;
        case 'kuaishou':
          testUrl = 'https://www.kuaishou.com/graphql';
          expectedContent = 'data';
          break;
        default:
          console.warn(`Unknown platform: ${platform}`);
          return false;
      }

      // Make test request with cookies
      const headers = {
        'Cookie': cookies,
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...customHeaders
      };

      const response = await axios.get(testUrl, {
        headers,
        timeout: 10000,
        validateStatus: () => true, // Don't throw on HTTP error status
        maxRedirects: 5 // 允许重定向
      });

      // Check if response indicates successful authentication
      const responseText = typeof response.data === 'string' ? response.data : JSON.stringify(response.data);

      // 更宽松的验证逻辑
      let isValid = false;

      if (platform === 'douyin') {
        // 抖音判断逻辑（更宽松）：
        // 1. HTTP状态码为200
        // 2. 包含RENDER_DATA（正常页面数据）
        // 3. 不包含验证相关关键词
        const hasRenderData = responseText.includes('RENDER_DATA');
        const hasVerification = responseText.includes('验证') || responseText.includes('verification');
        const statusOk = response.status === 200;

        isValid = statusOk && hasRenderData && !hasVerification;

        // 如果包含sessionid等关键字段，也认为可能有效
        if (!isValid && cookies.includes('sessionid')) {
          // 检查Cookie是否包含关键字段
          const hasSessionId = cookies.includes('sessionid=');
          const hasTtwid = cookies.includes('ttwid=');
          isValid = hasSessionId || hasTtwid;
        }

        console.log(`抖音Cookie测试 - 状态码: ${response.status}, RENDER_DATA: ${hasRenderData}, 验证页面: ${hasVerification}, 最终结果: ${isValid ? 'VALID' : 'INVALID'}`);
      } else {
        isValid = response.status === 200 && responseText.includes(expectedContent);
      }

      console.log(`Cookie test for ${platform}: ${isValid ? 'VALID' : 'INVALID'}`);

      // 如果测试失败，打印调试信息
      if (!isValid && platform === 'douyin') {
        console.log(`抖音Cookie测试失败详情:`);
        console.log(`- 状态码: ${response.status}`);
        console.log(`- 响应长度: ${responseText.length}`);
        console.log(`- 响应预览: ${responseText.substring(0, 300)}`);
      }

      return isValid;

    } catch (error) {
      console.error(`Cookie test error for ${platform}:`, error.message);
      return false;
    }
  }

  // Batch test all platform cookies
  static async batchTestPlatformCookies(req, res) {
    try {
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');

      const cookies = await platformCookieRepository.find();
      const results = [];

      for (const cookie of cookies) {
        try {
          const decryptedCookies = EncryptionService.decrypt(cookie.cookies_encrypted);
          const isValid = await PlatformCookieController.testCookieValidity(cookie.platform, decryptedCookies);

          // Update validity status
          cookie.is_valid = isValid;
          cookie.last_checked_at = new Date();
          await platformCookieRepository.save(cookie);

          results.push({
            id: cookie.id,
            platform: cookie.platform,
            account_alias: cookie.account_alias,
            is_valid: isValid
          });
        } catch (error) {
          console.error(`Error testing cookie ${cookie.id}:`, error);
          results.push({
            id: cookie.id,
            platform: cookie.platform,
            account_alias: cookie.account_alias,
            is_valid: false,
            error: error.message
          });
        }
      }

      res.status(200).json({
        message: '批量测试完成',
        data: results
      });
    } catch (error) {
      console.error('Batch test platform cookies error:', error);
      res.status(500).json({ message: '批量测试平台Cookie失败' });
    }
  }

  // Auto fetch cookie for a platform
  static async autoFetchCookie(req, res) {
    const { platform } = req.params;
    const { headless = false } = req.query;

    // 检查平台是否支持自动获取
    const supportedPlatforms = ['douyin', 'xiaohongshu'];
    if (!supportedPlatforms.includes(platform.toLowerCase())) {
      return res.status(400).json({
        message: `暂不支持自动获取 ${platform} 平台的Cookie`,
        supportedPlatforms
      });
    }

    try {
      console.log(`开始自动获取 ${platform} 平台Cookie...`);

      // 调用自动获取服务
      const cookie = await CookieAutoFetchService.getCookieByPlatform(platform, {
        timeout: 90000,
        headless: headless === 'true'
      });

      console.log(`${platform} 平台Cookie获取成功，长度: ${cookie.length}`);

      // 返回获取到的Cookie
      res.status(200).json({
        message: 'Cookie获取成功',
        data: {
          platform,
          cookie,
          length: cookie.length
        }
      });
    } catch (error) {
      console.error(`Auto fetch ${platform} cookie error:`, error);
      res.status(500).json({
        message: `自动获取${platform}平台Cookie失败: ${error.message}`
      });
    }
  }
}

module.exports = PlatformCookieController;
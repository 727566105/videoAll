const { AppDataSource } = require('../utils/db');

/**
 * 下载设置控制器
 * 管理各平台的下载偏好设置（如画质、格式等）
 */
class DownloadSettingsController {
  /**
   * 获取所有平台的下载设置
   * GET /api/v1/download-settings
   */
  static async getDownloadSettings(req, res) {
    try {
      const PlatformCookie = AppDataSource.getRepository('PlatformCookie');

      // 获取所有有效的平台Cookie配置
      const cookies = await PlatformCookie.find({
        where: { is_valid: true },
        order: { platform: 'ASC', created_at: 'DESC' }
      });

      // 按平台聚合，每个平台取最新的配置
      const platformSettings = {};
      const seenPlatforms = new Set();

      cookies.forEach(cookie => {
        if (!seenPlatforms.has(cookie.platform)) {
          seenPlatforms.add(cookie.platform);

          // 提取该平台的偏好设置
          if (cookie.preferences && cookie.preferences[cookie.platform]) {
            platformSettings[cookie.platform] = cookie.preferences[cookie.platform];
          } else {
            // 默认设置
            platformSettings[cookie.platform] = {
              preferred_quality: '1080P',
              auto_fallback: true
            };
          }
        }
      });

      res.status(200).json({
        message: '获取下载设置成功',
        data: platformSettings
      });
    } catch (error) {
      console.error('Get download settings error:', error);
      res.status(500).json({ message: '获取下载设置失败' });
    }
  }

  /**
   * 更新指定平台的下载设置
   * PUT /api/v1/download-settings
   * Body: { platform: 'bilibili', preferences: { preferred_quality: '4K', auto_fallback: true } }
   */
  static async updateDownloadSettings(req, res) {
    try {
      const { platform, preferences } = req.body;

      if (!platform) {
        return res.status(400).json({ message: '请指定平台' });
      }

      if (!preferences) {
        return res.status(400).json({ message: '请提供偏好设置' });
      }

      const PlatformCookie = AppDataSource.getRepository('PlatformCookie');

      // 查找该平台最新的有效Cookie配置
      const cookie = await PlatformCookie.findOne({
        where: { platform, is_valid: true },
        order: { created_at: 'DESC' }
      });

      if (!cookie) {
        return res.status(404).json({ message: `未找到平台 ${platform} 的有效Cookie配置` });
      }

      // 更新偏好设置
      const currentPreferences = cookie.preferences || {};
      currentPreferences[platform] = preferences;

      cookie.preferences = currentPreferences;
      await PlatformCookie.save(cookie);

      res.status(200).json({
        message: '更新下载设置成功',
        data: {
          platform,
          preferences: currentPreferences[platform]
        }
      });
    } catch (error) {
      console.error('Update download settings error:', error);
      res.status(500).json({ message: '更新下载设置失败' });
    }
  }

  /**
   * 获取平台支持的画质选项
   * GET /api/v1/download-settings/quality-options/:platform
   */
  static async getQualityOptions(req, res) {
    try {
      const { platform } = req.params;

      let qualityOptions = [];

      switch (platform) {
        case 'bilibili':
          qualityOptions = [
            { value: '4K', label: '4K 超清', premium: true, description: '需要大会员' },
            { value: '1080P+', label: '1080P+ 高码率', premium: true, description: '需要大会员' },
            { value: '1080P', label: '1080P 高清', premium: false },
            { value: '720P', label: '720P 清晰', premium: false },
            { value: '480P', label: '480P 标清', premium: false },
            { value: '360P', label: '360P 流畅', premium: false }
          ];
          break;

        default:
          return res.status(404).json({ message: `平台 ${platform} 暂不支持画质配置` });
      }

      res.status(200).json({
        message: '获取画质选项成功',
        data: qualityOptions
      });
    } catch (error) {
      console.error('Get quality options error:', error);
      res.status(500).json({ message: '获取画质选项失败' });
    }
  }
}

module.exports = DownloadSettingsController;

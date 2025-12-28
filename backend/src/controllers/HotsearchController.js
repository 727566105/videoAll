const HotsearchService = require('../services/HotsearchService');
const ParseService = require('../services/ParseService');
const CacheService = require('../services/CacheService');
const { AppDataSource } = require('../utils/db');

class HotsearchController {
  // Fetch hotsearch for a specific platform
  static async fetchHotsearch(req, res) {
    try {
      const { platform } = req.params;
      if (!platform) {
        return res.status(400).json({ message: '请提供平台名称' });
      }

      const data = await HotsearchService.fetchHotsearch(platform);
      res.status(200).json({
        message: '热搜抓取成功',
        data
      });
    } catch (error) {
      console.error('Fetch hotsearch error:', error);
      res.status(500).json({ message: error.message || '热搜抓取失败' });
    }
  }

  // Fetch hotsearch for all platforms
  static async fetchAllHotsearch(req, res) {
    try {
      const results = await HotsearchService.fetchAllHotsearch();
      res.status(200).json({
        message: '所有平台热搜抓取完成',
        data: results
      });
    } catch (error) {
      console.error('Fetch all hotsearch error:', error);
      res.status(500).json({ message: error.message || '热搜抓取失败' });
    }
  }

  // Get hotsearch by date and platform
  static async getHotsearchByDate(req, res) {
    try {
      const { platform } = req.params;
      const { date } = req.query;

      if (!platform) {
        return res.status(400).json({ message: '请提供平台名称' });
      }

      // Generate cache key
      const cacheKey = CacheService.getHotsearchCacheKey(platform, date);

      // Check cache first
      const cachedData = CacheService.get(cacheKey);
      if (cachedData) {
        return res.status(200).json(cachedData);
      }

      const data = await HotsearchService.getHotsearchByDate(platform, date);

      // Prepare response data
      const responseData = {
        message: '获取热搜成功',
        data
      };

      // Cache the response for 30 minutes (1800 seconds)
      CacheService.set(cacheKey, responseData, 1800);

      res.status(200).json(responseData);
    } catch (error) {
      console.error('Get hotsearch by date error:', error);
      res.status(500).json({ message: error.message || '获取热搜失败' });
    }
  }

  // Get hotsearch trends
  static async getHotsearchTrends(req, res) {
    try {
      const { platform } = req.params;
      const { days = 7 } = req.query;

      if (!platform) {
        return res.status(400).json({ message: '请提供平台名称' });
      }

      // Generate cache key with days parameter
      const cacheKey = `hotsearch:trends:${platform}:${days}`;

      // Check cache first
      const cachedData = CacheService.get(cacheKey);
      if (cachedData) {
        return res.status(200).json(cachedData);
      }

      const data = await HotsearchService.getHotsearchTrends(platform, parseInt(days));

      // Prepare response data
      const responseData = {
        message: '获取热搜趋势成功',
        data
      };

      // Cache the response for 1 hour (3600 seconds)
      CacheService.set(cacheKey, responseData, 3600);

      res.status(200).json(responseData);
    } catch (error) {
      console.error('Get hotsearch trends error:', error);
      res.status(500).json({ message: error.message || '获取热搜趋势失败' });
    }
  }

  // Get hotsearch platforms
  static async getHotsearchPlatforms(req, res) {
    try {
      // 返回固定四个平台
      const platforms = [
        { key: 'douyin', name: '抖音' },
        { key: 'xiaohongshu', name: '小红书' },
        { key: 'weibo', name: '微博' },
        { key: 'bilibili', name: 'B站' }
      ];

      res.status(200).json({
        message: '获取平台列表成功',
        data: platforms
      });
    } catch (error) {
      console.error('Get hotsearch platforms error:', error);
      res.status(500).json({ message: error.message || '获取平台列表失败' });
    }
  }

  // Parse content from hotsearch keyword
  static async parseHotsearchContent(req, res) {
    try {
      const { platform, keyword } = req.body;

      if (!platform || !keyword) {
        return res.status(400).json({ message: '请提供平台和关键词' });
      }

      // Build search link based on platform
      let searchLink;
      switch (platform) {
        case 'douyin':
          searchLink = `https://www.douyin.com/search/${encodeURIComponent(keyword)}`;
          break;
        case 'xiaohongshu':
          searchLink = `https://www.xiaohongshu.com/search_result?keyword=${encodeURIComponent(keyword)}`;
          break;
        case 'weibo':
          searchLink = `https://s.weibo.com/weibo?q=${encodeURIComponent(keyword)}`;
          break;
        case 'bilibili':
          searchLink = `https://search.bilibili.com/all?keyword=${encodeURIComponent(keyword)}`;
          break;
        default:
          return res.status(400).json({ message: `暂不支持${platform}平台的一键解析` });
      }

      // Parse content using ParseService
      const content = await ParseService.parseLink(searchLink);

      res.status(200).json({
        message: '一键解析成功',
        data: content
      });
    } catch (error) {
      console.error('Parse hotsearch content error:', error);
      res.status(500).json({ message: error.message || '一键解析失败' });
    }
  }

  // Get related content for a hotsearch keyword
  static async getHotsearchRelatedContent(req, res) {
    try {
      const { keyword, platform } = req.query;
      const { limit = 5 } = req.body;

      if (!keyword || !platform) {
        return res.status(400).json({ message: '请提供关键词和平台' });
      }

      // Get related content
      const relatedContent = await HotsearchService.getRelatedContent(keyword, platform, parseInt(limit));

      res.status(200).json({
        message: '获取热搜关联内容成功',
        data: relatedContent
      });
    } catch (error) {
      console.error('Get hotsearch related content error:', error);
      res.status(500).json({ message: error.message || '获取热搜关联内容失败' });
    }
  }

  // ========== Phase 2: New Controller Methods ==========

  // Get all platforms hotsearch (merge endpoint)
  static async getAllPlatformsHotsearch(req, res) {
    try {
      const data = await HotsearchService.getAllPlatformsHotsearch();
      res.status(200).json(data);
    } catch (error) {
      console.error('Get all platforms hotsearch error:', error);
      res.status(500).json({ message: error.message || '获取所有平台热搜失败' });
    }
  }

  // Get hotsearch history with advanced filtering
  static async getHotsearchHistory(req, res) {
    try {
      const result = await HotsearchService.getHotsearchHistory(req.query);
      res.status(200).json(result);
    } catch (error) {
      console.error('Get hotsearch history error:', error);
      res.status(500).json({ message: error.message || '获取历史热搜失败' });
    }
  }

  // Compare hotsearch across platforms
  static async compareHotsearchAcrossPlatforms(req, res) {
    try {
      const { date } = req.query;
      const result = await HotsearchService.compareHotsearchAcrossPlatforms(date);
      res.status(200).json(result);
    } catch (error) {
      console.error('Compare hotsearch across platforms error:', error);
      res.status(500).json({ message: error.message || '跨平台对比失败' });
    }
  }

  // Get hotsearch analysis
  static async getHotsearchAnalysis(req, res) {
    try {
      const result = await HotsearchService.getHotsearchAnalysis(req.query);
      res.status(200).json(result);
    } catch (error) {
      console.error('Get hotsearch analysis error:', error);
      res.status(500).json({ message: error.message || '获取数据分析失败' });
    }
  }

  // Get keyword trends
  static async getKeywordTrends(req, res) {
    try {
      const { keyword } = req.params;
      const { startDate, endDate } = req.query;

      if (!keyword) {
        return res.status(400).json({ message: '请提供关键词' });
      }

      const result = await HotsearchService.getKeywordTrends(keyword, startDate, endDate);
      res.status(200).json(result);
    } catch (error) {
      console.error('Get keyword trends error:', error);
      res.status(500).json({ message: error.message || '获取关键词趋势失败' });
    }
  }

  // Refresh all hotsearch (admin only)
  static async refreshAllHotsearch(req, res) {
    try {
      const results = await HotsearchService.fetchAllHotsearch();

      // Invalidate caches
      await HotsearchService.invalidateCaches(['douyin', 'xiaohongshu', 'weibo', 'bilibili']);

      res.status(200).json({
        message: '刷新所有热搜成功',
        data: results
      });
    } catch (error) {
      console.error('Refresh all hotsearch error:', error);
      res.status(500).json({ message: error.message || '刷新所有热搜失败' });
    }
  }

  // Get crawl statistics (admin only)
  static async getCrawlStats(req, res) {
    try {
      const hotsearchRepository = AppDataSource.getRepository('HotsearchSnapshot');

      // Get stats for the last 7 days
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const snapshots = await hotsearchRepository
        .createQueryBuilder('snapshot')
        .where('snapshot.capture_date >= :date', { date: sevenDaysAgo })
        .select('snapshot.platform', 'platform')
        .addSelect('COUNT(*)', 'count')
        .groupBy('snapshot.platform')
        .getRawMany();

      const platformStats = {};
      const platforms = ['douyin', 'xiaohongshu', 'weibo', 'bilibili'];

      platforms.forEach(platform => {
        const found = snapshots.find(s => s.platform === platform);
        platformStats[platform] = {
          successCount: found ? parseInt(found.count) : 0,
          expectedCount: 28, // 7 days × 4 times per day
          successRate: found ? (parseInt(found.count) / 28 * 100).toFixed(2) + '%' : '0%'
        };
      });

      res.status(200).json({
        message: '获取采集统计成功',
        data: {
          period: '最近7天',
          platformStats,
          healthStatus: Object.values(platformStats).every(s => parseFloat(s.successRate) >= 80)
            ? 'healthy' : 'warning'
        }
      });
    } catch (error) {
      console.error('Get crawl stats error:', error);
      res.status(500).json({ message: error.message || '获取采集统计失败' });
    }
  }
}

module.exports = HotsearchController;
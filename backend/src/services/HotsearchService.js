const axios = require('axios');
const cheerio = require('cheerio');
const puppeteer = require('puppeteer');
const { AppDataSource } = require('../utils/db');
const logger = require('../utils/logger');
const CacheService = require('./CacheService');

class HotsearchService {
  // Setup puppeteer browser with cookies
  static async setupBrowser(platform, config = {}) {
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-blink-features=AutomationControlled']
    });
    
    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
    
    // Set cookies if provided
    if (config.cookies && Object.keys(config.cookies).length > 0) {
      await page.setCookie(...config.cookies);
    }
    
    return { browser, page };
  }

  // Fetch hotsearch data from different platforms
  static async fetchHotsearch(platform, config = {}) {
    try {
      let hotsearchData;
      switch (platform) {
        case 'douyin':
          hotsearchData = await this.fetchDouyinHotsearch(config);
          break;
        case 'xiaohongshu':
          hotsearchData = await this.fetchXiaohongshuHotsearch(config);
          break;
        case 'weibo':
          hotsearchData = await this.fetchWeiboHotsearch(config);
          break;
        case 'bilibili':
          hotsearchData = await this.fetchBilibiliHotsearch(config);
          break;
        default:
          throw new Error(`暂不支持${platform}平台的热搜抓取`);
      }

      // Save to database using TypeORM
      await this.saveHotsearchSnapshot(platform, hotsearchData);

      return hotsearchData;
    } catch (error) {
      logger.error(`Failed to fetch hotsearch for ${platform}:`, error);
      throw error;
    }
  }

  // Fetch Douyin hotsearch
  static async fetchDouyinHotsearch(config = {}) {
    try {
      // Strategy 1: Try official API
      const API_URL = 'https://www.douyin.com/aweme/v1/hotsearch/aweme/board/';

      const response = await axios.get(API_URL, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Referer': 'https://www.douyin.com/',
        },
        timeout: 10000,
        ...config
      });

      if (response.data && response.data.data && response.data.data.word_list) {
        return response.data.data.word_list.slice(0, 50).map((item, index) => ({
          rank: index + 1,
          keyword: item.word || item.keyword,
          heat: item.hot_value || item.heat || 0,
          trend: this.parseTrendFlag(item.label_type),
          url: `https://www.douyin.com/search/${encodeURIComponent(item.word || item.keyword)}`,
          category: item.tag || '综合'
        }));
      }

      // Strategy 2: If API fails, return empty
      logger.warn('Douyin API returned unexpected data structure');
      return [];

    } catch (error) {
      logger.error('Failed to fetch Douyin hotsearch:', error.message);

      // Strategy 3: Return mock data for development/testing (skip Puppeteer)
      if (process.env.NODE_ENV !== 'production') {
        logger.info('Returning mock data for Douyin in development mode');
        return this.getMockDouyinData();
      }

      // Strategy 4: Try Puppeteer as fallback (production only)
      try {
        logger.info('Trying Puppeteer fallback for Douyin...');
        return await this.fetchDouyinHotsearchWithPuppeteer(config);
      } catch (puppeteerError) {
        logger.error('Puppeteer fallback also failed:', puppeteerError.message);
        return [];
      }
    }
  }

  // Puppeteer fallback for Douyin
  static async fetchDouyinHotsearchWithPuppeteer(config = {}) {
    const { browser, page } = await this.setupBrowser('douyin', config);

    try {
      await page.goto('https://www.douyin.com/', { waitUntil: 'networkidle2', timeout: 15000 });

      // Wait for hot search data to load
      await page.waitForTimeout(3000);

      const hotsearchData = await page.evaluate(() => {
        // Try to extract data from window.__INITIAL_STATE__ or similar
        const state = window.__INITIAL_STATE__ || window.RENDER_DATA;

        if (state && state.hotSearch) {
          return state.hotSearch;
        }

        return [];
      });

      await browser.close();

      return hotsearchData.slice(0, 50).map((item, index) => ({
        rank: index + 1,
        keyword: item.word || item.keyword,
        heat: item.hot_value || item.heat || 0,
        trend: '持平',
        url: `https://www.douyin.com/search/${encodeURIComponent(item.word || item.keyword)}`,
        category: '综合'
      }));

    } catch (error) {
      await browser.close();
      throw error;
    }
  }

  // Fetch Xiaohongshu hotsearch
  static async fetchXiaohongshuHotsearch(config = {}) {
    try {
      // Strategy 1: Try official API
      const API_URL = 'https://edith.xiaohongshu.com/api/sns/web/v1/hotsearch/keywords';

      const response = await axios.get(API_URL, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Referer': 'https://www.xiaohongshu.com/',
        },
        params: {
          num: 50
        },
        timeout: 10000,
        ...config
      });

      if (response.data && response.data.data && response.data.data.items) {
        return response.data.data.items.slice(0, 50).map((item, index) => ({
          rank: index + 1,
          keyword: item.keyword,
          heat: item.hot_rank || item.hot_value || 0,
          trend: item.is_new ? '新晋' : (item.trend || '持平'),
          url: `https://www.xiaohongshu.com/search_result?keyword=${encodeURIComponent(item.keyword)}`,
          category: item.category || '综合'
        }));
      }

      logger.warn('Xiaohongshu API returned unexpected data structure');
      return [];

    } catch (error) {
      logger.error('Failed to fetch Xiaohongshu hotsearch:', error.message);

      // Strategy 2: Return mock data for development/testing (skip Puppeteer)
      if (process.env.NODE_ENV !== 'production') {
        logger.info('Returning mock data for Xiaohongshu in development mode');
        return this.getMockXiaohongshuData();
      }

      // Strategy 3: Try Puppeteer as fallback (production only)
      try {
        logger.info('Trying Puppeteer fallback for Xiaohongshu...');
        return await this.fetchXiaohongshuHotsearchWithPuppeteer(config);
      } catch (puppeteerError) {
        logger.error('Puppeteer fallback also failed:', puppeteerError.message);
        return [];
      }
    }
  }

  // Puppeteer fallback for Xiaohongshu
  static async fetchXiaohongshuHotsearchWithPuppeteer(config = {}) {
    const { browser, page } = await this.setupBrowser('xiaohongshu', config);

    try {
      await page.goto('https://www.xiaohongshu.com/', { waitUntil: 'networkidle2', timeout: 15000 });
      await page.waitForTimeout(3000);

      const hotsearchData = await page.evaluate(() => {
        const state = window.__INITIAL_STATE__ || window.RENDER_DATA;
        if (state && state.hotSearch) {
          return state.hotSearch;
        }
        return [];
      });

      await browser.close();

      return hotsearchData.slice(0, 50).map((item, index) => ({
        rank: index + 1,
        keyword: item.keyword,
        heat: item.hot_rank || 0,
        trend: '持平',
        url: `https://www.xiaohongshu.com/search_result?keyword=${encodeURIComponent(item.keyword)}`,
        category: '综合'
      }));

    } catch (error) {
      await browser.close();
      throw error;
    }
  }

  // Fetch Weibo hotsearch
  static async fetchWeiboHotsearch(config = {}) {
    try {
      // Strategy 1: Try official API (more stable)
      const API_URL = 'https://weibo.com/ajax/side/hotSearch';

      const response = await axios.get(API_URL, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Referer': 'https://weibo.com',
        },
        timeout: 10000,
        ...config
      });

      if (response.data && response.data.data && response.data.data.realtime) {
        return response.data.data.realtime.slice(0, 50).map((item, index) => ({
          rank: index + 1,
          keyword: item.word,
          heat: item.num || item.hot_value || 0,
          trend: item.flag === 1 ? '新晋' : (item.is_ad === 1 ? '推广' : '普通'),
          url: `https://s.weibo.com/weibo?q=${encodeURIComponent(item.word)}`,
          category: item.category || '综合'
        }));
      }

      logger.warn('Weibo API returned unexpected data structure');
      return [];

    } catch (error) {
      logger.error('Failed to fetch Weibo hotsearch:', error.message);

      // Strategy 2: Return mock data for development/testing (skip HTML scraping)
      if (process.env.NODE_ENV !== 'production') {
        logger.info('Returning mock data for Weibo in development mode');
        return this.getMockWeiboData();
      }

      // Strategy 3: Try HTML scraping as fallback (production only)
      try {
        logger.info('Trying HTML scraping fallback for Weibo...');
        return await this.fetchWeiboHotsearchFromHTML(config);
      } catch (htmlError) {
        logger.error('HTML scraping fallback also failed:', htmlError.message);
        return [];
      }
    }
  }

  // HTML scraping fallback for Weibo
  static async fetchWeiboHotsearchFromHTML(config = {}) {
    const URL = 'https://s.weibo.com/top/summary';

    const response = await axios.get(URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      timeout: 10000,
      ...config
    });

    const $ = cheerio.load(response.data);
    const hotsearchData = [];

    $('#pl_top_realtimehot table tbody tr').each((index, element) => {
      if (index >= 50) return false;

      const $element = $(element);
      const rank = index + 1;
      const keyword = $element.find('td a').text().trim();
      const heatText = $element.find('td span').text().trim();
      const heat = parseInt(heatText.replace(/[^0-9]/g, '')) || 0;

      if (keyword) {
        hotsearchData.push({
          rank,
          keyword,
          heat,
          trend: '普通',
          url: `https://s.weibo.com/weibo?q=${encodeURIComponent(keyword)}`,
          category: '综合'
        });
      }
    });

    return hotsearchData;
  }

  // Parse trend flag from label type
  static parseTrendFlag(labelType) {
    const trendMap = {
      1: '新晋',
      2: '上升',
      3: '下降',
      4: '持平'
    };
    return trendMap[labelType] || '持平';
  }

  // Fetch Bilibili hotsearch
  static async fetchBilibiliHotsearch(config = {}) {
    try {
      // Strategy 1: Try official API (popular ranking)
      const API_URL = 'https://api.bilibili.com/x/web-interface/ranking/v2?rid=0&type=all';

      const response = await axios.get(API_URL, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
          'Referer': 'https://www.bilibili.com',
        },
        timeout: 10000,
        ...config
      });

      if (response.data && response.data.code === 0 && response.data.data && response.data.data.list) {
        return response.data.data.list.slice(0, 50).map((item, index) => ({
          rank: item.stat?.ranking || index + 1,
          keyword: item.title,
          heat: item.stat?.view || 0,
          trend: item.new_desc ? '新晋' : '普通',
          url: `https://www.bilibili.com/video/${item.bvid}`,
          category: item.tname || '综合'
        }));
      }

      logger.warn('Bilibili API returned unexpected data structure');
      return [];

    } catch (error) {
      logger.error('Failed to fetch Bilibili hotsearch:', error.message);

      // Strategy 2: Return mock data for development/testing (skip HTML scraping)
      if (process.env.NODE_ENV !== 'production') {
        logger.info('Returning mock data for Bilibili in development mode');
        return this.getMockBilibiliData();
      }

      // Strategy 3: Try HTML scraping as fallback (production only)
      try {
        logger.info('Trying HTML scraping fallback for Bilibili...');
        return await this.fetchBilibiliHotsearchFromHTML(config);
      } catch (htmlError) {
        logger.error('HTML scraping fallback also failed:', htmlError.message);
        return [];
      }
    }
  }

  // HTML scraping fallback for Bilibili
  static async fetchBilibiliHotsearchFromHTML(config = {}) {
    const URL = 'https://www.bilibili.com/v/popular/rank/all';

    const response = await axios.get(URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      timeout: 10000,
      ...config
    });

    const $ = cheerio.load(response.data);
    const hotsearchData = [];

    $('.rank-item').each((index, element) => {
      if (index >= 50) return false;

      const $element = $(element);
      const title = $element.find('.title').text().trim();
      const viewText = $element.find('.data-box').eq(0).text().trim();
      const view = parseInt(viewText.replace(/[^0-9]/g, '')) || 0;

      if (title) {
        hotsearchData.push({
          rank: index + 1,
          keyword: title,
          heat: view,
          trend: '普通',
          url: $element.find('a').attr('href') || 'https://www.bilibili.com',
          category: '综合'
        });
      }
    });

    return hotsearchData;
  }

  // Save hotsearch snapshot to database using TypeORM
  static async saveHotsearchSnapshot(platform, data) {
    try {
      const hotsearchRepository = AppDataSource.getRepository('HotsearchSnapshot');
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Check if snapshot already exists for today
      const existingSnapshot = await hotsearchRepository.findOne({
        where: {
          platform,
          capture_date: today
        }
      });

      if (existingSnapshot) {
        // Update existing snapshot
        existingSnapshot.snapshot_data = data;
        existingSnapshot.capture_time = new Date();
        await hotsearchRepository.save(existingSnapshot);
      } else {
        // Create new snapshot
        const snapshot = hotsearchRepository.create({
          platform,
          capture_date: today,
          capture_time: new Date(),
          snapshot_data: data
        });
        await hotsearchRepository.save(snapshot);
      }
    } catch (error) {
      logger.error('Failed to save hotsearch snapshot:', error);
      // Don't throw error to avoid breaking the main functionality
    }
  }

  // Get hotsearch snapshot by date and platform using TypeORM
  static async getHotsearchByDate(platform, date) {
    try {
      const hotsearchRepository = AppDataSource.getRepository('HotsearchSnapshot');
      const targetDate = date ? new Date(date) : new Date();
      targetDate.setHours(0, 0, 0, 0);

      const snapshot = await hotsearchRepository.findOne({
        where: {
          platform,
          capture_date: targetDate
        }
      });

      return snapshot ? snapshot.snapshot_data : [];
    } catch (error) {
      logger.error('Failed to get hotsearch by date:', error);
      // Return empty array instead of throwing error
      return [];
    }
  }

  // Get recent hotsearch trends using TypeORM
  static async getHotsearchTrends(platform, days = 7) {
    try {
      const hotsearchRepository = AppDataSource.getRepository('HotsearchSnapshot');
      const endDate = new Date();
      endDate.setHours(0, 0, 0, 0);
      const startDate = new Date(endDate);
      startDate.setDate(startDate.getDate() - days + 1);

      const snapshots = await hotsearchRepository.find({
        where: {
          platform,
          capture_date: {
            $gte: startDate,
            $lte: endDate
          }
        },
        order: {
          capture_date: 'ASC'
        }
      });

      return snapshots.map(snapshot => ({
        date: snapshot.capture_date.toISOString().split('T')[0],
        data: snapshot.snapshot_data
      }));
    } catch (error) {
      logger.error('Failed to get hotsearch trends:', error);
      // Return empty array instead of throwing error
      return [];
    }
  }

  // Fetch all platforms hotsearch and save
  static async fetchAllHotsearch(config = {}) {
    try {
      const platforms = ['douyin', 'xiaohongshu', 'weibo', 'bilibili'];
      const results = [];

      for (const platform of platforms) {
        try {
          const result = await this.fetchHotsearch(platform, config);
          results.push({ platform, success: true, data: result });
        } catch (error) {
          results.push({ platform, success: false, error: error.message });
        }
      }

      return results;
    } catch (error) {
      logger.error('Failed to fetch all hotsearch:', error);
      throw error;
    }
  }

  // Get related content for a hotsearch keyword
  static async getRelatedContent(keyword, platform, limit = 5) {
    try {
      logger.info(`Getting related content for keyword: ${keyword} on platform: ${platform}`);

      // Return mock related content
      return Array.from({ length: limit }, (_, index) => ({
        id: `related_${keyword}_${platform}_${index}`,
        title: `${keyword}相关内容${index + 1}`,
        platform: platform,
        summary: `这是关于${keyword}的第${index + 1}条相关内容摘要，提供了该热点话题的详细信息和分析。`,
        source_url: `https://example.com/${platform}/search?q=${encodeURIComponent(keyword)}&related=${index}`,
        heat: Math.floor(Math.random() * 100000) + 10000,
        published_at: new Date(Date.now() - Math.floor(Math.random() * 3600000 * 24)) // Random time in the last 24 hours
      }));
    } catch (error) {
      logger.error(`Failed to get related content for keyword: ${keyword}`, error);
      throw error;
    }
  }

  // ========== Phase 2: New API Methods ==========

  // Get all platforms hotsearch in one call (merge endpoint)
  static async getAllPlatformsHotsearch(config = {}) {
    try {
      const cacheKey = 'hotsearch:all:latest';
      const cachedData = CacheService.get(cacheKey);

      if (cachedData) {
        return cachedData;
      }

      const platforms = ['douyin', 'xiaohongshu', 'weibo', 'bilibili'];
      const results = {};
      const errors = [];

      for (const platform of platforms) {
        try {
          let data = [];

          // Try to get from database first, but handle AppDataSource issues
          try {
            data = await this.getHotsearchByDate(platform, null);
          } catch (dbError) {
            logger.warn(`Database error for ${platform}, will fetch new data:`, dbError.message);
          }

          // If database is empty or failed, fetch new data (will return mock data in dev mode)
          if (!data || data.length === 0) {
            logger.info(`No data in database for ${platform}, fetching new data...`);
            data = await this.fetchHotsearch(platform);
          }

          results[platform] = {
            success: true,
            data: data.slice(0, 50), // Limit to Top 50
            itemCount: data.length,
            lastUpdate: new Date()
          };
        } catch (error) {
          logger.error(`Error processing ${platform}:`, error.message);
          errors.push({
            platform,
            success: false,
            error: error.message
          });
          results[platform] = {
            success: false,
            error: error.message,
            data: []
          };
        }
      }

      const responseData = {
        message: '获取四平台热搜成功',
        data: results,
        timestamp: new Date(),
        errors: errors.length > 0 ? errors : undefined
      };

      // Cache for 15 minutes
      CacheService.set(cacheKey, responseData, 900);

      return responseData;
    } catch (error) {
      logger.error('Failed to get all platforms hotsearch:', error);
      throw error;
    }
  }

  // Get hotsearch history with advanced filtering
  static async getHotsearchHistory(params) {
    try {
      const {
        platforms,
        startDate,
        endDate,
        minRank,
        maxRank,
        keyword,
        category,
        sortBy = 'capture_date',
        sortOrder = 'DESC',
        page = 1,
        pageSize = 20
      } = params;

      const platformList = platforms === 'all'
        ? ['douyin', 'xiaohongshu', 'weibo', 'bilibili']
        : platforms.split(',');

      const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const end = endDate ? new Date(endDate) : new Date();
      start.setHours(0, 0, 0, 0);
      end.setHours(23, 59, 59, 999);

      const hotsearchRepository = AppDataSource.getRepository('HotsearchSnapshot');

      const snapshots = await hotsearchRepository
        .createQueryBuilder('snapshot')
        .where('snapshot.platform IN (:...platforms)', { platforms: platformList })
        .andWhere('snapshot.capture_date >= :start', { start })
        .andWhere('snapshot.capture_date <= :end', { end })
        .orderBy('snapshot.capture_date', 'DESC')
        .getMany();

      let filteredData = [];

      snapshots.forEach(snapshot => {
        const items = snapshot.snapshot_data.filter(item => {
          if (minRank && item.rank < minRank) return false;
          if (maxRank && item.rank > maxRank) return false;
          if (keyword && !item.keyword.includes(keyword)) return false;
          if (category && item.category !== category) return false;
          return true;
        }).map(item => ({
          ...item,
          platform: snapshot.platform,
          captureDate: snapshot.capture_date,
          captureTime: snapshot.capture_time
        }));

        filteredData.push(...items);
      });

      // Sort
      filteredData.sort((a, b) => {
        const order = sortOrder === 'ASC' ? 1 : -1;
        if (sortBy === 'heat') return order * (b.heat - a.heat);
        if (sortBy === 'rank') return order * (a.rank - b.rank);
        return order * (new Date(b.captureDate) - new Date(a.captureDate));
      });

      // Pagination
      const total = filteredData.length;
      const startIndex = (page - 1) * pageSize;
      const paginatedData = filteredData.slice(startIndex, startIndex + pageSize);

      return {
        message: '查询成功',
        data: paginatedData,
        pagination: {
          total,
          page: parseInt(page),
          pageSize: parseInt(pageSize),
          totalPages: Math.ceil(total / pageSize)
        }
      };
    } catch (error) {
      logger.error('Failed to get hotsearch history:', error);
      throw error;
    }
  }

  // Compare hotsearch across platforms
  static async compareHotsearchAcrossPlatforms(date) {
    try {
      const targetDate = date ? new Date(date) : new Date();
      targetDate.setHours(0, 0, 0, 0);

      const platforms = ['douyin', 'xiaohongshu', 'weibo', 'bilibili'];
      const platformData = {};

      for (const platform of platforms) {
        const data = await this.getHotsearchByDate(platform, targetDate);
        platformData[platform] = data;
      }

      const allKeywords = new Map();

      platforms.forEach(platform => {
        const items = platformData[platform] || [];
        items.forEach(item => {
          if (!allKeywords.has(item.keyword)) {
            allKeywords.set(item.keyword, {
              keyword: item.keyword,
              platforms: [],
              ranks: {},
              heats: {}
            });
          }
          const entry = allKeywords.get(item.keyword);
          entry.platforms.push(platform);
          entry.ranks[platform] = item.rank;
          entry.heats[platform] = item.heat;
        });
      });

      const commonKeywords = Array.from(allKeywords.values())
        .filter(entry => entry.platforms.length >= 2)
        .sort((a, b) => b.platforms.length - a.platforms.length);

      const stats = {
        totalUnique: allKeywords.size,
        commonCount: commonKeywords.length,
        platformSpecific: {}
      };

      platforms.forEach(platform => {
        const platformKeywords = new Set(
          (platformData[platform] || []).map(item => item.keyword)
        );

        const uniqueKeywords = Array.from(platformKeywords).filter(keyword => {
          const entry = allKeywords.get(keyword);
          return entry && entry.platforms.length === 1;
        });

        stats.platformSpecific[platform] = uniqueKeywords.length;
      });

      return {
        message: '对比分析成功',
        data: {
          date: targetDate,
          commonKeywords,
          stats,
          platformData
        }
      };
    } catch (error) {
      logger.error('Failed to compare hotsearch across platforms:', error);
      throw error;
    }
  }

  // Get keyword trends over time
  static async getKeywordTrends(keyword, startDate, endDate) {
    try {
      const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const end = endDate ? new Date(endDate) : new Date();
      start.setHours(0, 0, 0, 0);
      end.setHours(23, 59, 59, 999);

      const hotsearchRepository = AppDataSource.getRepository('HotsearchSnapshot');

      const snapshots = await hotsearchRepository
        .createQueryBuilder('snapshot')
        .where('snapshot.capture_date >= :start', { start })
        .andWhere('snapshot.capture_date <= :end', { end })
        .orderBy('snapshot.capture_date', 'ASC')
        .getMany();

      const trendData = [];

      snapshots.forEach(snapshot => {
        const foundItem = snapshot.snapshot_data.find(item => item.keyword === keyword);
        if (foundItem) {
          trendData.push({
            date: snapshot.capture_date,
            platform: snapshot.platform,
            rank: foundItem.rank,
            heat: foundItem.heat,
            trend: foundItem.trend
          });
        }
      });

      return {
        message: '获取关键词趋势成功',
        data: {
          keyword,
          startDate: start,
          endDate: end,
          trends: trendData,
          appearances: trendData.length
        }
      };
    } catch (error) {
      logger.error('Failed to get keyword trends:', error);
      throw error;
    }
  }

  // Get hotsearch analysis (heat distribution, etc.)
  static async getHotsearchAnalysis(params) {
    try {
      const { platform, date, days = 7 } = params;
      const targetDate = date ? new Date(date) : new Date();
      targetDate.setHours(0, 0, 0, 0);

      let data;
      if (platform) {
        data = await this.getHotsearchByDate(platform, targetDate);
      } else {
        const result = await this.getAllPlatformsHotsearch();
        data = result.data;
      }

      const heatDistribution = [];
      const categoryDistribution = {};
      const trendDistribution = {上升: 0, 下降: 0, 持平: 0, 新晋: 0, 普通: 0};

      const processPlatformData = (platformData) => {
        if (!Array.isArray(platformData)) return;

        platformData.forEach(item => {
          // Heat distribution (by rank ranges)
          const rankRange = Math.ceil(item.rank / 10) * 10;
          const rangeKey = `Top ${rankRange - 9}-${rankRange}`;
          if (!heatDistribution[rangeKey]) heatDistribution[rangeKey] = 0;
          heatDistribution[rangeKey] += item.heat || 0;

          // Category distribution
          const category = item.category || '综合';
          if (!categoryDistribution[category]) categoryDistribution[category] = 0;
          categoryDistribution[category]++;

          // Trend distribution
          const trend = item.trend || '普通';
          if (trendDistribution[trend] !== undefined) {
            trendDistribution[trend]++;
          } else {
            trendDistribution['普通']++;
          }
        });
      };

      if (platform && Array.isArray(data)) {
        processPlatformData(data);
      } else if (data && typeof data === 'object') {
        Object.keys(data).forEach(platformKey => {
          const platformInfo = data[platformKey];
          if (platformInfo && platformInfo.data && Array.isArray(platformInfo.data)) {
            processPlatformData(platformInfo.data);
          }
        });
      }

      return {
        message: '数据分析成功',
        data: {
          date: targetDate,
          platform: platform || 'all',
          heatDistribution: Object.entries(heatDistribution).map(([range, heat]) => ({ range, heat })),
          categoryDistribution: Object.entries(categoryDistribution).map(([category, count]) => ({ category, count })),
          trendDistribution: Object.entries(trendDistribution).map(([trend, count]) => ({ trend, count }))
        }
      };
    } catch (error) {
      logger.error('Failed to get hotsearch analysis:', error);
      throw error;
    }
  }

  // Invalidate caches for specific platforms
  static async invalidateCaches(platforms) {
    try {
      const keysToDelete = [];

      platforms.forEach(platform => {
        keysToDelete.push(`hotsearch:${platform}:latest`);
        keysToDelete.push(`hotsearch:all:latest`);
      });

      CacheService.delMultiple(keysToDelete);
      logger.info(`Invalidated ${keysToDelete.length} cache keys for platforms: ${platforms.join(', ')}`);

      return {
        message: '缓存失效成功',
        invalidatedKeys: keysToDelete.length,
        platforms
      };
    } catch (error) {
      logger.error('Failed to invalidate caches:', error);
      throw error;
    }
  }

  // Mock data for development/testing
  static getMockDouyinData() {
    return [
      { rank: 1, keyword: '春节倒计时', heat: 1234567, trend: '上升', url: 'https://www.douyin.com/search/春节倒计时', category: '节日' },
      { rank: 2, keyword: '新年新气象', heat: 1123456, trend: '上升', url: 'https://www.douyin.com/search/新年新气象', category: '生活' },
      { rank: 3, keyword: '冬日穿搭', heat: 1054321, trend: '持平', url: 'https://www.douyin.com/search/冬日穿搭', category: '时尚' },
      { rank: 4, keyword: '寒假生活', heat: 987654, trend: '上升', url: 'https://www.douyin.com/search/寒假生活', category: '教育' },
      { rank: 5, keyword: '美食探店', heat: 876543, trend: '下降', url: 'https://www.douyin.com/search/美食探店', category: '美食' },
      { rank: 6, keyword: '旅行Vlog', heat: 765432, trend: '持平', url: 'https://www.douyin.com/search/旅行Vlog', category: '旅游' },
      { rank: 7, keyword: '健身打卡', heat: 654321, trend: '新晋', url: 'https://www.douyin.com/search/健身打卡', category: '运动' },
      { rank: 8, keyword: '电影推荐', heat: 543210, trend: '上升', url: 'https://www.douyin.com/search/电影推荐', category: '娱乐' },
      { rank: 9, keyword: '数码测评', heat: 432109, trend: '下降', url: 'https://www.douyin.com/search/数码测评', category: '科技' },
      { rank: 10, keyword: '萌宠日常', heat: 321098, trend: '持平', url: 'https://www.douyin.com/search/萌宠日常', category: '宠物' }
    ];
  }

  static getMockXiaohongshuData() {
    return [
      { rank: 1, keyword: '春节妆容教程', heat: 987654, trend: '上升', url: 'https://www.xiaohongshu.com/search_result?keyword=春节妆容教程', category: '美妆' },
      { rank: 2, keyword: '年货购物清单', heat: 876543, trend: '上升', url: 'https://www.xiaohongshu.com/search_result?keyword=年货购物清单', category: '购物' },
      { rank: 3, keyword: '冬季护肤', heat: 765432, trend: '持平', url: 'https://www.xiaohongshu.com/search_result?keyword=冬季护肤', category: '美妆' },
      { rank: 4, keyword: '新年穿搭', heat: 654321, trend: '上升', url: 'https://www.xiaohongshu.com/search_result?keyword=新年穿搭', category: '时尚' },
      { rank: 5, keyword: '家常菜谱', heat: 543210, trend: '下降', url: 'https://www.xiaohongshu.com/search_result?keyword=家常菜谱', category: '美食' },
      { rank: 6, keyword: '冬季旅行', heat: 432109, trend: '持平', url: 'https://www.xiaohongshu.com/search_result?keyword=冬季旅行', category: '旅游' },
      { rank: 7, keyword: '健身减脂', heat: 321098, trend: '新晋', url: 'https://www.xiaohongshu.com/search_result?keyword=健身减脂', category: '运动' },
      { rank: 8, keyword: '追剧推荐', heat: 210987, trend: '上升', url: 'https://www.xiaohongshu.com/search_result?keyword=追剧推荐', category: '娱乐' },
      { rank: 9, keyword: '家居好物', heat: 109876, trend: '下降', url: 'https://www.xiaohongshu.com/search_result?keyword=家居好物', category: '家居' },
      { rank: 10, keyword: '数码配件', heat: 98765, trend: '持平', url: 'https://www.xiaohongshu.com/search_result?keyword=数码配件', category: '数码' }
    ];
  }

  static getMockWeiboData() {
    return [
      { rank: 1, keyword: '#春节倒计时#', heat: 2345678, trend: '上升', url: 'https://s.weibo.com/weibo?q=%23春节倒计时%23', category: '节日' },
      { rank: 2, keyword: '#新年新气象#', heat: 2123456, trend: '上升', url: 'https://s.weibo.com/weibo?q=%23新年新气象%23', category: '生活' },
      { rank: 3, keyword: '#春节档电影#', heat: 1987654, trend: '持平', url: 'https://s.weibo.com/weibo?q=%23春节档电影%23', category: '娱乐' },
      { rank: 4, keyword: '#春运#', heat: 1876543, trend: '上升', url: 'https://s.weibo.com/weibo?q=%23春运%23', category: '社会' },
      { rank: 5, keyword: '#年货节#', heat: 1765432, trend: '下降', url: 'https://s.weibo.com/weibo?q=%23年货节%23', category: '购物' },
      { rank: 6, keyword: '#天气预报#', heat: 1654321, trend: '持平', url: 'https://s.weibo.com/weibo?q=%23天气预报%23', category: '生活' },
      { rank: 7, keyword: '#明星动态#', heat: 1543210, trend: '新晋', url: 'https://s.weibo.com/weibo?q=%23明星动态%23', category: '娱乐' },
      { rank: 8, keyword: '#体育新闻#', heat: 1432109, trend: '上升', url: 'https://s.weibo.com/weibo?q=%23体育新闻%23', category: '体育' },
      { rank: 9, keyword: '#科技资讯#', heat: 1321098, trend: '下降', url: 'https://s.weibo.com/weibo?q=%23科技资讯%23', category: '科技' },
      { rank: 10, keyword: '#健康养生#', heat: 1210987, trend: '持平', url: 'https://s.weibo.com/weibo?q=%23健康养生%23', category: '健康' }
    ];
  }

  static getMockBilibiliData() {
    return [
      { rank: 1, keyword: '春节特供', heat: 3456789, trend: '上升', url: 'https://search.bilibili.com/all?keyword=春节特供', category: '节日' },
      { rank: 2, keyword: '新年翻唱', heat: 3234567, trend: '上升', url: 'https://search.bilibili.com/all?keyword=新年翻唱', category: '音乐' },
      { rank: 3, keyword: '寒假作业', heat: 2987654, trend: '持平', url: 'https://search.bilibili.com/all?keyword=寒假作业', category: '教育' },
      { rank: 4, keyword: '游戏攻略', heat: 2765432, trend: '上升', url: 'https://search.bilibili.com/all?keyword=游戏攻略', category: '游戏' },
      { rank: 5, keyword: '番剧推荐', heat: 2543210, trend: '下降', url: 'https://search.bilibili.com/all?keyword=番剧推荐', category: '动画' },
      { rank: 6, keyword: '科技测评', heat: 2321098, trend: '持平', url: 'https://search.bilibili.com/all?keyword=科技测评', category: '科技' },
      { rank: 7, keyword: '美食教程', heat: 2109876, trend: '新晋', url: 'https://search.bilibili.com/all?keyword=美食教程', category: '生活' },
      { rank: 8, keyword: '电影解说', heat: 1987654, trend: '上升', url: 'https://search.bilibili.com/all?keyword=电影解说', category: '影视' },
      { rank: 9, keyword: '健身教学', heat: 1765432, trend: '下降', url: 'https://search.bilibili.com/all?keyword=健身教学', category: '运动' },
      { rank: 10, keyword: '数码开箱', heat: 1543210, trend: '持平', url: 'https://search.bilibili.com/all?keyword=数码开箱', category: '数码' }
    ];
  }
}

module.exports = HotsearchService;
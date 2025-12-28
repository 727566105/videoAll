/**
 * OCR服务
 *
 * 使用Tesseract.js从图片中提取文字
 * 支持批量处理、错误降级、结果缓存
 */

const Tesseract = require('tesseract.js');
const NodeCache = require('node-cache');
const pLimit = require('p-limit');
const path = require('path');
const fs = require('fs').promises;
const logger = require('../utils/logger');
const ocrConfig = require('../config/ocr.config');
const ImageProcessor = require('../utils/imageProcessor');

// OCR结果缓存
const ocrCache = new NodeCache({
  stdTTL: ocrConfig.cacheTTL,
  checkperiod: 600,  // 每10分钟检查过期
  useClones: false
});

// 并发控制器
const limit = pLimit(ocrConfig.maxConcurrency);

class OcrService {
  /**
   * 从单张图片提取文字
   * @param {string} imagePath - 图片路径
   * @param {object} options - 选项
   * @returns {Promise<object>} OCR结果
   */
  static async extractTextFromImage(imagePath, options = {}) {
    const {
      language = 'chi_sim+eng',
      preprocess = true,
      useCache = ocrConfig.cacheEnabled
    } = options;

    const startTime = Date.now();

    try {
      // 检查缓存
      if (useCache) {
        const cacheKey = this.getCacheKey(imagePath, language);
        const cached = ocrCache.get(cacheKey);
        if (cached) {
          logger.info('使用OCR缓存结果', { imagePath });
          return cached;
        }
      }

      // 图片预处理
      let processedPath = imagePath;
      if (preprocess && ocrConfig.preprocessing.enabled) {
        processedPath = await ImageProcessor.preprocessForOcr(imagePath);
      }

      // 执行OCR（带重试）
      const result = await this.performOcrWithRetry(processedPath, language);

      // 清理结果
      const cleanedResult = this.cleanOcrResult(result.data.text, {
        confidence: result.data.confidence,
        imagePath
      });

      // 清理临时文件
      if (processedPath !== imagePath) {
        await ImageProcessor.cleanup([processedPath]);
      }

      const duration = Date.now() - startTime;
      logger.info('OCR提取完成', {
        imagePath,
        duration: `${duration}ms`,
        confidence: cleanedResult.confidence,
        textLength: cleanedResult.text.length
      });

      // 保存到缓存
      if (useCache) {
        const cacheKey = this.getCacheKey(imagePath, language);
        ocrCache.set(cacheKey, cleanedResult);
      }

      return cleanedResult;
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error('OCR提取失败:', {
        imagePath,
        error: error.message,
        duration: `${duration}ms`
      });

      throw new Error(`OCR提取失败: ${error.message}`);
    }
  }

  /**
   * 批量处理多张图片
   * @param {string[]} imagePaths - 图片路径数组
   * @param {object} options - 选项
   * @returns {Promise<object[]>} OCR结果数组
   */
  static async extractTextFromImages(imagePaths, options = {}) {
    const {
      language = 'chi_sim+eng',
      preprocess = true,
      useCache = ocrConfig.cacheEnabled
    } = options;

    const startTime = Date.now();
    const results = [];

    // 使用并发控制处理图片
    const tasks = imagePaths.map(imagePath =>
      limit(async () => {
        try {
          const result = await this.extractTextFromImage(imagePath, {
            language,
            preprocess,
            useCache
          });
          return { success: true, imagePath, result };
        } catch (error) {
          logger.warn(`图片OCR失败: ${imagePath}`, error);
          return { success: false, imagePath, error: error.message };
        }
      })
    );

    const taskResults = await Promise.all(tasks);

    // 分离成功和失败的结果
    const successful = taskResults.filter(t => t.success);
    const failed = taskResults.filter(t => !t.success);

    logger.info('批量OCR完成', {
      total: imagePaths.length,
      successful: successful.length,
      failed: failed.length,
      duration: `${Date.now() - startTime}ms`
    });

    // 返回所有结果（包括失败的）
    return taskResults.map(task => {
      if (task.success) {
        return task.result;
      } else {
        return {
          text: '',
          confidence: 0,
          imagePath: task.imagePath,
          error: task.error
        };
      }
    });
  }

  /**
   * 从Content对象提取所有图片文字
   * @param {object} content - Content实体对象
   * @param {object} options - 选项
   * @returns {Promise<object[]>} OCR结果数组
   */
  static async extractFromContent(content, options = {}) {
    const {
      language,
      preprocess = true,
      useCache = ocrConfig.cacheEnabled
    } = options;

    try {
      // 解析图片路径
      const imagePaths = await this.getContentImagePaths(content);

      if (imagePaths.length === 0) {
        logger.info('内容没有图片', { contentId: content.id });
        return [];
      }

      // 确定语言
      const ocrLanguage = language || ocrConfig.languages[content.platform] || ocrConfig.languages.default;

      // 批量处理
      const results = await this.extractTextFromImages(imagePaths, {
        language: ocrLanguage,
        preprocess,
        useCache
      });

      // 过滤成功的结果
      const successfulResults = results.filter(r => r.text && r.text.length > 0);

      logger.info('内容OCR提取完成', {
        contentId: content.id,
        platform: content.platform,
        totalImages: imagePaths.length,
        successful: successfulResults.length
      });

      return successfulResults;
    } catch (error) {
      logger.error('从Content提取OCR失败:', {
        contentId: content.id,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * 执行OCR（带重试机制）
   * @param {string} imagePath - 图片路径
   * @param {string} language - OCR语言
   * @returns {Promise<object>} Tesseract结果
   */
  static async performOcrWithRetry(imagePath, language) {
    const maxAttempts = ocrConfig.retry.maxAttempts;
    const backoffMs = ocrConfig.retry.backoffMs;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const worker = await Tesseract.createWorker({
          logger: m => {
            if (ocrConfig.metrics.enabled && m.status === 'recognizing text') {
              // 可以在这里记录进度
            }
          }
        });

        await worker.loadLanguage(language);
        await worker.initialize(language);

        const result = await worker.recognize(imagePath);

        await worker.terminate();

        return result;
      } catch (error) {
        if (attempt === maxAttempts) {
          throw error;
        }

        logger.warn(`OCR重试 ${attempt}/${maxAttempts}`, {
          imagePath,
          error: error.message
        });

        // 等待后重试
        await new Promise(resolve => setTimeout(resolve, backoffMs * attempt));
      }
    }
  }

  /**
   * 清理OCR结果
   * @param {string} rawText - 原始文字
   * @param {object} metadata - 元数据
   * @returns {object} 清理后的结果
   */
  static cleanOcrResult(rawText, metadata = {}) {
    const config = ocrConfig.postProcessing;
    let text = rawText;

    // 去除首尾空白
    text = text.trim();

    // 去除噪声字符
    if (config.removeNoise) {
      // 去除特殊符号和乱码
      text = text.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
      // 去除过多的空白字符
      text = text.replace(/\s+/g, ' ');
    }

    // 合并断行
    if (config.mergeLines) {
      text = text.replace(/-\s+/g, '');  // 合并连字符
      text = text.replace(/\s+([，。！？；：""''（）])/g, '$1');  // 中文标点前的空格
    }

    // 过滤过短的文本
    if (text.length < config.minLength) {
      text = '';
    }

    return {
      text,
      confidence: metadata.confidence || 0,
      imagePath: metadata.imagePath || '',
      originalLength: rawText.length,
      cleanedLength: text.length
    };
  }

  /**
   * 获取Content的图片路径列表
   * @param {object} content - Content对象
   * @returns {Promise<string[]>} 图片路径数组
   */
  static async getContentImagePaths(content) {
    const imagePaths = [];

    try {
      // 从all_images字段解析
      if (content.all_images) {
        let allImages = [];

        if (typeof content.all_images === 'string') {
          try {
            allImages = JSON.parse(content.all_images);
          } catch (e) {
            logger.warn('解析all_images失败', { contentId: content.id });
          }
        } else if (Array.isArray(content.all_images)) {
          allImages = content.all_images;
        }

        // 获取本地存储的图片路径
        for (const imageUrl of allImages) {
          const localPath = await this.getLocalImagePath(content, imageUrl);
          if (localPath) {
            imagePaths.push(localPath);
          }
        }
      }

      // 检查本地存储目录
      const storageDir = path.join(process.env.STORAGE_ROOT_PATH || './media', content.platform, `${content.author}_${content.title}_${content.content_id}`);

      try {
        await fs.access(storageDir);
        const files = await fs.readdir(storageDir);

        for (const file of files) {
          if (file.match(/^image_\d+\.(jpg|jpeg|png|webp)$/i)) {
            imagePaths.push(path.join(storageDir, file));
          }
        }
      } catch (e) {
        // 目录不存在，忽略
      }

      // 去重
      const uniquePaths = [...new Set(imagePaths)];

      logger.info('找到Content图片', {
        contentId: content.id,
        count: uniquePaths.length
      });

      return uniquePaths;
    } catch (error) {
      logger.error('获取Content图片路径失败:', {
        contentId: content.id,
        error: error.message
      });
      return [];
    }
  }

  /**
   * 获取图片的本地存储路径
   * @param {object} content - Content对象
   * @param {string} imageUrl - 图片URL
   * @returns {Promise<string|null>} 本地路径
   */
  static async getLocalImagePath(content, imageUrl) {
    try {
      const filename = path.basename(imageUrl).split('?')[0];
      const storageDir = path.join(
        process.env.STORAGE_ROOT_PATH || './media',
        content.platform,
        `${content.author}_${content.title}_${content.content_id}`
      );

      const localPath = path.join(storageDir, filename);

      await fs.access(localPath);
      return localPath;
    } catch (e) {
      return null;
    }
  }

  /**
   * 生成缓存键
   * @param {string} imagePath - 图片路径
   * @param {string} language - OCR语言
   * @returns {string} 缓存键
   */
  static getCacheKey(imagePath, language) {
    return `ocr:${imagePath}:${language}`;
  }

  /**
   * 清除缓存
   * @param {string} imagePath - 图片路径（可选）
   */
  static clearCache(imagePath = null) {
    if (imagePath) {
      const keys = ocrCache.keys().filter(key => key.startsWith(`ocr:${imagePath}`));
      keys.forEach(key => ocrCache.del(key));
      logger.info('已清除图片OCR缓存', { imagePath });
    } else {
      ocrCache.flushAll();
      logger.info('已清除所有OCR缓存');
    }
  }

  /**
   * 获取缓存统计
   * @returns {object} 缓存统计
   */
  static getCacheStats() {
    const keys = ocrCache.keys();
    const stats = ocrCache.getStats();

    return {
      count: keys.length,
      keys: keys.slice(0, 10),  // 返回前10个键
      stats: {
        hits: stats.hits,
        misses: stats.misses,
        keys: stats.keys,
        ksize: stats.ksize,
        vsize: stats.vsize
      }
    };
  }
}

module.exports = OcrService;

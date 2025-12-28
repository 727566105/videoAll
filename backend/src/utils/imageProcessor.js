/**
 * 图片预处理工具
 *
 * 使用Sharp库对图片进行预处理，提高OCR准确率
 */

const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const ocrConfig = require('../config/ocr.config');
const logger = require('../utils/logger');

class ImageProcessor {
  /**
   * 预处理图片以提高OCR准确率
   * @param {string} inputPath - 原始图片路径
   * @param {object} options - 处理选项
   * @returns {Promise<string>} 处理后的图片路径
   */
  static async preprocessForOcr(inputPath, options = {}) {
    const startTime = Date.now();

    try {
      // 检查文件是否存在
      await fs.access(inputPath);

      const config = ocrConfig.preprocessing;
      const outputPath = this.generateProcessedPath(inputPath);

      // 构建Sharp处理链
      let pipeline = sharp(inputPath);

      // 调整尺寸（保持宽高比）
      if (config.enabled) {
        pipeline = pipeline.resize(config.maxWidth, config.maxHeight, {
          fit: 'inside',
          withoutEnlargement: true
        });
      }

      // 转灰度（提高OCR准确率）
      if (config.grayscale) {
        pipeline = pipeline.grayscale();
      }

      // 标准化对比度
      if (config.normalize) {
        pipeline = pipeline.normalize();
      }

      // 输出处理后的图片
      await pipeline.jpeg({ quality: config.quality }).toFile(outputPath);

      const duration = Date.now() - startTime;

      if (ocrConfig.metrics.enabled && ocrConfig.metrics.logSlowOperations) {
        if (duration > ocrConfig.metrics.slowThreshold) {
          logger.warn(`图片预处理耗时过长: ${duration}ms`, { inputPath });
        }
      }

      logger.info('图片预处理完成', {
        inputPath,
        outputPath,
        duration: `${duration}ms`
      });

      return outputPath;
    } catch (error) {
      logger.error('图片预处理失败:', error);
      throw new Error(`图片预处理失败: ${error.message}`);
    }
  }

  /**
   * 批量预处理图片
   * @param {string[]} inputPaths - 原始图片路径数组
   * @param {object} options - 处理选项
   * @returns {Promise<string[]>} 处理后的图片路径数组
   */
  static async batchPreprocess(inputPaths, options = {}) {
    const results = [];

    for (const inputPath of inputPaths) {
      try {
        const processedPath = await this.preprocessForOcr(inputPath, options);
        results.push(processedPath);
      } catch (error) {
        logger.error(`批量预处理失败: ${inputPath}`, error);
        results.push(null); // 标记失败
      }
    }

    return results;
  }

  /**
   * 生成处理后的图片路径
   * @param {string} originalPath - 原始图片路径
   * @returns {string} 处理后的图片路径
   */
  static generateProcessedPath(originalPath) {
    const parsedPath = path.parse(originalPath);
    return path.join(
      parsedPath.dir,
      `${parsedPath.name}_ocr_processed${parsedPath.ext}`
    );
  }

  /**
   * 获取图片信息
   * @param {string} imagePath - 图片路径
   * @returns {Promise<object>} 图片信息
   */
  static async getImageInfo(imagePath) {
    try {
      const metadata = await sharp(imagePath).metadata();

      return {
        width: metadata.width,
        height: metadata.height,
        format: metadata.format,
        size: metadata.size,
        space: metadata.space
      };
    } catch (error) {
      logger.error('获取图片信息失败:', error);
      throw new Error(`获取图片信息失败: ${error.message}`);
    }
  }

  /**
   * 检查图片是否需要预处理
   * @param {string} imagePath - 图片路径
   * @returns {Promise<boolean>} 是否需要预处理
   */
  static async needsPreprocessing(imagePath) {
    try {
      const info = await this.getImageInfo(imagePath);
      const config = ocrConfig.preprocessing;

      // 如果图片尺寸超过阈值，需要预处理
      if (info.width > config.maxWidth || info.height > config.maxHeight) {
        return true;
      }

      // 如果不是灰度图，可以考虑预处理
      if (config.grayscale && info.space !== 'b-w') {
        return true;
      }

      return false;
    } catch (error) {
      logger.error('检查图片预处理需求失败:', error);
      return true; // 出错时默认需要预处理
    }
  }

  /**
   * 清理处理后的临时文件
   * @param {string[]} processedPaths - 处理后的文件路径数组
   */
  static async cleanup(processedPaths) {
    for (const filePath of processedPaths) {
      if (!filePath) continue;

      try {
        await fs.unlink(filePath);
        logger.debug('已删除临时文件:', filePath);
      } catch (error) {
        logger.warn(`删除临时文件失败: ${filePath}`, error);
      }
    }
  }

  /**
   * 批量清理临时文件（带错误处理）
   * @param {string[]} processedPaths - 处理后的文件路径数组
   */
  static async batchCleanup(processedPaths) {
    const cleanupPromises = processedPaths.map(async (filePath) => {
      if (!filePath) return null;

      try {
        await fs.unlink(filePath);
        return { path: filePath, success: true };
      } catch (error) {
        logger.warn(`删除临时文件失败: ${filePath}`, error);
        return { path: filePath, success: false, error: error.message };
      }
    });

    const results = await Promise.all(cleanupPromises);
    const successCount = results.filter(r => r && r.success).length;

    logger.info(`批量清理完成: ${successCount}/${processedPaths.length} 成功`);
  }
}

module.exports = ImageProcessor;

/**
 * AI标签服务
 *
 * 负责管理AI生成的标签，包括自动添加、人工确认等操作
 */

const { AppDataSource } = require('../utils/db');
const logger = require('../utils/logger');

class AiTagService {
  // 置信度阈值
  static CONFIDENCE_AUTO_ADD = 0.8; // 置信度>0.8自动添加
  static CONFIDENCE_PENDING = 0.5;  // 置信度0.5-0.8待确认
  static CONFIDENCE_IGNORE = 0.5;   // 置信度<0.5忽略

  /**
   * 自动添加高置信度标签
   * @param {string} contentId - 内容ID
   * @param {Array} aiTags - AI生成的标签数组
   * @returns {Promise<object>}
   */
  static async autoAddTags(contentId, aiTags) {
    try {
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      const contentRepository = AppDataSource.getRepository('Content');

      // 过滤高置信度标签
      const highConfidenceTags = aiTags.filter(tag => {
        const confidence = tag.confidence || tag.score || 0.8;
        return confidence >= this.CONFIDENCE_AUTO_ADD;
      });

      if (highConfidenceTags.length === 0) {
        return {
          success: true,
          message: '没有高置信度标签需要自动添加',
          added: [],
        };
      }

      const addedTags = [];

      for (const tagData of highConfidenceTags) {
        const tagName = tagData.name || tagData;
        const confidence = tagData.confidence || tagData.score || 0.8;

        // 检查标签是否存在，不存在则创建
        let tag = await tagRepository.findOne({
          where: { name: tagName },
        });

        if (!tag) {
          // 创建新标签
          tag = tagRepository.create({
            name: tagName,
            color: this.getTagColor(tagName),
            description: `AI自动生成 (置信度: ${(confidence * 100).toFixed(0)}%)`,
          });
          await tagRepository.save(tag);
          logger.info(`AI创建新标签: ${tagName}`);
        } else {
          // 更新标签使用计数
          tag.usage_count = (tag.usage_count || 0) + 1;
          await tagRepository.save(tag);
        }

        // 检查内容是否已有该标签
        const existingContentTag = await contentTagRepository.findOne({
          where: { content_id: contentId, tag_id: tag.id },
        });

        if (!existingContentTag) {
          // 添加标签到内容
          const contentTag = contentTagRepository.create({
            content_id: contentId,
            tag_id: tag.id,
          });
          await contentTagRepository.save(contentTag);

          // 更新内容的tags字段
          const content = await contentRepository.findOne({
            where: { id: contentId },
          });

          if (content) {
            const currentTags = content.tags || [];
            if (!currentTags.some(t => t.id === tag.id)) {
              currentTags.push({
                id: tag.id,
                name: tag.name,
                color: tag.color,
                is_ai_generated: true,
                confidence: confidence,
              });
              content.tags = currentTags;
              await contentRepository.save(content);
            }
          }

          addedTags.push({
            id: tag.id,
            name: tag.name,
            confidence,
          });
        }
      }

      logger.info(`AI自动添加标签完成 (内容: ${contentId}, 添加数: ${addedTags.length})`);

      return {
        success: true,
        message: `自动添加 ${addedTags.length} 个标签`,
        added: addedTags,
      };
    } catch (error) {
      logger.error(`自动添加AI标签失败 (内容: ${contentId}):`, error);
      return {
        success: false,
        message: `自动添加标签失败: ${error.message}`,
        added: [],
      };
    }
  }

  /**
   * 获取待确认的标签
   * @param {string} contentId - 内容ID
   * @returns {Promise<object>}
   */
  static async getPendingTags(contentId) {
    try {
      const aiResultRepository = AppDataSource.getRepository('AiAnalysisResult');

      const result = await aiResultRepository.findOne({
        where: { content_id: contentId },
        order: { created_at: 'DESC' },
      });

      if (!result) {
        return {
          success: true,
          pending: [],
        };
      }

      const tags = result.generated_tags || [];

      // 过滤待确认标签
      const pendingTags = tags.filter(tag => {
        const confidence = tag.confidence || tag.score || 0;
        return confidence >= this.CONFIDENCE_PENDING && confidence < this.CONFIDENCE_AUTO_ADD;
      });

      return {
        success: true,
        pending: pendingTags,
        analysis_id: result.id,
        status: result.status,
        created_at: result.created_at,
      };
    } catch (error) {
      logger.error(`获取待确认标签失败 (内容: ${contentId}):`, error);
      return {
        success: false,
        message: `获取待确认标签失败: ${error.message}`,
        pending: [],
      };
    }
  }

  /**
   * 确认AI标签
   * @param {string} contentId - 内容ID
   * @param {Array} confirmedTagNames - 确认的标签名称数组
   * @param {Array} rejectedTagNames - 拒绝的标签名称数组
   * @returns {Promise<object>}
   */
  static async confirmTags(contentId, confirmedTagNames, rejectedTagNames = []) {
    try {
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      const contentRepository = AppDataSource.getRepository('Content');
      const aiResultRepository = AppDataSource.getRepository('AiAnalysisResult');

      const confirmedTags = [];
      const rejectedTags = [];

      // 处理确认的标签
      for (const tagName of confirmedTagNames) {
        // 检查标签是否存在，不存在则创建
        let tag = await tagRepository.findOne({
          where: { name: tagName },
        });

        if (!tag) {
          tag = tagRepository.create({
            name: tagName,
            color: this.getTagColor(tagName),
            description: '用户手动确认的AI标签',
          });
          await tagRepository.save(tag);
        } else {
          tag.usage_count = (tag.usage_count || 0) + 1;
          await tagRepository.save(tag);
        }

        // 检查内容是否已有该标签
        const existingContentTag = await contentTagRepository.findOne({
          where: { content_id: contentId, tag_id: tag.id },
        });

        if (!existingContentTag) {
          // 添加标签到内容
          const contentTag = contentTagRepository.create({
            content_id: contentId,
            tag_id: tag.id,
          });
          await contentTagRepository.save(contentTag);

          // 更新内容的tags字段
          const content = await contentRepository.findOne({
            where: { id: contentId },
          });

          if (content) {
            const currentTags = content.tags || [];
            if (!currentTags.some(t => t.id === tag.id)) {
              currentTags.push({
                id: tag.id,
                name: tag.name,
                color: tag.color,
                is_ai_generated: true,
                is_confirmed: true,
              });
              content.tags = currentTags;
              await contentRepository.save(content);
            }
          }
        }

        confirmedTags.push(tagName);
      }

      // 记录拒绝的标签（用于统计分析）
      rejectedTags.push(...rejectedTagNames);

      // 更新分析结果状态
      const aiResult = await aiResultRepository.findOne({
        where: { content_id: contentId },
        order: { created_at: 'DESC' },
      });

      if (aiResult) {
        const currentTags = aiResult.generated_tags || [];
        const updatedTags = currentTags.map(tag => {
          if (confirmedTagNames.includes(tag.name)) {
            return { ...tag, confirmed: true };
          }
          if (rejectedTagNames.includes(tag.name)) {
            return { ...tag, rejected: true };
          }
          return tag;
        });
        aiResult.generated_tags = updatedTags;
        await aiResultRepository.save(aiResult);
      }

      logger.info(`标签确认完成 (内容: ${contentId}, 确认: ${confirmedTags.length}, 拒绝: ${rejectedTags.length})`);

      return {
        success: true,
        message: `确认 ${confirmedTags.length} 个标签，拒绝 ${rejectedTags.length} 个标签`,
        confirmed: confirmedTags,
        rejected: rejectedTags,
      };
    } catch (error) {
      logger.error(`确认AI标签失败 (内容: ${contentId}):`, error);
      return {
        success: false,
        message: `确认标签失败: ${error.message}`,
      };
    }
  }

  /**
   * 批量确认AI标签
   * @param {string} contentId - 内容ID
   * @param {object} tagActions - 标签操作对象 { tagName: 'confirm' | 'reject' }
   * @returns {Promise<object>}
   */
  static async batchConfirmTags(contentId, tagActions) {
    const confirmed = [];
    const rejected = [];

    for (const [tagName, action] of Object.entries(tagActions)) {
      if (action === 'confirm') {
        confirmed.push(tagName);
      } else if (action === 'reject') {
        rejected.push(tagName);
      }
    }

    return this.confirmTags(contentId, confirmed, rejected);
  }

  /**
   * 获取内容的AI标签状态
   * @param {string} contentId - 内容ID
   * @returns {Promise<object>}
   */
  static async getContentAiStatus(contentId) {
    try {
      const aiResultRepository = AppDataSource.getRepository('AiAnalysisResult');
      const contentRepository = AppDataSource.getRepository('Content');

      // 获取AI分析结果
      const aiResult = await aiResultRepository.findOne({
        where: { content_id: contentId },
        order: { created_at: 'DESC' },
      });

      // 获取内容标签和描述
      const content = await contentRepository.findOne({
        where: { id: contentId },
      });

      // 确保 tags 是数组
      const contentTags = Array.isArray(content?.tags) ? content.tags : [];
      const aiGeneratedTags = contentTags.filter(t => t.is_ai_generated);

      // 从 analysis_result 中提取详细数据
      const analysisResult = aiResult?.analysis_result || {};
      const stages = analysisResult.stages || {};
      const ocrResults = analysisResult.ocr_results || [];
      const aiDescription = analysisResult.description || null; // AI生成的描述

      // 判断是否正在分析中
      const isProcessing = aiResult?.status === 'processing';

      return {
        success: true,
        data: {
          has_analysis: !!aiResult && aiResult.status === 'completed',
          analysis_status: aiResult?.status || 'none',
          is_processing: isProcessing,
          current_stage: aiResult?.current_stage || null,
          analysis_time: aiResult?.created_at || null,
          execution_time: aiResult?.execution_time || null,
          ai_generated_count: aiGeneratedTags.length,
          ai_tags: aiGeneratedTags,
          total_tags: contentTags.length,
          // AI生成的描述（不是原始描述）
          description: aiDescription,
          ocr_results: ocrResults,
          stages: stages,
        },
      };
    } catch (error) {
      logger.error(`获取内容AI标签状态失败 (内容: ${contentId}):`, error);
      return {
        success: false,
        message: `获取状态失败: ${error.message}`,
      };
    }
  }

  /**
   * 重新分析内容
   * @param {string} contentId - 内容ID
   * @param {object} contentData - 内容数据
   * @returns {Promise<object>}
   */
  static async reAnalyzeContent(contentId, contentData) {
    try {
      const AiAnalysisService = require('./AiAnalysisService');

      // 触发重新分析
      const result = await AiAnalysisService.analyzeWithRetry(contentData, contentId, 3);

      if (result.success) {
        // 自动添加高置信度标签
        await this.autoAddTags(contentId, result.tags);
      }

      return result;
    } catch (error) {
      logger.error(`重新分析内容失败 (内容: ${contentId}):`, error);
      return {
        success: false,
        message: `重新分析失败: ${error.message}`,
      };
    }
  }

  /**
   * 获取标签颜色
   * @param {string} tagName - 标签名称
   * @returns {string}
   */
  static getTagColor(tagName) {
    // 根据标签名称生成一致的颜色
    const colors = [
      'magenta', 'red', 'volcano', 'orange', 'gold',
      'lime', 'green', 'cyan', 'blue', 'geekblue',
      'purple'
    ];

    let hash = 0;
    for (let i = 0; i < tagName.length; i++) {
      hash = tagName.charCodeAt(i) + ((hash << 5) - hash);
    }

    return colors[Math.abs(hash) % colors.length];
  }

  /**
   * 获取AI生成标签的统计信息
   * @returns {Promise<object>}
   */
  static async getAiTagStats() {
    try {
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');

      // 获取所有标签
      const allTags = await tagRepository.find();

      // 统计AI生成的标签
      let aiGeneratedCount = 0;
      let totalUsage = 0;

      for (const tag of allTags) {
        if (tag.description?.includes('AI自动生成') || tag.description?.includes('AI')) {
          aiGeneratedCount++;
        }
        totalUsage += tag.usage_count || 0;
      }

      // 统计已确认的AI标签数量
      const aiContentTags = await contentTagRepository
        .createQueryBuilder('ct')
        .leftJoinAndSelect('ct.tag', 'tag')
        .where('tag.description LIKE :desc', { desc: '%AI%' })
        .getCount();

      return {
        success: true,
        data: {
          total_ai_tags: aiGeneratedCount,
          total_ai_usages: aiContentTags,
          total_tags: allTags.length,
          total_usages: totalUsage,
          ai_percentage: allTags.length > 0 ? ((aiGeneratedCount / allTags.length) * 100).toFixed(1) : 0,
        },
      };
    } catch (error) {
      logger.error('获取AI标签统计信息失败:', error);
      return {
        success: false,
        message: `获取统计信息失败: ${error.message}`,
      };
    }
  }
}

module.exports = AiTagService;

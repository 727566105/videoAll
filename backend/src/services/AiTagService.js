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
   * @param {Array} aiTags - AI生成的标签数组（支持字符串数组或对象数组）
   * @returns {Promise<object>}
   */
  static async autoAddTags(contentId, aiTags) {
    const traceId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    logger.info(`[AI标签][${traceId}] 开始处理 (内容: ${contentId})`);
    logger.debug(`[AI标签][${traceId}] 输入标签: ${JSON.stringify(aiTags)}`);

    try {
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');

      // ✅ 新增：兼容两种输入格式
      const normalizedTags = aiTags.map(tag => {
        if (typeof tag === 'string') {
          return { name: tag, confidence: 0.8, type: '未知' };
        }
        return {
          name: tag.name || tag.tag,
          confidence: tag.confidence || tag.score || 0.8,
          type: tag.type || '未知'
        };
      });

      // 过滤高置信度标签
      const highConfidenceTags = normalizedTags.filter(tag => {
        const confidence = tag.confidence || 0.8;
        return confidence >= this.CONFIDENCE_AUTO_ADD;
      });

      if (highConfidenceTags.length === 0) {
        logger.info(`[AI标签][${traceId}] 没有高置信度标签需要自动添加`);
        return {
          success: true,
          message: '没有高置信度标签需要自动添加',
          added: [],
        };
      }

      const addedTags = [];

      for (const tagData of highConfidenceTags) {
        const tagName = tagData.name.trim();
        const confidence = tagData.confidence;

        // ✅ 新增：验证标签质量
        if (!this.isValidTag(tagName)) {
          logger.warn(`[AI标签][${traceId}] 跳过低质量标签: ${tagName}`);
          continue;
        }

        // ✅ 新增：查找相似标签（优先复用）
        let tag = await this.findSimilarTags(tagName);

        if (!tag) {
          // 创建新标签
          tag = tagRepository.create({
            name: tagName,
            color: this.getTagColor(tagName),
            description: `AI自动生成 (${tagData.type}标签, 置信度: ${(confidence * 100).toFixed(0)}%)`,
          });
          await tagRepository.save(tag);
          logger.info(`[AI标签][${traceId}] AI创建新标签: ${tagName}`);
        } else {
          // 更新使用计数
          tag.usage_count = (tag.usage_count || 0) + 1;
          await tagRepository.save(tag);
          logger.info(`[AI标签][${traceId}] 复用现有标签: ${tagName} (使用次数: ${tag.usage_count})`);
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

          addedTags.push({
            id: tag.id,
            name: tag.name,
            color: tag.color,
            confidence,
            type: tagData.type
          });
        }
      }

      // ✅ 新增：同步更新 Content.tags 字段
      await this.syncContentTags(contentId);

      logger.info(`[AI标签][${traceId}] 处理完成 (添加数: ${addedTags.length})`);

      return {
        success: true,
        message: `自动添加 ${addedTags.length} 个标签`,
        added: addedTags,
      };
    } catch (error) {
      logger.error(`[AI标签][${traceId}] 处理失败:`, {
        contentId,
        error: error.message,
        stack: error.stack
      });
      return {
        success: false,
        message: `自动添加标签失败: ${error.message}`,
        added: [],
      };
    }
  }

  /**
   * 标签质量验证
   * @param {string} tagName - 标签名称
   * @returns {boolean}
   */
  static isValidTag(tagName) {
    // 1. 长度检查（2-6个字符，兼容emoji等）
    if (tagName.length < 2 || tagName.length > 6) {
      logger.debug(`标签长度不合格: ${tagName} (长度: ${tagName.length})`);
      return false;
    }

    // 2. 禁止泛化词
    const forbiddenWords = ['推荐', '热门', '必看', '分享', '精选', '最新', '优质', '不错'];
    if (forbiddenWords.includes(tagName)) {
      logger.debug(`标签包含禁止词: ${tagName}`);
      return false;
    }

    // 3. 必须包含至少一个汉字
    if (!/[\u4e00-\u9fa5]/.test(tagName)) {
      logger.debug(`标签不含汉字: ${tagName}`);
      return false;
    }

    return true;
  }

  /**
   * 计算编辑距离（Levenshtein Distance）
   * @param {string} str1 - 第一个字符串
   * @param {string} str2 - 第二个字符串
   * @returns {number} 编辑距离
   */
  static levenshteinDistance(str1, str2) {
    const m = str1.length;
    const n = str2.length;
    const dp = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0));

    for (let i = 0; i <= m; i++) dp[i][0] = i;
    for (let j = 0; j <= n; j++) dp[0][j] = j;

    for (let i = 1; i <= m; i++) {
      for (let j = 1; j <= n; j++) {
        if (str1[i - 1] === str2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + 1);
        }
      }
    }

    return dp[m][n];
  }

  /**
   * 查找语义相似的现有标签（避免创建重复标签）
   * @param {string} newTagName - 新标签名称
   * @returns {Promise<object|null>} 相似标签或null
   */
  static async findSimilarTags(newTagName) {
    try {
      const tagRepository = AppDataSource.getRepository('Tag');

      // 1. 精确匹配（大小写不敏感）
      const exactMatch = await tagRepository
        .createQueryBuilder('tag')
        .where('LOWER(tag.name) = LOWER(:name)', { name: newTagName })
        .getOne();

      if (exactMatch) {
        logger.debug(`标签精确匹配: ${newTagName}`);
        return exactMatch;
      }

      // 2. 同义词映射
      const synonyms = {
        '教程': ['教学', '指南', '入门', '基础', '教程'],
        '测评': ['评测', '体验', '开箱', '测试', '测评'],
        '种草': ['推荐', '安利', '好物', '必买', '种草'],
        '干货': ['技巧', '攻略', '秘籍', '方法', '干货'],
        '平价': ['便宜', '实惠', '性价比', '省钱', '平价'],
        '高端': ['奢华', '精致', '品质', '轻奢', '高端'],
        '穿搭': ['搭配', '造型', 'OOTD', '穿搭'],
        '美食': ['吃播', '探店', '料理', '美食'],
        '健身': ['运动', '塑形', '减脂', '健身']
      };

      for (const [canonical, variants] of Object.entries(synonyms)) {
        if (variants.includes(newTagName)) {
          const canonicalTag = await tagRepository.findOne({
            where: { name: canonical }
          });
          if (canonicalTag) {
            logger.info(`标签同义词映射: ${newTagName} -> ${canonical}`);
            return canonicalTag;
          }
        }
      }

      // 3. 模糊匹配（编辑距离<=1）
      const allTags = await tagRepository.find();
      for (const tag of allTags) {
        const distance = this.levenshteinDistance(newTagName, tag.name);
        if (distance <= 1 && tag.name.length >= 2) {
          logger.info(`标签模糊匹配: ${newTagName} -> ${tag.name} (距离: ${distance})`);
          return tag;
        }
      }

      return null;
    } catch (error) {
      logger.error(`查找相似标签失败 (${newTagName}):`, error);
      return null;
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
   * 同步 Content.tags JSON 字段（与 ContentTag 表保持一致）
   * @param {string} contentId - 内容ID
   * @returns {Promise<void>}
   */
  static async syncContentTags(contentId) {
    try {
      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentRepository = AppDataSource.getRepository('Content');

      // 获取所有关联标签
      const contentTags = await contentTagRepository.find({
        where: { content_id: contentId }
      });

      const tagIds = contentTags.map(ct => ct.tag_id);

      // 如果没有标签，清空Content.tags字段
      if (tagIds.length === 0) {
        await contentRepository.update(contentId, {
          tags: JSON.stringify([])
        });
        logger.debug(`同步内容标签完成: ${contentId} (0个标签)`);
        return;
      }

      // 获取标签详情
      const tags = await tagRepository
        .createQueryBuilder('tag')
        .where('tag.id IN (:...tagIds)', { tagIds })
        .getMany();

      // 构建标签对象数组
      const tagObjects = tags.map(tag => ({
        id: tag.id,
        name: tag.name,
        color: tag.color,
        usage_count: tag.usage_count || 0,
        is_ai_generated: tag.description?.includes('AI') || false
      }));

      // 更新 Content.tags 字段
      await contentRepository.update(contentId, {
        tags: JSON.stringify(tagObjects)
      });

      logger.debug(`同步内容标签完成: ${contentId} (${tags.length}个标签)`);
    } catch (error) {
      logger.error(`同步内容标签失败 (contentId: ${contentId}):`, error);
      throw error;
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

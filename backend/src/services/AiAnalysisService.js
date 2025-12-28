/**
 * AI分析服务
 *
 * 负责调用AI API分析内容并生成标签
 * 支持Ollama、OpenAI、Anthropic等提供商
 */

const { AppDataSource } = require('../utils/db');
const EncryptionService = require('../utils/encryption');
const logger = require('../utils/logger');
const OcrService = require('./OcrService');
const AiTagService = require('./AiTagService');

class AiAnalysisService {
  // 缓存配置，避免频繁查询数据库
  static configCache = null;
  static configCacheTime = 0;
  static CONFIG_CACHE_TTL = 60000; // 1分钟缓存

  /**
   * 获取活跃的AI配置
   * @returns {Promise<object|null>}
   */
  static async getActiveConfig() {
    const now = Date.now();

    // 使用缓存
    if (this.configCache && (now - this.configCacheTime) < this.CONFIG_CACHE_TTL) {
      return this.configCache;
    }

    try {
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const config = await aiConfigRepository.findOne({
        where: { is_enabled: true, status: 'active' },
        order: { priority: 'ASC' },
      });

      // 解密API密钥
      if (config?.api_key_encrypted) {
        config.api_key = EncryptionService.decrypt(config.api_key_encrypted);
        config.api_key_encrypted = null;
      }

      this.configCache = config;
      this.configCacheTime = now;

      return config;
    } catch (error) {
      logger.error('获取AI配置失败:', error);
      return null;
    }
  }

  /**
   * 清除配置缓存
   */
  static clearConfigCache() {
    this.configCache = null;
    this.configCacheTime = 0;
  }

  /**
   * 分析内容并生成标签
   * @param {object} parsedData - 解析后的内容数据
   * @param {string} contentId - 内容ID
   * @returns {Promise<object>} 分析结果
   */
  static async analyzeContent(parsedData, contentId) {
    const startTime = Date.now();
    let aiConfig = null;

    try {
      // 获取AI配置
      aiConfig = await this.getActiveConfig();

      if (!aiConfig) {
        logger.warn('未找到启用的AI配置，跳过AI分析');
        return {
          success: false,
          message: 'AI配置未启用',
          tags: [],
        };
      }

      logger.info(`开始AI分析 (内容: ${contentId}, 提供商: ${aiConfig.provider})`);

      // 构建Prompt
      const prompt = this.buildPrompt(parsedData);

      // 调用AI API
      const aiResponse = await this.callAiApi(prompt, aiConfig);

      // 解析响应
      const analysisResult = this.parseAiResponse(aiResponse);

      // 保存分析结果
      const executionTime = Date.now() - startTime;
      await this.saveAnalysisResult(contentId, aiConfig.id, analysisResult, aiResponse, executionTime);

      logger.info(`AI分析完成 (内容: ${contentId}, 耗时: ${executionTime}ms, 标签数: ${analysisResult.tags?.length || 0})`);

      return {
        success: true,
        message: 'AI分析成功',
        tags: analysisResult.tags || [],
        confidence_scores: analysisResult.confidence_scores || {},
        execution_time: executionTime,
      };
    } catch (error) {
      logger.error(`AI分析失败 (内容: ${contentId}):`, error);

      // 保存失败记录
      const executionTime = Date.now() - startTime;
      await this.saveAnalysisResult(
        contentId,
        aiConfig?.id || null,
        { tags: [], error: error.message },
        null,
        executionTime,
        error.message
      );

      return {
        success: false,
        message: `AI分析失败: ${error.message}`,
        tags: [],
      };
    }
  }

  /**
   * 带重试的分析
   * @param {object} parsedData - 解析后的内容数据
   * @param {string} contentId - 内容ID
   * @param {number} maxRetries - 最大重试次数
   * @returns {Promise<object>}
   */
  static async analyzeWithRetry(parsedData, contentId, maxRetries = 3) {
    let lastError = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const result = await this.analyzeContent(parsedData, contentId);

        if (result.success) {
          return result;
        }

        lastError = new Error(result.message);
      } catch (error) {
        lastError = error;
      }

      // 如果不是最后一次尝试，等待后重试（指数退避）
      if (attempt < maxRetries) {
        const waitTime = Math.pow(2, attempt) * 1000; // 2, 4, 8秒
        logger.info(`AI分析重试 ${attempt}/${maxRetries} 失败，等待 ${waitTime}ms 后重试`);
        await this.sleep(waitTime);
      }
    }

    return {
      success: false,
      message: `AI分析重试${maxRetries}次均失败: ${lastError?.message}`,
      tags: [],
    };
  }

  /**
   * 构建AI分析Prompt
   * @param {object} parsedData - 解析后的内容数据
   * @returns {string}
   */
  static buildPrompt(parsedData) {
    const { title, description, platform, original_tags, author } = parsedData;

    // 从偏好设置中获取系统提示词
    const systemPrompt = this.getSystemPrompt(platform);

    // 构建用户提示词
    let userPrompt = `请分析以下社交媒体内容，生成相关标签：\n\n`;

    if (title) {
      userPrompt += `标题：${title}\n`;
    }

    if (description) {
      // 限制描述长度，避免超出token限制
      const truncatedDesc = description.length > 1000 ? description.substring(0, 1000) + '...' : description;
      userPrompt += `描述：${truncatedDesc}\n`;
    }

    if (platform) {
      userPrompt += `平台：${this.getPlatformName(platform)}\n`;
    }

    if (author) {
      userPrompt += `作者：${author}\n`;
    }

    if (original_tags && Array.isArray(original_tags) && original_tags.length > 0) {
      userPrompt += `原始标签：${original_tags.join(', ')}\n`;
    }

    userPrompt += `\n请根据内容分析，生成5-10个相关标签。\n`;
    userPrompt += `标签要求：\n`;
    userPrompt += `1. 简洁明了，每个标签2-4个汉字\n`;
    userPrompt += `2. 符合平台内容风格\n`;
    userPrompt += `3. 包括主题、风格、受众等相关维度\n`;
    userPrompt += `4. 以JSON格式返回结果\n\n`;
    userPrompt += `返回格式：\n`;
    userPrompt += `{\n`;
    userPrompt += `  "tags": ["标签1", "标签2", "标签3"],\n`;
    userPrompt += `  "reasoning": "简要说明标签生成理由"\n`;
    userPrompt += `}`;

    // 组合完整消息
    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ];

    return JSON.stringify(messages);
  }

  /**
   * 获取系统提示词
   * @param {string} platform - 平台名称
   * @returns {string}
   */
  static getSystemPrompt(platform) {
    const defaultPrompt = `你是一个社交媒体内容分析助手，专注于为内容生成精准的标签。
你的任务是：
1. 理解内容的主题和风格
2. 生成符合平台特点的标签
3. 标签应该简洁、有代表性`;

    // 平台特定的提示词
    const platformPrompts = {
      xiaohongshu: `你是一个社交媒体内容分析助手，专注于小红书平台。
小红书标签特点：
1. 常用标签如：#教程、#测评、#种草、#好物分享、#生活记录
2. 风格标签如：#干货、#避坑、#必入、#平价、#高端
3. 关注实用性、生活美学、个人成长类内容`,
      douyin: `你是一个社交媒体内容分析助手，专注于抖音平台。
抖音标签特点：
1. 常用标签如：#搞笑、#舞蹈、#美食、#情感、#知识分享
2. 热门话题标签、挑战赛标签
3. 关注娱乐性、传播性强的内容`,
      bilibili: `你是一个社交媒体内容分析助手，专注于B站平台。
B站标签特点：
1. 常用标签如：#技术宅、二次元、游戏、科普、鬼畜
2. 分区标签如：#动画、#游戏、#科技、#生活
3. 关注深度内容、专业性强的内容`,
      weibo: `你是一个社交媒体内容分析助手，专注于微博平台。
微博标签特点：
1. 热点话题标签、明星八卦、社会新闻
2. 观点表达类标签
3. 关注时效性、话题性强的内容`,
      kuaishou: `你是一个社交媒体内容分析助手，专注于快手平台。
快手标签特点：
1. 接地气、生活化标签
2. 接地气的才艺、技能展示标签
3. 关注真实、普通人的生活内容`,
    };

    return platformPrompts[platform] || defaultPrompt;
  }

  /**
   * 获取平台中文名称
   * @param {string} platform - 平台标识
   * @returns {string}
   */
  static getPlatformName(platform) {
    const platformNames = {
      xiaohongshu: '小红书',
      douyin: '抖音',
      bilibili: '哔哩哔哩',
      weibo: '微博',
      kuaishou: '快手',
    };

    return platformNames[platform] || platform;
  }

  /**
   * 调用AI API
   * @param {string} prompt - 提示词
   * @param {object} config - AI配置
   * @returns {Promise<object>}
   */
  static async callAiApi(prompt, config) {
    const { provider, api_endpoint, api_key, model, timeout, preferences } = config;

    switch (provider) {
      case 'ollama':
        return this.callOllamaApi(prompt, api_endpoint, model, timeout, preferences);
      case 'openai':
        return this.callOpenAiApi(prompt, api_endpoint, api_key, model, timeout, preferences);
      case 'anthropic':
        return this.callAnthropicApi(prompt, api_endpoint, api_key, model, timeout, preferences);
      case 'deepseek':
        return this.callDeepSeekApi(prompt, api_endpoint, api_key, model, timeout, preferences);
      case 'custom':
        return this.callCustomApi(prompt, api_endpoint, api_key, model, timeout, preferences);
      default:
        throw new Error(`不支持的AI提供商: ${provider}`);
    }
  }

  /**
   * 调用Ollama API
   */
  static async callOllamaApi(prompt, endpoint, model, timeout, preferences) {
    const defaultEndpoint = 'http://localhost:11434';
    const endpointUrl = endpoint || defaultEndpoint;
    const modelName = model || 'qwen2.5:7b';

    let messages;
    try {
      messages = JSON.parse(prompt);
    } catch {
      messages = [{ role: 'user', content: prompt }];
    }

    const temperature = preferences?.temperature ?? 0.7;
    const maxTokens = preferences?.max_tokens ?? 1000;

    try {
      const response = await fetch(`${endpointUrl}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: modelName,
          messages: messages,
          temperature,
          max_tokens: maxTokens,
          stream: false,
        }),
        signal: AbortSignal.timeout(timeout || 60000),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(`Ollama API错误: ${error.error?.message || response.status}`);
      }

      const data = await response.json();

      return {
        provider: 'ollama',
        model: modelName,
        content: data.choices?.[0]?.message?.content || '',
        usage: data.usage,
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new Error('Ollama API调用超时');
      }
      throw error;
    }
  }

  /**
   * 调用OpenAI API
   */
  static async callOpenAiApi(prompt, endpoint, apiKey, model, timeout, preferences) {
    const defaultEndpoint = 'https://api.openai.com/v1';
    const endpointUrl = endpoint || defaultEndpoint;

    let messages;
    try {
      messages = JSON.parse(prompt);
    } catch {
      messages = [{ role: 'user', content: prompt }];
    }

    const temperature = preferences?.temperature ?? 0.7;
    const maxTokens = preferences?.max_tokens ?? 1000;

    try {
      const response = await fetch(`${endpointUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: model || 'gpt-3.5-turbo',
          messages,
          temperature,
          max_tokens: maxTokens,
        }),
        signal: AbortSignal.timeout(timeout || 60000),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(error.error?.message || `OpenAI API错误: ${response.status}`);
      }

      const data = await response.json();

      return {
        provider: 'openai',
        model: data.model,
        content: data.choices?.[0]?.message?.content || '',
        usage: data.usage,
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new Error('OpenAI API调用超时');
      }
      throw error;
    }
  }

  /**
   * 调用Anthropic API
   */
  static async callAnthropicApi(prompt, endpoint, apiKey, model, timeout, preferences) {
    const defaultEndpoint = 'https://api.anthropic.com';
    const endpointUrl = endpoint || defaultEndpoint;

    let messages;
    try {
      messages = JSON.parse(prompt);
    } catch {
      messages = [{ role: 'user', content: prompt }];
    }

    // Anthropic API格式不同，需要转换
    const systemMessage = messages.find(m => m.role === 'system');
    const userMessages = messages.filter(m => m.role !== 'system');

    const temperature = preferences?.temperature ?? 0.7;
    const maxTokens = preferences?.max_tokens ?? 1000;

    try {
      const response = await fetch(`${endpointUrl}/v1/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: model || 'claude-sonnet-4-20250514',
          max_tokens: maxTokens,
          temperature,
          system: systemMessage?.content,
          messages: userMessages.map(m => ({
            role: m.role,
            content: m.content,
          })),
        }),
        signal: AbortSignal.timeout(timeout || 60000),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(error.error?.message || `Anthropic API错误: ${response.status}`);
      }

      const data = await response.json();

      return {
        provider: 'anthropic',
        model: data.model,
        content: data.content?.[0]?.text || '',
        usage: { input_tokens: data.usage?.input_tokens, output_tokens: data.usage?.output_tokens },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new Error('Anthropic API调用超时');
      }
      throw error;
    }
  }

  /**
   * 调用自定义API（OpenAI兼容格式）
   */
  static async callCustomApi(prompt, endpoint, apiKey, model, timeout, preferences) {
    if (!endpoint) {
      throw new Error('自定义API端点不能为空');
    }

    let messages;
    try {
      messages = JSON.parse(prompt);
    } catch {
      messages = [{ role: 'user', content: prompt }];
    }

    const temperature = preferences?.temperature ?? 0.7;
    const maxTokens = preferences?.max_tokens ?? 1000;

    try {
      const headers = {
        'Content-Type': 'application/json',
      };

      // 如果提供了API密钥，添加到请求头
      if (apiKey) {
        headers['Authorization'] = `Bearer ${apiKey}`;
      }

      const response = await fetch(`${endpoint}/chat/completions`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          model: model || 'gpt-3.5-turbo',
          messages,
          temperature,
          max_tokens: maxTokens,
        }),
        signal: AbortSignal.timeout(timeout || 60000),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(error.error?.message || `自定义API错误: ${response.status}`);
      }

      const data = await response.json();

      return {
        provider: 'custom',
        model: data.model,
        content: data.choices?.[0]?.message?.content || '',
        usage: data.usage,
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new Error('自定义API调用超时');
      }
      throw error;
    }
  }

  /**
   * 调用DeepSeek API生成标签
   * @param {string} prompt - 提示词
   * @param {string} endpoint - API端点
   * @param {string} apiKey - API密钥
   * @param {string} model - 模型名称
   * @param {number} timeout - 超时时间
   * @param {object} preferences - 偏好设置
   * @returns {Promise<object>}
   */
  static async callDeepSeekApi(prompt, endpoint, apiKey, model, timeout, preferences) {
    const defaultEndpoint = 'https://api.deepseek.com/v1';
    const endpointUrl = endpoint || defaultEndpoint;
    const modelName = model || 'deepseek-chat';

    let messages;
    try {
      messages = JSON.parse(prompt);
    } catch {
      messages = [{ role: 'user', content: prompt }];
    }

    const temperature = preferences?.temperature ?? 0.7;
    const maxTokens = preferences?.max_tokens ?? 1000;

    try {
      const response = await fetch(`${endpointUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: modelName,
          messages,
          temperature,
          max_tokens: maxTokens,
        }),
        signal: AbortSignal.timeout(timeout || 60000),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(error.error?.message || `DeepSeek API错误: ${response.status}`);
      }

      const data = await response.json();

      return {
        provider: 'deepseek',
        model: data.model,
        content: data.choices?.[0]?.message?.content || '',
        usage: data.usage,
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new Error('DeepSeek API调用超时');
      }
      throw error;
    }
  }

  /**
   * 解析AI响应
   * @param {object} aiResponse - AI API响应
   * @returns {object}
   */
  static parseAiResponse(aiResponse) {
    const content = aiResponse.content;

    if (!content) {
      logger.warn('AI响应内容为空');
      return { tags: [], error: 'AI响应内容为空' };
    }

    try {
      // 尝试直接解析JSON
      const parsed = JSON.parse(content);

      // ✅ 验证新格式（带类型的标签对象）
      if (parsed.tags && Array.isArray(parsed.tags)) {
        logger.info('AI响应解析成功 (标准格式 - 带类型标签)');
        return {
          tags: parsed.tags.map(t => ({
            name: t.name,
            type: t.type || '未知',
            confidence: t.confidence || 0.8
          })),
          reasoning: parsed.reasoning
        };
      }

      // 兼容纯数组格式
      if (Array.isArray(parsed)) {
        logger.info('AI响应解析成功 (纯数组格式)');
        return {
          tags: parsed.map(tagName => ({
            name: tagName,
            type: '未知',
            confidence: 0.8
          }))
        };
      }

      throw new Error('无效的响应格式');
    } catch (parseError) {
      logger.warn('JSON解析失败，尝试文本提取:', parseError.message);

      // 尝试提取JSON片段
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.tags && Array.isArray(parsed.tags)) {
            logger.info('从文本中提取到标准格式标签');
            return {
              tags: parsed.tags.map(t => ({
                name: t.name,
                type: t.type || '未知',
                confidence: t.confidence || 0.8
              }))
            };
          }
        } catch (e) {
          logger.debug('JSON片段解析失败:', e.message);
        }
      }

      // 最后尝试：文本提取作为后备方案
      const tagMatches = content.match(/["'「『]([\\u4e00-\\u9fa5]{2,4})["'」』]/g);
      if (tagMatches && tagMatches.length > 0) {
        const tags = tagMatches.map(m => ({
          name: m.replace(/["'「『」』]/g, ''),
          type: '未知',
          confidence: 0.7
        }));
        logger.info('文本提取成功，提取到标签:', tags.map(t => t.name));
        return { tags };
      }

      logger.error('AI响应解析完全失败');
      return { tags: [], error: '无法解析AI响应' };
    }
  }

  /**
   * 从文本中提取标签
   * @param {string} text - 文本内容
   * @returns {string[]}
   */
  static extractTagsFromText(text) {
    const tags = [];

    // 提取 "标签: xxx, xxx, xxx" 格式
    const tagLineMatch = text.match(/标签[：:]\s*(.+)/i);
    if (tagLineMatch) {
      const tagStr = tagLineMatch[1];
      const extracted = tagStr.split(/[,，、]/).map(t => t.trim()).filter(t => t.length > 0);
      tags.push(...extracted);
    }

    // 提取 #标签 格式
    const hashTags = text.match(/#[\u4e00-\u9fa5a-zA-Z0-9_]+/g);
    if (hashTags) {
      tags.push(...hashTags.map(t => t.replace('#', '')));
    }

    // 如果还是没有找到，尝试按行分割取包含标签含义的词
    if (tags.length === 0) {
      const lines = text.split('\n');
      for (const line of lines) {
        if (line.length >= 2 && line.length <= 6 && !line.includes('：') && !line.includes(':')) {
          tags.push(line.trim());
        }
      }
    }

    // 去重并清理
    const uniqueTags = [...new Set(tags)].map(tag => {
      // 清理标签
      return tag.replace(/^[""'']['"'']$/g, '').trim();
    }).filter(tag => tag.length >= 2 && tag.length <= 6);

    // 限制标签数量
    return uniqueTags.slice(0, 10);
  }

  /**
   * 保存分析结果到数据库
   */
  static async saveAnalysisResult(contentId, aiConfigId, analysisResult, aiResponse, executionTime, errorMessage = null) {
    try {
      const resultRepository = AppDataSource.getRepository('AiAnalysisResult');

      const result = resultRepository.create({
        content_id: contentId,
        ai_config_id: aiConfigId,
        analysis_result: aiResponse,
        generated_tags: analysisResult.tags || [],
        confidence_scores: analysisResult.confidence_scores || {},
        status: errorMessage ? 'failed' : 'completed',
        execution_time: executionTime,
        error_message: errorMessage,
        completed_at: errorMessage ? null : new Date(),
      });

      await resultRepository.save(result);
    } catch (error) {
      logger.error('保存AI分析结果失败:', error);
    }
  }

  /**
   * 获取内容的AI分析结果
   * @param {string} contentId - 内容ID
   * @returns {Promise<object|null>}
   */
  static async getAnalysisResult(contentId) {
    try {
      const resultRepository = AppDataSource.getRepository('AiAnalysisResult');

      const result = await resultRepository.findOne({
        where: { content_id: contentId },
        order: { created_at: 'DESC' },
      });

      return result;
    } catch (error) {
      logger.error('获取AI分析结果失败:', error);
      return null;
    }
  }

  /**
   * 批量分析内容
   * @param {Array} contents - 内容列表
   * @returns {Promise<object>}
   */
  static async batchAnalyze(contents) {
    const results = {
      success: 0,
      failed: 0,
      total: contents.length,
      details: [],
    };

    for (const content of contents) {
      try {
        const result = await this.analyzeWithRetry(content.parsedData, content.contentId);

        if (result.success) {
          results.success++;
        } else {
          results.failed++;
        }

        results.details.push({
          contentId: content.contentId,
          success: result.success,
          tags: result.tags,
          message: result.message,
        });

        // 添加延迟，避免API限流
        await this.sleep(1000);
      } catch (error) {
        results.failed++;
        results.details.push({
          contentId: content.contentId,
          success: false,
          message: error.message,
        });
      }
    }

    return results;
  }

  /**
   * 等待指定时间
   * @param {number} ms - 毫秒数
   */
  static sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // ==================== 统一分析方法（OCR + 标签 + 描述）====================

  /**
   * 统一AI分析 - 一次性完成OCR提取、标签生成和描述生成
   * @param {string} contentId - 内容ID
   * @param {object} options - 选项
   * @returns {Promise<object>} 分析结果
   */
  static async analyzeUnified(contentId, options = {}) {
    const {
      generateTags = true,
      generateDescription = true,
      enableOcr = true
    } = options;

    const result = {
      tags: null,
      description: null,
      ocrResults: [],
      stages: {
        ocr: { success: false, duration: 0 },
        tags: { success: false, duration: 0 },
        description: { success: false, duration: 0 }
      }
    };

    // 创建分析记录用于跟踪进度
    const aiConfig = await this.getActiveConfig();
    let analysisRecord = null;
    try {
      const resultRepository = AppDataSource.getRepository('AiAnalysisResult');
      analysisRecord = resultRepository.create({
        content_id: contentId,
        ai_config_id: aiConfig?.id,
        status: 'processing',
        current_stage: 'initializing',
        analysis_type: 'unified_analysis'
      });
      await resultRepository.save(analysisRecord);
    } catch (error) {
      logger.warn('创建分析记录失败:', error);
    }

    try {
      // 1. 获取内容
      await this.updateAnalysisProgress(contentId, 'initializing');
      const content = await this.getContentById(contentId);
      if (!content) {
        throw new Error('内容不存在');
      }

      // 2. OCR提取（如果启用且有图片）
      if (enableOcr && generateDescription) {
        await this.updateAnalysisProgress(contentId, 'ocr');
        const ocrStart = Date.now();
        try {
          result.ocrResults = await OcrService.extractFromContent(content);
          result.stages.ocr = {
            success: true,
            duration: Date.now() - ocrStart
          };
          logger.info(`OCR提取完成: ${result.ocrResults.length}张图片`);
        } catch (error) {
          logger.warn('OCR提取失败:', error);
          result.stages.ocr = {
            success: false,
            duration: Date.now() - ocrStart,
            error: error.message
          };
        }
      }

      // 3. 生成标签
      if (generateTags) {
        await this.updateAnalysisProgress(contentId, 'generating_tags');
        const tagsStart = Date.now();
        try {
          // 构建包含OCR文字的Prompt
          const prompt = this.buildTagPrompt(content, result.ocrResults);

          const aiResponse = await this.callAiApi(prompt, aiConfig);
          result.tags = this.parseAiResponse(aiResponse).tags || [];

          // 保存标签到数据库
          if (result.tags.length > 0) {
            await this.saveTags(contentId, result.tags);
          }

          result.stages.tags = {
            success: true,
            duration: Date.now() - tagsStart
          };
          logger.info(`标签生成完成: ${result.tags.length}个标签`);
        } catch (error) {
          logger.error('标签生成失败:', error);
          result.stages.tags = {
            success: false,
            duration: Date.now() - tagsStart,
            error: error.message
          };
        }
      }

      // 4. 生成描述（不覆盖原始描述，只保存在分析结果中）
      if (generateDescription) {
        await this.updateAnalysisProgress(contentId, 'generating_description');
        const descStart = Date.now();
        try {
          const prompt = this.buildDescriptionPrompt(content, result.ocrResults);

          const description = await this.callAiForDescription(prompt, aiConfig);

          // 不再保存到Content表，只保存在result中
          result.description = description;

          result.stages.description = {
            success: true,
            duration: Date.now() - descStart
          };
          logger.info(`描述生成完成: ${description.length}字符`);
        } catch (error) {
          logger.error('描述生成失败:', error);
          result.stages.description = {
            success: false,
            duration: Date.now() - descStart,
            error: error.message
          };
        }
      }

      // 5. 保存统一分析历史
      await this.saveUnifiedAnalysisHistory(contentId, result);

      // 更新为完成状态
      await this.updateAnalysisProgress(contentId, 'completed');

      return result;
    } catch (error) {
      logger.error('统一分析失败:', error);
      await this.updateAnalysisProgress(contentId, 'failed', error.message);
      throw error;
    }
  }

  /**
   * 构建包含OCR文字的标签生成Prompt
   * @param {object} content - 内容对象
   * @param {array} ocrResults - OCR结果数组
   * @returns {string} Prompt
   */
  static buildTagPrompt(content, ocrResults = []) {
    const ocrTexts = ocrResults
      .filter(r => r.text && r.text.length > 0)
      .map(r => r.text)
      .join('\n');

    const systemPrompt = this.getSystemPrompt(content.platform);

    let userPrompt = `你是一位专业的社交媒体内容分析专家。

【内容信息】
平台：${this.getPlatformName(content.platform)}
标题：${content.title || '无标题'}
作者：${content.author || '未知'}
`;

    if (content.description) {
      const truncatedDesc = content.description.length > 500
        ? content.description.substring(0, 500) + '...'
        : content.description;
      userPrompt += `描述：${truncatedDesc}\n`;
    }

    if (ocrTexts) {
      userPrompt += `\n【图片中提取的文字】\n${ocrTexts}\n`;
    }

    userPrompt += `\n【任务要求】
请分析上述内容，生成3-5个精准的标签（严格控制在2-4个汉字，最多5个标签）。

【标签分类体系】
1. **主题标签**（必填1-2个）：内容的核心主题
   - 示例：美食、旅游、美妆、科技、教育、健身、穿搭、宠物、家居

2. **风格标签**（必填1-2个）：内容的表现风格
   - 示例：教程、测评、干货、种草、vlog、搞笑、励志、剧情

3. **细节标签**（选填0-1个）：具体元素或特征
   - 示例：平价、高端、新手、进阶、限时、独家、原创

4. **情感标签**（选填0-1个）：情感倾向
   - 示例：治愈、励志、温馨、震惊、感动

【质量控制规则】
1. 严格字数限制：必须2-4个汉字，不允许1个字或超过4个字
2. 避免泛化词：❌推荐、❌热门、❌必看、❌分享、❌精选、❌最新
3. 优先提取关键词：从标题、描述中提取2-4字的词组
4. 保证语义明确：
   - ✅"夏日护肤"（主题+时间）
   - ✅"新手教程"（对象+风格）
   - ❌"关于护肤的内容"（句子而非标签）
   - ❌"分享一个护肤技巧"（过于冗长）

5. 平台特性适配：
   - 小红书：偏重生活方式（种草、教程、测评、探店）
   - 抖音：偏重娱乐性（搞笑、挑战、剧情、热点）
   - B站：偏重专业深度（技术、科普、攻略、分析）

【输出格式】
请直接以JSON格式输出：
{
  "tags": [
    {"name": "美食", "type": "主题", "confidence": 0.95},
    {"name": "教程", "type": "风格", "confidence": 0.90},
    {"name": "新手", "type": "细节", "confidence": 0.85}
  ],
  "reasoning": "简要说明标签选择理由（50字以内）"
}

字段说明：
- name: 标签名称（2-4个汉字，必填）
- type: 标签类型（主题/风格/细节/情感，必填）
- confidence: 置信度（0.6-1.0之间，必填）
- reasoning: 标签选择理由（选填）
`;

    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];

    return JSON.stringify(messages);
  }

  /**
   * 构建描述生成Prompt（包含OCR文字）
   * @param {object} content - 内容对象
   * @param {array} ocrResults - OCR结果数组
   * @returns {string} Prompt
   */
  static buildDescriptionPrompt(content, ocrResults = []) {
    const ocrTexts = ocrResults
      .filter(r => r.text && r.text.length > 0)
      .map(r => r.text)
      .join('\n\n');

    return `你是一位专业的社交媒体内容分析专家。

【内容信息】
平台：${this.getPlatformName(content.platform)}
媒体类型：${content.media_type === 'video' ? '视频' : '图片'}
作者：${content.author || '未知'}

【标题】
${content.title || '无标题'}

【原始描述】
${content.description || '（无原始描述）'}

${ocrTexts ? `【图片中提取的文字】\n${ocrTexts}` : ''}

【任务要求】
1. 综合分析标题、描述和图片文字
2. 提取内容的主题和核心信息点
3. 识别内容中的视觉元素和关键文字
4. 分析内容传达的情感、氛围和价值
5. 生成200-500字的全面描述

【输出要求】
- 使用简洁流畅的中文段落
- 直接输出描述文本，无需JSON格式或其他标记
- 描述应包含：内容主题、视觉元素、关键文字、情感氛围
- 基于实际信息分析，避免编造内容
- 如果信息不足，就如实描述已知部分

请生成内容描述：`;
  }

  /**
   * 调用AI生成描述（返回纯文本，非JSON）
   * @param {string} prompt - Prompt
   * @param {object} aiConfig - AI配置
   * @returns {Promise<string>} 生成的描述
   */
  static async callAiForDescription(prompt, aiConfig) {
    const { provider, api_endpoint, api_key, model, timeout, preferences } = aiConfig;

    switch (provider) {
      case 'ollama':
        return await this.callOllamaForDescription(prompt, api_endpoint, model, timeout, preferences);
      case 'openai':
      case 'custom':
        return await this.callOpenAIForDescription(prompt, api_endpoint, api_key, model, timeout, preferences, provider);
      case 'anthropic':
        return await this.callAnthropicForDescription(prompt, api_endpoint, api_key, model, timeout, preferences);
      case 'deepseek':
        return await this.callDeepSeekForDescription(prompt, api_endpoint, api_key, model, timeout, preferences);
      default:
        throw new Error(`不支持的提供商: ${provider}`);
    }
  }

  /**
   * 调用Ollama生成描述
   */
  static async callOllamaForDescription(prompt, endpoint, model, timeout, preferences) {
    const endpointUrl = endpoint || 'http://localhost:11434';
    const modelName = model || 'qwen2.5:7b';

    const response = await fetch(`${endpointUrl}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: modelName,
        prompt: prompt,
        stream: false,
        options: {
          temperature: preferences?.temperature ?? 0.7,
          top_p: preferences?.top_p ?? 0.9,
          num_predict: preferences?.max_tokens ?? 2000
        }
      }),
      signal: AbortSignal.timeout(timeout || 90000)
    });

    if (!response.ok) {
      throw new Error(`Ollama API错误: ${response.status}`);
    }

    const data = await response.json();
    return data.response.trim();
  }

  /**
   * 调用OpenAI兼容API生成描述
   */
  static async callOpenAIForDescription(prompt, endpoint, apiKey, model, timeout, preferences, providerName) {
    const defaultEndpoint = providerName === 'openai'
      ? 'https://api.openai.com/v1'
      : endpoint;

    const endpointUrl = endpoint || defaultEndpoint;
    const modelName = model || 'gpt-3.5-turbo';

    const response = await fetch(`${endpointUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: modelName,
        messages: [{ role: 'user', content: prompt }],
        temperature: preferences?.temperature ?? 0.7,
        max_tokens: preferences?.max_tokens ?? 2000
      }),
      signal: AbortSignal.timeout(timeout || 90000)
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(`OpenAI API错误: ${errorData.error?.message || response.status}`);
    }

    const data = await response.json();
    return data.choices[0].message.content.trim();
  }

  /**
   * 调用Anthropic API生成描述
   */
  static async callAnthropicForDescription(prompt, endpoint, apiKey, model, timeout, preferences) {
    const endpointUrl = endpoint || 'https://api.anthropic.com';
    const modelName = model || 'claude-3-haiku-20250307';

    const response = await fetch(`${endpointUrl}/v1/messages`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: modelName,
        max_tokens: preferences?.max_tokens ?? 2000,
        messages: [{ role: 'user', content: prompt }]
      }),
      signal: AbortSignal.timeout(timeout || 90000)
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(`Anthropic API错误: ${errorData.error?.message || response.status}`);
    }

    const data = await response.json();
    return data.content[0].text.trim();
  }

  /**
   * 调用DeepSeek API生成描述
   * @param {string} prompt - 提示词
   * @param {string} endpoint - API端点
   * @param {string} apiKey - API密钥
   * @param {string} model - 模型名称
   * @param {number} timeout - 超时时间
   * @param {object} preferences - 偏好设置
   * @returns {Promise<string>} 生成的描述
   */
  static async callDeepSeekForDescription(prompt, endpoint, apiKey, model, timeout, preferences) {
    const endpointUrl = endpoint || 'https://api.deepseek.com/v1';
    const modelName = model || 'deepseek-chat';

    const response = await fetch(`${endpointUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: modelName,
        messages: [{ role: 'user', content: prompt }],
        temperature: preferences?.temperature ?? 0.7,
        max_tokens: preferences?.max_tokens ?? 2000
      }),
      signal: AbortSignal.timeout(timeout || 90000)
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(`DeepSeek API错误: ${errorData.error?.message || response.status}`);
    }

    const data = await response.json();
    return data.choices[0].message.content.trim();
  }

  /**
   * 更新Content的description字段
   * @param {string} contentId - 内容ID
   * @param {string} description - 描述文本
   */
  static async updateContentDescription(contentId, description) {
    const contentRepository = AppDataSource.getRepository('Content');
    await contentRepository.update(contentId, { description });
    logger.info('描述已更新到数据库', { contentId, length: description.length });
  }

  /**
   * 保存标签到数据库
   * @param {string} contentId - 内容ID
   * @param {array} tags - 标签数组
   */
  static async saveTags(contentId, tags) {
    try {
      // 使用AiTagService自动添加标签
      await AiTagService.autoAddTags(contentId, tags);
      logger.info('标签已保存', { contentId, count: tags.length });
    } catch (error) {
      logger.error('保存标签失败:', error);
      throw error;
    }
  }

  /**
   * 获取内容对象
   * @param {string} contentId - 内容ID
   * @returns {Promise<object|null>} Content对象
   */
  static async getContentById(contentId) {
    try {
      const contentRepository = AppDataSource.getRepository('Content');
      const content = await contentRepository.findOne({ where: { id: contentId } });
      return content;
    } catch (error) {
      logger.error('获取内容失败:', { contentId, error: error.message });
      return null;
    }
  }

  /**
   * 更新分析进度
   * @param {string} contentId - 内容ID
   * @param {string} stage - 当前阶段
   * @param {string} errorMessage - 错误信息（可选）
   */
  static async updateAnalysisProgress(contentId, stage, errorMessage = null) {
    try {
      const resultRepository = AppDataSource.getRepository('AiAnalysisResult');

      // 查找最新的处理中记录
      const record = await resultRepository.findOne({
        where: { content_id: contentId },
        order: { created_at: 'DESC' }
      });

      if (!record) {
        logger.debug('未找到分析记录，跳过进度更新');
        return;
      }

      // 更新当前阶段
      if (stage === 'completed') {
        record.status = 'completed';
        record.current_stage = null;
        record.completed_at = new Date();
      } else if (stage === 'failed') {
        record.status = 'failed';
        record.current_stage = null;
        record.error_message = errorMessage;
      } else {
        record.current_stage = stage;
      }

      await resultRepository.save(record);
      logger.debug(`分析进度已更新: ${contentId} -> ${stage}`);
    } catch (error) {
      logger.warn('更新分析进度失败:', error);
      // 不抛出错误，进度更新失败不影响主流程
    }
  }

  /**
   * 保存统一分析历史
   * @param {string} contentId - 内容ID
   * @param {object} result - 分析结果
   */
  static async saveUnifiedAnalysisHistory(contentId, result) {
    try {
      const resultRepository = AppDataSource.getRepository('AiAnalysisResult');
      const aiConfig = await this.getActiveConfig();

      await resultRepository.save({
        content_id: contentId,
        ai_config_id: aiConfig?.id,
        analysis_type: 'unified_analysis',
        analysis_result: {
          tags: result.tags,
          description: result.description,
          ocr_results: result.ocrResults,
          stages: result.stages
        },
        generated_tags: result.tags || [],
        status: 'completed',
        execution_time: Object.values(result.stages).reduce((sum, s) => sum + s.duration, 0),
        completed_at: new Date()
      });

      logger.debug('统一分析历史已保存', { contentId });
    } catch (error) {
      logger.warn('保存统一分析历史失败:', error);
      // 不抛出错误，历史记录失败不影响主流程
    }
  }
}

module.exports = AiAnalysisService;

/**
 * AI分析服务
 *
 * 负责调用AI API分析内容并生成标签
 * 支持Ollama、OpenAI、Anthropic等提供商
 */

const { AppDataSource } = require('../utils/db');
const EncryptionService = require('../utils/encryption');
const logger = require('../utils/logger');

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
   * 解析AI响应
   * @param {object} aiResponse - AI API响应
   * @returns {object}
   */
  static parseAiResponse(aiResponse) {
    const content = aiResponse.content;

    if (!content) {
      return { tags: [], error: 'AI响应内容为空' };
    }

    try {
      // 尝试直接解析JSON
      const parsed = JSON.parse(content);
      return parsed;
    } catch {
      // 如果不是JSON，尝试提取JSON
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          return JSON.parse(jsonMatch[0]);
        } catch {
          // 继续尝试其他方法
        }
      }

      // 如果还是无法解析，尝试从文本中提取标签
      const tags = this.extractTagsFromText(content);
      return {
        tags,
        reasoning: content.substring(0, 200),
      };
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
}

module.exports = AiAnalysisService;

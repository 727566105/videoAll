/**
 * AI配置控制器
 *
 * 处理AI API配置的CRUD操作，包括保存、查询、测试连接等
 */

const { AppDataSource } = require('../utils/db');
const EncryptionService = require('../utils/encryption');
const logger = require('../utils/logger');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);
const AiConfigValidationService = require('../services/AiConfigValidationService');
const KeyRotationService = require('../services/KeyRotationService');

class AiConfigController {
  /**
   * 获取AI配置列表
   * GET /api/v1/ai-config
   */
  static async getConfigs(req, res) {
    try {
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const configs = await aiConfigRepository.find({
        order: { priority: 'ASC', created_at: 'DESC' },
      });

      // 解密返回API密钥（但只在需要时返回）
      const configsWithDecryptedKey = configs.map(config => ({
        ...config,
        api_key: config.api_key_encrypted ? '[已加密]' : '',
        // 不返回加密的密钥，改用占位符
        api_key_encrypted: undefined,
      }));

      res.status(200).json({
        success: true,
        message: '获取AI配置列表成功',
        data: configsWithDecryptedKey,
      });
    } catch (error) {
      logger.error('获取AI配置列表失败:', error);
      res.status(500).json({
        success: false,
        message: '获取AI配置列表失败',
      });
    }
  }

  /**
   * 获取单个AI配置
   * GET /api/v1/ai-config/:id
   */
  static async getConfigById(req, res) {
    try {
      const { id } = req.params;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const config = await aiConfigRepository.findOne({
        where: { id },
      });

      if (!config) {
        return res.status(404).json({
          success: false,
          message: 'AI配置不存在',
        });
      }

      res.status(200).json({
        success: true,
        message: '获取AI配置成功',
        data: {
          ...config,
          api_key_encrypted: undefined,
        },
      });
    } catch (error) {
      logger.error('获取AI配置失败:', error);
      res.status(500).json({
        success: false,
        message: '获取AI配置失败',
      });
    }
  }

  /**
   * 获取当前启用的AI配置
   * GET /api/v1/ai-config/active
   */
  static async getActiveConfig(req, res) {
    try {
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      // 查找启用的配置，按优先级排序
      const config = await aiConfigRepository.findOne({
        where: { is_enabled: true, status: 'active' },
        order: { priority: 'ASC' },
      });

      if (!config) {
        return res.status(200).json({
          success: true,
          message: '未找到启用的AI配置',
          data: null,
        });
      }

      res.status(200).json({
        success: true,
        message: '获取活跃AI配置成功',
        data: {
          ...config,
          api_key_encrypted: undefined,
        },
      });
    } catch (error) {
      logger.error('获取活跃AI配置失败:', error);
      res.status(500).json({
        success: false,
        message: '获取活跃AI配置失败',
      });
    }
  }

  /**
   * 创建AI配置
   * POST /api/v1/ai-config
   */
  static async createConfig(req, res) {
    try {
      const { provider, api_endpoint, api_key, model, timeout, is_enabled, preferences, status } = req.body;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      // 验证配置数据
      const validation = AiConfigValidationService.validateConfig(req.body);
      if (!validation.valid) {
        return res.status(400).json({
          success: false,
          message: '配置验证失败',
          errors: validation.errors
        });
      }

      // 验证必填字段
      if (!provider) {
        return res.status(400).json({
          success: false,
          message: '提供商类型不能为空',
        });
      }

      // 加密API密钥
      let apiKeyEncrypted = null;
      if (api_key) {
        apiKeyEncrypted = EncryptionService.encrypt(api_key);
      }

      // 创建配置
      const config = aiConfigRepository.create({
        provider,
        api_endpoint: api_endpoint || null,
        api_key_encrypted: apiKeyEncrypted,
        model: model || null,
        timeout: timeout || 60000,
        is_enabled: is_enabled !== undefined ? is_enabled : false,
        preferences: preferences || null,
        status: status || 'active',
      });

      await aiConfigRepository.save(config);

      logger.info(`AI配置创建成功: ${provider}`);

      res.status(201).json({
        success: true,
        message: 'AI配置创建成功',
        data: {
          ...config,
          api_key_encrypted: undefined,
        },
      });
    } catch (error) {
      logger.error('创建AI配置失败:', error);
      res.status(500).json({
        success: false,
        message: '创建AI配置失败',
      });
    }
  }

  /**
   * 更新AI配置
   * PUT /api/v1/ai-config/:id
   */
  static async updateConfig(req, res) {
    try {
      const { id } = req.params;
      const { provider, api_endpoint, api_key, model, timeout, is_enabled, preferences, status } = req.body;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      // 验证配置数据（如果提供了更新字段）
      if (provider || api_endpoint || api_key || model || timeout !== undefined || preferences) {
        const validation = AiConfigValidationService.validateConfig({
          provider: provider || req.body.provider,
          api_endpoint: api_endpoint || req.body.api_endpoint,
          api_key: api_key || req.body.api_key,
          model: model || req.body.model,
          timeout: timeout !== undefined ? timeout : req.body.timeout,
          preferences: preferences || req.body.preferences
        });
        if (!validation.valid) {
          return res.status(400).json({
            success: false,
            message: '配置验证失败',
            errors: validation.errors
          });
        }
      }

      const config = await aiConfigRepository.findOne({
        where: { id },
      });

      if (!config) {
        return res.status(404).json({
          success: false,
          message: 'AI配置不存在',
        });
      }

      // 更新字段
      if (provider !== undefined) config.provider = provider;
      if (api_endpoint !== undefined) config.api_endpoint = api_endpoint;
      if (api_key !== undefined) {
        config.api_key_encrypted = api_key ? EncryptionService.encrypt(api_key) : null;
      }
      if (model !== undefined) config.model = model;
      if (timeout !== undefined) config.timeout = timeout;
      if (is_enabled !== undefined) config.is_enabled = is_enabled;
      if (preferences !== undefined) config.preferences = preferences;
      if (status !== undefined) config.status = status;

      config.updated_at = new Date();

      await aiConfigRepository.save(config);

      logger.info(`AI配置更新成功: ${id}`);

      res.status(200).json({
        success: true,
        message: 'AI配置更新成功',
        data: {
          ...config,
          api_key_encrypted: undefined,
        },
      });
    } catch (error) {
      logger.error('更新AI配置失败:', error);
      res.status(500).json({
        success: false,
        message: '更新AI配置失败',
      });
    }
  }

  /**
   * 删除AI配置
   * DELETE /api/v1/ai-config/:id
   */
  static async deleteConfig(req, res) {
    try {
      const { id } = req.params;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const config = await aiConfigRepository.findOne({
        where: { id },
      });

      if (!config) {
        return res.status(404).json({
          success: false,
          message: 'AI配置不存在',
        });
      }

      await aiConfigRepository.remove(config);

      logger.info(`AI配置删除成功: ${id}`);

      res.status(200).json({
        success: true,
        message: 'AI配置删除成功',
      });
    } catch (error) {
      logger.error('删除AI配置失败:', error);
      res.status(500).json({
        success: false,
        message: '删除AI配置失败',
      });
    }
  }

  /**
   * 测试AI配置连接
   * POST /api/v1/ai-config/:id/test
   */
  static async testConnection(req, res) {
    try {
      const { id } = req.params;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const config = await aiConfigRepository.findOne({
        where: { id },
      });

      if (!config) {
        return res.status(404).json({
          success: false,
          message: 'AI配置不存在',
        });
      }

      // 解密API密钥
      let apiKey = null;
      if (config.api_key_encrypted) {
        try {
          apiKey = EncryptionService.decrypt(config.api_key_encrypted);
        } catch (e) {
          return res.status(400).json({
            success: false,
            message: 'API密钥解密失败',
          });
        }
      }

      // 测试连接
      const result = await this.testAiConnection(config.provider, config.api_endpoint, apiKey, config.model, config.timeout);

      // 更新最后测试时间
      config.last_test_at = new Date();
      await aiConfigRepository.save(config);

      res.status(200).json({
        success: result.success,
        message: result.message,
        details: result.details,
      });
    } catch (error) {
      logger.error('测试AI连接失败:', error);
      res.status(500).json({
        success: false,
        message: `测试失败: ${error.message}`,
      });
    }
  }

  /**
   * 测试AI连接
   * @param {string} provider - 提供商类型
   * @param {string} apiEndpoint - API端点
   * @param {string} apiKey - API密钥
   * @param {string} model - 模型名称
   * @param {number} timeout - 超时时间
   * @returns {Promise<object>} 测试结果
   */
  static async testAiConnection(provider, apiEndpoint, apiKey, model, timeout) {
    try {
      // 根据提供商类型选择测试方法
      switch (provider) {
        case 'ollama':
          return await this.testOllamaConnection(apiEndpoint, model, timeout);
        case 'openai':
        case 'custom':
          return await this.testOpenAiConnection(apiEndpoint, apiKey, model, timeout);
        case 'anthropic':
          return await this.testAnthropicConnection(apiEndpoint, apiKey, model, timeout);
        case 'qwen':
          return await this.testQwenConnection(apiEndpoint, apiKey, model, timeout);
        case 'wenxin':
          return await this.testWenxinConnection(apiEndpoint, apiKey, model, timeout);
        case 'zhipu':
          return await this.testZhipuConnection(apiEndpoint, apiKey, model, timeout);
        case 'deepseek':
          return await this.testDeepSeekConnection(apiEndpoint, apiKey, model, timeout);
        default:
          return {
            success: false,
            message: `不支持的提供商类型: ${provider}`,
          };
      }
    } catch (error) {
      return {
        success: false,
        message: `连接测试失败: ${error.message}`,
        details: error.stack,
      };
    }
  }

  /**
   * 测试Ollama连接
   */
  static async testOllamaConnection(apiEndpoint, model, timeout) {
    const defaultEndpoint = 'http://localhost:11434';
    const endpoint = apiEndpoint || defaultEndpoint;
    const modelName = model || 'qwen2.5:7b';

    try {
      // 尝试调用Ollama API
      const response = await fetch(`${endpoint}/api/tags`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        return {
          success: false,
          message: `Ollama服务响应错误: ${response.status}`,
        };
      }

      const data = await response.json();

      // 检查指定模型是否存在
      const modelExists = data.models && data.models.some(m =>
        m.name === modelName || m.name.includes(modelName.split(':')[0])
      );

      if (!modelExists) {
        return {
          success: true,
          message: `Ollama服务连接成功，但未找到模型 "${modelName}"`,
          details: {
            available_models: data.models?.map(m => m.name) || [],
            suggestion: `请运行: ollama pull ${modelName}`,
          },
        };
      }

      return {
        success: true,
        message: 'Ollama连接成功',
        details: {
          available_models: data.models?.map(m => m.name) || [],
        },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时，请检查Ollama服务是否运行',
        };
      }

      // 尝试检查Ollama是否已安装
      try {
        await execAsync('which ollama', { timeout: 5000 });
        return {
          success: false,
          message: 'Ollama未运行，请启动Ollama服务',
          suggestion: '运行命令: ollama serve',
        };
      } catch (e) {
        return {
          success: false,
          message: 'Ollama未安装，请先安装Ollama',
          suggestion: '访问 https://ollama.ai 下载安装',
        };
      }
    }
  }

  /**
   * 测试OpenAI兼容API连接
   */
  static async testOpenAiConnection(apiEndpoint, apiKey, model, timeout) {
    const defaultEndpoint = 'https://api.openai.com/v1';
    const endpoint = apiEndpoint || defaultEndpoint;

    if (!apiKey) {
      return {
        success: false,
        message: 'API密钥不能为空',
      };
    }

    try {
      const response = await fetch(`${endpoint}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: model || 'gpt-3.5-turbo',
          messages: [{ role: 'user', content: 'Hello' }],
          max_tokens: 5,
        }),
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          message: `API响应错误: ${response.status} ${errorData.error?.message || ''}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        message: 'API连接成功',
        details: {
          model: data.model,
        },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时',
        };
      }
      throw error;
    }
  }

  /**
   * 测试Anthropic API连接
   */
  static async testAnthropicConnection(apiEndpoint, apiKey, model, timeout) {
    const defaultEndpoint = 'https://api.anthropic.com';
    const endpoint = apiEndpoint || defaultEndpoint;

    if (!apiKey) {
      return {
        success: false,
        message: 'API密钥不能为空',
      };
    }

    try {
      const response = await fetch(`${endpoint}/v1/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: model || 'claude-sonnet-4-20250514',
          max_tokens: 5,
          messages: [{ role: 'user', content: 'Hello' }],
        }),
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          message: `API响应错误: ${response.status} ${errorData.error?.message || ''}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        message: 'Anthropic API连接成功',
        details: {
          model: data.model,
        },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时',
        };
      }
      throw error;
    }
  }

  /**
   * 测试通义千问连接
   */
  static async testQwenConnection(apiEndpoint, apiKey, model, timeout) {
    const defaultEndpoint = 'https://dashscope.aliyuncs.com/api/v1';
    const endpoint = apiEndpoint || defaultEndpoint;

    if (!apiKey) {
      return {
        success: false,
        message: 'API密钥不能为空',
      };
    }

    try {
      const response = await fetch(`${endpoint}/services/aigc/text-generation/generation`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: model || 'qwen-turbo',
          input: {
            messages: [{ role: 'user', content: '你好' }]
          },
          parameters: {
            max_tokens: 5,
          }
        }),
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          message: `API响应错误: ${response.status} ${errorData.message || errorData.code || ''}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        message: '通义千问API连接成功',
        details: {
          model: data.output?.model,
        },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时',
        };
      }
      throw error;
    }
  }

  /**
   * 测试文心一言连接
   */
  static async testWenxinConnection(apiEndpoint, apiKey, model, timeout) {
    // 文心一言的API Key格式为: {apikey}.{secret_key}
    if (!apiKey || !apiKey.includes('.')) {
      return {
        success: false,
        message: '文心一言API密钥格式不正确（应为apikey.secret_key）',
      };
    }

    const [accessToken] = apiKey.split('.');

    try {
      const defaultEndpoint = 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop';
      const endpoint = apiEndpoint || defaultEndpoint;

      const response = await fetch(`${endpoint}/chat/eb-instant?access_token=${accessToken}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: [{ role: 'user', content: '你好' }],
        }),
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          message: `API响应错误: ${errorData.error_msg || response.status}`,
        };
      }

      return {
        success: true,
        message: '文心一言API连接成功',
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时',
        };
      }
      throw error;
    }
  }

  /**
   * 测试智谱AI连接
   */
  static async testZhipuConnection(apiEndpoint, apiKey, model, timeout) {
    const defaultEndpoint = 'https://open.bigmodel.cn/api/paas/v4';
    const endpoint = apiEndpoint || defaultEndpoint;

    if (!apiKey) {
      return {
        success: false,
        message: 'API密钥不能为空',
      };
    }

    try {
      const response = await fetch(`${endpoint}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: model || 'glm-4',
          messages: [{ role: 'user', content: '你好' }],
          max_tokens: 5,
        }),
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          message: `API响应错误: ${response.status} ${errorData.error?.message || ''}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        message: '智谱AI连接成功',
        details: {
          model: data.model,
        },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时',
        };
      }
      throw error;
    }
  }

  /**
   * 测试DeepSeek连接
   */
  static async testDeepSeekConnection(apiEndpoint, apiKey, model, timeout) {
    const defaultEndpoint = 'https://api.deepseek.com/v1';
    const endpoint = apiEndpoint || defaultEndpoint;

    if (!apiKey) {
      return {
        success: false,
        message: 'API密钥不能为空',
      };
    }

    try {
      const response = await fetch(`${endpoint}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: model || 'deepseek-chat',
          messages: [{ role: 'user', content: 'Hello' }],
          max_tokens: 5,
        }),
        signal: AbortSignal.timeout(timeout || 30000),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        return {
          success: false,
          message: `API响应错误: ${response.status} ${errorData.error?.message || ''}`,
        };
      }

      const data = await response.json();

      return {
        success: true,
        message: 'DeepSeek API连接成功',
        details: {
          model: data.model,
        },
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        return {
          success: false,
          message: '连接超时',
        };
      }
      throw error;
    }
  }

  /**
   * 获取支持的提供商列表
   * GET /api/v1/ai-config/providers
   */
  static async getProviders(req, res) {
    try {
      const providers = [
        {
          id: 'ollama',
          name: 'Ollama (本地)',
          description: '本地部署的AI模型，完全免费，数据隐私安全',
          features: ['免费使用', '本地运行', '数据隐私', '支持多种模型'],
          requiresApiKey: false,
          requiresEndpoint: true,
          defaultEndpoint: 'http://localhost:11434',
          recommendedModels: [
            { name: 'qwen2.5:7b', description: '通用标签生成（推荐）', memory: '~8GB' },
            { name: 'llama3.2:3b', description: '资源受限环境', memory: '~4GB' },
            { name: 'deepseek-r1:8b', description: '推理能力强', memory: '~10GB' },
            { name: 'gemma3:4b', description: '多语言支持', memory: '~6GB' },
          ],
        },
        {
          id: 'openai',
          name: 'OpenAI API',
          description: 'OpenAI官方API，支持GPT-4o、GPT-3.5等模型',
          features: ['模型强大', '稳定可靠', '全球CDN', '按量付费'],
          requiresApiKey: true,
          requiresEndpoint: false,
          defaultEndpoint: 'https://api.openai.com/v1',
          recommendedModels: [
            { name: 'gpt-4o', description: '最新旗舰模型', cost: '高' },
            { name: 'gpt-4o-mini', description: '性价比之选', cost: '低' },
            { name: 'gpt-3.5-turbo', description: '快速响应', cost: '低' },
          ],
        },
        {
          id: 'anthropic',
          name: 'Anthropic Claude',
          description: 'Anthropic公司开发的AI模型，擅长长文本理解',
          features: ['长文本处理', '安全性高', '推理能力强'],
          requiresApiKey: true,
          requiresEndpoint: false,
          defaultEndpoint: 'https://api.anthropic.com',
          recommendedModels: [
            { name: 'claude-sonnet-4-20250514', description: '最新 Sonnet 模型', cost: '中' },
            { name: 'claude-haiku-3-20250514', description: '快速响应', cost: '低' },
          ],
        },
        {
          id: 'custom',
          name: '自定义API',
          description: '支持任意OpenAI兼容的第三方API',
          features: ['灵活配置', '兼容性强', '可对接私有模型'],
          requiresApiKey: true,
          requiresEndpoint: true,
          defaultEndpoint: '',
          recommendedModels: [],
        },
        {
          id: 'qwen',
          name: '通义千问（阿里云）',
          description: '阿里云大语言模型服务，中文优化',
          features: ['中文优化', 'API稳定', '性价比高'],
          requiresApiKey: true,
          requiresEndpoint: false,
          defaultEndpoint: 'https://dashscope.aliyuncs.com/api/v1',
          recommendedModels: [
            { name: 'qwen-turbo', description: '高性能版本', cost: '低' },
            { name: 'qwen-plus', description: '平衡版本', cost: '中' },
            { name: 'qwen-max', description: '最强版本', cost: '高' },
          ],
        },
        {
          id: 'wenxin',
          name: '文心一言（百度）',
          description: '百度大语言模型，知识增强',
          features: ['中文优化', '知识增强', '多场景'],
          requiresApiKey: true,
          requiresEndpoint: false,
          defaultEndpoint: 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop',
          recommendedModels: [
            { name: 'ernie-bot-4', description: '最新版本', cost: '高' },
            { name: 'ernie-bot', description: '标准版本', cost: '中' },
            { name: 'ernie-bot-turbo', description: '快速版本', cost: '低' },
          ],
        },
        {
          id: 'zhipu',
          name: '智谱AI（清言）',
          description: '智谱AI大语言模型，推理能力强',
          features: ['推理能力强', '学术性能好', '长文本'],
          requiresApiKey: true,
          requiresEndpoint: false,
          defaultEndpoint: 'https://open.bigmodel.cn/api/paas/v4',
          recommendedModels: [
            { name: 'glm-4', description: '最新版本', cost: '中' },
            { name: 'glm-3-turbo', description: '快速版本', cost: '低' },
            { name: 'glm-4v', description: '视觉模型', cost: '高' },
          ],
        },
        {
          id: 'deepseek',
          name: 'DeepSeek（深度求索）',
          description: '深度求索开源模型，代码能力强',
          features: ['开源', '性价比高', '代码能力强'],
          requiresApiKey: true,
          requiresEndpoint: false,
          defaultEndpoint: 'https://api.deepseek.com/v1',
          recommendedModels: [
            { name: 'deepseek-chat', description: '对话模型', cost: '低' },
            { name: 'deepseek-coder', description: '代码模型', cost: '低' },
          ],
        },
      ];

      res.status(200).json({
        success: true,
        message: '获取提供商列表成功',
        data: providers,
      });
    } catch (error) {
      logger.error('获取提供商列表失败:', error);
      res.status(500).json({
        success: false,
        message: '获取提供商列表失败',
      });
    }
  }

  /**
   * 获取默认配置模板
   * GET /api/v1/ai-config/templates/:provider
   */
  static async getConfigTemplate(req, res) {
    try {
      const { provider } = req.params;

      const templates = {
        ollama: {
          provider: 'ollama',
          api_endpoint: 'http://localhost:11434',
          model: 'qwen2.5:7b',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
            system_prompt: '你是一个社交媒体内容分析助手，请根据提供的内容生成相关标签。标签要求：1. 简洁明了，每个标签2-4个汉字；2. 符合平台内容风格；3. 包括主题、风格、受众等相关维度。',
          },
        },
        openai: {
          provider: 'openai',
          api_endpoint: 'https://api.openai.com/v1',
          model: 'gpt-3.5-turbo',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
        anthropic: {
          provider: 'anthropic',
          api_endpoint: 'https://api.anthropic.com',
          model: 'claude-sonnet-4-20250514',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
        custom: {
          provider: 'custom',
          api_endpoint: '',
          model: '',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
        qwen: {
          provider: 'qwen',
          api_endpoint: 'https://dashscope.aliyuncs.com/api/v1',
          model: 'qwen-turbo',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
        wenxin: {
          provider: 'wenxin',
          api_endpoint: 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop',
          model: 'ernie-bot',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
        zhipu: {
          provider: 'zhipu',
          api_endpoint: 'https://open.bigmodel.cn/api/paas/v4',
          model: 'glm-4',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
        deepseek: {
          provider: 'deepseek',
          api_endpoint: 'https://api.deepseek.com/v1',
          model: 'deepseek-chat',
          timeout: 60000,
          preferences: {
            temperature: 0.7,
            max_tokens: 1000,
          },
        },
      };

      const template = templates[provider];

      if (!template) {
        return res.status(404).json({
          success: false,
          message: '不支持的提供商类型',
        });
      }

      res.status(200).json({
        success: true,
        message: '获取配置模板成功',
        data: template,
      });
    } catch (error) {
      logger.error('获取配置模板失败:', error);
      res.status(500).json({
        success: false,
        message: '获取配置模板失败',
      });
    }
  }

  /**
   * 获取加密密钥安全状态
   * GET /api/v1/ai-config/security/key-status
   */
  static async getKeyStatus(req, res) {
    try {
      const isDefaultKey = KeyRotationService.isUsingDefaultKey();
      const strengthReport = KeyRotationService.getKeyStrengthReport();

      res.status(200).json({
        success: true,
        message: '获取密钥状态成功',
        data: {
          using_default_key: isDefaultKey,
          ...strengthReport
        }
      });
    } catch (error) {
      logger.error('获取密钥状态失败:', error);
      res.status(500).json({
        success: false,
        message: '获取密钥状态失败'
      });
    }
  }

  /**
   * 轮换加密密钥
   * POST /api/v1/ai-config/security/rotate-key
   */
  static async rotateKey(req, res) {
    try {
      const { old_key, new_key } = req.body;

      if (!old_key || !new_key) {
        return res.status(400).json({
          success: false,
          message: '请提供旧密钥和新密钥'
        });
      }

      // 验证新密钥格式
      const keyValidation = KeyRotationService.validateKey(new_key);
      if (!keyValidation.valid) {
        return res.status(400).json({
          success: false,
          message: '新密钥格式不正确',
          errors: keyValidation.errors
        });
      }

      const result = await KeyRotationService.rotateEncryptionKey(old_key, new_key);

      res.status(200).json({
        success: result.success,
        message: result.message,
        data: result.details
      });
    } catch (error) {
      logger.error('密钥轮换失败:', error);
      res.status(500).json({
        success: false,
        message: '密钥轮换失败',
        error: error.message
      });
    }
  }

  /**
   * 导入配置
   * POST /api/v1/ai-config/import
   */
  static async importConfig(req, res) {
    try {
      const configData = req.body;

      // 验证配置
      const validation = AiConfigValidationService.validateConfig(configData);
      if (!validation.valid) {
        return res.status(400).json({
          success: false,
          message: '配置验证失败',
          errors: validation.errors
        });
      }

      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      // 加密API密钥
      let apiKeyEncrypted = null;
      if (configData.api_key) {
        apiKeyEncrypted = EncryptionService.encrypt(configData.api_key);
      }

      // 创建配置
      const config = aiConfigRepository.create({
        provider: configData.provider,
        api_endpoint: configData.api_endpoint || null,
        api_key_encrypted: apiKeyEncrypted,
        model: configData.model || null,
        timeout: configData.timeout || 60000,
        is_enabled: configData.is_enabled !== undefined ? configData.is_enabled : false,
        preferences: configData.preferences || null,
        status: configData.status || 'active',
        imported_at: new Date()
      });

      await aiConfigRepository.save(config);

      logger.info(`AI配置导入成功: ${configData.provider}`);

      res.status(201).json({
        success: true,
        message: '配置导入成功',
        data: {
          ...config,
          api_key_encrypted: undefined
        }
      });
    } catch (error) {
      logger.error('导入配置失败:', error);
      res.status(500).json({
        success: false,
        message: '导入配置失败'
      });
    }
  }

  /**
   * 导出配置
   * POST /api/v1/ai-config/export/:id
   */
  static async exportConfig(req, res) {
    try {
      const { id } = req.params;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const config = await aiConfigRepository.findOne({
        where: { id }
      });

      if (!config) {
        return res.status(404).json({
          success: false,
          message: '配置不存在'
        });
      }

      // 准备导出数据（不包含加密的密钥）
      const exportData = {
        provider: config.provider,
        api_endpoint: config.api_endpoint,
        model: config.model,
        timeout: config.timeout,
        is_enabled: config.is_enabled,
        priority: config.priority,
        preferences: config.preferences,
        status: config.status,
        exported_at: new Date().toISOString()
      };

      // 更新导出时间
      config.exported_at = new Date();
      await aiConfigRepository.save(config);

      res.status(200).json({
        success: true,
        message: '导出成功',
        data: exportData
      });
    } catch (error) {
      logger.error('导出配置失败:', error);
      res.status(500).json({
        success: false,
        message: '导出配置失败'
      });
    }
  }

  /**
   * 批量更新配置
   * PUT /api/v1/ai-config/batch
   */
  static async batchUpdate(req, res) {
    try {
      const { config_ids, is_enabled, status } = req.body;

      if (!config_ids || !Array.isArray(config_ids) || config_ids.length === 0) {
        return res.status(400).json({
          success: false,
          message: '请选择要操作的配置'
        });
      }

      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      // 构建更新数据
      const updateData = {};
      if (is_enabled !== undefined) updateData.is_enabled = is_enabled;
      if (status !== undefined) updateData.status = status;

      // 执行批量更新
      const result = await aiConfigRepository
        .createQueryBuilder()
        .update('AiConfig')
        .set(updateData)
        .where('id IN (:...ids)', { ids: config_ids })
        .execute();

      logger.info(`批量更新${result.affected || 0}个AI配置成功`);

      res.status(200).json({
        success: true,
        message: `成功更新${result.affected || 0}个配置`,
        data: { affected: result.affected || 0 }
      });
    } catch (error) {
      logger.error('批量更新失败:', error);
      res.status(500).json({
        success: false,
        message: '批量更新失败'
      });
    }
  }

  /**
   * 批量删除配置
   * DELETE /api/v1/ai-config/batch
   */
  static async batchDelete(req, res) {
    try {
      const { config_ids } = req.body;

      if (!config_ids || !Array.isArray(config_ids) || config_ids.length === 0) {
        return res.status(400).json({
          success: false,
          message: '请选择要删除的配置'
        });
      }

      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const result = await aiConfigRepository
        .createQueryBuilder()
        .delete()
        .from('AiConfig')
        .where('id IN (:...ids)', { ids: config_ids })
        .execute();

      logger.info(`批量删除${result.affected || 0}个AI配置成功`);

      res.status(200).json({
        success: true,
        message: `成功删除${result.affected || 0}个配置`,
        data: { affected: result.affected || 0 }
      });
    } catch (error) {
      logger.error('批量删除失败:', error);
      res.status(500).json({
        success: false,
        message: '批量删除失败'
      });
    }
  }

  /**
   * 复制配置
   * POST /api/v1/ai-config/:id/copy
   */
  static async copyConfig(req, res) {
    try {
      const { id } = req.params;
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      const originalConfig = await aiConfigRepository.findOne({
        where: { id }
      });

      if (!originalConfig) {
        return res.status(404).json({
          success: false,
          message: '配置不存在'
        });
      }

      // 获取下一个优先级
      const configs = await aiConfigRepository.find({
        order: { priority: 'DESC' },
        take: 1
      });
      const nextPriority = configs.length > 0 ? configs[0].priority + 1 : 0;

      // 创建副本（不包含API密钥）
      const copyConfig = aiConfigRepository.create({
        provider: originalConfig.provider,
        api_endpoint: originalConfig.api_endpoint,
        api_key_encrypted: null, // 不复制密钥
        model: originalConfig.model,
        timeout: originalConfig.timeout,
        is_enabled: false, // 默认禁用
        priority: nextPriority,
        preferences: originalConfig.preferences,
        status: 'inactive'
      });

      const saved = await aiConfigRepository.save(copyConfig);

      logger.info(`AI配置复制成功: ${id} -> ${saved.id}`);

      res.status(201).json({
        success: true,
        message: '配置复制成功',
        data: {
          ...saved,
          api_key_encrypted: undefined
        }
      });
    } catch (error) {
      logger.error('复制配置失败:', error);
      res.status(500).json({
        success: false,
        message: '复制配置失败'
      });
    }
  }

  /**
   * 获取测试历史
   * GET /api/v1/ai-config/:id/test-history
   */
  static async getTestHistory(req, res) {
    try {
      const { id } = req.params;
      const limit = parseInt(req.query.limit) || 20;

      const testHistoryRepository = AppDataSource.getRepository('AiTestHistory');

      const history = await testHistoryRepository.find({
        where: { ai_config_id: id },
        order: { created_at: 'DESC' },
        take: limit
      });

      res.status(200).json({
        success: true,
        message: '获取测试历史成功',
        data: history
      });
    } catch (error) {
      logger.error('获取测试历史失败:', error);
      res.status(500).json({
        success: false,
        message: '获取测试历史失败'
      });
    }
  }
}

module.exports = AiConfigController;

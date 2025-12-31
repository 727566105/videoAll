/**
 * AI配置验证服务
 *
 * 提供AI配置数据的验证功能，包括：
 * - URL格式验证
 * - API密钥格式验证
 * - 模型名称验证
 * - 超时时间范围验证
 * - JSON格式验证（preferences字段）
 * - 提供商支持检查
 */

const logger = require('../utils/logger');

class AiConfigValidationService {
  // URL验证正则（支持http和https）
  static URL_PATTERN = /^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/;

  // 提供商特定的API密钥格式（放宽验证，只做基本检查）
  static API_KEY_PATTERNS = {
    openai: /^sk-[a-zA-Z0-9]{20,}$/, // OpenAI格式: sk-开头，至少20字符
    anthropic: /^sk-ant-[a-zA-Z0-9_-]{20,}$/, // Anthropic格式
    qwen: /^sk-[a-zA-Z0-9]{20,}$/, // 通义千问
    wenxin: /^[a-zA-Z0-9]{10,}\.[a-zA-Z0-9]{10,}$/, // 文心一言格式: apikey.secret_key
    zhipu: /^[a-zA-Z0-9._-]{20,}$/, // 智谱AI，放宽长度
    deepseek: /^sk-[a-zA-Z0-9]{20,}$/, // DeepSeek，放宽长度要求
    custom: /^.{20,}$/, // 自定义：至少20字符
  };

  // 模型名称验证规则（大幅放宽限制）
  static MODEL_PATTERNS = {
    openai: /^gpt-[\w\-\.]+$/i,
    anthropic: /^claude-[\w\-]+$/i,
    ollama: /^[\w\-:\.]+$/,  // 放宽：允许字母数字及:_:-.符号
    qwen: /^qwen-[\w\-]+$/i,
    wenxin: /^ernie-?bot[\w\-]*$/i,
    zhipu: /^glm-[\w\-]+$/i,
    deepseek: /^deepseek-?[\w\-]*$/i,  // 放宽：允许 deepseek 或 deepseek-chat
  };

  /**
   * 验证配置数据
   * @param {object} configData - 配置数据
   * @returns {object} { valid: boolean, errors: string[] }
   */
  static validateConfig(configData) {
    const errors = [];

    // 1. 验证提供商
    if (!configData.provider) {
      errors.push('提供商不能为空');
    } else if (!this.getSupportedProviders().includes(configData.provider)) {
      errors.push(`不支持的提供商: ${configData.provider}`);
    }

    const provider = configData.provider;
    const providerInfo = this.getProviderInfo(provider);

    // 2. 验证API端点（根据提供商配置）
    if (providerInfo && providerInfo.requiresEndpoint) {
      if (!configData.api_endpoint) {
        errors.push(`${provider}需要API端点`);
      } else {
        const urlValidation = this.validateUrl(configData.api_endpoint);
        if (!urlValidation.valid) {
          errors.push(`API端点格式无效: ${urlValidation.error}`);
        }
      }
    } else if (configData.api_endpoint) {
      // 如果不需要端点但提供了，也验证格式
      const urlValidation = this.validateUrl(configData.api_endpoint);
      if (!urlValidation.valid) {
        errors.push(`API端点格式无效: ${urlValidation.error}`);
      }
    }

    // 3. 验证API密钥（根据提供商配置）
    if (this.requiresApiKey(provider)) {
      if (!configData.api_key) {
        errors.push(`${provider}需要API密钥`);
      } else {
        const keyValidation = this.validateApiKey(provider, configData.api_key);
        if (!keyValidation.valid) {
          errors.push(`API密钥格式无效: ${keyValidation.error}`);
        }
      }
    }

    // 4. 验证模型名称（可选字段，但如果提供了就验证）
    if (configData.model) {
      const modelValidation = this.validateModel(provider, configData.model);
      if (!modelValidation.valid) {
        errors.push(`模型名称无效: ${modelValidation.error}`);
      }
    }

    // 5. 验证超时时间
    if (configData.timeout !== undefined) {
      const timeoutValidation = this.validateTimeout(configData.timeout);
      if (!timeoutValidation.valid) {
        errors.push(`超时时间无效: ${timeoutValidation.error}`);
      }
    }

    // 6. 验证偏好设置（JSON格式）
    if (configData.preferences) {
      const prefsValidation = this.validatePreferences(configData.preferences);
      if (!prefsValidation.valid) {
        errors.push(`偏好设置格式无效: ${prefsValidation.error}`);
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * 验证URL格式
   * @param {string} url - URL字符串
   * @returns {object} { valid: boolean, error: string }
   */
  static validateUrl(url) {
    if (!url || typeof url !== 'string') {
      return { valid: false, error: 'URL不能为空' };
    }

    if (!this.URL_PATTERN.test(url)) {
      return { valid: false, error: 'URL格式不正确' };
    }

    try {
      const parsedUrl = new URL(url);
      if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
        return { valid: false, error: '仅支持HTTP和HTTPS协议' };
      }
    } catch (e) {
      return { valid: false, error: 'URL解析失败' };
    }

    return { valid: true };
  }

  /**
   * 验证API密钥格式
   * @param {string} provider - 提供商类型
   * @param {string} apiKey - API密钥
   * @returns {object} { valid: boolean, error: string }
   */
  static validateApiKey(provider, apiKey) {
    if (!apiKey || typeof apiKey !== 'string') {
      return { valid: false, error: 'API密钥不能为空' };
    }

    const pattern = this.API_KEY_PATTERNS[provider];
    if (pattern && !pattern.test(apiKey)) {
      return {
        valid: false,
        error: `${provider}的API密钥格式不正确`
      };
    }

    // 通用密钥强度检查
    if (apiKey.length < 20) {
      return { valid: false, error: 'API密钥长度不足（至少20字符）' };
    }

    return { valid: true };
  }

  /**
   * 验证模型名称
   * @param {string} provider - 提供商类型
   * @param {string} model - 模型名称
   * @returns {object} { valid: boolean, error: string }
   */
  static validateModel(provider, model) {
    if (!model || typeof model !== 'string') {
      return { valid: false, error: '模型名称不能为空' };
    }

    // ollama、custom 和 deepseek 提供商允许更灵活的模型名称格式
    if (provider === 'ollama' || provider === 'custom' || provider === 'deepseek') {
      // 只需要是非空字符串，长度在1-100之间
      if (model.length < 1 || model.length > 100) {
        return { valid: false, error: '模型名称长度必须在1-100字符之间' };
      }
      return { valid: true };
    }

    // 其他提供商使用严格的格式验证
    const pattern = this.MODEL_PATTERNS[provider];
    if (pattern && !pattern.test(model)) {
      return {
        valid: false,
        error: `${provider}的模型名称格式不正确`
      };
    }

    return { valid: true };
  }

  /**
   * 验证超时时间
   * @param {number} timeout - 超时时间（毫秒）
   * @returns {object} { valid: boolean, error: string }
   */
  static validateTimeout(timeout) {
    if (typeof timeout !== 'number' || isNaN(timeout)) {
      return { valid: false, error: '超时时间必须是数字' };
    }

    if (timeout < 5000) {
      return { valid: false, error: '超时时间不能少于5000毫秒' };
    }

    if (timeout > 300000) {
      return { valid: false, error: '超时时间不能超过300000毫秒（5分钟）' };
    }

    return { valid: true };
  }

  /**
   * 验证偏好设置JSON
   * @param {string|object} preferences - 偏好设置
   * @returns {object} { valid: boolean, error: string }
   */
  static validatePreferences(preferences) {
    if (typeof preferences === 'string') {
      try {
        JSON.parse(preferences);
        return { valid: true };
      } catch (e) {
        return { valid: false, error: 'JSON格式不正确' };
      }
    }

    if (typeof preferences === 'object') {
      try {
        JSON.stringify(preferences);
        return { valid: true };
      } catch (e) {
        return { valid: false, error: '对象序列化失败' };
      }
    }

    return { valid: false, error: '偏好设置必须是对象或JSON字符串' };
  }

  /**
   * 检查提供商是否需要API密钥
   * @param {string} provider - 提供商类型
   * @returns {boolean}
   */
  static requiresApiKey(provider) {
    return ['openai', 'anthropic', 'custom', 'qwen', 'wenxin', 'zhipu', 'deepseek'].includes(provider);
  }

  /**
   * 获取提供商配置信息
   * @param {string} provider - 提供商类型
   * @returns {object|null}
   */
  static getProviderInfo(provider) {
    const providers = {
      ollama: {
        requiresApiKey: false,
        requiresEndpoint: true,
        defaultEndpoint: 'http://localhost:11434',
      },
      openai: {
        requiresApiKey: true,
        requiresEndpoint: false,
        defaultEndpoint: 'https://api.openai.com/v1',
      },
      anthropic: {
        requiresApiKey: true,
        requiresEndpoint: false,
        defaultEndpoint: 'https://api.anthropic.com',
      },
      custom: {
        requiresApiKey: true,
        requiresEndpoint: true,
        defaultEndpoint: '',
      },
      qwen: {
        requiresApiKey: true,
        requiresEndpoint: false,
        defaultEndpoint: 'https://dashscope.aliyuncs.com/api/v1',
      },
      wenxin: {
        requiresApiKey: true,
        requiresEndpoint: false,
        defaultEndpoint: 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop',
      },
      zhipu: {
        requiresApiKey: true,
        requiresEndpoint: false,
        defaultEndpoint: 'https://open.bigmodel.cn/api/paas/v4',
      },
      deepseek: {
        requiresApiKey: true,
        requiresEndpoint: false,
        defaultEndpoint: 'https://api.deepseek.com/v1',
      },
    };

    return providers[provider] || null;
  }

  /**
   * 获取支持的提供商列表
   * @returns {string[]}
   */
  static getSupportedProviders() {
    return [
      'ollama',
      'openai',
      'anthropic',
      'custom',
      'qwen',
      'wenxin',
      'zhipu',
      'deepseek'
    ];
  }

  /**
   * 获取提供商的API密钥格式说明
   * @param {string} provider - 提供商类型
   * @returns {string}
   */
  static getApiKeyFormatHint(provider) {
    const hints = {
      openai: '格式: sk-开头的48位字符',
      anthropic: '格式: sk-ant-开头',
      qwen: '格式: sk-开头的32位以上字符',
      wenxin: '格式: apikey.secret_key（24位.24位）',
      zhipu: '格式: 40位以上字符',
      deepseek: '格式: sk-开头的40位以上字符',
      custom: '至少20个字符',
      ollama: '本地部署，无需API密钥'
    };
    return hints[provider] || '请参考提供商文档';
  }
}

module.exports = AiConfigValidationService;

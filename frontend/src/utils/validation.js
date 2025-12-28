/**
 * 前端验证工具
 *
 * 提供实时验证功能
 */

/**
 * URL格式验证
 * @param {string} url - URL字符串
 * @returns {object} { valid: boolean, error: string | null }
 */
export const validateUrl = (url) => {
  if (!url) return { valid: true }; // 可选字段
  const pattern = /^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/;
  return {
    valid: pattern.test(url),
    error: pattern.test(url) ? null : '请输入有效的URL（以http://或https://开头）'
  };
};

/**
 * JSON格式验证
 * @param {string} jsonString - JSON字符串
 * @returns {object} { valid: boolean, error: string | null }
 */
export const validateJson = (jsonString) => {
  if (!jsonString) return { valid: true };
  try {
    JSON.parse(jsonString);
    return { valid: true, error: null };
  } catch (e) {
    return {
      valid: false,
      error: 'JSON格式不正确，请检查语法'
    };
  }
};

/**
 * API密钥格式验证
 * @param {string} provider - 提供商类型
 * @param {string} apiKey - API密钥
 * @returns {object} { valid: boolean, error: string | null }
 */
export const validateApiKey = (provider, apiKey) => {
  if (!apiKey) return { valid: true }; // 由required控制

  const patterns = {
    openai: /^sk-[a-zA-Z0-9]{48}$/,
    anthropic: /^sk-ant-[a-zA-Z0-9_-]{95}$/,
    qwen: /^sk-[a-zA-Z0-9]{32,}$/,
    wenxin: /^[a-zA-Z0-9]{24}\.[a-zA-Z0-9]{24}$/,
    zhipu: /^[a-zA-Z0-9._-]{40,}$/,
    deepseek: /^sk-[a-zA-Z0-9]{40,}$/,
  };

  const pattern = patterns[provider];
  if (pattern && !pattern.test(apiKey)) {
    return {
      valid: false,
      error: `${provider}的API密钥格式不正确`
    };
  }

  if (apiKey.length < 20) {
    return {
      valid: false,
      error: 'API密钥长度不足（至少20字符）'
    };
  }

  return { valid: true, error: null };
};

/**
 * 超时时间验证
 * @param {number} timeout - 超时时间（毫秒）
 * @returns {object} { valid: boolean, error: string | null }
 */
export const validateTimeout = (timeout) => {
  if (timeout === undefined || timeout === null) return { valid: true };

  if (typeof timeout !== 'number' || isNaN(timeout)) {
    return {
      valid: false,
      error: '超时时间必须是数字'
    };
  }

  if (timeout < 5000) {
    return {
      valid: false,
      error: '超时时间不能少于5000毫秒'
    };
  }

  if (timeout > 300000) {
    return {
      valid: false,
      error: '超时时间不能超过300000毫秒（5分钟）'
    };
  }

  return { valid: true, error: null };
};

/**
 * 模型名称验证
 * @param {string} provider - 提供商类型
 * @param {string} model - 模型名称
 * @returns {object} { valid: boolean, error: string | null }
 */
export const validateModel = (provider, model) => {
  if (!model) return { valid: true }; // 可选字段

  const patterns = {
    openai: /^gpt-[a-z0-9\-\.]+$/i,
    anthropic: /^claude-[a-z0-9\-]+$/i,
    ollama: /^[a-z0-9]+:[a-z0-9\.]+$/i,
    qwen: /^qwen-[-a-z0-9]+$/i,
    wenxin: /^ernie-bot[-a-z0-9]*$/i,
    zhipu: /^glm-[-a-z0-9]+$/i,
    deepseek: /^deepseek-[-a-z0-9]+$/i,
  };

  const pattern = patterns[provider];
  if (pattern && !pattern.test(model)) {
    return {
      valid: false,
      error: `${provider}的模型名称格式不正确`
    };
  }

  return { valid: true, error: null };
};

/**
 * 获取API密钥格式提示
 * @param {string} provider - 提供商类型
 * @returns {string}
 */
export const getApiKeyFormatHint = (provider) => {
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
};

/**
 * 实时验证Hook（用于React组件）
 * 注意：这个函数需要在React组件中使用useState
 * @returns {object} 验证工具函数
 */
export const createValidationHelper = () => {
  const errors = {};

  const validateField = (fieldName, value, rules) => {
    let error = null;

    if (rules.required && !value) {
      error = `${rules.label || '该字段'}不能为空`;
    } else if (value && rules.validator) {
      const result = rules.validator(value);
      if (!result.valid) {
        error = result.error;
      }
    }

    if (error) {
      errors[fieldName] = error;
    } else {
      delete errors[fieldName];
    }

    return !error;
  };

  const getError = (fieldName) => errors[fieldName];
  const hasErrors = () => Object.keys(errors).length > 0;
  const getAllErrors = () => errors;

  return {
    validateField,
    getError,
    hasErrors,
    getAllErrors
  };
};

/**
 * 验证所有表单字段
 * @param {object} formData - 表单数据
 * @param {object} rules - 验证规则
 * @returns {object} { valid: boolean, errors: object }
 */
export const validateForm = (formData, rules) => {
  const errors = {};

  Object.keys(rules).forEach(fieldName => {
    const fieldRules = rules[fieldName];
    const value = formData[fieldName];

    let error = null;

    if (fieldRules.required && !value) {
      error = `${fieldRules.label || '该字段'}不能为空`;
    } else if (value && fieldRules.validator) {
      const result = fieldRules.validator(value);
      if (!result.valid) {
        error = result.error;
      }
    }

    if (error) {
      errors[fieldName] = error;
    }
  });

  return {
    valid: Object.keys(errors).length === 0,
    errors
  };
};

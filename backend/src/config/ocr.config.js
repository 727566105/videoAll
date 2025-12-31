/**
 * OCR配置
 *
 * 配置Tesseract.js的参数和行为
 */

module.exports = {
  // OCR引擎选择
  engine: 'tesseract',

  // 各平台对应的OCR语言配置
  languages: {
    'xiaohongshu': 'chi_sim+eng',  // 小红书：中文为主
    'douyin': 'chi_sim+eng',       // 抖音：中文为主
    'bilibili': 'chi_sim+eng',     // B站：中文为主
    'weibo': 'chi_sim+eng',        // 微博：中文为主
    'instagram': 'eng',            // Instagram：英文为主
    'tiktok': 'eng',               // TikTok：英文为主
    'default': 'chi_sim+eng'       // 默认：中英混合
  },

  // 超时配置（毫秒）
  timeout: 30000,  // 单张图片30秒超时

  // 并发控制
  maxConcurrency: 3,  // 最多3个并发OCR任务

  // 置信度阈值
  confidenceThreshold: 0.6,  // 低于0.6的结果标记为低置信度

  // 缓存配置
  cacheEnabled: true,
  cacheTTL: 3600,  // 缓存1小时（秒）

  // 图片预处理配置
  preprocessing: {
    enabled: true,
    maxWidth: 1920,    // 最大宽度
    maxHeight: 1080,   // 最大高度
    grayscale: true,   // 转灰度（提高OCR准确率）
    normalize: true,   // 标准化对比度
    quality: 80        // JPEG质量
  },

  // 重试配置
  retry: {
    maxAttempts: 2,    // 最多重试2次
    backoffMs: 1000    // 重试间隔1秒
  },

  // OCR结果处理配置
  postProcessing: {
    minLength: 2,      // 最小文字长度
    removeNoise: true, // 去除噪声字符
    mergeLines: true,  // 合并断行
    deduplicate: true  // 去重相似结果
  },

  // 性能监控
  metrics: {
    enabled: true,
    logSlowOperations: true,  // 记录慢操作
    slowThreshold: 5000       // 慢操作阈值（毫秒）
  }
};

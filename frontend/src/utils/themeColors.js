/**
 * 主题颜色工具函数
 * 提供跨主题兼容的颜色管理方案
 */

/**
 * 获取主题相关的颜色对象
 * @param {string} theme - 主题名称 ('light' | 'dark' | 'highContrast')
 * @returns {Object} 主题颜色配置
 */
export const getThemeColors = (theme = 'light') => {
  const colors = {
    light: {
      // 背景色
      bg: {
        container: '#ffffff',
        layout: '#f5f5f5',
        elevated: '#ffffff',
        spotlight: 'rgba(0, 0, 0, 0.85)',
        mask: 'rgba(0, 0, 0, 0.45)',
        secondary: '#fafafa',
        tertiary: '#f5f5f5',
        quaternary: '#f0f0f0',
      },
      // 文本色
      text: {
        primary: 'rgba(0, 0, 0, 0.88)',
        secondary: 'rgba(0, 0, 0, 0.65)',
        tertiary: 'rgba(0, 0, 0, 0.45)',
        quaternary: 'rgba(0, 0, 0, 0.25)',
      },
      // 边框色
      border: {
        default: '#d9d9d9',
        secondary: '#f0f0f0',
      },
      // 语义色
      primary: '#1677ff',
      success: '#52c41a',
      warning: '#faad14',
      error: '#ff4d4f',
      info: '#1677ff',
    },
    dark: {
      bg: {
        container: '#1f1f1f',
        layout: '#141414',
        elevated: '#262626',
        spotlight: 'rgba(255, 255, 255, 0.85)',
        mask: 'rgba(0, 0, 0, 0.45)',
        secondary: '#1f1f1f',
        tertiary: '#262626',
        quaternary: '#2c2c2c',
      },
      text: {
        primary: 'rgba(255, 255, 255, 0.85)',
        secondary: 'rgba(255, 255, 255, 0.65)',
        tertiary: 'rgba(255, 255, 255, 0.45)',
        quaternary: 'rgba(255, 255, 255, 0.25)',
      },
      border: {
        default: '#434343',
        secondary: '#303030',
      },
      primary: '#40a9ff',
      success: '#73d13d',
      warning: '#ffc53d',
      error: '#ff7875',
      info: '#40a9ff',
    },
    highContrast: {
      bg: {
        container: '#ffffff',
        layout: '#f5f5f5',
        elevated: '#ffffff',
        spotlight: 'rgba(0, 0, 0, 1)',
        mask: 'rgba(0, 0, 0, 0.45)',
        secondary: '#f0f0f0',
        tertiary: '#e8e8e8',
        quaternary: '#dddddd',
      },
      text: {
        primary: '#000000',
        secondary: '#333333',
        tertiary: '#666666',
        quaternary: '#999999',
      },
      border: {
        default: '#000000',
        secondary: '#cccccc',
      },
      primary: '#0066cc',
      success: '#008000',
      warning: '#b38600',
      error: '#a60000',
      info: '#0066cc',
    },
  };

  return colors[theme] || colors.light;
};

/**
 * 获取平台品牌色（与主题无关）
 */
export const PLATFORM_COLORS = {
  xiaohongshu: '#ff2442',
  douyin: '#000000',
  weibo: '#e6162d',
  bilibili: '#00a1d6',
  kuaishou: '#ff5000',
  default: '#1677ff',
};

/**
 * 获取平台颜色
 * @param {string} platform - 平台名称
 * @returns {string} 平台品牌色
 */
export const getPlatformColor = (platform) => {
  const platformMap = {
    'xiaohongshu': PLATFORM_COLORS.xiaohongshu,
    '小红书': PLATFORM_COLORS.xiaohongshu,
    'douyin': PLATFORM_COLORS.douyin,
    '抖音': PLATFORM_COLORS.douyin,
    'weibo': PLATFORM_COLORS.weibo,
    '微博': PLATFORM_COLORS.weibo,
    'bilibili': PLATFORM_COLORS.bilibili,
    '哔哩哔哩': PLATFORM_COLORS.bilibili,
    'kuaishou': PLATFORM_COLORS.kuaishou,
    '快手': PLATFORM_COLORS.kuaishou,
  };
  return platformMap[platform] || PLATFORM_COLORS.default;
};

/**
 * 根据主题获取样式对象
 * @param {string} theme - 主题名称
 * @returns {Object} 包含常用样式的对象
 */
export const getThemeStyles = (theme = 'light') => {
  const colors = getThemeColors(theme);
  const isDark = theme === 'dark';

  return {
    // 容器卡片样式
    cardStyle: {
      backgroundColor: colors.bg.container,
      border: `1px solid ${colors.border.default}`,
      borderRadius: 8,
      padding: 16,
    },
    // 次要容器样式
    secondaryCardStyle: {
      backgroundColor: colors.bg.secondary,
      border: `1px solid ${colors.border.secondary}`,
      borderRadius: 6,
      padding: 12,
    },
    // 主要文本样式
    primaryTextStyle: {
      color: colors.text.primary,
      fontSize: 14,
    },
    // 次要文本样式
    secondaryTextStyle: {
      color: colors.text.secondary,
      fontSize: 13,
    },
    // 成功状态样式
    successStyle: {
      color: colors.success,
    },
    // 警告状态样式
    warningStyle: {
      color: colors.warning,
    },
    // 错误状态样式
    errorStyle: {
      color: colors.error,
    },
    // 阴影
    boxShadow: isDark
      ? '0 2px 8px rgba(0, 0, 0, 0.3)'
      : '0 2px 8px rgba(0, 0, 0, 0.1)',
  };
};

/**
 * 状态颜色映射（用于表格、标签等）
 * @param {string} status - 状态值
 * @param {string} theme - 主题名称
 * @returns {string} 对应的颜色
 */
export const getStatusColor = (status, theme = 'light') => {
  const colors = getThemeColors(theme);

  const statusMap = {
    success: colors.success,
    completed: colors.success,
    active: colors.success,
    online: colors.success,
    '运行中': colors.success,
    '已完成': colors.success,

    warning: colors.warning,
    pending: colors.warning,
    processing: colors.warning,
    '进行中': colors.warning,
    '等待中': colors.warning,

    error: colors.error,
    failed: colors.error,
    inactive: colors.error,
    offline: colors.error,
    '已失败': colors.error,
    '已停止': colors.error,

    info: colors.info,
    default: colors.text.secondary,
  };

  return statusMap[status] || statusMap.default;
};

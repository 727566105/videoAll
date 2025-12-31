import { theme } from 'antd';

const { darkAlgorithm, defaultAlgorithm, highContrastAlgorithm } = theme;

// 主题配置
export const themes = {
  light: {
    algorithm: defaultAlgorithm,
    token: {
      // 主色系 - 使用 Ant Design 5.x 新标准
      colorPrimary: '#1677ff',
      colorSuccess: '#52c41a',
      colorWarning: '#faad14',
      colorError: '#ff4d4f',
      colorInfo: '#1677ff',
      colorLink: '#1677ff',

      // 背景色系
      colorBgContainer: '#ffffff',
      colorBgLayout: '#f5f5f5',
      colorBgElevated: '#ffffff',
      colorBgSpotlight: 'rgba(0, 0, 0, 0.85)',
      colorBgMask: 'rgba(0, 0, 0, 0.45)',

      // 文本色系 - 使用标准透明度层级
      colorText: 'rgba(0, 0, 0, 0.88)',
      colorTextSecondary: 'rgba(0, 0, 0, 0.65)',
      colorTextTertiary: 'rgba(0, 0, 0, 0.45)',
      colorTextQuaternary: 'rgba(0, 0, 0, 0.25)',

      // 边框色系
      colorBorder: '#d9d9d9',
      colorBorderSecondary: '#f0f0f0',

      // 填充色系 - 用于不同层级的背景
      colorFillSecondary: '#fafafa',
      colorFillTertiary: '#f5f5f5',
      colorFillQuaternary: '#f0f0f0',

      // 圆角
      borderRadius: 6,
      borderRadiusLG: 8,
      borderRadiusSM: 4,

      // 阴影
      boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.03), 0 1px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px 0 rgba(0, 0, 0, 0.02)',
      boxShadowSecondary: '0 6px 16px 0 rgba(0, 0, 0, 0.08), 0 3px 6px -4px rgba(0, 0, 0, 0.12), 0 9px 28px 8px rgba(0, 0, 0, 0.05)',
    },
  },
  dark: {
    algorithm: darkAlgorithm,
    token: {
      colorPrimary: '#40a9ff',
      colorSuccess: '#73d13d',
      colorWarning: '#ffc53d',
      colorError: '#ff7875',
      colorInfo: '#40a9ff',
      colorLink: '#40a9ff',

      colorBgContainer: '#1f1f1f',
      colorBgLayout: '#141414',
      colorBgElevated: '#262626',
      colorBgSpotlight: 'rgba(255, 255, 255, 0.85)',
      colorBgMask: 'rgba(0, 0, 0, 0.45)',

      colorText: 'rgba(255, 255, 255, 0.85)',
      colorTextSecondary: 'rgba(255, 255, 255, 0.65)',
      colorTextTertiary: 'rgba(255, 255, 255, 0.45)',
      colorTextQuaternary: 'rgba(255, 255, 255, 0.25)',

      colorBorder: '#434343',
      colorBorderSecondary: '#303030',

      colorFillSecondary: '#1f1f1f',
      colorFillTertiary: '#262626',
      colorFillQuaternary: '#2c2c2c',

      borderRadius: 6,
      borderRadiusLG: 8,
      borderRadiusSM: 4,

      boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.03), 0 1px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px 0 rgba(0, 0, 0, 0.02)',
      boxShadowSecondary: '0 6px 16px 0 rgba(0, 0, 0, 0.08), 0 3px 6px -4px rgba(0, 0, 0, 0.12), 0 9px 28px 8px rgba(0, 0, 0, 0.05)',
    },
  },
  highContrast: {
    algorithm: highContrastAlgorithm,
    token: {
      // 主色系 - 提高对比度以满足 WCAG AAA 标准
      colorPrimary: '#0052cc',
      colorSuccess: '#006600',
      colorWarning: '#cc8800',
      colorError: '#cc0000',
      colorInfo: '#0052cc',
      colorLink: '#0052cc',

      // 背景色系 - 纯白背景确保最大对比度
      colorBgContainer: '#ffffff',
      colorBgLayout: '#ffffff',
      colorBgElevated: '#ffffff',
      colorBgSpotlight: '#000000',
      colorBgMask: 'rgba(0, 0, 0, 0.7)',

      // 文本色系 - 使用纯黑和深灰确保可读性
      colorText: '#000000',
      colorTextSecondary: '#000000',
      colorTextTertiary: '#000000',
      colorTextQuaternary: '#333333',

      // 边框色系 - 纯黑边框达到最大对比度
      colorBorder: '#000000',
      colorBorderSecondary: '#000000',

      // 填充色系 - 使用浅灰背景
      colorFillSecondary: '#f0f0f0',
      colorFillTertiary: '#e0e0e0',
      colorFillQuaternary: '#d0d0d0',

      // 圆角 - 使用较小的圆角减少视觉杂乱
      borderRadius: 0,
      borderRadiusLG: 2,
      borderRadiusSM: 0,

      // 阴影 - 无阴影以提高清晰度
      boxShadow: 'none',
      boxShadowSecondary: '2px 2px 0px #000000',

      // 字体 - 增加字号和行高
      fontSize: 16,
      lineHeight: 1.6,

      // 字重 - 增加字重提高可读性
      fontWeightStrong: 700,
    },
  },
};

// 主题选项，用于下拉选择器
export const themeOptions = [
  { value: 'light', label: '浅色主题' },
  { value: 'dark', label: '深色主题' },
  { value: 'highContrast', label: '高对比度主题' },
];

// 主题切换过渡配置
export const themeTransitionConfig = {
  motion: {
    default: { motion: true, },
  },
  components: {
    Layout: {
      motion: true,
    },
    Modal: {
      motion: true,
    },
    Drawer: {
      motion: true,
    },
  },
};

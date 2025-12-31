/**
 * 全局样式变量
 * 统一管理 spacing、fontSize、zIndex 等设计规范
 */

/**
 * 间距系统 (基于 4px 网格)
 */
export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,
};

/**
 * 字体大小系统
 */
export const fontSize = {
  xs: 10,
  sm: 12,
  base: 14,
  lg: 16,
  xl: 18,
  xxl: 20,
  xxxl: 24,
};

/**
 * 行高系统
 */
export const lineHeight = {
  tight: 1.25,
  normal: 1.5,
  relaxed: 1.75,
};

/**
 * 圆角系统
 */
export const borderRadius = {
  none: 0,
  sm: 4,
  base: 6,
  md: 8,
  lg: 12,
  xl: 16,
  full: 9999,
};

/**
 * Z-index 层级系统
 */
export const zIndex = {
  base: 0,
  dropdown: 1000,
  sticky: 1020,
  fixed: 1030,
  modalBackdrop: 1040,
  modal: 1050,
  popover: 1060,
  tooltip: 1070,
};

/**
 * 过渡动画时长
 */
export const transitionDuration = {
  fast: 150,
  base: 300,
  slow: 500,
};

/**
 * 断点系统 (响应式设计)
 */
export const breakpoints = {
  xs: '480px',
  sm: '576px',
  md: '768px',
  lg: '992px',
  xl: '1200px',
  xxl: '1600px',
};

/**
 * 常用样式组合
 */
export const commonStyles = {
  // Flex 布局
  flexCenter: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  flexBetween: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  flexStart: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'flex-start',
  },

  // 卡片样式
  card: {
    backgroundColor: '#ffffff',
    border: '1px solid #d9d9d9',
    borderRadius: borderRadius.base,
    padding: spacing.lg,
  },

  // 按钮间距
  buttonGap: {
    display: 'flex',
    gap: spacing.md,
  },
};

/**
 * 响应式工具函数
 * @param {Object} values - 断点对应的值
 * @returns {Object} 媒体查询样式
 */
export const responsive = (values) => {
  const style = {};
  const mediaQueries = {
    xs: `(max-width: 480px)`,
    sm: `(max-width: 576px)`,
    md: `(max-width: 768px)`,
    lg: `(max-width: 992px)`,
    xl: `(max-width: 1200px)`,
  };

  return style;
};

/**
 * 获取间距样式
 * @param {string|number} size - 间距大小
 * @param {string} direction - 方向 (all, x, y, top, right, bottom, left)
 * @returns {Object} 样式对象
 */
export const getSpacingStyle = (size, direction = 'all') => {
  const value = typeof size === 'string' ? spacing[size] || size : size;

  const styles = {
    all: { padding: value },
    x: { paddingLeft: value, paddingRight: value },
    y: { paddingTop: value, paddingBottom: value },
    top: { paddingTop: value },
    right: { paddingRight: value },
    bottom: { paddingBottom: value },
    left: { paddingLeft: value },
  };

  return styles[direction] || styles.all;
};

/**
 * 获取字体大小样式
 * @param {string|number} size - 字体大小
 * @returns {Object} 样式对象
 */
export const getFontSizeStyle = (size) => {
  const value = typeof size === 'string' ? fontSize[size] || size : size;
  return { fontSize: value };
};

/**
 * 导出所有常量和工具函数
 */
export default {
  spacing,
  fontSize,
  lineHeight,
  borderRadius,
  zIndex,
  transitionDuration,
  breakpoints,
  commonStyles,
  responsive,
  getSpacingStyle,
  getFontSizeStyle,
};

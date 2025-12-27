/**
 * AI配置路由
 *
 * 定义AI API配置的RESTful API路由
 */

const express = require('express');
const router = express.Router();
const AiConfigController = require('../controllers/AiConfigController');
const { authenticate, authorize } = require('../middleware/auth');

// 所有路由都需要认证
router.use(authenticate);

// 获取AI配置列表 - 所有认证用户可访问
router.get('/', AiConfigController.getConfigs);

// 获取当前启用的AI配置
router.get('/active', AiConfigController.getActiveConfig);

// 获取单个AI配置
router.get('/:id', AiConfigController.getConfigById);

// 获取支持的提供商列表
router.get('/meta/providers', AiConfigController.getProviders);

// 获取配置模板
router.get('/meta/templates/:provider', AiConfigController.getConfigTemplate);

// AI配置管理操作 - 需要 admin 权限
router.use(authorize(['admin']));

// 创建AI配置
router.post('/', AiConfigController.createConfig);

// 更新AI配置
router.put('/:id', AiConfigController.updateConfig);

// 删除AI配置
router.delete('/:id', AiConfigController.deleteConfig);

// 测试AI配置连接
router.post('/:id/test', AiConfigController.testConnection);

module.exports = router;

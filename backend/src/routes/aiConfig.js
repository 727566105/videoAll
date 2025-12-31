/**
 * AI配置路由
 *
 * 定义AI API配置的RESTful API路由
 */

const express = require('express');
const router = express.Router();
const AiConfigController = require('../controllers/AiConfigController');
const { authenticate, authorize } = require('../middleware/auth');

// 辅助函数：确保 this 上下文正确
const withContext = (fn) => (req, res, next) => fn.call(AiConfigController, req, res, next);

// 所有路由都需要认证
router.use(authenticate);

// 获取AI配置列表 - 所有认证用户可访问
router.get('/', withContext(AiConfigController.getConfigs));

// 获取当前启用的AI配置
router.get('/active', withContext(AiConfigController.getActiveConfig));

// 元数据路由（必须在 /:id 之前定义）
router.get('/meta/providers', withContext(AiConfigController.getProviders));
router.get('/meta/templates/:provider', withContext(AiConfigController.getConfigTemplate));

// 安全相关路由（必须在 /:id 之前定义）
router.get('/security/key-status', authorize(['admin']), withContext(AiConfigController.getKeyStatus));

// 获取单个AI配置（必须在所有具体路由之后）
router.get('/:id', withContext(AiConfigController.getConfigById));

// AI配置管理操作 - 需要 admin 权限
router.use(authorize(['admin']));

// 创建AI配置
router.post('/', withContext(AiConfigController.createConfig));

// 更新AI配置
router.put('/:id', withContext(AiConfigController.updateConfig));

// 删除AI配置
router.delete('/:id', withContext(AiConfigController.deleteConfig));

// 测试AI配置连接
router.post('/:id/test', withContext(AiConfigController.testConnection));

// 复制配置
router.post('/:id/copy', withContext(AiConfigController.copyConfig));

// 获取测试历史
router.get('/:id/test-history', withContext(AiConfigController.getTestHistory));

// 导入配置
router.post('/import', withContext(AiConfigController.importConfig));

// 导出配置
router.post('/export/:id', withContext(AiConfigController.exportConfig));

// 批量更新配置
router.put('/batch', withContext(AiConfigController.batchUpdate));

// 批量删除配置
router.delete('/batch', withContext(AiConfigController.batchDelete));

// 轮换加密密钥
router.post('/security/rotate-key', withContext(AiConfigController.rotateKey));

module.exports = router;

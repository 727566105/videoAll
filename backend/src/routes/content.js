const express = require('express');
const router = express.Router();
const ContentController = require('../controllers/ContentController');
// const { authenticate } = require('../middleware/auth');

// All routes are protected by authentication
// router.use(authenticate);

// Parse content from link
router.post('/parse', ContentController.parseContent);

// Proxy download for external media files
router.get('/proxy-download', ContentController.proxyDownload);

// Proxy image for frontend display (bypass CORS)
router.get('/proxy-image', ContentController.proxyImage);

// 访问本地媒体文件（优先使用本地文件）
router.get('/:id/local-media', ContentController.getLocalMedia);

// Download exported Excel file
router.get('/download-export', ContentController.downloadExport);

// Get content list with pagination and filters
router.get('/', ContentController.getContentList);

// Get content by ID
router.get('/:id', ContentController.getContentById);

// Delete content by ID
router.delete('/:id', ContentController.deleteContent);

// Refresh statistics from original source
router.post('/:id/refresh-stats', ContentController.refreshStats);

// Batch delete contents
router.post('/batch-delete', ContentController.batchDeleteContents);

// Batch export contents
router.post('/export', ContentController.batchExportContents);

// Download single content file
router.post('/download', ContentController.downloadContent);

// Save content to both database and project root directory
router.post('/save', ContentController.saveContent);

// AI分析相关路由
// 分析单个内容的AI标签
router.post('/:id/ai-analyze', ContentController.analyzeContentAi);

// 获取内容的AI分析状态
router.get('/:id/ai-status', ContentController.getContentAiStatus);

// 确认或拒绝AI生成的标签
router.post('/:id/ai-tags/confirm', ContentController.confirmAiTags);

// 获取待确认的AI标签
router.get('/:id/ai-tags/pending', ContentController.getPendingAiTags);

// 获取AI标签统计信息
router.get('/ai-tags/stats', ContentController.getAiTagStats);

module.exports = router;
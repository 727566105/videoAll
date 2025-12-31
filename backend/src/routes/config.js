const express = require('express');
const router = express.Router();
const PlatformCookieController = require('../controllers/PlatformCookieController');
const SystemSettingsController = require('../controllers/SystemSettingsController');
const DownloadSettingsController = require('../controllers/DownloadSettingsController');
const { authenticate, authorize } = require('../middleware/auth');

// ========== 公开接口（无需认证） ==========
// 获取平台支持的画质选项
router.get('/download-settings/quality-options/:platform', DownloadSettingsController.getQualityOptions);

// ========== 以下接口需要认证 ==========
// All routes below are protected by authentication
router.use(authenticate);

// ========== Platform Cookie Management Routes (TypeORM) ==========
// Get all platform cookies
router.get('/cookies', PlatformCookieController.getPlatformCookies);
router.get('/platform-cookies', PlatformCookieController.getPlatformCookies);

// Create a new platform cookie (admin only)
router.post('/cookies', authorize(['admin']), PlatformCookieController.createPlatformCookie);
router.post('/platform-cookies', authorize(['admin']), PlatformCookieController.createPlatformCookie);

// Update a platform cookie (admin only)
router.put('/cookies/:id', authorize(['admin']), PlatformCookieController.updatePlatformCookie);
router.put('/platform-cookies/:id', authorize(['admin']), PlatformCookieController.updatePlatformCookie);

// Delete a platform cookie (admin only)
router.delete('/cookies/:id', authorize(['admin']), PlatformCookieController.deletePlatformCookie);
router.delete('/platform-cookies/:id', authorize(['admin']), PlatformCookieController.deletePlatformCookie);

// Test platform cookie validity
router.post('/cookies/:id/test', PlatformCookieController.testPlatformCookieById);
router.post('/platform-cookies/:id/test', PlatformCookieController.testPlatformCookieById);

// Batch test all platform cookies
router.post('/platform-cookies/batch-test', authorize(['admin']), PlatformCookieController.batchTestPlatformCookies);

// Auto fetch cookie for a platform
router.get('/platform-cookies/auto-fetch/:platform', authorize(['admin']), PlatformCookieController.autoFetchCookie);

// ========== System Settings Routes (TypeORM) ==========
// Get system settings
router.get('/system', SystemSettingsController.getSystemSettings);

// Update system settings (admin only)
router.put('/system', authorize(['admin']), SystemSettingsController.updateSystemSettings);

// ========== Download Settings Routes ==========
// Get all platform download settings (需要登录，不需要admin)
router.get('/download-settings', DownloadSettingsController.getDownloadSettings);

// Update platform download settings (需要admin权限)
router.put('/download-settings', authorize(['admin']), DownloadSettingsController.updateDownloadSettings);

module.exports = router;

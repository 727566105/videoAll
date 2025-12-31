const express = require('express');
const router = express.Router();
const DownloadSettingsController = require('../controllers/DownloadSettingsController');

// 获取所有平台的下载设置
router.get('/', DownloadSettingsController.getDownloadSettings);

// 更新指定平台的下载设置
router.put('/', DownloadSettingsController.updateDownloadSettings);

// 获取平台支持的画质选项
router.get('/quality-options/:platform', DownloadSettingsController.getQualityOptions);

module.exports = router;

const express = require('express');
const router = express.Router();
const HotsearchController = require('../controllers/HotsearchController');
const { authenticate, adminOnly } = require('../middleware/auth');

// All routes are protected by authentication
router.use(authenticate);

// ========== Phase 2: New Routes ==========

// Get all platforms hotsearch (merge endpoint)
router.get('/all', HotsearchController.getAllPlatformsHotsearch);

// Get hotsearch history with advanced filtering
router.get('/history', HotsearchController.getHotsearchHistory);

// Compare hotsearch across platforms
router.get('/compare', HotsearchController.compareHotsearchAcrossPlatforms);

// Get hotsearch analysis
router.get('/analysis', HotsearchController.getHotsearchAnalysis);

// Get keyword trends
router.get('/keywords/:keyword', HotsearchController.getKeywordTrends);

// Refresh all hotsearch (admin only)
router.post('/refresh', adminOnly, HotsearchController.refreshAllHotsearch);

// Get crawl statistics (admin only)
router.get('/stats', adminOnly, HotsearchController.getCrawlStats);

// ========== Existing Routes ==========

// Get hotsearch platforms - specific route first
router.get('/platforms', HotsearchController.getHotsearchPlatforms);

// Get related content for a hotsearch keyword - specific route
router.get('/related', HotsearchController.getHotsearchRelatedContent);

// Get hotsearch trends - specific route with parameter
router.get('/:platform/trends', HotsearchController.getHotsearchTrends);

// Get hotsearch by date and platform - general route
router.get('/:platform', HotsearchController.getHotsearchByDate);

// Fetch hotsearch for all platforms
router.post('/', HotsearchController.fetchAllHotsearch);

// Fetch hotsearch for a specific platform
router.post('/:platform', HotsearchController.fetchHotsearch);

// Parse content from hotsearch keyword
router.post('/parse', HotsearchController.parseHotsearchContent);

module.exports = router;
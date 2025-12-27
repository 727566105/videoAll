const express = require('express');
const router = express.Router();
const TagController = require('../controllers/TagController');
const { authenticate, authorize } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// 查询标签 - 所有认证用户都可以访问
router.get('/', TagController.getAllTags);
router.get('/content/:id/tags', TagController.getContentTags);

// 标签管理操作 - 需要 admin 权限
router.use(authorize(['admin']));

// 创建、更新、删除标签
router.post('/', TagController.createTag);
router.put('/:id', TagController.updateTag);
router.delete('/:id', TagController.deleteTag);

// 批量操作标签
router.post('/content/tags/add', TagController.addTagsToContent);
router.post('/content/tags/remove', TagController.removeTagsFromContent);
router.post('/content/tags/batch', TagController.batchUpdateContentTags);

module.exports = router;

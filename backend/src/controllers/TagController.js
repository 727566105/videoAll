const { AppDataSource } = require('../utils/db');
const CacheService = require('../services/CacheService');
const AiTagService = require('../services/AiTagService');

class TagController {
  // 预定义颜色数组
  static PREDEFINED_COLORS = [
    '#f50', '#faad14', '#52c41a', '#1890ff',
    '#722ed1', '#eb2f96', '#fa8c16', '#a0d911',
    '#13c2c2', '#2f54eb', '#f759ab', '#9254de'
  ];

  /**
   * 获取所有标签（带使用频率）
   */
  static async getAllTags(req, res) {
    try {
      // 检查缓存
      const cacheKey = 'tags:all';
      const cachedData = CacheService.get(cacheKey);
      if (cachedData) {
        return res.status(200).json(cachedData);
      }

      const tagRepository = AppDataSource.getRepository('Tag');
      const tags = await tagRepository.find({
        order: { usage_count: 'DESC', created_at: 'DESC' }
      });

      const responseData = {
        message: '获取标签成功',
        data: tags
      };

      // 缓存5分钟
      CacheService.set(cacheKey, responseData, 300);

      res.status(200).json(responseData);
    } catch (error) {
      console.error('获取标签失败:', error);
      res.status(500).json({ message: '获取标签失败' });
    }
  }

  /**
   * 创建标签（自动分配颜色）
   */
  static async createTag(req, res) {
    try {
      const { name, color, description } = req.body;

      // 验证必填字段
      if (!name || name.trim() === '') {
        return res.status(400).json({ message: '标签名称不能为空' });
      }

      const tagRepository = AppDataSource.getRepository('Tag');

      // 检查标签名是否已存在
      const existingTag = await tagRepository.findOne({
        where: { name: name.trim() }
      });

      if (existingTag) {
        return res.status(400).json({ message: '标签名称已存在' });
      }

      // 如果没有提供颜色，自动分配
      let finalColor = color;
      if (!finalColor) {
        finalColor = await TagController.generateColor();
      }

      // 创建标签
      const newTag = tagRepository.create({
        name: name.trim(),
        color: finalColor,
        description: description || null
      });

      const savedTag = await tagRepository.save(newTag);

      // 清除缓存
      CacheService.del('tags:all');

      res.status(201).json({
        message: '创建标签成功',
        data: savedTag
      });
    } catch (error) {
      console.error('创建标签失败:', error);
      res.status(500).json({ message: '创建标签失败' });
    }
  }

  /**
   * 更新标签
   */
  static async updateTag(req, res) {
    try {
      const { id } = req.params;
      const { name, color, description } = req.body;

      const tagRepository = AppDataSource.getRepository('Tag');
      const tag = await tagRepository.findOne({ where: { id } });

      if (!tag) {
        return res.status(404).json({ message: '标签不存在' });
      }

      // 如果更新名称，检查是否重复
      if (name && name.trim() !== tag.name) {
        const existingTag = await tagRepository.findOne({
          where: { name: name.trim() }
        });

        if (existingTag) {
          return res.status(400).json({ message: '标签名称已存在' });
        }

        tag.name = name.trim();
      }

      // 更新其他字段
      if (color) {
        tag.color = color;
      }
      if (description !== undefined) {
        tag.description = description;
      }

      tag.updated_at = new Date();
      const updatedTag = await tagRepository.save(tag);

      // 清除缓存
      CacheService.del('tags:all');

      res.status(200).json({
        message: '更新标签成功',
        data: updatedTag
      });
    } catch (error) {
      console.error('更新标签失败:', error);
      res.status(500).json({ message: '更新标签失败' });
    }
  }

  /**
   * 删除标签（级联删除关联）
   */
  static async deleteTag(req, res) {
    try {
      const { id } = req.params;

      const tagRepository = AppDataSource.getRepository('Tag');
      const tag = await tagRepository.findOne({ where: { id } });

      if (!tag) {
        return res.status(404).json({ message: '标签不存在' });
      }

      // 删除关联的 content_tags 记录
      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      await contentTagRepository.delete({ tag_id: id });

      // 删除标签
      await tagRepository.delete(id);

      // 清除缓存
      CacheService.del('tags:all');

      res.status(200).json({ message: '删除标签成功' });
    } catch (error) {
      console.error('删除标签失败:', error);
      res.status(500).json({ message: '删除标签失败' });
    }
  }

  /**
   * 获取内容的标签
   */
  static async getContentTags(req, res) {
    try {
      const { id } = req.params;

      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      const tagRepository = AppDataSource.getRepository('Tag');

      // 查询内容关联的所有标签
      const contentTags = await contentTagRepository.find({
        where: { content_id: id }
      });

      // 获取标签详细信息
      const tagIds = contentTags.map(ct => ct.tag_id);
      const tags = await tagRepository.findBy({ id: tagIds });

      res.status(200).json({
        message: '获取内容标签成功',
        data: tags
      });
    } catch (error) {
      console.error('获取内容标签失败:', error);
      res.status(500).json({ message: '获取内容标签失败' });
    }
  }

  /**
   * 为内容添加标签
   */
  static async addTagsToContent(req, res) {
    try {
      const { content_id, tag_ids } = req.body;

      // 验证必填字段
      if (!content_id || !tag_ids || !Array.isArray(tag_ids) || tag_ids.length === 0) {
        return res.status(400).json({ message: '缺少必要参数' });
      }

      const contentRepository = AppDataSource.getRepository('Content');
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');

      // 验证内容是否存在
      const content = await contentRepository.findOne({ where: { id: content_id } });
      if (!content) {
        return res.status(404).json({ message: '内容不存在' });
      }

      // 验证标签是否存在
      const tags = await tagRepository
        .createQueryBuilder('tag')
        .where('tag.id IN (:...tag_ids)', { tag_ids })
        .getMany();

      if (tags.length !== tag_ids.length) {
        return res.status(400).json({ message: '部分标签不存在' });
      }

      // 添加关联（跳过已存在的）
      let addedCount = 0;
      for (const tag_id of tag_ids) {
        const existing = await contentTagRepository.findOne({
          where: { content_id, tag_id }
        });

        if (!existing) {
          const contentTag = contentTagRepository.create({ content_id, tag_id });
          await contentTagRepository.save(contentTag);
          addedCount++;

          // 更新标签使用次数
          await tagRepository.increment({ id: tag_id }, 'usage_count', 1);
        }
      }

      // 同步更新 Content.tags JSON 字段
      await AiTagService.syncContentTags(content_id);

      // 清除缓存
      CacheService.del('tags:all');

      res.status(200).json({
        message: `成功添加 ${addedCount} 个标签`,
        data: { addedCount }
      });
    } catch (error) {
      console.error('添加标签失败:', error);
      console.error('Error stack:', error.stack);
      console.error('Error name:', error.name);
      console.error('Error message:', error.message);
      res.status(500).json({ message: `添加标签失败: ${error.message}` });
    }
  }

  /**
   * 从内容移除标签
   */
  static async removeTagsFromContent(req, res) {
    try {
      const { content_id, tag_ids } = req.body;

      // 验证必填字段
      if (!content_id || !tag_ids || !Array.isArray(tag_ids) || tag_ids.length === 0) {
        return res.status(400).json({ message: '缺少必要参数' });
      }

      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      const tagRepository = AppDataSource.getRepository('Tag');

      // 移除关联并减少使用次数
      let removedCount = 0;
      for (const tag_id of tag_ids) {
        const result = await contentTagRepository.delete({
          content_id,
          tag_id
        });

        if (result.affected > 0) {
          removedCount++;

          // 更新标签使用次数（不小于0）
          await tagRepository
            .createQueryBuilder()
            .update('Tag')
            .set('usage_count', () => 'GREATEST(usage_count - 1, 0)')
            .where('id = :id', { id: tag_id })
            .execute();
        }
      }

      // 清除缓存
      CacheService.del('tags:all');

      res.status(200).json({
        message: `成功移除 ${removedCount} 个标签`,
        data: { removedCount }
      });
    } catch (error) {
      console.error('移除标签失败:', error);
      res.status(500).json({ message: '移除标签失败' });
    }
  }

  /**
   * 批量操作（支持 add/remove/replace）
   */
  static async batchUpdateContentTags(req, res) {
    try {
      const { content_ids, tag_ids, operation } = req.body;

      // 验证必填字段
      if (!content_ids || !Array.isArray(content_ids) || content_ids.length === 0) {
        return res.status(400).json({ message: '请选择要操作的内容' });
      }

      if (!tag_ids || !Array.isArray(tag_ids) || tag_ids.length === 0) {
        return res.status(400).json({ message: '请选择标签' });
      }

      if (!operation || !['add', 'remove', 'replace'].includes(operation)) {
        return res.status(400).json({ message: '无效的操作类型' });
      }

      const contentRepository = AppDataSource.getRepository('Content');
      const tagRepository = AppDataSource.getRepository('Tag');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');

      // 验证内容是否存在
      const contents = await contentRepository
        .createQueryBuilder('content')
        .where('content.id IN (:...content_ids)', { content_ids })
        .getMany();
      if (contents.length !== content_ids.length) {
        return res.status(400).json({ message: '部分内容不存在' });
      }

      // 验证标签是否存在
      const tags = await tagRepository
        .createQueryBuilder('tag')
        .where('tag.id IN (:...tag_ids)', { tag_ids })
        .getMany();

      let resultMessage = '';

      // 根据操作类型执行
      if (operation === 'add') {
        // 批量添加标签
        let addedCount = 0;
        for (const content_id of content_ids) {
          for (const tag_id of tag_ids) {
            const existing = await contentTagRepository.findOne({
              where: { content_id, tag_id }
            });

            if (!existing) {
              const contentTag = contentTagRepository.create({ content_id, tag_id });
              await contentTagRepository.save(contentTag);
              addedCount++;
            }
          }
        }

        // 更新标签使用次数
        for (const tag_id of tag_ids) {
          const count = content_ids.length;
          await tagRepository.increment({ id: tag_id }, 'usage_count', count);
        }

        resultMessage = `成功为 ${content_ids.length} 个内容添加了标签`;

      } else if (operation === 'remove') {
        // 批量移除标签
        let removedCount = 0;
        for (const content_id of content_ids) {
          for (const tag_id of tag_ids) {
            const result = await contentTagRepository.delete({
              content_id,
              tag_id
            });
            if (result.affected > 0) {
              removedCount++;
            }
          }
        }

        // 更新标签使用次数（减少但不小于0）
        for (const tag_id of tag_ids) {
          const count = content_ids.length;
          // 使用原生 SQL 执行更新
          await tagRepository.query(
            `UPDATE tags SET usage_count = GREATEST(usage_count - $1, 0) WHERE id = $2`,
            [count, tag_id]
          );
        }

        resultMessage = `成功从 ${content_ids.length} 个内容移除了标签`;

      } else if (operation === 'replace') {
        // 批量替换标签
        for (const content_id of content_ids) {
          // 删除所有现有标签关联
          await contentTagRepository.delete({ content_id });

          // 添加新标签关联
          for (const tag_id of tag_ids) {
            const contentTag = contentTagRepository.create({ content_id, tag_id });
            await contentTagRepository.save(contentTag);
          }
        }

        resultMessage = `成功为 ${content_ids.length} 个内容替换了标签`;
      }

      // 同步更新所有内容的 Content.tags JSON 字段
      for (const content_id of content_ids) {
        try {
          await AiTagService.syncContentTags(content_id);
        } catch (syncError) {
          console.error(`同步内容标签失败 (content_id: ${content_id}):`, syncError);
          // 继续处理其他内容，不中断整个批量操作
        }
      }

      // 清除缓存
      CacheService.del('tags:all');

      res.status(200).json({
        message: resultMessage,
        data: {
          affectedContentCount: content_ids.length,
          operation
        }
      });
    } catch (error) {
      console.error('批量操作失败:', error);
      res.status(500).json({ message: '批量操作失败' });
    }
  }

  /**
   * 自动颜色生成器（从预设颜色中选择未使用的）
   */
  static async generateColor() {
    try {
      const tagRepository = AppDataSource.getRepository('Tag');
      const tags = await tagRepository.find();

      // 获取已使用的颜色
      const usedColors = tags.map(tag => tag.color);

      // 从预设颜色中找到第一个未使用的
      const availableColor = TagController.PREDEFINED_COLORS.find(
        color => !usedColors.includes(color)
      );

      // 如果都用了，随机返回一个
      return availableColor ||
        TagController.PREDEFINED_COLORS[
          Math.floor(Math.random() * TagController.PREDEFINED_COLORS.length)
        ];
    } catch (error) {
      console.error('生成颜色失败，使用默认颜色:', error);
      return '#1890ff';
    }
  }
}

module.exports = TagController;

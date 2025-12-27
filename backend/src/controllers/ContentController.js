const { AppDataSource } = require('../utils/db');
const ParseService = require('../services/ParseService');
const MediaDownloadService = require('../services/MediaDownloadService');
const fs = require('fs-extra');
const path = require('path');
const CacheService = require('../services/CacheService');
const xlsx = require('xlsx');
const axios = require('axios');

class ContentController {
  // Parse content from link
  static async parseContent(req, res) {
    let link = null;  // 在外部声明，确保catch块中可以访问

    try {
      const { link: requestLink } = req.body;
      link = requestLink;  // 赋值给外部变量

      if (!link) {
        return res.status(400).json({ message: '请提供作品链接' });
      }

      // Parse link only - no media download
      const parsedData = await ParseService.parseLink(link);
      
      // Detect platform from link
      const platform = ParseService.detectPlatform(link);
      if (!platform) {
        return res.status(400).json({ message: '不支持的平台链接' });
      }
      
      // Return the full parsed result including media_url, all_images, and all_videos
      // This is what the frontend expects - directly return parsedData
      res.status(201).json({
        message: '解析成功',
        title: parsedData.title,
        author: parsedData.author,
        platform,
        content_id: parsedData.content_id,
        description: parsedData.description || '',
        media_type: parsedData.media_type,
        cover_url: parsedData.cover_url,
        media_url: parsedData.media_url, // Ensure media_url is included
        all_images: parsedData.all_images, // Ensure all_images is included
        all_videos: parsedData.all_videos, // Ensure all_videos is included - NEW
        has_live_photo: parsedData.has_live_photo, // Include live photo support
        like_count: parsedData.like_count, // Include interaction stats
        collect_count: parsedData.collect_count,
        comment_count: parsedData.comment_count,
        share_count: parsedData.share_count,
        view_count: parsedData.view_count,
        publish_time: parsedData.publish_time,
        tags: parsedData.tags, // Include tags
        source_url: link,
        source_type: 1, // 1-单链接解析
        created_at: new Date()
      });
    } catch (error) {
      console.error('Parse content error:', error);
      console.error('Error stack:', error.stack);
      console.error('Error name:', error.name);
      console.error('Error message:', error.message);

      // 记录到专门的错误日志文件 - 使用 JSON 确保完整记录
      const fs = require('fs-extra');
      const path = require('path');
      const errorLogPath = path.join(__dirname, '../../logs/parse-error.log');
      try {
        const errorInfo = {
          timestamp: new Date().toISOString(),
          link: link,
          error: {
            message: error.message,
            name: error.name,
            stack: error.stack,
            code: error.code,
            // 完整的错误对象
            full: JSON.stringify(error, Object.getOwnPropertyNames(error))
          }
        };
        fs.appendFileSync(errorLogPath, '\n' + JSON.stringify(errorInfo, null, 2) + '\n---\n');
        console.log('Parse error logged to:', errorLogPath);
      } catch (logError) {
        console.error('Failed to write parse error log:', logError);
      }

      // Provide more detailed error messages based on error type
      let errorMessage = '解析失败';
      if (error.message) {
        errorMessage = `解析失败: ${error.message}`;
      } else if (error.code) {
        errorMessage = `解析失败 (错误代码: ${error.code})`;
      }
      
      // Handle specific error types
      if (error.code === 'ECONNREFUSED') {
        errorMessage = '解析失败: 网络连接被拒绝，请检查网络连接';
      } else if (error.code === 'ETIMEDOUT') {
        errorMessage = '解析失败: 请求超时，请稍后重试';
      } else if (error.code === '23505') {
        errorMessage = '解析失败: 内容已存在';
      }
      
      res.status(500).json({ message: errorMessage });
    }
  }

  // Get content list with pagination and filters
  static async getContentList(req, res) {
    try {
      const {
        page = 1,
        page_size = 10,
        platform,
        media_type,
        author,
        source_type,
        keyword,
        start_date,
        end_date,
        tags
      } = req.query;

      // Create cache key based on query parameters
      const cacheKey = CacheService.getContentListCacheKey(req.query);

      // Check cache first
      const cachedData = CacheService.get(cacheKey);
      if (cachedData) {
        return res.status(200).json(cachedData);
      }

      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');
      const contentTagRepository = AppDataSource.getRepository('ContentTag');

      // Build query with TypeORM QueryBuilder
      const queryBuilder = contentRepository.createQueryBuilder('content');

      // 标签筛选 - 使用 OR 逻辑（包含任意一个标签即可）
      let filteredContentIds = null;
      if (tags) {
        // 确保标签ID是数组
        let tagIds;
        if (Array.isArray(tags)) {
          tagIds = tags;
        } else if (typeof tags === 'string') {
          // 处理逗号分隔的字符串
          tagIds = tags.split(',').map(t => t.trim()).filter(t => t);
        } else {
          tagIds = [tags];
        }

        if (tagIds.length > 0) {
          // 查询包含这些标签的内容ID（使用 OR 逻辑）
          // 转义每个 UUID 并构建 IN 子句
          const escapedTagIds = tagIds.map(id => `'${id}'`).join(',');
          const query = `
            SELECT DISTINCT ct.content_id
            FROM content_tags ct
            WHERE ct.tag_id IN (${escapedTagIds})
          `;

          const contentTags = await contentTagRepository.query(query);

          filteredContentIds = contentTags.map(ct => ct.content_id);

          // 如果没有找到任何内容，返回空结果
          if (filteredContentIds.length === 0) {
            return res.status(200).json({
              message: '获取成功',
              data: {
                list: [],
                total: 0,
                page: parseInt(page),
                page_size: parseInt(page_size)
              }
            });
          }
        }
      }

      // Apply filters
      if (platform) {
        queryBuilder.andWhere('content.platform = :platform', { platform });
      }
      if (media_type) {
        queryBuilder.andWhere('content.media_type = :media_type', { media_type });
      }
      if (author) {
        queryBuilder.andWhere('content.author ILIKE :author', { author: `%${author}%` });
      }
      if (source_type) {
        queryBuilder.andWhere('content.source_type = :source_type', { source_type: parseInt(source_type) });
      }
      if (keyword) {
        queryBuilder.andWhere('content.title ILIKE :keyword OR content.description ILIKE :keyword', { keyword: `%${keyword}%` });
      }
      if (start_date || end_date) {
        if (start_date) {
          queryBuilder.andWhere('content.created_at >= :start_date', { start_date: new Date(start_date) });
        }
        if (end_date) {
          queryBuilder.andWhere('content.created_at <= :end_date', { end_date: new Date(end_date) });
        }
      }

      // 应用标签筛选
      if (filteredContentIds) {
        queryBuilder.andWhere('content.id IN (:...contentIds)', { contentIds: filteredContentIds });
      }

      // Get total count
      const total = await queryBuilder.getCount();

      // Get paginated data
      const contents = await queryBuilder
        .orderBy('content.created_at', 'DESC')
        .skip((parseInt(page) - 1) * parseInt(page_size))
        .take(parseInt(page_size))
        .getMany();

      // 批量获取内容的标签
      const contentIds = contents.map(c => c.id);
      const contentTags = contentIds.length > 0
        ? await contentTagRepository
            .createQueryBuilder('ct')
            .where('ct.content_id IN (:...contentIds)', { contentIds })
            .getMany()
        : [];

      // 构建 contentId -> tags 的映射
      const contentTagsMap = {};
      for (const ct of contentTags) {
        if (!contentTagsMap[ct.content_id]) {
          contentTagsMap[ct.content_id] = [];
        }
        contentTagsMap[ct.content_id].push(ct.tag_id);
      }

      // Process all_images and all_videos fields - parse JSON strings to arrays
      const processedContents = await Promise.all(contents.map(async (content) => {
        // 获取标签详细信息
        let tags = [];
        if (contentTagsMap[content.id] && contentTagsMap[content.id].length > 0) {
          const tagRepository = AppDataSource.getRepository('Tag');
          // 使用 QueryBuilder 避免数组参数问题
          tags = await tagRepository
            .createQueryBuilder('tag')
            .where('tag.id IN (:...tagIds)', { tagIds: contentTagsMap[content.id] })
            .getMany();
        }

        return {
          ...content,
          all_images: content.all_images ? JSON.parse(content.all_images) : [],
          all_videos: content.all_videos ? JSON.parse(content.all_videos) : [],
          tags: tags // 添加标签数组
        };
      }));

      // Prepare response data
      const responseData = {
        message: '获取成功',
        data: {
          list: processedContents,
          total,
          page: parseInt(page),
          page_size: parseInt(page_size)
        }
      };

      // Cache the response for 1 minute (60 seconds)
      CacheService.set(cacheKey, responseData, 60);

      res.status(200).json(responseData);
    } catch (error) {
      console.error('Get content list error:', error);
      console.error('Error stack:', error.stack);
      console.error('Error name:', error.name);
      console.error('Error message:', error.message);
      res.status(500).json({ message: `获取内容列表失败: ${error.message}` });
    }
  }

  // Get content by ID
  static async getContentById(req, res) {
    try {
      const { id } = req.params;

      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');
      const content = await contentRepository.findOne({ where: { id } });

      if (!content) {
        return res.status(404).json({ message: '内容不存在' });
      }

      // 查询内容关联的标签
      const contentTagRepository = AppDataSource.getRepository('ContentTag');
      const tagRepository = AppDataSource.getRepository('Tag');

      const contentTags = await contentTagRepository.find({
        where: { content_id: id }
      });

      const tagIds = contentTags.map(ct => ct.tag_id);
      const tags = tagIds.length > 0
        ? await tagRepository.findBy({ id: tagIds })
        : [];

      res.status(200).json({
        message: '获取成功',
        data: {
          ...content,
          tags: tags
        }
      });
    } catch (error) {
      console.error('Get content by id error:', error);
      res.status(500).json({ message: '获取内容失败' });
    }
  }

  // Delete content by ID
  static async deleteContent(req, res) {
    try {
      const { id } = req.params;
      
      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');
      
      // Find content first to get file path
      const content = await contentRepository.findOne({ where: { id } });
      if (!content) {
        return res.status(404).json({ message: '内容不存在' });
      }
      
      // Delete from database
      await contentRepository.delete(id);

      // 清除内容列表缓存
      CacheService.flush();

      // Delete file from disk
      const filePath = path.join(process.env.STORAGE_ROOT_PATH, content.file_path);
      try {
        await fs.unlink(filePath);
      } catch (fileError) {
        console.error('Delete file error:', fileError);
        // Continue even if file deletion fails
      }
      
      res.status(200).json({ message: '删除成功' });
    } catch (error) {
      console.error('Delete content error:', error);
      res.status(500).json({ message: '删除内容失败' });
    }
  }

  // Refresh statistics from original source
  static async refreshStats(req, res) {
    try {
      const { id } = req.params;

      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');

      // Find content first
      const content = await contentRepository.findOne({ where: { id } });
      if (!content) {
        return res.status(404).json({ message: '内容不存在' });
      }

      // Check if content has source_url
      if (!content.source_url) {
        return res.status(400).json({ message: '没有源链接，无法刷新统计数据' });
      }

      // Re-parse the content from original source
      let parsedData;
      try {
        parsedData = await ParseService.parseLink(content.source_url);
      } catch (parseError) {
        console.error('Refresh stats - parse error:', parseError);

        // If parsing failed, mark as missing but keep existing data
        const updatedContent = {
          ...content,
          is_missing: true
        };

        await contentRepository.save(updatedContent);

        return res.status(200).json({
          success: true,
          message: '笔记已消失，但保留了已有数据',
          data: {
            is_missing: true,
            like_count: content.like_count || 0,
            collect_count: content.collect_count || 0,
            comment_count: content.comment_count || 0,
            share_count: content.share_count || 0,
            view_count: content.view_count || 0
          }
        });
      }

      // Update only statistics fields, keep media data unchanged
      const updatedContent = {
        ...content,
        like_count: parsedData.like_count || 0,
        collect_count: parsedData.collect_count || 0,
        comment_count: parsedData.comment_count || 0,
        share_count: parsedData.share_count || 0,
        view_count: parsedData.view_count || 0,
        publish_time: parsedData.publish_time || content.publish_time,
        is_missing: false
      };

      await contentRepository.save(updatedContent);

      // 清除内容列表缓存
      CacheService.flush();

      res.status(200).json({
        success: true,
        message: '统计数据已更新',
        data: {
          is_missing: false,
          like_count: updatedContent.like_count,
          collect_count: updatedContent.collect_count,
          comment_count: updatedContent.comment_count,
          share_count: updatedContent.share_count,
          view_count: updatedContent.view_count,
          publish_time: updatedContent.publish_time
        }
      });
    } catch (error) {
      console.error('Refresh stats error:', error);
      res.status(500).json({ message: '刷新统计数据失败' });
    }
  }

  // Batch delete contents
  static async batchDeleteContents(req, res) {
    try {
      const { ids } = req.body;
      
      if (!Array.isArray(ids) || ids.length === 0) {
        return res.status(400).json({ message: '请选择要删除的内容' });
      }
      
      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');

      // Get contents to delete
      const contents = await contentRepository.findBy({ id: ids });
      
      // Delete from database
      await contentRepository.delete(ids);

      // 清除内容列表缓存
      CacheService.flush();

      // Delete files from disk
      for (const content of contents) {
        const filePath = path.join(process.env.STORAGE_ROOT_PATH, content.file_path);
        try {
          await fs.unlink(filePath);
        } catch (fileError) {
          console.error('Delete file error:', fileError);
          // Continue even if file deletion fails
        }
      }
      
      res.status(200).json({ message: '批量删除成功' });
    } catch (error) {
      console.error('Batch delete contents error:', error);
      res.status(500).json({ message: '批量删除失败' });
    }
  }

  // Batch export contents
  static async batchExportContents(req, res) {
    try {
      const { ids } = req.body;
      
      if (!Array.isArray(ids) || ids.length === 0) {
        return res.status(400).json({ message: '请选择要导出的内容' });
      }
      
      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');

      // Get contents to export
      const contents = await contentRepository.findBy({ id: ids });
      
      // Convert content data to Excel format
      const exportData = contents.map(content => ({
        '标题': content.title,
        '作者': content.author,
        '平台': content.platform,
        '类型': content.media_type === 'video' ? '视频' : '图片',
        '来源': content.source_type === 1 ? '单链接解析' : '监控任务',
        '采集时间': content.created_at ? new Date(content.created_at).toLocaleString() : '',
        '原始链接': content.source_url,
        '文件路径': content.file_path
      }));
      
      // Create workbook and worksheet
      const ws = xlsx.utils.json_to_sheet(exportData);
      const wb = xlsx.utils.book_new();
      xlsx.utils.book_append_sheet(wb, ws, '内容列表');
      
      // Generate file name with timestamp
      const timestamp = new Date().getTime();
      const fileName = `content_export_${timestamp}.xlsx`;
      const filePath = path.join(__dirname, '../../tmp', fileName);
      
      // Ensure tmp directory exists
      await fs.ensureDir(path.join(__dirname, '../../tmp'));
      
      // Write workbook to file
      await xlsx.writeFile(wb, filePath);
      
      // Generate download URL
      const downloadUrl = `/api/v1/content/download-export?file=${fileName}`;
      
      res.status(200).json({
        message: '导出成功',
        data: {
          download_url: downloadUrl,
          file_name: fileName
        }
      });
    } catch (error) {
      console.error('Batch export contents error:', error);
      res.status(500).json({ message: '导出失败' });
    }
  }

  // Download exported Excel file
  static async downloadExport(req, res) {
    try {
      const { file } = req.query;
      
      if (!file) {
        return res.status(400).json({ message: '请提供文件名' });
      }
      
      // Prevent directory traversal attack
      if (file.includes('..') || file.includes('/')) {
        return res.status(400).json({ message: '无效的文件名' });
      }
      
      const filePath = path.join(__dirname, '../../tmp', file);
      
      // Check if file exists
      if (!await fs.pathExists(filePath)) {
        return res.status(404).json({ message: '文件不存在' });
      }
      
      // Set headers and send file
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename=${encodeURIComponent(file)}`);
      res.sendFile(filePath, (err) => {
        if (err) {
          console.error('Send file error:', err);
          res.status(500).json({ message: '文件下载失败' });
        } else {
          // Delete file after download (optional)
          setTimeout(() => {
            fs.unlink(filePath).catch(console.error);
          }, 5000);
        }
      });
    } catch (error) {
      console.error('Download export error:', error);
      res.status(500).json({ message: '文件下载失败' });
    }
  }

  // Download single content file
  static async downloadContent(req, res) {
    try {
      const { id } = req.body;
      
      if (!id) {
        return res.status(400).json({ message: '请提供内容ID' });
      }
      
      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');
      
      // Get content from database
      const content = await contentRepository.findOne({ where: { id } });
      if (!content) {
        return res.status(404).json({ message: '内容不存在' });
      }
      
      // Check if file_path is a directory (new format) or single file (old format)
      let filePath = content.file_path;
      
      // If file_path is not an absolute path, make it relative to storage root
      if (!path.isAbsolute(filePath)) {
        filePath = path.join(process.env.STORAGE_ROOT_PATH || process.cwd(), filePath);
      }
      
      // Check if path exists
      if (!await fs.pathExists(filePath)) {
        return res.status(404).json({ message: '文件不存在' });
      }
      
      // Check if it's a directory (new format with multiple files)
      const stats = await fs.stat(filePath);
      
      if (stats.isDirectory()) {
        // For directories, create a zip file with all media files
        const archiver = require('archiver');
        const archive = archiver('zip', { zlib: { level: 9 } });
        
        // Set response headers for zip download
        const zipFileName = `${content.title || 'content'}_${content.platform || 'unknown'}_${content.id}.zip`;
        res.setHeader('Content-Type', 'application/zip');
        res.setHeader('Content-Disposition', `attachment; filename=${encodeURIComponent(zipFileName)}`);
        
        // Pipe archive to response
        archive.pipe(res);
        
        // Add all files from the directory to the archive
        const files = await fs.readdir(filePath);
        
        for (const file of files) {
          const fullPath = path.join(filePath, file);
          const fileStats = await fs.stat(fullPath);
          if (fileStats.isFile()) {
            archive.file(fullPath, { name: file });
          }
        }
        
        // Finalize the archive
        await archive.finalize();
        
      } else {
        // Single file (old format)
        // Determine file extension and set appropriate Content-Type
        const fileExtension = path.extname(filePath).toLowerCase();
        let contentType = 'application/octet-stream';
        
        if (fileExtension === '.mp4') {
          contentType = 'video/mp4';
        } else if (fileExtension === '.jpg' || fileExtension === '.jpeg') {
          contentType = 'image/jpeg';
        } else if (fileExtension === '.png') {
          contentType = 'image/png';
        } else if (fileExtension === '.gif') {
          contentType = 'image/gif';
        }
        
        // Extract original filename from content
        const fileName = `${content.title || 'content'}_${content.platform || 'unknown'}_${content.id}${fileExtension}`;
        
        // Set headers and send file
        res.setHeader('Content-Type', contentType);
        res.setHeader('Content-Disposition', `attachment; filename=${encodeURIComponent(fileName)}`);
        res.sendFile(filePath, (err) => {
          if (err) {
            console.error('Send file error:', err);
            if (!res.headersSent) {
              res.status(500).json({ message: '文件下载失败' });
            }
          }
        });
      }
      
    } catch (error) {
      console.error('Download content error:', error);
      if (!res.headersSent) {
        res.status(500).json({ message: '文件下载失败' });
      }
    }
  }

  // Helper function to check if content type is a supported media type
  static isSupportedMediaType(contentType) {
    const supportedTypes = {
      'image': ['jpeg', 'png', 'gif', 'webp', 'jpg'],
      'video': ['mp4', 'mov', 'avi', 'mkv', 'webm']
    };
    
    if (!contentType) return false;
    
    const typeParts = contentType.split('/');
    if (typeParts.length !== 2) return false;
    
    const [mainType, subType] = typeParts;
    return supportedTypes[mainType] && supportedTypes[mainType].includes(subType);
  }
  
  // Helper function to check if content is HTML
  static isHTMLContent(contentType, data) {
    if (contentType && contentType.includes('text/html')) {
      return true;
    }
    
    // Check if data is a string and contains HTML tags
    if (typeof data === 'string' && /<html|<!DOCTYPE html/i.test(data)) {
      return true;
    }
    
    return false;
  }
  
  // Proxy download for external media files (bypass CORS)
  static async proxyDownload(req, res) {
    try {
      const { url, filename } = req.query;
      
      if (!url) {
        console.error('ProxyDownload: No URL provided');
        return res.status(400).json({ message: '请提供下载URL' });
      }
      
      console.log('ProxyDownload: Starting download for URL:', url);
      
      // Validate URL (basic validation to prevent SSRF attacks)
      const parsedUrl = new URL(url);
      if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
        console.error('ProxyDownload: Unsupported protocol for URL:', url);
        return res.status(400).json({ message: '不支持的URL协议' });
      }
      
      // Smart Referer selection based on domain
      let referer = `${parsedUrl.protocol}//${parsedUrl.host}/`;

      // Special handling for known platforms
      if (parsedUrl.host.includes('xhscdn.com') || parsedUrl.host.includes('xiaohongshu.com')) {
        referer = 'https://www.xiaohongshu.com/';
      } else if (parsedUrl.host.includes('bilibili.com') || parsedUrl.host.includes('bili')) {
        referer = 'https://www.bilibili.com/';
      } else if (parsedUrl.host.includes('douyin.com') || parsedUrl.host.includes('iesdouyin.com')) {
        referer = 'https://www.douyin.com/';
      } else if (parsedUrl.host.includes('kuaishou.com') || parsedUrl.host.includes('kwai')) {
        referer = 'https://www.kuaishou.com/';
      }

      console.log('ProxyDownload: Using Referer:', referer);

      // Set a timeout for the request (20 seconds)
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => {
          console.error('ProxyDownload: Request timed out for URL:', url);
          reject(new Error('下载超时'));
        }, 20000);
      });

      // Fetch the file from the external URL with follow redirects enabled
      const axiosResponse = await Promise.race([
        axios.get(url, {
          responseType: 'stream',
          maxRedirects: 5, // Follow up to 5 redirects
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': referer, // 使用动态生成的Referer
            'Accept': 'image/webp,image/apng,image/svg+xml,image/*,video/*,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Sec-Fetch-Dest': 'image',
            'Sec-Fetch-Mode': 'no-cors',
            'Sec-Fetch-Site': 'cross-site'
          }
        }),
        timeoutPromise
      ]);
      
      console.log('ProxyDownload: Received response with status:', axiosResponse.status);
      
      // Determine content type from response headers
      const contentType = axiosResponse.headers['content-type'] || 'application/octet-stream';
      console.log('ProxyDownload: Content-Type:', contentType);
      
      // Check if content type is a supported media type
      if (!ContentController.isSupportedMediaType(contentType)) {
        console.error('ProxyDownload: Unsupported media type:', contentType, 'for URL:', url);
        return res.status(400).json({ message: '不支持的媒体类型' });
      }
      
      // Determine file extension if not provided
      let ext = '';
      if (contentType.includes('image/jpeg')) ext = '.jpg';
      else if (contentType.includes('image/png')) ext = '.png';
      else if (contentType.includes('image/webp')) ext = '.webp';
      else if (contentType.includes('video/mp4')) ext = '.mp4';
      else if (contentType.includes('video/mov')) ext = '.mov';
      
      // Set filename if not provided
      const downloadFilename = filename || `download_${Date.now()}${ext}`;
      
      // Set response headers
      res.setHeader('Content-Type', contentType);
      
      // Only set Content-Disposition as attachment if not requested inline
      const isInline = req.query.inline === 'true';
      if (!isInline) {
        res.setHeader('Content-Disposition', `attachment; filename=${encodeURIComponent(downloadFilename)}`);
      } else {
        // For inline requests (like when fetching content for ZIP creation), don't set attachment
        res.setHeader('Content-Disposition', `inline; filename=${encodeURIComponent(downloadFilename)}`);
      }
      
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Access-Control-Allow-Origin', '*');
      
      // Pipe the response stream to the client
      axiosResponse.data.pipe(res);
      
      // Handle stream errors
      axiosResponse.data.on('error', (err) => {
        console.error('ProxyDownload: Stream error:', err);
        if (!res.headersSent) {
          res.status(500).json({ message: '文件下载失败' });
        }
      });
      
      // Handle stream end
      axiosResponse.data.on('end', () => {
        console.log('ProxyDownload: Download completed successfully for URL:', url);
      });
      
    } catch (error) {
      console.error('ProxyDownload: Error:', error.stack);
      if (!res.headersSent) {
        res.status(500).json({ message: `下载失败: ${error.message}` });
      }
    }
  }

  // Proxy image for frontend display (bypass CORS)
  static async proxyImage(req, res) {
    try {
      const { url } = req.query;
      
      if (!url) {
        console.error('ProxyImage: No URL provided');
        // Return placeholder SVG if no URL provided
        const svgPlaceholder = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="#f0f0f0"/><text x="75" y="80" font-size="12" text-anchor="middle" fill="#666">缺少图片URL</text></svg>`;
        res.setHeader('Content-Type', 'image/svg+xml');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.setHeader('Access-Control-Allow-Origin', '*');
        return res.send(svgPlaceholder);
      }
      
      console.log('ProxyImage: Starting request for URL:', url);
      
      // Validate URL (basic validation to prevent SSRF attacks)
      const parsedUrl = new URL(url);
      if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
        console.error('ProxyImage: Unsupported protocol for URL:', url);
        // Return placeholder SVG for invalid protocol
        const svgPlaceholder = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="#f0f0f0"/><text x="75" y="80" font-size="12" text-anchor="middle" fill="#666">不支持的URL协议</text></svg>`;
        res.setHeader('Content-Type', 'image/svg+xml');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.setHeader('Access-Control-Allow-Origin', '*');
        return res.send(svgPlaceholder);
      }
      
      // Smart Referer selection based on domain
      let referer = `${parsedUrl.protocol}//${parsedUrl.host}/`;

      // Special handling for known platforms
      if (parsedUrl.host.includes('xhscdn.com') || parsedUrl.host.includes('xiaohongshu.com')) {
        referer = 'https://www.xiaohongshu.com/';
      } else if (parsedUrl.host.includes('bilibili.com') || parsedUrl.host.includes('bili')) {
        referer = 'https://www.bilibili.com/';
      } else if (parsedUrl.host.includes('douyin.com') || parsedUrl.host.includes('iesdouyin.com')) {
        referer = 'https://www.douyin.com/';
      } else if (parsedUrl.host.includes('kuaishou.com') || parsedUrl.host.includes('kwai')) {
        referer = 'https://www.kuaishou.com/';
      }

      console.log('ProxyImage: Using Referer:', referer);

      // Set a timeout for the request (20 seconds)
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => {
          console.error('ProxyImage: Request timed out for URL:', url);
          reject(new Error('图片加载超时'));
        }, 20000);
      });

      // Fetch the image from the external URL with follow redirects enabled
      const axiosResponse = await Promise.race([
        axios.get(url, {
          responseType: 'stream',
          maxRedirects: 5, // Follow up to 5 redirects
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': referer, // 使用动态生成的Referer
            'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Sec-Fetch-Dest': 'image',
            'Sec-Fetch-Mode': 'no-cors',
            'Sec-Fetch-Site': 'cross-site'
          }
        }),
        timeoutPromise
      ]);
      
      console.log('ProxyImage: Received response with status:', axiosResponse.status);
      
      // Determine content type from response headers
      const contentType = axiosResponse.headers['content-type'] || 'image/jpeg';
      console.log('ProxyImage: Content-Type:', contentType);
      
      // Check if content type is a supported image type
      if (!ContentController.isSupportedMediaType(contentType) || !contentType.startsWith('image/')) {
        console.error('ProxyImage: Unsupported image type:', contentType, 'for URL:', url);
        // Return placeholder SVG for unsupported image type
        const svgPlaceholder = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="#f0f0f0"/><text x="75" y="70" font-size="12" text-anchor="middle" fill="#666">不支持的图片类型</text><text x="75" y="90" font-size="10" text-anchor="middle" fill="#999">${contentType}</text></svg>`;
        res.setHeader('Content-Type', 'image/svg+xml');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.setHeader('Access-Control-Allow-Origin', '*');
        return res.send(svgPlaceholder);
      }
      
      // Set response headers for image display
      res.setHeader('Content-Type', contentType);
      res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
      res.setHeader('Access-Control-Allow-Origin', '*'); // Allow CORS for all origins
      
      // Pipe the response stream to the client
      axiosResponse.data.pipe(res);
      
      // Handle stream errors
      axiosResponse.data.on('error', (err) => {
        console.error('ProxyImage: Stream error:', err);
        // End response if stream errors
        res.end();
      });
      
      // Handle stream end
      axiosResponse.data.on('end', () => {
        console.log('ProxyImage: Image loaded successfully for URL:', url);
      });
      
    } catch (error) {
      console.error('ProxyImage: Error:', error.stack);
      // Return a placeholder SVG if any error occurs
      const svgPlaceholder = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="#f0f0f0"/><text x="75" y="70" font-size="12" text-anchor="middle" fill="#666">图片加载失败</text><text x="75" y="90" font-size="10" text-anchor="middle" fill="#999">${error.message}</text></svg>`;
      if (!res.headersSent) {
        res.setHeader('Content-Type', 'image/svg+xml');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.send(svgPlaceholder);
      }
    }
  }

  // Save content to both database and project root directory
  static async saveContent(req, res) {
    try {
      const { link, source_type = 1, task_id = null } = req.body;
      
      if (!link) {
        return res.status(400).json({ message: '请提供作品链接' });
      }
      
      // Parse the link first
      const parsedData = await ParseService.parseLink(link);
      
      // Detect platform from link
      const platform = ParseService.detectPlatform(link);
      if (!platform) {
        return res.status(400).json({ message: '不支持的平台链接' });
      }
      
      // Get Content repository from TypeORM
      const contentRepository = AppDataSource.getRepository('Content');
      
      // Check if content already exists in database
      const existingContent = await contentRepository.findOne({
        where: {
          platform,
          content_id: parsedData.content_id
        }
      });
      
      if (existingContent) {
        return res.status(409).json({ 
          message: '内容已存在，无需重复保存',
          data: existingContent
        });
      }
      
      // Check if content already exists in file system
      const contentExists = await MediaDownloadService.checkContentExists(platform, parsedData.content_id);
      if (contentExists) {
        console.log('内容文件已存在，跳过下载');
      }
      
      // Download and save content to file system
      let downloadResult = null;
      if (!contentExists) {
        try {
          downloadResult = await MediaDownloadService.downloadAndSaveContent(parsedData, platform, link);
          console.log('内容下载完成:', downloadResult.folderName);
        } catch (downloadError) {
          console.error('下载内容失败:', downloadError);
          // 继续保存到数据库，即使下载失败
          downloadResult = {
            success: false,
            error: downloadError.message,
            contentDir: MediaDownloadService.getContentPath(platform, parsedData.title, parsedData.content_id),
            downloadedFiles: [],
            totalFiles: 0,
            successfulFiles: 0
          };
        }
      } else {
        downloadResult = {
          success: true,
          contentDir: MediaDownloadService.getContentPath(platform, parsedData.title, parsedData.content_id),
          downloadedFiles: [],
          totalFiles: 0,
          successfulFiles: 0,
          message: '文件已存在，跳过下载'
        };
      }
      
      // Prepare content data for database
      const content = contentRepository.create({
        platform,
        content_id: parsedData.content_id,
        title: parsedData.title,
        author: parsedData.author,
        description: parsedData.description || '',
        media_type: parsedData.media_type,
        file_path: downloadResult.contentDir, // 保存文件夹路径而不是单个文件路径
        cover_url: parsedData.cover_url,
        all_images: parsedData.all_images ? JSON.stringify(parsedData.all_images) : null,
        all_videos: parsedData.all_videos ? JSON.stringify(parsedData.all_videos) : null,
        source_url: link,
        source_type: parseInt(source_type),
        task_id,
        like_count: parsedData.like_count || 0,
        collect_count: parsedData.collect_count || 0,
        comment_count: parsedData.comment_count || 0,
        share_count: parsedData.share_count || 0,
        view_count: parsedData.view_count || 0,
        publish_time: parsedData.publish_time ? new Date(parsedData.publish_time) : null,
        tags: parsedData.tags ? JSON.stringify(parsedData.tags) : null,
        created_at: new Date()
      });
      
      // Save to database
      await contentRepository.save(content);

      // 清除内容列表缓存
      CacheService.flush();

      // Prepare response message
      let message = '内容保存成功';
      if (downloadResult.success) {
        message += `，共下载${downloadResult.successfulFiles}个文件`;
        if (downloadResult.totalFiles > downloadResult.successfulFiles) {
          message += `（${downloadResult.totalFiles - downloadResult.successfulFiles}个文件下载失败）`;
        }
      } else if (downloadResult.error) {
        message += `，但文件下载失败: ${downloadResult.error}`;
      } else if (downloadResult.message) {
        message += `，${downloadResult.message}`;
      }
      
      res.status(201).json({
        message,
        data: {
          ...content,
          all_images: parsedData.all_images || [],
          all_videos: parsedData.all_videos || [],
          downloadResult: {
            success: downloadResult.success,
            contentDir: downloadResult.contentDir,
            downloadedFiles: downloadResult.downloadedFiles?.length || 0,
            totalFiles: downloadResult.totalFiles || 0,
            successfulFiles: downloadResult.successfulFiles || 0
          }
        }
      });
    } catch (error) {
      console.error('Save content error:', error);
      res.status(500).json({ message: `保存失败: ${error.message}` });
    }
  }

  // 访问本地媒体文件（封面、图片、视频等）
  static async getLocalMedia(req, res) {
    try {
      const { id } = req.params;
      const { type = 'cover', index } = req.query; // type: cover, image, video

      // 获取内容记录
      const contentRepository = AppDataSource.getRepository('Content');
      const content = await contentRepository.findOne({ where: { id } });

      if (!content) {
        return res.status(404).json({ message: '内容不存在' });
      }

      // 使用数据库中的完整路径（已经包含完整路径信息）
      const contentDir = content.file_path;

      // 尝试读取 metadata.json
      const metadataPath = path.join(contentDir, 'metadata.json');
      let metadata = null;

      try {
        const metadataContent = await fs.readFile(metadataPath, 'utf-8');
        metadata = JSON.parse(metadataContent);
      } catch (err) {
        console.error('读取 metadata.json 失败:', err.message);
      }

      let localFilePath = null;
      let contentType = 'image/jpeg'; // 默认内容类型

      if (metadata && metadata.downloaded_files && metadata.downloaded_files.length > 0) {
        // 从 metadata 中查找对应的本地文件
        if (type === 'cover') {
          // 优先查找 type='cover' 的文件
          const coverFile = metadata.downloaded_files.find(f => f.type === 'cover');
          if (coverFile && coverFile.filePath && await fs.pathExists(coverFile.filePath)) {
            localFilePath = coverFile.filePath;
          } else {
            // 如果没有 cover.jpg，尝试使用第一张图片 (image_1, index=1) 作为主封面
            const firstImageFile = metadata.downloaded_files.find(f => f.type === 'image' && f.index === 1);
            if (firstImageFile && firstImageFile.filePath && await fs.pathExists(firstImageFile.filePath)) {
              localFilePath = firstImageFile.filePath;
            } else {
              // 如果第一张图片不存在，尝试查找任何可用的图片
              const anyImageFile = metadata.downloaded_files.find(f => f.type === 'image');
              if (anyImageFile && anyImageFile.filePath) {
                localFilePath = anyImageFile.filePath;
              }
            }
          }
        } else if (type === 'image' && index !== undefined) {
          const imageFile = metadata.downloaded_files.find(
            f => f.type === 'image' && f.index === parseInt(index)
          );
          if (imageFile && imageFile.filePath) {
            localFilePath = imageFile.filePath;
          }
        } else if (type === 'video' && index !== undefined) {
          const videoFile = metadata.downloaded_files.find(
            f => f.type === 'video' && f.index === parseInt(index)
          );
          if (videoFile && videoFile.filePath) {
            localFilePath = videoFile.filePath;
            contentType = 'video/mp4';
          }
        }
      }

      // 如果没有找到 metadata 中的文件，使用传统文件名规则
      if (!localFilePath) {
        if (type === 'cover') {
          // cover.jpg 已被全局删除，使用 image_1.jpg
          localFilePath = path.join(contentDir, 'image_1.jpg');
        } else if (type === 'image' && index !== undefined) {
          localFilePath = path.join(contentDir, `image_${index}.jpg`);
        } else if (type === 'video' && index !== undefined) {
          localFilePath = path.join(contentDir, `video_${index}.mp4`);
          contentType = 'video/mp4';
        }
      }

      // 检查文件是否存在
      if (!localFilePath || !await fs.pathExists(localFilePath)) {
        console.log('本地文件不存在，返回占位图:', localFilePath);
        // 返回 SVG 占位图
        const svgPlaceholder = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="#f0f0f0"/><text x="75" y="75" font-size="12" text-anchor="middle" fill="#999">暂无本地图片</text></svg>`;
        res.setHeader('Content-Type', 'image/svg+xml');
        res.setHeader('Cache-Control', 'public, max-age=3600');
        return res.send(svgPlaceholder);
      }

      // 根据文件扩展名确定 Content-Type
      const ext = path.extname(localFilePath).toLowerCase();
      if (ext === '.png') {
        contentType = 'image/png';
      } else if (ext === '.gif') {
        contentType = 'image/gif';
      } else if (ext === '.webp') {
        contentType = 'image/webp';
      } else if (ext === '.mp4') {
        contentType = 'video/mp4';
      } else if (ext === '.mov') {
        contentType = 'video/quicktime';
      }

      // 获取文件统计信息用于缓存控制
      const stats = fs.statSync(localFilePath);
      const etag = `"${stats.mtime.getTime()}"`;
      const lastModified = stats.mtime.toUTCString();

      // 检查客户端的If-None-Match或If-Modified-Since头
      const clientETag = req.get('If-None-Match');
      const clientLastModified = req.get('If-Modified-Since');

      // 如果客户端缓存仍然有效，返回304
      if ((clientETag && clientETag === etag) ||
          (clientLastModified && new Date(clientLastModified) >= stats.mtime)) {
        return res.status(304).end();
      }

      // 设置缓存头并返回文件
      res.setHeader('Content-Type', contentType);
      res.setHeader('Cache-Control', 'public, max-age=3600, must-revalidate'); // 缓存1小时，必须重新验证
      res.setHeader('Last-Modified', lastModified);
      res.setHeader('ETag', etag);
      res.setHeader('Access-Control-Allow-Origin', '*'); // 允许所有来源访问
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.sendFile(localFilePath, (err) => {
        if (err) {
          console.error('发送本地文件错误:', err);
          if (!res.headersSent) {
            res.status(500).json({ message: '文件读取失败' });
          }
        }
      });

    } catch (error) {
      console.error('获取本地媒体文件错误:', error);
      if (!res.headersSent) {
        res.status(500).json({ message: '获取本地文件失败' });
      }
    }
  }
}

module.exports = ContentController;
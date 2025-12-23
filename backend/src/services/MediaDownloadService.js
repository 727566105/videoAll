const fs = require('fs-extra');
const path = require('path');
const axios = require('axios');
const crypto = require('crypto');

class MediaDownloadService {
  /**
   * 下载并保存内容到本地文件系统
   * @param {Object} parsedData - 解析后的内容数据
   * @param {string} platform - 平台名称
   * @param {string} link - 原始链接
   * @returns {Object} 下载结果
   */
  static async downloadAndSaveContent(parsedData, platform, link) {
    try {
      console.log('开始下载内容:', parsedData.title);
      
      // 创建安全的文件夹名称（移除特殊字符）
      const safeTitle = this.sanitizeFileName(parsedData.title || 'untitled');
      const contentId = parsedData.content_id || this.generateContentId();
      const folderName = `${safeTitle}_${contentId}`;
      
      // 创建目录结构: ./media/platform/folderName/
      const mediaDir = path.join(process.cwd(), 'media');
      const platformDir = path.join(mediaDir, platform);
      const contentDir = path.join(platformDir, folderName);
      
      // 确保目录存在
      await fs.ensureDir(contentDir);
      
      console.log('创建内容目录:', contentDir);
      
      // 准备下载的文件列表
      const downloadTasks = [];
      const downloadedFiles = [];
      
      // 下载封面图片
      if (parsedData.cover_url) {
        downloadTasks.push({
          url: parsedData.cover_url,
          type: 'cover',
          filename: 'cover'
        });
      }
      
      // 下载所有图片
      if (parsedData.all_images && parsedData.all_images.length > 0) {
        parsedData.all_images.forEach((imageUrl, index) => {
          downloadTasks.push({
            url: imageUrl,
            type: 'image',
            filename: `image_${index + 1}`,
            index: index + 1
          });
        });
      }
      
      // 下载所有视频
      if (parsedData.all_videos && parsedData.all_videos.length > 0) {
        parsedData.all_videos.forEach((videoUrl, index) => {
          downloadTasks.push({
            url: videoUrl,
            type: 'video',
            filename: `video_${index + 1}`,
            index: index + 1
          });
        });
      }
      
      // 如果没有媒体文件，至少尝试下载media_url
      if (downloadTasks.length === 0 && parsedData.media_url) {
        downloadTasks.push({
          url: parsedData.media_url,
          type: parsedData.media_type || 'media',
          filename: 'media'
        });
      }
      
      console.log(`准备下载 ${downloadTasks.length} 个文件`);
      
      // 并发下载所有文件
      const downloadPromises = downloadTasks.map(task => 
        this.downloadFile(task.url, contentDir, task.filename, task.type)
          .then(result => {
            if (result.success) {
              downloadedFiles.push({
                ...result,
                type: task.type,
                index: task.index,
                originalUrl: task.url
              });
            }
            return result;
          })
          .catch(error => {
            console.error(`下载文件失败 ${task.url}:`, error.message);
            return { success: false, error: error.message, url: task.url };
          })
      );
      
      const downloadResults = await Promise.all(downloadPromises);
      const successfulDownloads = downloadResults.filter(result => result.success);
      
      console.log(`成功下载 ${successfulDownloads.length}/${downloadTasks.length} 个文件`);
      
      // 创建元数据JSON文件
      const metadata = {
        title: parsedData.title,
        author: parsedData.author,
        platform: platform,
        content_id: contentId,
        description: parsedData.description,
        media_type: parsedData.media_type,
        source_url: link,
        cover_url: parsedData.cover_url,
        all_images: parsedData.all_images || [],
        all_videos: parsedData.all_videos || [],
        has_live_photo: parsedData.has_live_photo,
        like_count: parsedData.like_count,
        comment_count: parsedData.comment_count,
        share_count: parsedData.share_count,
        tags: parsedData.tags || [],
        publish_time: parsedData.publish_time,
        downloaded_files: downloadedFiles,
        download_time: new Date().toISOString(),
        folder_path: contentDir
      };
      
      // 保存元数据JSON文件
      const metadataPath = path.join(contentDir, 'metadata.json');
      await fs.writeJson(metadataPath, metadata, { spaces: 2 });
      
      console.log('元数据已保存:', metadataPath);
      
      return {
        success: true,
        contentDir,
        folderName,
        downloadedFiles: successfulDownloads,
        totalFiles: downloadTasks.length,
        successfulFiles: successfulDownloads.length,
        metadataPath,
        metadata
      };
      
    } catch (error) {
      console.error('下载内容失败:', error);
      throw error;
    }
  }
  
  /**
   * 下载单个文件
   * @param {string} url - 文件URL
   * @param {string} dir - 保存目录
   * @param {string} filename - 文件名（不含扩展名）
   * @param {string} type - 文件类型
   * @returns {Object} 下载结果
   */
  static async downloadFile(url, dir, filename, type) {
    try {
      console.log(`开始下载文件: ${filename} from ${url}`);
      
      // 设置请求头，模拟浏览器请求
      const headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.xiaohongshu.com/',
        'Accept': 'image/webp,image/apng,image/svg+xml,image/*,video/*,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Sec-Fetch-Dest': type === 'video' ? 'video' : 'image',
        'Sec-Fetch-Mode': 'no-cors',
        'Sec-Fetch-Site': 'cross-site'
      };
      
      // 发送请求
      const response = await axios.get(url, {
        responseType: 'stream',
        headers,
        timeout: 30000, // 30秒超时
        maxRedirects: 5
      });
      
      // 从响应头获取内容类型
      const contentType = response.headers['content-type'] || '';
      
      // 确定文件扩展名
      let extension = this.getFileExtension(contentType, url);
      
      // 如果无法确定扩展名，根据类型设置默认扩展名
      if (!extension) {
        if (type === 'video') {
          extension = '.mp4';
        } else if (type === 'image' || type === 'cover') {
          extension = '.jpg';
        } else {
          extension = '.bin';
        }
      }
      
      // 构建完整文件路径
      const filePath = path.join(dir, `${filename}${extension}`);
      
      // 创建写入流
      const writer = fs.createWriteStream(filePath);
      
      // 将响应流写入文件
      response.data.pipe(writer);
      
      // 等待写入完成
      await new Promise((resolve, reject) => {
        writer.on('finish', resolve);
        writer.on('error', reject);
        response.data.on('error', reject);
      });
      
      // 获取文件大小
      const stats = await fs.stat(filePath);
      const fileSize = stats.size;
      
      console.log(`文件下载完成: ${filename}${extension} (${fileSize} bytes)`);
      
      return {
        success: true,
        filename: `${filename}${extension}`,
        filePath,
        fileSize,
        contentType,
        extension
      };
      
    } catch (error) {
      console.error(`下载文件失败 ${filename}:`, error.message);
      return {
        success: false,
        error: error.message,
        filename,
        url
      };
    }
  }
  
  /**
   * 根据内容类型和URL确定文件扩展名
   * @param {string} contentType - 内容类型
   * @param {string} url - 文件URL
   * @returns {string} 文件扩展名
   */
  static getFileExtension(contentType, url) {
    // 首先尝试从内容类型获取扩展名
    if (contentType) {
      const typeMap = {
        'image/jpeg': '.jpg',
        'image/jpg': '.jpg',
        'image/png': '.png',
        'image/gif': '.gif',
        'image/webp': '.webp',
        'video/mp4': '.mp4',
        'video/mov': '.mov',
        'video/avi': '.avi',
        'video/mkv': '.mkv',
        'video/webm': '.webm'
      };
      
      const extension = typeMap[contentType.toLowerCase()];
      if (extension) {
        return extension;
      }
    }
    
    // 如果内容类型无法确定，尝试从URL获取扩展名
    try {
      const urlPath = new URL(url).pathname;
      const match = urlPath.match(/\.([a-zA-Z0-9]+)(?:\?|$)/);
      if (match) {
        return `.${match[1].toLowerCase()}`;
      }
    } catch (error) {
      // URL解析失败，忽略
    }
    
    return null;
  }
  
  /**
   * 清理文件名，移除不安全的字符
   * @param {string} filename - 原始文件名
   * @returns {string} 安全的文件名
   */
  static sanitizeFileName(filename) {
    if (!filename) return 'untitled';
    
    // 移除或替换不安全的字符
    return filename
      .replace(/[<>:"/\\|?*]/g, '_') // 替换Windows不允许的字符
      .replace(/[\x00-\x1f\x80-\x9f]/g, '') // 移除控制字符
      .replace(/^\.+/, '') // 移除开头的点
      .replace(/\.+$/, '') // 移除结尾的点
      .replace(/\s+/g, '_') // 替换空格为下划线
      .substring(0, 100); // 限制长度
  }
  
  /**
   * 生成内容ID
   * @returns {string} 内容ID
   */
  static generateContentId() {
    return crypto.randomBytes(8).toString('hex');
  }
  
  /**
   * 检查文件是否已存在
   * @param {string} platform - 平台名称
   * @param {string} contentId - 内容ID
   * @returns {boolean} 是否存在
   */
  static async checkContentExists(platform, contentId) {
    try {
      const mediaDir = path.join(process.cwd(), 'media');
      const platformDir = path.join(mediaDir, platform);
      
      if (!await fs.pathExists(platformDir)) {
        return false;
      }
      
      // 查找包含contentId的文件夹
      const folders = await fs.readdir(platformDir);
      return folders.some(folder => folder.includes(contentId));
      
    } catch (error) {
      console.error('检查内容是否存在失败:', error);
      return false;
    }
  }
  
  /**
   * 获取内容文件夹路径
   * @param {string} platform - 平台名称
   * @param {string} title - 标题
   * @param {string} contentId - 内容ID
   * @returns {string} 文件夹路径
   */
  static getContentPath(platform, title, contentId) {
    const safeTitle = this.sanitizeFileName(title || 'untitled');
    const folderName = `${safeTitle}_${contentId}`;
    return path.join(process.cwd(), 'media', platform, folderName);
  }
}

module.exports = MediaDownloadService;
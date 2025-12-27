const path = require('path');
const { exec } = require('child_process');
const { AppDataSource } = require('../utils/db');
const storageService = require('./StorageService');
const EncryptionService = require('../utils/encryption');

class ParseService {
  // Python SDK包装器路径
  static SDK_WRAPPER_PATH = path.join(__dirname, '../../../media_parser_sdk/wrapper.py');

  // 获取平台Cookie
  static async getPlatformCookie(platform) {
    try {
      const platformCookieRepository = AppDataSource.getRepository('PlatformCookie');

      // 查找该平台最新且有效的Cookie
      const cookieRecord = await platformCookieRepository.findOne({
        where: {
          platform: platform,
          is_valid: true
        },
        order: {
          last_checked_at: 'DESC'
        }
      });

      if (cookieRecord) {
        // 解密Cookie
        const cookie = EncryptionService.decrypt(cookieRecord.cookies_encrypted);
        console.log(`✓ 使用${platform}平台Cookie (账户: ${cookieRecord.account_alias})`);
        return cookie;
      } else {
        console.log(`⚠ 未找到${platform}平台的有效Cookie，将使用无Cookie模式`);
        return null;
      }
    } catch (error) {
      console.warn(`Cookie获取失败: ${error.message}`);
      return null;
    }
  }

  // Parse link from different platforms using Python SDK
  static async parseLink(link) {
    try {
      // 检测平台并选择合适的SDK命令
      let sdkCommand = ['parse', link];

      // 对小红书使用增强解析器
      if (link.includes('xiaohongshu.com') || link.includes('xhslink.com')) {
        sdkCommand = ['xiaohongshu_note', link];

        // 可选：为小红书添加Cookie支持
        const cookie = await this.getPlatformCookie('xiaohongshu');
        if (cookie) {
          sdkCommand.push('--cookie', cookie);
        }
      }

      // 对抖音使用增强解析器
      else if (link.includes('douyin.com') || link.includes('tiktok.com') || link.includes('iesdouyin.com')) {
        sdkCommand = ['douyin_video', link];

        // 自动获取并添加Cookie（提高成功率到80-95%）
        const cookie = await this.getPlatformCookie('douyin');
        if (cookie) {
          sdkCommand.push('--cookie', cookie);
        }
      }

      // 对哔哩哔哩使用增强解析器
      else if (link.includes('bilibili.com') || link.includes('b23.tv')) {
        sdkCommand = ['bilibili_video', link];

        // 自动获取并添加Cookie（提高解析成功率）
        const cookie = await this.getPlatformCookie('bilibili');
        if (cookie) {
          sdkCommand.push('--cookie', cookie);
        }

        // 从平台Cookie配置中读取用户偏好画质
        const preferredQuality = await this.getPreferredQuality('bilibili');
        sdkCommand.push('--quality', preferredQuality);
        console.log(`使用偏好画质: ${preferredQuality}`);
      }
      
      // 使用Python SDK解析链接
      const sdkResult = await this.executePythonSDK(sdkCommand);
      
      // 检查解析结果是否包含错误
      if (sdkResult.error) {
        throw new Error(sdkResult.error);
      }
      
      // 映射SDK结果到现有数据格式
      const parsedData = this.mapSdkResultToExistingFormat(sdkResult, link);
      
      return parsedData;
    } catch (error) {
      console.error('Parse link error:', error);
      throw error;
    }
  }

  // 执行Python SDK包装器
  static executePythonSDK(args) {
    return new Promise((resolve, reject) => {
      // 正确地引用URL参数，防止Shell注入和参数分割问题
      const command = `python3 ${this.SDK_WRAPPER_PATH} ${args.map(arg => {
        // 如果参数包含特殊Shell字符，用引号包裹
        if (arg.includes('&') || arg.includes('|') || arg.includes('>') || arg.includes('<') || arg.includes(' ')) {
          return `"${arg.replace(/"/g, '\\"')}"`;
        }
        return arg;
      }).join(' ')}`;
      console.log(`执行SDK命令: ${command}`);

      exec(command, { encoding: 'utf8', maxBuffer: 1024 * 1024 * 10, timeout: 120000 }, (error, stdout, stderr) => {
        if (error) {
          console.error('SDK执行错误:', stderr || error.message);
          reject(new Error(stderr || error.message));
          return;
        }

        try {
          const result = JSON.parse(stdout);
          resolve(result);
        } catch (parseError) {
          console.error('JSON解析失败:', stdout);
          reject(new Error(`JSON解析失败: ${stdout}`));
        }
      });
    });
  }

  // 映射SDK结果到现有格式
  static mapSdkResultToExistingFormat(sdkResult, originalLink) {
    // 处理增强解析器的响应格式
    let actualResult = sdkResult;
    if (sdkResult.success && sdkResult.data) {
      // 这是增强解析器的响应格式，使用sdkResult.data
      actualResult = sdkResult.data;

      // 转换videos数组格式
      if (actualResult.videos && Array.isArray(actualResult.videos)) {
        actualResult.download_urls = actualResult.download_urls || {};
        actualResult.download_urls.video = actualResult.videos.map(v => v.url);
      }

      // 转换images数组格式
      if (actualResult.images && Array.isArray(actualResult.images)) {
        actualResult.download_urls = actualResult.download_urls || {};
        actualResult.download_urls.images = actualResult.images.map(i => i.url);
      }

      // 映射其他字段
      // 保留原始平台标识
      if (!actualResult.platform || actualResult.platform === 'unknown') {
        actualResult.platform = 'xiaohongshu';
      }

      actualResult.author = actualResult.author?.nickname || actualResult.author || '未知作者';

      // 小红书特有的字段映射
      if (actualResult.platform === 'xiaohongshu') {
        actualResult.like_count = actualResult.interaction_stats?.like_count;
        actualResult.comment_count = actualResult.interaction_stats?.comment_count;
        actualResult.share_count = actualResult.interaction_stats?.share_count;
      }
      // 抖音字段已在SDK中处理，这里不需要额外映射

      // 哔哩哔哩特有的字段映射
      if (actualResult.platform === 'bilibili') {
        actualResult.danmaku_count = actualResult.danmaku_count || 0;  // 弹幕数
        actualResult.coin_count = actualResult.coin_count || 0;        // 投币数
        // duration字段已在SDK中处理（视频时长，单位：秒）
      }

      // 修复描述字段：增强解析器使用 'content' 字段
      if (actualResult.content !== undefined) {
        actualResult.description = actualResult.content;
      }
    }
    
    // 平台映射
    const platformMap = {
      'xiaohongshu': 'xiaohongshu',
      'douyin': 'douyin',
      'weibo': 'weibo',
      'bilibili': 'bilibili',
      'unknown': 'unknown'
    };
    
    const platform = platformMap[actualResult.platform] || 'unknown';
    const mediaType = actualResult.media_type || 'unknown';
    
    // 生成文件路径
    const cleanedAuthor = this.cleanFilename(actualResult.author || 'unknown');
    const cleanedTitle = this.cleanFilename(actualResult.title || 'untitled');
    const fileExt = mediaType === 'video' ? 'mp4' : 'jpg';
    const contentId = actualResult.note_id || `sdk_${Date.now()}`;
    const filePath = path.join(platform, cleanedAuthor, `${contentId}.${fileExt}`);
    
    // 确定主要媒体URL和所有媒体URL
    let mediaUrl = '';
    let allImages = [];
    let allVideos = [];
    let allLivePhotos = []; // 实况图片数组

    if (actualResult.download_urls) {
      // 提取所有视频URL
      allVideos = actualResult.download_urls.video || [];

      // 特殊处理：实况图片的 videos 应该映射为 live_photos
      if (mediaType === 'live_photo' && allVideos.length > 0) {
        // 当媒体类型是实况图片时，videos 实际上是实况图片的视频
        allLivePhotos = allVideos;
        allVideos = []; // 清空普通视频数组
      }

      // 视频URL优先作为主媒体URL
      if (allVideos.length > 0) {
        mediaUrl = allVideos[0];
      }

      // 图片URL处理，包括普通图片和实况图片
      allImages = [...(actualResult.download_urls.images || []), ...(actualResult.download_urls.live || [])];

      // 如果没有视频，使用图片作为主媒体URL
      if (!mediaUrl && allImages.length > 0) {
        mediaUrl = allImages[0];
      }
    }

    // 去重处理 - 防止SDK返回重复的URL
    allVideos = this.deduplicateUrls(allVideos);
    allImages = this.deduplicateUrls(allImages);
    
    // 封面URL处理
    let coverUrl = actualResult.cover_url || '';
    if (!coverUrl && allImages.length > 0) {
      coverUrl = allImages[0];
    }
    
    return {
      platform,
      content_id: contentId,
      title: actualResult.title || '未知标题',
      author: actualResult.author || '未知作者',
      description: actualResult.description || '',
      media_type: mediaType,
      cover_url: coverUrl,
      media_url: mediaUrl, // 主要媒体URL
      all_images: allImages, // 所有图片URL
      all_videos: allVideos, // 所有视频URL - 新增字段
      all_live_photos: allLivePhotos, // 实况图片URL - 新增字段
      file_path: filePath, // 生成的文件路径
      source_url: originalLink,
      source_type: 1, // 1-单链接解析
      created_at: new Date(),
      // SDK扩展字段
      tags: actualResult.tags || [],
      like_count: actualResult.like_count,
      collect_count: actualResult.collect_count,
      comment_count: actualResult.comment_count,
      share_count: actualResult.share_count,
      view_count: actualResult.view_count,
      has_live_photo: actualResult.has_live_photo || allLivePhotos.length > 0, // 如果有实况图片URL，也标记为有实况
      publish_time: actualResult.publish_time ? new Date(actualResult.publish_time) : null,
      // 哔哩哔哩特有字段
      danmaku_count: actualResult.danmaku_count,
      coin_count: actualResult.coin_count,
      duration: actualResult.duration
    };
  }

  // 清理文件名，移除特殊字符
  static cleanFilename(filename) {
    return filename.replace(/[\\/:*?"<>|]/g, '_').substring(0, 50);
  }

  // URL去重 - 使用文件标识符进行比较，支持小红书主备服务器去重
  static deduplicateUrls(urlList) {
    if (!Array.isArray(urlList)) return [];

    const seen = new Set();
    const result = [];

    for (const url of urlList) {
      if (!url || typeof url !== 'string') continue;

      // 提取文件标识符（URL路径中的文件名部分）
      // 例如：从 http://sns-video-hs.xhscdn.com/stream/1/110/258/01e94ce73c1d5de3010370019b546c3462_258.mp4
      // 提取：01e94ce73c1d5de3010370019b546c3462_258.mp4
      let fileIdentifier = null;
      try {
        const urlPath = new URL(url).pathname;
        // 获取路径的最后一部分（文件名）
        const fileName = urlPath.split('/').pop();
        if (fileName) {
          fileIdentifier = fileName;
        }
      } catch (e) {
        // URL解析失败，使用完整URL作为标识符
        const baseUrl = url.split('?')[0].split('#')[0];
        fileIdentifier = baseUrl;
      }

      if (fileIdentifier && !seen.has(fileIdentifier)) {
        seen.add(fileIdentifier);
        result.push(url);
      } else if (fileIdentifier) {
        console.log(`去除重复URL (文件标识符: ${fileIdentifier}): ${url}`);
      }
    }

    return result;
  }

  // Detect platform from URL (保持API兼容性)
  static detectPlatform(url) {
    if (url.includes('douyin.com') || url.includes('tiktok.com')) {
      return 'douyin';
    } else if (url.includes('xiaohongshu.com') || url.includes('xhslink.com')) {
      return 'xiaohongshu';
    } else if (url.includes('kuaishou.com')) {
      return 'kuaishou';
    } else if (url.includes('bilibili.com') || url.includes('b23.tv')) {
      return 'bilibili';
    } else if (url.includes('weibo.com')) {
      return 'weibo';
    }
    return null;
  }

  // 下载所有媒体文件 (保持API兼容性)
  static async downloadAllMedia(parsedData, platform, sourceType = 1, taskId = null) {
    try {
      console.log('处理媒体文件信息:', parsedData.content_id);
      
      // 不实际下载文件，只返回文件信息用于数据库保存
      // 实际的文件下载由前端的代理服务处理
      
      const allImages = parsedData.all_images || [];
      const hasLivePhoto = parsedData.has_live_photo || false;
      
      // 构建返回结果
      return {
        mainImagePath: parsedData.file_path || `${platform}/${parsedData.content_id || Date.now()}.jpg`,
        downloadedFiles: allImages.map((url, index) => ({
          originalUrl: url,
          watermarkFreeUrl: url, // SDK已处理水印
          filePath: `${platform}/${parsedData.content_id || Date.now()}_${index + 1}.jpg`,
          isLivePhoto: hasLivePhoto,
          index: index
        })),
        totalFiles: allImages.length || 1,
        hasLivePhoto: hasLivePhoto
      };
    } catch (error) {
      console.error('处理媒体文件信息失败:', error);
      throw error;
    }
  }

  /**
   * 获取平台的偏好画质设置
   * @param {string} platform - 平台名称（如 'bilibili'）
   * @returns {Promise<string>} 偏好画质（如 '1080P'、'4K'）
   */
  static async getPreferredQuality(platform) {
    try {
      const { AppDataSource } = require('../utils/db');
      const PlatformCookie = AppDataSource.getRepository('PlatformCookie');

      // 查找该平台最新的有效Cookie配置
      const config = await PlatformCookie.findOne({
        where: { platform, is_valid: true },
        order: { created_at: 'DESC' }
      });

      // 如果配置中有偏好画质，返回它
      if (config?.preferences?.[platform]?.preferred_quality) {
        return config.preferences[platform].preferred_quality;
      }

      // 默认返回1080P
      return '1080P';
    } catch (error) {
      console.error('获取偏好画质失败:', error);
      return '1080P';
    }
  }
}

module.exports = ParseService;
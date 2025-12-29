import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import JSZip from 'jszip';
import { Form, Input, Button, Card, Typography, Space, Progress, Modal, Image, App } from 'antd';
import { FileSearchOutlined, DownloadOutlined, FileTextOutlined, EyeOutlined, SettingOutlined } from '@ant-design/icons';
import apiService from '../services/api';
import { getPlatformColor } from '../utils/themeColors';

const { Title } = Typography;

const ContentParsing = () => {
  const location = useLocation();
  const { token, message } = App.useApp();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [parsedResult, setParsedResult] = useState(null);
  const [processingStatus, setProcessingStatus] = useState(null); // null, 'processing', 'completed', 'failed'
  const [progress, setProgress] = useState(0); // Progress percentage
  const [downloadProgress, setDownloadProgress] = useState(null); // Download progress
  const [downloadStatus, setDownloadStatus] = useState(null); // Download status: null, 'downloading', 'completed', 'failed'
  
  // Image preview modal states
  const [previewVisible, setPreviewVisible] = useState(false);
  const [previewImage, setPreviewImage] = useState('');
  const [previewTitle, setPreviewTitle] = useState('');

  // 处理从热搜页面传递过来的URL
  useEffect(() => {
    if (location.state && location.state.url) {
      form.setFieldsValue({ link: location.state.url });
      message.info('已从热搜页面填入链接，请点击"解析"按钮开始解析');
    }
  }, [location.state, form]);

  // Handle image preview
  const handlePreview = (imageUrl, index) => {
    setPreviewImage(getProxyImageUrl(imageUrl));
    setPreviewTitle(`图片 ${index + 1}`);
    setPreviewVisible(true);
  };

  // Close image preview
  const handlePreviewCancel = () => {
    setPreviewVisible(false);
    setPreviewImage('');
    setPreviewTitle('');
  };

  // Helper function to get proxy image URL
  const getProxyImageUrl = (imageUrl) => {
    if (!imageUrl) {
      console.log('getProxyImageUrl: No image URL provided, returning placeholder');
      return 'https://via.placeholder.com/300x200?text=图片加载失败';
    }
    
    try {
      // Use relative path for proxy requests to avoid baseURL issues
      const proxyUrl = `/api/v1/content/proxy-image?url=${encodeURIComponent(imageUrl)}`;
      console.log('getProxyImageUrl:', { originalUrl: imageUrl, proxyUrl });
      return proxyUrl;
    } catch (error) {
      console.error('Error generating proxy image URL:', error, { imageUrl });
      return 'https://via.placeholder.com/300x200?text=图片加载失败';
    }
  };
  
  // Helper function to get proxy video URL
  const getProxyVideoUrl = (videoUrl) => {
    if (!videoUrl) {
      console.log('getProxyVideoUrl: No video URL provided');
      return '';
    }
    
    try {
      // Check if video URL is already a local path
      if (videoUrl.startsWith('/media/')) {
        console.log('getProxyVideoUrl: Using local video path:', videoUrl);
        return videoUrl;
      }
      
      // Use relative path for proxy requests to avoid baseURL issues
      const proxyUrl = `/api/v1/content/proxy-download?url=${encodeURIComponent(videoUrl)}`;
      console.log('getProxyVideoUrl:', { originalUrl: videoUrl, proxyUrl });
      return proxyUrl;
    } catch (error) {
      console.error('Error generating proxy video URL:', error, { videoUrl });
      return '';
    }
  };

  // Helper function to handle image load errors
  const handleImageError = (e) => {
    console.error('Image load error:', {
      src: e.target.src,
      alt: e.target.alt,
      naturalWidth: e.target.naturalWidth,
      naturalHeight: e.target.naturalHeight
    });
    
    // Get current retry count from dataset, default to 0 if not exists
    let retryCount = parseInt(e.target.dataset.retryCount || '0', 10);
    const maxRetries = 2; // Maximum retry attempts
    
    if (retryCount < maxRetries) {
      // Increment retry count and store back in dataset
      retryCount++;
      e.target.dataset.retryCount = retryCount;
      
      console.log(`Image retry ${retryCount}/${maxRetries}:`, e.target.src);
      
      // Implement exponential backoff - wait 500ms * retryCount before retrying
      setTimeout(() => {
        // Append a cache busting parameter to force a fresh request
        const url = new URL(e.target.src);
        url.searchParams.set('_retry', retryCount);
        url.searchParams.set('_timestamp', Date.now());
        e.target.src = url.toString();
      }, 500 * retryCount);
    } else {
      console.log(`Max retries reached for image:`, e.target.src);
      // If max retries reached, show placeholder
      e.target.src = 'https://via.placeholder.com/300x200?text=图片加载失败';
    }
  };

  // Helper function to download a single file using backend proxy
  const downloadFile = async (url, filename) => {
    try {
      // Validate URL
      if (!url || typeof url !== 'string') {
        throw new Error('无效的下载URL');
      }
      
      // Sanitize filename to ensure it's not a hidden file
      let sanitizedFilename = filename || 'download_file';
      sanitizedFilename = sanitizedFilename.trim();
      
      // If the filename starts with a dot, add a prefix to make it visible
      if (sanitizedFilename.startsWith('.')) {
        sanitizedFilename = `file_${sanitizedFilename.substring(1)}`;
      }
      
      // Replace invalid characters in filename
      sanitizedFilename = sanitizedFilename.replace(/[<>:"/\\|?*]/g, '_');
      
      // Ensure the filename is not empty after sanitization
      if (!sanitizedFilename || sanitizedFilename === '_') {
        sanitizedFilename = 'download_file';
      }
      
      // Show download progress
      setDownloadProgress(0);
      setDownloadStatus('downloading');
      
      // Create a proxy download URL using backend API with relative path
      const proxyUrl = `/api/v1/content/proxy-download?url=${encodeURIComponent(url)}&filename=${encodeURIComponent(sanitizedFilename)}`;
      
      console.log('Downloading file:', { originalUrl: url, proxyUrl, filename: sanitizedFilename });
      
      // Create a download link and trigger it
      const link = document.createElement('a');
      link.href = proxyUrl;
      link.download = sanitizedFilename;
      document.body.appendChild(link);
      
      // Simulate progress update while waiting for download to start
      const progressInterval = setInterval(() => {
        setDownloadProgress(prev => {
          if (prev < 90) return prev + 5;
          clearInterval(progressInterval);
          return prev;
        });
      }, 1000);
      
      // Trigger download
      link.click();
      
      // Clean up
      document.body.removeChild(link);
      
      // Wait a bit for download to start, then complete progress
      await new Promise(resolve => setTimeout(resolve, 2000));
      clearInterval(progressInterval);
      
      // Complete download
      setDownloadProgress(100);
      setDownloadStatus('completed');
      
      setTimeout(() => {
        setDownloadProgress(null);
        setDownloadStatus(null);
      }, 2000);
      
      message.success('文件下载成功');
      
      return true;
    } catch (error) {
      console.error('Download error:', error, { url, filename });
      setDownloadStatus('failed');
      message.error(`下载失败: ${error.message}`);
      
      setTimeout(() => {
        setDownloadProgress(null);
        setDownloadStatus(null);
      }, 2000);
      
      return false;
    }
  };

  // Handle download of all images
  // Helper function to fetch blob from URL with proxy
  const fetchFileBlob = async (url) => {
    try {
      const proxyUrl = `/api/v1/content/proxy-download?url=${encodeURIComponent(url)}`;
      const response = await fetch(proxyUrl);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.blob();
    } catch (error) {
      console.error('Fetch blob error:', error);
      throw error;
    }
  };

  // Handle download all content
  const handleDownload = async () => {
    if (!parsedResult) {
      message.warning('没有可下载的内容');
      return;
    }
    
    try {
      setDownloadProgress(0);
      setDownloadStatus('downloading');
      message.info('开始下载全部内容...');
      
      // Create JSZip instance
      const zip = new JSZip();
      
      // Sanitize folder name
      let folderName = (parsedResult.title || 'xiaohongshu_content')
        .trim()
        .replace(/[<>:"/\\|?*]/g, '_')
        .replace(/^\./, 'content_'); // Handle hidden files
      
      if (!folderName || folderName === '_') {
        folderName = 'xiaohongshu_content';
      }
      
      // Collect all files to download
      const filesToDownload = [];
      
      // Add all images
      if (parsedResult.all_images && parsedResult.all_images.length > 0) {
        parsedResult.all_images.forEach((imgUrl, index) => {
          filesToDownload.push({
            name: `${folderName}/image_${String(index + 1).padStart(2, '0')}.jpg`,
            url: imgUrl,
            type: 'image'
          });
        });
      }
      
      // Add all videos from all_videos array
      if (parsedResult.all_videos && parsedResult.all_videos.length > 0) {
        parsedResult.all_videos.forEach((videoUrl, index) => {
          filesToDownload.push({
            name: `${folderName}/video_${String(index + 1).padStart(2, '0')}.mp4`,
            url: videoUrl,
            type: 'video'
          });
        });
      }
      
      // Add main media if it's different from all_videos (fallback for single video)
      if (parsedResult.media_type === 'video' && parsedResult.media_url && 
          (!parsedResult.all_videos || parsedResult.all_videos.length === 0)) {
        filesToDownload.push({
          name: `${folderName}/main_video.mp4`,
          url: parsedResult.media_url,
          type: 'video'
        });
      }
      
      // Add Live Photo videos
      if (parsedResult.live_photos && parsedResult.live_photos.length > 0) {
        parsedResult.live_photos.forEach((livePhoto, index) => {
          if (livePhoto.live_video_url) {
            filesToDownload.push({
              name: `${folderName}/live_photo_${String(index + 1).padStart(2, '0')}.mov`,
              url: livePhoto.live_video_url,
              type: 'live_video'
            });
          }
        });
      }
      
      // Create info file
      const infoContent = {
        title: parsedResult.title,
        author: parsedResult.author,
        platform: parsedResult.platform,
        content_id: parsedResult.content_id,
        media_type: parsedResult.media_type,
        source_url: parsedResult.source_url,
        download_date: new Date().toISOString(),
        total_files: filesToDownload.length
      };
      
      zip.file(`${folderName}/info.json`, JSON.stringify(infoContent, null, 2));
      
      // Download all files
      let successCount = 0;
      for (let i = 0; i < filesToDownload.length; i++) {
        const file = filesToDownload[i];
        try {
          const progress = Math.round(((i + 1) / filesToDownload.length) * 90);
          setDownloadProgress(progress);
          
          const blob = await fetchFileBlob(file.url);
          zip.file(file.name, blob);
          successCount++;
          
        } catch (error) {
          console.error(`Failed to download ${file.name}:`, error);
          message.warning(`文件 ${file.name} 下载失败，将跳过`);
        }
      }
      
      // Generate and download zip
      setDownloadProgress(95);
      const zipBlob = await zip.generateAsync({ type: 'blob' });
      
      setDownloadProgress(100);
      const url = URL.createObjectURL(zipBlob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${folderName}.zip`;
      document.body.appendChild(a);
      a.click();
      
      // Cleanup
      setTimeout(() => {
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }, 1000);
      
      setDownloadStatus('completed');
      message.success(`下载完成！成功下载 ${successCount}/${filesToDownload.length} 个文件`);
      
      setTimeout(() => {
        setDownloadProgress(null);
        setDownloadStatus(null);
      }, 3000);
      
    } catch (error) {
      console.error('Download error:', error);
      setDownloadStatus('failed');
      message.error(`下载失败: ${error.message || '未知错误'}`);
      
      setTimeout(() => {
        setDownloadProgress(null);
        setDownloadStatus(null);
      }, 3000);
    }
  };

  // Helper function to extract URLs from mixed text
  const extractUrlsFromText = (text) => {
    if (!text || typeof text !== 'string') return [];

    // 支持多种链接格式的正则表达式
    const patterns = [
      // 标准HTTP/HTTPS链接（支持中文参数和路径）
      /https?:\/\/[^\s\u4e00-\u9fa5\)\]}》】，。！？；：""''`~]+[^\s\)\]}》】，。！？；：""''`~]*/gi,
      // 小红书短链接 xhslink.com
      /https?:\/\/xhslink\.com\/[a-zA-Z0-9]+/gi,
      // 小红书完整链接
      /https?:\/\/[a-z]*\.?xiaohongshu\.com\/[^\s\u4e00-\u9fa5]*/gi,
      // 抖音链接
      /https?:\/\/[a-z]*\.?douyin\.com\/[^\s\u4e00-\u9fa5]*/gi,
    ];

    const urls = new Set();

    patterns.forEach(pattern => {
      const matches = text.match(pattern);
      if (matches) {
        matches.forEach(url => {
          // 清理URL末尾可能的中文标点
          const cleanUrl = url.replace(/[》】，。！？；：""''`~]+$/, '');
          urls.add(cleanUrl);
        });
      }
    });

    return Array.from(urls);
  };

  const handleParse = async (values) => {
    try {
      setLoading(true);
      setProcessingStatus('processing');
      setProgress(10);
      setParsedResult(null);
      let link = values.link;

      console.log('📝 原始输入内容:', link);

      // 检测输入是否包含中文字符（可能是混合文本）
      const hasChinese = /[\u4e00-\u9fa5]/.test(link);
      console.log('🔤 包含中文:', hasChinese);

      // 从混合文本中提取链接
      const extractedUrls = extractUrlsFromText(link);

      if (extractedUrls.length > 0) {
        console.log('🔗 提取到的链接:', extractedUrls);

        // 优先使用小红书链接
        const xiaohongshuUrls = extractedUrls.filter(url =>
          url.includes('xiaohongshu.com') || url.includes('xhslink.com')
        );

        if (xiaohongshuUrls.length > 0) {
          link = xiaohongshuUrls[0];
          console.log('✅ 使用小红书链接:', link);

          if (extractedUrls.length > 1) {
            message.info(`已从文本中提取小红书链接，忽略其他 ${extractedUrls.length - 1} 个链接`);
          }
        } else {
          link = extractedUrls[0];
          console.log('✅ 使用提取的链接:', link);

          if (hasChinese) {
            message.info(`已从文本中提取链接: ${link.substring(0, 50)}...`);
          }
        }
      } else if (hasChinese) {
        console.warn('⚠️ 检测到中文但未找到有效链接');
        message.warning('未在文本中找到有效的链接，请检查输入内容');
        setLoading(false);
        setProcessingStatus('failed');
        return;
      }

      console.log('🎯 最终使用的链接:', link);

      // Check if it's a Xiaohongshu URL
      const isXiaohongshuUrl = link.includes('xiaohongshu.com') || link.includes('xhslink.com');
      
      // Call backend API to parse the link
      const result = await apiService.content.parse({ link });

      console.log('🔍 解析结果完整数据:', JSON.stringify(result, null, 2));

      setProgress(50);

      // 提取视频数据的辅助函数
      const extractVideos = (result) => {
        // 尝试从多个可能的路径获取视频数据
        if (result.all_videos && result.all_videos.length > 0) {
          return result.all_videos;
        }
        if (result.data?.all_videos && result.data.all_videos.length > 0) {
          return result.data.all_videos;
        }
        if (result.data?.videos && Array.isArray(result.data.videos)) {
          return result.data.videos.map(v => v.url || v);
        }
        if (result.download_urls?.video && result.download_urls.video.length > 0) {
          return result.download_urls.video;
        }
        if (result.data?.download_urls?.video && result.data.download_urls.video.length > 0) {
          return result.data.download_urls.video;
        }
        return [];
      };

      // 提取图片数据的辅助函数
      const extractImages = (result) => {
        if (result.all_images && result.all_images.length > 0) {
          return result.all_images;
        }
        if (result.data?.all_images && result.data.all_images.length > 0) {
          return result.data.all_images;
        }
        if (result.data?.images && Array.isArray(result.data.images)) {
          return result.data.images.map(i => i.url || i);
        }
        if (result.download_urls?.images && result.download_urls.images.length > 0) {
          return result.download_urls.images;
        }
        if (result.data?.download_urls?.images && result.data.download_urls.images.length > 0) {
          return result.data.download_urls.images;
        }
        return [];
      };

      const extractedVideos = extractVideos(result);
      const extractedImages = extractImages(result);

      console.log('🎥 提取到的视频:', extractedVideos);
      console.log('📸 提取到的图片:', extractedImages);

      // Set parsed result with data validation and defaults
      const parsedData = {
        title: result.title || result.data?.title || '未知标题',
        author: result.author || result.data?.author || '未知作者',
        platform: result.platform || result.data?.platform || (isXiaohongshuUrl ? 'xiaohongshu' : '未知平台'),
        cover_url: result.cover_url || result.data?.cover_url || 'https://via.placeholder.com/300x200',
        media_type: result.media_type || result.data?.media_type || 'image',
        media_url: result.media_url || result.data?.media_url || 'https://via.placeholder.com/800x600',
        all_images: extractedImages,
        all_videos: extractedVideos,
        has_live_photo: result.has_live_photo || result.data?.has_live_photo || false,
        live_photos: result.live_photos || result.data?.live_photos || [],
        content_id: result.content_id || result.data?.content_id || null,
        source_url: link,
        // 增强功能字段
        like_count: result.like_count || result.data?.like_count || 0,
        comment_count: result.comment_count || result.data?.comment_count || 0,
        collect_count: result.collect_count || result.data?.collect_count || 0,
        share_count: result.share_count || result.data?.share_count || 0,
        tags: result.tags || result.data?.tags || [],
        topics: result.topics || result.data?.topics || [],
        is_original: result.is_original !== false,
        note_type: result.note_type || result.data?.note_type || 'normal',
        enhanced: result.enhanced || false
      };
      
      // 🎥 改进媒体类型检测逻辑
      if (parsedData.all_videos && parsedData.all_videos.length > 0) {
        parsedData.media_type = 'video';
        console.log(`✅ 检测到视频内容，共 ${parsedData.all_videos.length} 个视频`);
      } else if (parsedData.media_url && (
        parsedData.media_url.includes('.mp4') || 
        parsedData.media_url.includes('video') ||
        parsedData.media_url.includes('stream')
      )) {
        parsedData.media_type = 'video';
        console.log('✅ 根据media_url检测到视频内容');
      } else if (parsedData.has_live_photo) {
        parsedData.media_type = 'live_photo';
      }
      
      setProgress(100);
      setParsedResult(parsedData);

      // Automatically save to database and local file system after successful parsing
      try {
        console.log('开始自动保存到内容库...');

        // Call backend API to save content (this will save to both database and local files)
        await apiService.content.save({
          link: link, // Original link for parsing and downloading
          source_type: 1, // 1-单链接解析
          task_id: null
        });

        // 合并后的成功提醒
        message.success('解析成功并已保存到内容管理');
        console.log('自动保存成功');
      } catch (saveError) {
        console.error('Auto save error:', saveError);

        // 区分409（内容已存在）和其他错误
        if (saveError.message && saveError.message.includes('内容已存在')) {
          // 合并后的内容已存在提醒
          message.info('解析成功，内容已存在，无需重复保存');
        } else {
          // 合并后的保存失败提醒
          message.warning(`解析成功，但保存失败：${saveError.message}`);
        }
      }
      
      setProcessingStatus('completed');
      form.resetFields();
    } catch (error) {
      console.error('Parse error:', error);

      // 根据后端返回的 error_type 显示不同的错误提示
      const errorType = error.response?.data?.error_type || 'general';
      const errorMessage = error.response?.data?.message || error.message || '解析失败';

      if (errorType === 'cookie_required') {
        // Cookie 缺失错误 - 显示友好的引导提示
        Modal.error({
          title: '需要配置 Cookie',
          content: (
            <div>
              <p>该链接需要 Cookie 才能访问，请配置后重试。</p>
              <div style={{ marginTop: 16, padding: 12, background: '#f5f5f5', borderRadius: 4 }}>
                <strong>📋 获取 Cookie 方法：</strong>
                <ol style={{ marginTop: 8, paddingLeft: 20 }}>
                  <li>浏览器登录小红书</li>
                  <li>打开开发者工具 (F12)</li>
                  <li>进入 Network 标签</li>
                  <li>刷新页面，找到任意请求</li>
                  <li>复制 Request Headers 中的 Cookie 值</li>
                </ol>
              </div>
              <Button
                type="primary"
                icon={<SettingOutlined />}
                style={{ marginTop: 16 }}
                onClick={() => window.location.href = '/system-config'}
              >
                前往配置 Cookie
              </Button>
            </div>
          ),
          width: 500,
          okText: '我知道了'
        });
      } else {
        // 其他错误 - 显示简短提示
        message.error(`解析失败：${errorMessage}`);
      }

      setProcessingStatus('failed');
      setProgress(0);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Space orientation="vertical" size="large" style={{ width: '100%' }}>
      <Card title="输入链接">
        <Form
          form={form}
          name="parsing"
          onFinish={handleParse}
          layout="horizontal"
        >
          <Form.Item
            name="link"
            rules={[
              {
                required: true,
                message: '请输入作品链接或包含链接的文本!',
                validator: (_, value) => {
                  if (!value || !value.trim()) {
                    return Promise.reject('请输入作品链接或包含链接的文本');
                  }

                  // 检查是否包含链接
                  const hasLink = /https?:\/\/[^\s]+/.test(value);

                  // 如果不包含链接，提示用户
                  if (!hasLink) {
                    return Promise.reject('输入内容中未找到有效链接，请检查后重试');
                  }

                  return Promise.resolve();
                }
              }
            ]}
            style={{ flex: 1, marginRight: 16 }}
            extra={
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 8 }}>
                <span style={{ fontSize: 12, color: token?.colorTextQuaternary }}>
                  💡 提示：可以直接粘贴包含链接的文本，系统会自动提取链接
                </span>
                <Button
                  type="text"
                  icon={<FileTextOutlined />}
                  onClick={async () => {
                    try {
                      const text = await navigator.clipboard.readText();
                      if (text) {
                        form.setFieldsValue({ link: text });
                        message.success('已从剪贴板粘贴内容');
                      } else {
                        message.warning('剪贴板内容为空');
                      }
                    } catch (error) {
                      console.error('剪贴板读取失败:', error);
                      message.error('无法访问剪贴板，请手动粘贴');
                    }
                  }}
                  style={{ color: token?.colorPrimary }}
                  title="粘贴剪贴板内容"
                  size="small"
                >
                  粘贴剪贴板
                </Button>
              </div>
            }
          >
            <Input.TextArea
              placeholder="支持以下输入方式：&#10;1. 直接粘贴链接：http://xhslink.com/xxx&#10;2. 粘贴包含链接的文本：袜子挂好了吗 我要来啰🎅🏻 http://xhslink.com/xxx 复制后打开【小红书】查看笔记！"
              autoSize={{ minRows: 2, maxRows: 6 }}
              style={{ fontSize: 14, padding: '8px 16px' }}
              allowClear
            />
          </Form.Item>
          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              icon={<FileSearchOutlined />}
              loading={loading}
              style={{ fontSize: 16, padding: '0 24px', height: 40 }}
            >
              解析
            </Button>
          </Form.Item>
        </Form>
      </Card>
      
      {/* Processing Status Card */}
      {processingStatus && (
        <Card title={processingStatus === 'processing' ? '解析中' : processingStatus === 'completed' ? '解析成功' : '解析失败'}>
          {processingStatus === 'processing' && (
            <Space orientation="vertical" size="middle" style={{ width: '100%' }}>
              <div>
                <h4>正在解析链接，请稍候...</h4>
              </div>
              <div style={{ width: '100%' }}>
                <div style={{ width: '100%', height: 20, backgroundColor: token?.colorFillQuaternary, borderRadius: 10, overflow: 'hidden' }}>
                  <div 
                    style={{ 
                      width: `${progress}%`, 
                      height: '100%', 
                      backgroundColor: '#1890ff', 
                      borderRadius: 10, 
                      transition: 'width 0.3s ease' 
                    }}
                  ></div>
                </div>
                <div style={{ textAlign: 'center', marginTop: 8, fontSize: 14, color: token?.colorTextTertiary }}>
                  {progress}%
                </div>
              </div>
              <div>
                <p>当前进度：{progress < 30 ? '正在识别平台和链接...' : progress < 60 ? '正在解析作品信息...' : '正在下载媒体文件...'}</p>
              </div>
            </Space>
          )}
          
          {parsedResult && (processingStatus === 'completed' || processingStatus === 'processing') && (
            <Space orientation="vertical" size="middle" style={{ width: '100%' }}>
              <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
                <div>
                  <img 
                    src={getProxyImageUrl(parsedResult.cover_url)} 
                    alt="封面" 
                    style={{ width: 300, height: 200, objectFit: 'cover', borderRadius: 8 }}
                    onError={handleImageError}
                  />
                </div>
                <div style={{ flex: 1, minWidth: 300 }}>
                  <h4>标题：{parsedResult.title}</h4>
                  <p>作者：{parsedResult.author}</p>
                  <p>平台：{parsedResult.platform}</p>
                  <p>类型：{parsedResult.media_type === 'video' ? '视频' : parsedResult.media_type === 'live_photo' ? '实况图片' : '图片'}</p>
                  {parsedResult.all_images && parsedResult.all_images.length > 0 && (
                    <p>图片数量：{parsedResult.all_images.length} 张</p>
                  )}
                  {parsedResult.all_videos && parsedResult.all_videos.length > 0 && (
                    <p style={{ color: token?.colorError, fontWeight: 'bold' }}>🎥 视频数量：{parsedResult.all_videos.length} 个</p>
                  )}
                  {parsedResult.has_live_photo && (
                    <p style={{ color: token?.colorPrimary, fontWeight: 'bold' }}>🎬 包含实况图片</p>
                  )}
                  {parsedResult.enhanced && (
                    <div style={{ marginTop: 12, padding: 8, backgroundColor: `${token?.colorSuccess}10`, border: `1px solid ${token?.colorSuccess}`, borderRadius: 4 }}>
                      <p style={{ color: token?.colorSuccess, fontWeight: 'bold', margin: 0 }}>✨ 增强解析成功</p>
                      <div style={{ fontSize: 12, color: token?.colorTextTertiary, marginTop: 4 }}>
                        {parsedResult.like_count > 0 && <span>👍 {parsedResult.like_count} </span>}
                        {parsedResult.collect_count > 0 && <span>⭐ {parsedResult.collect_count} </span>}
                        {parsedResult.comment_count > 0 && <span>💬 {parsedResult.comment_count} </span>}
                        {parsedResult.share_count > 0 && <span>🔗 {parsedResult.share_count} </span>}
                      </div>
                      {parsedResult.tags && parsedResult.tags.length > 0 && (
                        <div style={{ marginTop: 4 }}>
                          <span style={{ fontSize: 12, color: token?.colorTextTertiary }}>标签：</span>
                          {parsedResult.tags.map((tag, index) => (
                            <span key={index} style={{ fontSize: 12, color: token?.colorPrimary, marginRight: 8 }}>#{tag}</span>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                  <Space size="middle" style={{ marginTop: 16 }}>
                    <Button 
                      type="primary" 
                      icon={<DownloadOutlined />} 
                      onClick={handleDownload}
                      loading={downloadStatus === 'downloading'}
                    >
                      下载全部 ({
                        (parsedResult.all_images ? parsedResult.all_images.length : 0) + 
                        (parsedResult.all_videos ? parsedResult.all_videos.length : 0) + 
                        (parsedResult.media_type === 'video' && parsedResult.media_url && 
                         (!parsedResult.all_videos || parsedResult.all_videos.length === 0) ? 1 : 0) + 
                        (parsedResult.live_photos ? parsedResult.live_photos.filter(p => p.live_video_url).length : 0)
                      }个文件)
                    </Button>
                  </Space>
                </div>
              </div>
              
              {/* Download Progress */}
              {downloadProgress !== null && (
                <div style={{ marginTop: 20, width: '100%' }}>
                  <h4>下载进度</h4>
                  <Progress 
                    percent={downloadProgress} 
                    status={downloadStatus === 'failed' ? 'exception' : downloadStatus === 'completed' ? 'success' : 'active'} 
                    strokeColor={{
                      '0%': token?.colorPrimary,
                      '100%': token?.colorSuccess,
                    }}
                  />
                  <div style={{ textAlign: 'center', marginTop: 8, fontSize: 14, color: token?.colorTextTertiary }}>
                    {downloadStatus === 'downloading' ? '正在下载...' : 
                     downloadStatus === 'completed' ? '下载完成！' : 
                     downloadStatus === 'failed' ? '下载失败！' : ''}
                  </div>
                </div>
              )}
              
              {/* 🎥 视频预览区域 - 优先显示 */}
              {parsedResult.all_videos && parsedResult.all_videos.length > 0 && (
                <div style={{ marginTop: 20, width: '100%' }}>
                  <h4>
                    🎥 视频预览
                    <span style={{ color: token?.colorError, marginLeft: 8, fontSize: 14 }}>
                      共 {parsedResult.all_videos.length} 个视频
                    </span>
                  </h4>

                  {/* 主视频播放器 */}
                  <div style={{ display: 'flex', justifyContent: 'center', backgroundColor: token?.colorFillTertiary, borderRadius: 8, padding: 20, marginBottom: 15 }}>
                    <video
                      src={getProxyVideoUrl(parsedResult.media_url || parsedResult.all_videos[0] || (parsedResult.file_path ? `/media/${parsedResult.file_path}` : ''))}
                      controls
                      style={{ maxWidth: '100%', maxHeight: '400px', borderRadius: 4 }}
                      onError={(e) => {
                        console.error('Video load error:', e);
                        message.error('视频加载失败，请检查网络或稍后重试');
                      }}
                    />
                  </div>

                  {/* 多视频缩略图列表 */}
                  {parsedResult.all_videos.length > 1 && (
                    <div style={{ marginTop: 15 }}>
                      <div style={{ fontSize: 13, color: token?.colorTextTertiary, marginBottom: 8 }}>更多视频：</div>
                      <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 10 }}>
                        {parsedResult.all_videos.slice(1).map((videoUrl, index) => (
                          <div
                            key={index + 1}
                            style={{
                              flex: '0 0 auto',
                              cursor: 'pointer',
                              borderRadius: 8,
                              overflow: 'hidden',
                              border: `2px solid ${token?.colorBorderSecondary}`,
                              transition: 'all 0.3s'
                            }}
                            onClick={() => {
                              // 切换主视频
                              const videoEl = document.querySelector('video');
                              if (videoEl) {
                                videoEl.src = getProxyVideoUrl(videoUrl);
                              }
                            }}
                            onMouseEnter={(e) => {
                              e.target.style.borderColor = token?.colorPrimary;
                            }}
                            onMouseLeave={(e) => {
                              e.target.style.borderColor = token?.colorBorderSecondary;
                            }}
                          >
                            <video
                              src={getProxyVideoUrl(videoUrl)}
                              style={{ width: 160, height: 120, objectFit: 'cover', display: 'block' }}
                              muted
                            />
                            <div style={{ padding: '6px 10px', backgroundColor: token?.colorBgContainer, fontSize: 12, color: token?.colorTextTertiary, textAlign: 'center' }}>
                              视频 {index + 2}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* 📸 图片预览区域 - 可与视频共存 */}
              {parsedResult.all_images && parsedResult.all_images.length > 0 && (
                <div style={{ marginTop: parsedResult.all_videos && parsedResult.all_videos.length > 0 ? 20 : 0, width: '100%' }}>
                  <h4>
                    📸 图片预览
                    <span style={{ color: token?.colorPrimary, marginLeft: 8, fontSize: 14 }}>
                      共 {parsedResult.all_images.length} 张
                    </span>
                    {parsedResult.has_live_photo && (
                      <span style={{ color: token?.colorSuccess, marginLeft: 8, fontSize: 13 }}>
                        🎬 包含实况图片
                      </span>
                    )}
                  </h4>
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))',
                    gap: 12,
                    padding: 15,
                    backgroundColor: token?.colorFillSecondary,
                    borderRadius: 8
                  }}>
                    {parsedResult.all_images.map((imgUrl, index) => (
                      <div key={index} style={{ textAlign: 'center' }}>
                        <img
                          src={getProxyImageUrl(imgUrl)}
                          alt={`图片 ${index + 1}`}
                          style={{
                            width: '100%',
                            height: 150,
                            objectFit: 'cover',
                            borderRadius: 8,
                            cursor: 'pointer',
                            border: `2px solid ${token?.colorBorderSecondary}`,
                            transition: 'all 0.3s'
                          }}
                          onClick={() => handlePreview(imgUrl, index)}
                          onError={handleImageError}
                          onMouseEnter={(e) => {
                            e.target.style.borderColor = token?.colorPrimary;
                            e.target.style.transform = 'scale(1.02)';
                          }}
                          onMouseLeave={(e) => {
                            e.target.style.borderColor = token?.colorBorderSecondary;
                            e.target.style.transform = 'scale(1)';
                          }}
                        />
                        <div style={{ fontSize: 12, color: token?.colorTextTertiary, marginTop: 6 }}>
                          图片 {index + 1}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </Space>
          )}
        </Card>
      )}
      
      {/* Image Preview Modal */}
      <Modal
        open={previewVisible}
        title={
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>{previewTitle}</span>
            <Button
              type="link"
              icon={<DownloadOutlined />}
              onClick={() => {
                // Extract original URL from proxy URL
                const urlMatch = previewImage.match(/url=([^&]+)/);
                if (urlMatch) {
                  const originalUrl = decodeURIComponent(urlMatch[1]);
                  window.open(originalUrl, '_blank');
                }
              }}
            >
              查看原图
            </Button>
          </div>
        }
        footer={null}
        onCancel={handlePreviewCancel}
        width="80%"
        style={{ top: 20 }}
        styles={{ body: { padding: 0, textAlign: 'center', backgroundColor: token?.colorFillTertiary } }}
      >
        <Image
          src={previewImage}
          alt={previewTitle}
          style={{ maxWidth: '100%', maxHeight: '80vh' }}
          preview={false}
        />
      </Modal>
    </Space>
  );
};

export default ContentParsing;
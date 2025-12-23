const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs').promises;
const logger = require('../utils/logger');

/**
 * 小红书博主作品下载服务
 * 调用 xiaohongshu_downloader.py 脚本下载博主所有作品
 */
class XiaohongshuDownloadService {
  constructor() {
    this.scriptPath = path.join(__dirname, '../../xiaohongshu_downloader.py');
    this.baseOutputDir = path.join(__dirname, '../../downloads');
  }

  /**
   * 下载博主所有作品
   * @param {string} authorUrl - 博主主页URL
   * @param {Object} options - 配置选项
   * @param {string} options.cookie - 小红书 Cookie
   * @param {string} options.outputDir - 输出目录
   * @param {number} options.maxNotes - 最大下载笔记数
   * @param {number} options.delay - 请求延迟（秒）
   * @returns {Promise<Object>} 下载结果
   */
  async downloadAuthorNotes(authorUrl, options = {}) {
    const {
      cookie = null,
      outputDir = this.baseOutputDir,
      maxNotes = null,
      delay = 0.5
    } = options;

    try {
      logger.info(`Starting Xiaohongshu author notes download: ${authorUrl}`);

      // 构建命令参数
      const args = [this.scriptPath, authorUrl];

      if (cookie) {
        args.push('--cookie', cookie);
      }

      if (outputDir) {
        args.push('--output', outputDir);
      }

      if (maxNotes) {
        args.push('--max-notes', maxNotes.toString());
      }

      if (delay) {
        args.push('--delay', delay.toString());
      }

      logger.info(`Executing command: python3 ${args.join(' ')}`);

      // 执行下载脚本
      const result = await this.executePythonScript(args);

      // 解析下载结果
      const downloadResult = await this.parseDownloadResult(outputDir, authorUrl);

      logger.info(`Xiaohongshu download completed: ${downloadResult.stats.total_notes} notes`);

      return {
        success: true,
        authorUrl,
        outputDir: downloadResult.outputDir,
        stats: downloadResult.stats,
        notes: downloadResult.notes
      };
    } catch (error) {
      logger.error(`Failed to download Xiaohongshu author notes:`, error);
      return {
        success: false,
        error: error.message,
        authorUrl
      };
    }
  }

  /**
   * 执行 Python 脚本
   * @param {Array<string>} args - 命令参数
   * @returns {Promise<string>} 脚本输出
   */
  executePythonScript(args) {
    return new Promise((resolve, reject) => {
      const python = spawn('python3', args);
      let stdout = '';
      let stderr = '';

      python.stdout.on('data', (data) => {
        const text = data.toString();
        stdout += text;
        logger.info(`[Python stdout] ${text.trim()}`);
      });

      python.stderr.on('data', (data) => {
        const text = data.toString();
        stderr += text;
        logger.warn(`[Python stderr] ${text.trim()}`);
      });

      python.on('close', (code) => {
        if (code === 0) {
          resolve(stdout);
        } else {
          reject(new Error(`Python script exited with code ${code}: ${stderr}`));
        }
      });

      python.on('error', (error) => {
        reject(new Error(`Failed to start Python process: ${error.message}`));
      });
    });
  }

  /**
   * 解析下载结果
   * @param {string} outputDir - 输出目录
   * @param {string} authorUrl - 作者URL
   * @returns {Promise<Object>} 解析结果
   */
  async parseDownloadResult(outputDir, authorUrl) {
    try {
      // 从作者URL中提取博主名称或ID
      const authorMatch = authorUrl.match(/user\/profile\/([a-zA-Z0-9]+)/);
      const authorId = authorMatch ? authorMatch[1] : 'unknown';

      // 查找下载目录（可能在博主名称子文件夹中）
      const dirs = await fs.readdir(outputDir);
      const authorDir = dirs.find(d => d.includes(authorId) || d !== 'test');

      if (!authorDir) {
        throw new Error(`Download directory not found for author: ${authorId}`);
      }

      const authorPath = path.join(outputDir, authorDir);

      // 读取下载报告
      const reportPath = path.join(authorPath, 'download_report.json');
      const reportData = await fs.readFile(reportPath, 'utf-8').then(JSON.parse).catch(() => null);

      // 读取笔记数据
      const notesDataPath = path.join(authorPath, 'notes_data.json');
      const notesData = await fs.readFile(notesDataPath, 'utf-8').then(JSON.parse).catch(() => null);

      const stats = reportData || {
        total_notes: 0,
        successful: 0,
        failed: 0,
        total_images: 0,
        total_videos: 0,
        notes: []
      };

      return {
        outputDir: authorPath,
        stats,
        notes: notesData?.notes || []
      };
    } catch (error) {
      logger.error('Failed to parse download result:', error);
      return {
        outputDir,
        stats: {
          total_notes: 0,
          successful: 0,
          failed: 0,
          total_images: 0,
          total_videos: 0,
          notes: []
        },
        notes: []
      };
    }
  }

  /**
   * 获取博主信息和笔记列表（不下载媒体文件）
   * @param {string} authorUrl - 博主主页URL
   * @param {string} cookie - Cookie
   * @returns {Promise<Object>} 博主信息和笔记列表
   */
  async getAuthorNotesInfo(authorUrl, cookie = null) {
    try {
      const { spawn } = require('child_process');

      // 创建临时测试脚本
      const testScript = `
import sys
sys.path.insert(0, 'media_parser_sdk')
from media_parser_sdk.platforms.xiaohongshu_enhanced import extract_xiaohongshu_author_notes_sync
import json

url = "${authorUrl}"
cookie = "${cookie or ''}"

result = extract_xiaohongshu_author_notes_sync(
    url,
    max_notes=50,
    fetch_detail=False,
    cookie=cookie if cookie else None
)

if result.success:
    data = result.data
    print(json.dumps({
        "success": True,
        "author": data.get("author_profile", {}),
        "notes_count": len(data.get("notes", [])),
        "notes": data.get("notes", [])
    }))
else:
    print(json.dumps({
        "success": False,
        "error": result.error_message
    }))
`;

      const testScriptPath = path.join(__dirname, '../../temp_get_notes.py');
      await fs.writeFile(testScriptPath, testScript);

      const result = await this.executePythonScript(['python3', testScriptPath]);

      // 清理临时脚本
      await fs.unlink(testScriptPath).catch(() => {});

      // 解析输出（最后一行是 JSON）
      const lines = result.trim().split('\n');
      const jsonLine = lines[lines.length - 1];
      const data = JSON.parse(jsonLine);

      return data;
    } catch (error) {
      logger.error('Failed to get author notes info:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * 将下载的笔记转换为系统内容格式
   * @param {Object} downloadResult - 下载结果
   * @returns {Array} 内容列表
   */
  convertDownloadedNotesToContent(downloadResult) {
    const { notes, outputDir } = downloadResult;
    const contents = [];

    notes.forEach((note, index) => {
      const noteDir = path.join(outputDir, `${index + 1:02d}_${note.title?.substring(0, 30) || 'note'}`);

      contents.push({
        content_id: note.note_id || `xiaohongshu_${Date.now()}_${index}`,
        title: note.title || '无标题',
        author: note.author?.nickname || '未知作者',
        description: note.content || '',
        media_type: note.type || 'image',
        cover_url: note.cover_image?.url || '',
        file_path: noteDir,
        source_url: note.source_url || '',
        platform: 'xiaohongshu',
        tags: note.tags || [],
        has_live_photo: note.has_live_photo || false,
        interaction_stats: note.interaction_stats || {},
        created_at: note.publish_time ? new Date(note.publish_time) : new Date(),
        // 媒体文件信息
        images_count: note.images?.length || 0,
        videos_count: note.videos?.length || 0,
        // 本地文件路径
        local_images: note.images?.map((img, i) => path.join(noteDir, `image_${i + 1}.jpg`)) || [],
        local_videos: note.videos?.map((vid, i) => path.join(noteDir, `video_${i + 1}.mp4`)) || [],
        local_cover: path.join(noteDir, 'cover.jpg')
      });
    });

    return contents;
  }
}

module.exports = new XiaohongshuDownloadService();

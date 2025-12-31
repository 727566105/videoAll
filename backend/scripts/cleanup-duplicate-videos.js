#!/usr/bin/env node
/**
 * 清理重复的视频文件
 *
 * 问题说明：
 * 小红书 API 返回了主服务器和备份服务器的 URL，导致同一个视频被下载两次。
 * 例如：video_1.mp4 和 video_2.mp4 的 MD5 值完全相同。
 *
 * 此脚本会：
 * 1. 扫描 media/xiaohongshu 目录下的所有内容文件夹
 * 2. 检测重复的视频文件（通过 MD5 值）
 * 3. 删除重复的文件，保留第一个
 * 4. 生成清理报告
 */

const fs = require('fs-extra');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

// 配置
// 支持两种可能的目录结构
const possiblePaths = [
  path.join(__dirname, '../../media/xiaohongshu'),
  path.join(__dirname, '../../../backend/media/xiaohongshu'),
  path.join(process.cwd(), 'media/xiaohongshu')
];

let MEDIA_DIR = possiblePaths.find(p => fs.existsSync(p));
if (!MEDIA_DIR) {
  // 尝试从环境变量获取
  MEDIA_DIR = path.join(process.env.STORAGE_ROOT_PATH || process.cwd(), 'xiaohongshu');
}

const REPORT_FILE = path.join(__dirname, `cleanup-report-${Date.now()}.json`);

/**
 * 计算文件的 MD5 哈希值
 */
async function calculateMD5(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('md5');
    const stream = fs.createReadStream(filePath);

    stream.on('data', (data) => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

/**
 * 获取目录下所有视频文件
 */
async function getVideoFiles(dir) {
  const files = await fs.readdir(dir);
  const videoFiles = [];

  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = await fs.stat(fullPath);

    if (stat.isDirectory()) {
      const subFiles = await getVideoFiles(fullPath);
      videoFiles.push(...subFiles);
    } else if (stat.isFile() && /\.(mp4|mov|avi|mkv|webm)$/i.test(file)) {
      videoFiles.push(fullPath);
    }
  }

  return videoFiles;
}

/**
 * 清理重复文件
 */
async function cleanupDuplicates() {
  console.log('开始扫描重复文件...\n');

  // 检查媒体目录是否存在
  if (!await fs.pathExists(MEDIA_DIR)) {
    console.error(`媒体目录不存在: ${MEDIA_DIR}`);
    process.exit(1);
  }

  // 获取所有内容文件夹
  const contentFolders = (await fs.readdir(MEDIA_DIR))
    .filter(f => {
      const fullPath = path.join(MEDIA_DIR, f);
      return fs.statSync(fullPath).isDirectory();
    });

  console.log(`找到 ${contentFolders.length} 个内容文件夹\n`);

  const report = {
    startTime: new Date().toISOString(),
    totalFolders: contentFolders.length,
    foldersProcessed: 0,
    duplicatesFound: 0,
    filesDeleted: 0,
    spaceSaved: 0,
    details: []
  };

  // 遍历每个内容文件夹
  for (const folder of contentFolders) {
    const folderPath = path.join(MEDIA_DIR, folder);
    console.log(`处理文件夹: ${folder}`);

    // 获取该文件夹下的所有视频文件
    const files = (await fs.readdir(folderPath))
      .filter(f => /\.(mp4|mov|avi|mkv|webm)$/i.test(f))
      .map(f => ({
        name: f,
        path: path.join(folderPath, f)
      }));

    if (files.length < 2) {
      console.log(`  跳过：文件数量不足 2 个\n`);
      report.foldersProcessed++;
      continue;
    }

    // 计算每个文件的 MD5
    const fileHashMap = new Map();

    for (const file of files) {
      try {
        const md5 = await calculateMD5(file.path);
        const stats = await fs.stat(file.path);

        if (!fileHashMap.has(md5)) {
          fileHashMap.set(md5, []);
        }

        fileHashMap.get(md5).push({
          name: file.name,
          path: file.path,
          size: stats.size
        });
      } catch (error) {
        console.error(`  计算哈希失败: ${file.name} - ${error.message}`);
      }
    }

    // 查找重复文件
    let folderDuplicates = 0;
    let folderDeleted = 0;
    let folderSaved = 0;

    for (const [md5, fileList] of fileHashMap.entries()) {
      if (fileList.length > 1) {
        console.log(`  发现重复文件 (MD5: ${md5}):`);
        fileList.forEach((f, i) => {
          console.log(`    [${i + 1}] ${f.name} (${(f.size / 1024 / 1024).toFixed(2)} MB)`);
        });

        // 保留第一个文件，删除其余的
        const [keep, ...toDelete] = fileList;

        for (const file of toDelete) {
          try {
            await fs.unlink(file.path);
            console.log(`    ✓ 已删除: ${file.name}`);
            folderDeleted++;
            folderSaved += file.size;
          } catch (error) {
            console.error(`    ✗ 删除失败: ${file.name} - ${error.message}`);
          }
        }

        folderDuplicates++;
        report.details.push({
          folder,
          md5,
          files: fileList.map(f => f.name),
          kept: keep.name,
          deleted: toDelete.map(f => f.name),
          totalSizeSaved: toDelete.reduce((sum, f) => sum + f.size, 0)
        });
      }
    }

    report.duplicatesFound += folderDuplicates;
    report.filesDeleted += folderDeleted;
    report.spaceSaved += folderSaved;
    report.foldersProcessed++;

    if (folderDuplicates > 0) {
      console.log(`  该文件夹清理完成：删除 ${folderDeleted} 个重复文件，释放 ${(folderSaved / 1024 / 1024).toFixed(2)} MB\n`);
    } else {
      console.log(`  该文件夹无重复文件\n`);
    }
  }

  report.endTime = new Date().toISOString();
  report.spaceSavedMB = (report.spaceSaved / 1024 / 1024).toFixed(2);

  // 打印总结
  console.log('═══════════════════════════════════════');
  console.log('清理完成！');
  console.log('═══════════════════════════════════════');
  console.log(`处理的文件夹数: ${report.foldersProcessed}`);
  console.log(`发现的重复组数: ${report.duplicatesFound}`);
  console.log(`删除的文件数: ${report.filesDeleted}`);
  console.log(`释放的空间: ${report.spaceSavedMB} MB`);
  console.log('═══════════════════════════════════════\n');

  // 保存报告
  await fs.writeJson(REPORT_FILE, report, { spaces: 2 });
  console.log(`详细报告已保存到: ${REPORT_FILE}\n`);
}

// 运行清理脚本
(async () => {
  try {
    await cleanupDuplicates();
  } catch (error) {
    console.error('清理失败:', error);
    process.exit(1);
  }
})();

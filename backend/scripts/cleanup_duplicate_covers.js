#!/usr/bin/env node
/**
 * 清理重复的 cover.jpg 文件脚本
 * 检查所有子目录，如果 cover.jpg 和 image_1.jpg 内容相同，则删除 cover.jpg
 * 并在下载时通过复制 image_1.jpg 来创建 cover.jpg
 */

const fs = require('fs-extra');
const path = require('path');
const crypto = require('crypto');

/**
 * 计算文件的 MD5 哈希值
 */
async function calculateFileHash(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('md5');
    const stream = fs.createReadStream(filePath);

    stream.on('data', data => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

/**
 * 检查两个文件是否相同（比较大小和哈希值）
 */
async function areFilesSame(file1, file2) {
  try {
    const stats1 = await fs.stat(file1);
    const stats2 = await fs.stat(file2);

    // 首先比较文件大小
    if (stats1.size !== stats2.size) {
      return false;
    }

    // 大小相同，比较哈希值
    const hash1 = await calculateFileHash(file1);
    const hash2 = await calculateFileHash(file2);

    return hash1 === hash2;
  } catch (error) {
    console.error(`比较文件失败: ${error.message}`);
    return false;
  }
}

/**
 * 清理重复的封面文件
 */
async function cleanupDuplicateCovers(mediaDir) {
  console.log('='.repeat(80));
  console.log('开始清理重复的 cover.jpg 文件');
  console.log('='.repeat(80));

  const platformDir = path.join(mediaDir, 'xiaohongshu');

  if (!await fs.pathExists(platformDir)) {
    console.log(`目录不存在: ${platformDir}`);
    return;
  }

  const directories = await fs.readdir(platformDir);
  let totalChecked = 0;
  let totalDeleted = 0;
  let totalSpaceSaved = 0;
  const processedDirs = [];

  for (const dir of directories) {
    const contentDir = path.join(platformDir, dir);

    // 跳过非目录
    if (!(await fs.stat(contentDir)).isDirectory()) {
      continue;
    }

    const coverPath = path.join(contentDir, 'cover.jpg');
    const image1Path = path.join(contentDir, 'image_1.jpg');

    // 检查是否同时存在两个文件
    if (!(await fs.pathExists(coverPath)) || !(await fs.pathExists(image1Path))) {
      continue;
    }

    totalChecked++;

    // 检查文件是否相同
    const isSame = await areFilesSame(coverPath, image1Path);

    if (isSame) {
      const stats = await fs.stat(coverPath);
      const fileSize = stats.size;

      // 删除重复的 cover.jpg
      await fs.remove(coverPath);

      totalDeleted++;
      totalSpaceSaved += fileSize;

      processedDirs.push({
        dir,
        size: fileSize,
        status: '已删除重复文件'
      });

      console.log(`✓ ${dir}: 删除重复的 cover.jpg (${(fileSize / 1024).toFixed(2)} KB)`);
    } else {
      processedDirs.push({
        dir,
        status: '文件不同，保留'
      });

      console.log(`○ ${dir}: cover.jpg 和 image_1.jpg 内容不同，已保留`);
    }
  }

  console.log('\n' + '='.repeat(80));
  console.log('清理完成统计');
  console.log('='.repeat(80));
  console.log(`检查目录总数: ${totalChecked}`);
  console.log(`删除重复文件: ${totalDeleted}`);
  console.log(`节省磁盘空间: ${(totalSpaceSaved / 1024 / 1024).toFixed(2)} MB`);
  console.log('='.repeat(80));

  return {
    totalChecked,
    totalDeleted,
    totalSpaceSaved,
    processedDirs
  };
}

// 执行清理（media 目录在 backend 下）
const mediaDir = path.join(__dirname, '../media');

cleanupDuplicateCovers(mediaDir)
  .then(result => {
    console.log('\n✓ 清理完成！');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n✗ 清理失败:', error);
    process.exit(1);
  });

#!/usr/bin/env node
/**
 * 测试抖音解析功能
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const COOKIE_FILE = path.join(__dirname, 'douyin-cookie.txt');
const TEST_URL = 'https://www.douyin.com/video/7587637524178554161';

console.log('='.repeat(70));
console.log('抖音解析功能测试');
console.log('='.repeat(70));

// 1. 检查Cookie文件
console.log('\n步骤1: 检查Cookie文件');
if (!fs.existsSync(COOKIE_FILE)) {
  console.log('❌ Cookie文件不存在');
  console.log(`路径: ${COOKIE_FILE}`);
  process.exit(1);
}

const cookie = fs.readFileSync(COOKIE_FILE, 'utf8').trim();
console.log(`✓ Cookie文件存在，长度: ${cookie.length} 字符`);
console.log(`✓ Cookie预览: ${cookie.substring(0, 50)}...`);

// 2. 检查Cookie关键字段
console.log('\n步骤2: 检查Cookie关键字段');
const requiredFields = ['sessionid', 'ttwid'];
let foundFields = 0;
requiredFields.forEach(field => {
  if (cookie.includes(`${field}=`)) {
    foundFields++;
    console.log(`✓ 包含 ${field}`);
  } else {
    console.log(`✗ 缺少 ${field}`);
  }
});

if (foundFields < requiredFields.length) {
  console.log('\n⚠️  Cookie可能不完整');
}

// 3. 测试SDK解析（带Cookie）
console.log('\n步骤3: 测试SDK解析（带Cookie）');
console.log(`URL: ${TEST_URL}`);

const sdkPath = path.join(__dirname, '../media_parser_sdk');
const command = `cd "${sdkPath}" && python3 wrapper.py douyin_video "${TEST_URL}" --cookie "${cookie}"`;

console.log('\n执行命令:');
console.log(command);
console.log('\n等待结果...\n');

exec(command, { timeout: 30000 }, (error, stdout, stderr) => {
  if (error) {
    console.error('❌ 执行失败');
    console.error('错误代码:', error.code);
    console.error('错误信号:', error.signal);
    if (error.killed) {
      console.error('进程被终止（超时）');
    }
  }

  console.log('\n标准输出:');
  console.log(stdout);

  if (stderr) {
    console.log('\n标准错误:');
    console.log(stderr);
  }

  // 4. 分析结果
  console.log('\n' + '='.repeat(70));
  console.log('结果分析:');
  console.log('='.repeat(70));

  if (stdout.includes('error')) {
    console.log('❌ 解析失败');

    if (stdout.includes('NETWORK_ERROR')) {
      console.log('原因: 网络错误');
      if (stdout.includes('反爬虫验证页面')) {
        console.log('详细原因: 检测到反爬虫验证页面');
        console.log('\n建议解决方案:');
        console.log('1. Cookie可能已过期，请重新获取');
        console.log('2. IP可能被标记，请稍后重试');
        console.log('3. 抖音加强了反爬虫，暂时无法解析');
      }
    } else if (stdout.includes('PARSE_ERROR')) {
      console.log('原因: 解析错误');
    }
  } else if (stdout.includes('title') || stdout.includes('desc') || stdout.includes('author')) {
    console.log('✅ 解析成功！');
    console.log('包含关键字段: title, desc 或 author');
  } else {
    console.log('⚠️  结果不确定');
    console.log('请检查上面的输出');
  }

  console.log('\n' + '='.repeat(70));
});

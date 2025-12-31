/**
 * 密钥轮换服务
 *
 * 提供加密密钥的安全管理功能，包括：
 * - 检测默认加密密钥
 * - 生成新的加密密钥
 * - 密钥轮换功能
 * - 密钥强度报告
 */

const { AppDataSource } = require('../utils/db');
const EncryptionService = require('../utils/encryption');
const logger = require('../utils/logger');
const crypto = require('crypto');

class KeyRotationService {
  /**
   * 检查是否使用默认加密密钥
   * @returns {boolean}
   */
  static isUsingDefaultKey() {
    try {
      // 尝试获取加密服务实例
      const encryptionService = require('../utils/encryption');

      // 检查是否使用默认密钥
      // 默认密钥可能在不同的地方定义，这里检查常见的情况
      const defaultKeys = [
        'default-secret-key-change-in-production',
        'your-secret-key-here',
        'change-this-secret-key',
      ];

      // 检查环境变量中的密钥
      const envKey = process.env.ENCRYPTION_KEY || process.env.SECRET_KEY;
      if (!envKey || defaultKeys.includes(envKey)) {
        return true;
      }

      // 检查加密服务中的密钥
      if (encryptionService.secretKey && defaultKeys.includes(encryptionService.secretKey)) {
        return true;
      }

      return false;
    } catch (error) {
      logger.error('检查默认密钥失败:', error);
      return true; // 出错时假设使用默认密钥，更安全
    }
  }

  /**
   * 生成新的加密密钥
   * @param {number} length - 密钥长度（字节数）
   * @returns {string} 十六进制格式的密钥
   */
  static generateNewKey(length = 32) {
    try {
      return crypto.randomBytes(length).toString('hex');
    } catch (error) {
      logger.error('生成密钥失败:', error);
      throw new Error('密钥生成失败');
    }
  }

  /**
   * 重新加密所有API密钥（使用新密钥）
   * @param {string} oldKey - 旧的加密密钥
   * @param {string} newKey - 新的加密密钥
   * @returns {Promise<object>} 轮换结果
   */
  static async rotateEncryptionKey(oldKey, newKey) {
    try {
      const aiConfigRepository = AppDataSource.getRepository('AiConfig');

      // 获取所有有加密密钥的配置
      const configs = await aiConfigRepository.find({
        where: { api_key_encrypted: { $ne: null } }
      });

      logger.info(`开始轮换${configs.length}个配置的加密密钥`);

      // 保存原始加密服务设置
      const encryptionService = require('../utils/encryption');
      const originalSecretKey = encryptionService.secretKey;

      const results = {
        success: 0,
        failed: 0,
        errors: []
      };

      // 临时设置旧密钥进行解密
      encryptionService.secretKey = oldKey;

      for (const config of configs) {
        try {
          // 使用旧密钥解密
          const decryptedKey = EncryptionService.decrypt(config.api_key_encrypted);

          // 切换到新密钥加密
          encryptionService.secretKey = newKey;
          const newEncryptedKey = EncryptionService.encrypt(decryptedKey);

          // 更新配置
          config.api_key_encrypted = newEncryptedKey;
          config.last_rotation_at = new Date();
          await aiConfigRepository.save(config);

          results.success++;
          logger.info(`配置${config.id}密钥轮换成功`);
        } catch (error) {
          results.failed++;
          results.errors.push({
            configId: config.id,
            error: error.message
          });
          logger.error(`配置${config.id}密钥轮换失败:`, error);
        }
      }

      // 恢复原始设置
      encryptionService.secretKey = originalSecretKey;

      logger.info(`密钥轮换完成: 成功${results.success}, 失败${results.failed}`);

      return {
        success: results.failed === 0,
        message: `密钥轮换完成: 成功${results.success}, 失败${results.failed}`,
        details: results
      };
    } catch (error) {
      logger.error('密钥轮换失败:', error);
      throw error;
    }
  }

  /**
   * 获取加密密钥强度报告
   * @returns {object} 强度报告
   */
  static getKeyStrengthReport() {
    try {
      const encryptionService = require('../utils/encryption');
      const key = process.env.ENCRYPTION_KEY ||
                  process.env.SECRET_KEY ||
                  encryptionService.secretKey ||
                  '';

      const issues = [];

      // 检查是否使用默认密钥
      const defaultKeys = [
        'default-secret-key-change-in-production',
        'your-secret-key-here',
        'change-this-secret-key',
      ];

      if (defaultKeys.includes(key)) {
        issues.push({
          level: 'critical',
          message: '使用默认加密密钥，存在严重安全风险',
          recommendation: '请在环境变量中设置ENCRYPTION_KEY并重启服务'
        });
      }

      // 检查密钥长度
      if (key.length < 32) {
        issues.push({
          level: 'warning',
          message: `加密密钥长度不足（当前: ${key.length}，建议: 至少32字符）`,
          recommendation: '使用更长的密钥以提高安全性'
        });
      }

      // 检查密钥复杂度
      if (key.length > 0 && /^[a-zA-Z0-9]+$/.test(key)) {
        issues.push({
          level: 'warning',
          message: '加密密钥复杂度不足（仅包含字母和数字）',
          recommendation: '建议使用包含特殊字符的密钥'
        });
      }

      // 检查是否为空
      if (!key || key.length === 0) {
        issues.push({
          level: 'critical',
          message: '未设置加密密钥',
          recommendation: '必须在环境变量中设置ENCRYPTION_KEY'
        });
      }

      return {
        isSecure: issues.length === 0,
        keyLength: key.length,
        hasKey: key.length > 0,
        issues
      };
    } catch (error) {
      logger.error('获取密钥强度报告失败:', error);
      return {
        isSecure: false,
        keyLength: 0,
        hasKey: false,
        issues: [{
          level: 'critical',
          message: '无法获取密钥信息',
          error: error.message
        }]
      };
    }
  }

  /**
   * 验证密钥格式
   * @param {string} key - 密钥
   * @returns {object} 验证结果
   */
  static validateKey(key) {
    const errors = [];

    if (!key || typeof key !== 'string') {
      return {
        valid: false,
        errors: ['密钥不能为空']
      };
    }

    // 长度检查
    if (key.length < 16) {
      errors.push('密钥长度至少16个字符');
    }

    // 复杂度检查（建议）
    if (!/[a-z]/.test(key) || !/[A-Z]/.test(key)) {
      errors.push('建议密钥包含大小写字母');
    }

    if (!/[0-9]/.test(key)) {
      errors.push('建议密钥包含数字');
    }

    if (!/[^a-zA-Z0-9]/.test(key)) {
      errors.push('建议密钥包含特殊字符');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * 获取环境变量配置建议
   * @returns {object} 配置建议
   */
  static getConfigurationAdvice() {
    const report = this.getKeyStrengthReport();
    const advice = {
      needsConfiguration: false,
      envVariable: 'ENCRYPTION_KEY',
      currentValue: '***', // 不显示实际值
      recommendedAction: null,
      instructions: []
    };

    if (!report.hasKey) {
      advice.needsConfiguration = true;
      advice.recommendedAction = '立即设置加密密钥';
      advice.instructions = [
        '1. 生成一个强密钥（32字符以上）',
        '2. 在 .env 文件中添加: ENCRYPTION_KEY=your-generated-key',
        '3. 重启后端服务',
        '4. 确认密钥已生效（使用密钥状态检查API）'
      ];
    } else if (!report.isSecure) {
      advice.needsConfiguration = true;
      advice.recommendedAction = '改进当前密钥配置';

      if (report.issues.some(i => i.level === 'critical')) {
        advice.instructions.push('⚠️ 检测到严重安全问题，建议立即修复');
      }

      report.issues.forEach(issue => {
        if (issue.recommendation) {
          advice.instructions.push(`• ${issue.recommendation}`);
        }
      });
    } else {
      advice.recommendedAction = '当前配置安全';
      advice.instructions = [
        '• 定期检查密钥安全状态',
        '• 考虑定期轮换密钥（建议每6个月）',
        '• 妥善保管密钥，不要提交到版本控制系统'
      ];
    }

    return advice;
  }
}

module.exports = KeyRotationService;

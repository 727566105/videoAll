import CryptoJS from 'crypto-js';

/**
 * 凭证加密存储工具模块
 * 使用 AES-256-CBC 加密算法保护用户密码
 */

// 加密密钥（生产环境应从环境变量读取）
const SECRET_KEY = import.meta.env.VITE_CREDENTIAL_SECRET_KEY || 'video-all-credential-secret-key-2024';

// 凭证过期时间（7天，单位：毫秒）
const CREDENTIAL_EXPIRY = 7 * 24 * 60 * 60 * 1000;

// localStorage 存储键名
const STORAGE_KEY = 'savedCredentials';

/**
 * 生成设备特定的盐值
 * 基于用户名和浏览器特征生成，确保每个设备的密钥不同
 * @param {string} username - 用户名
 * @returns {string} 盐值
 */
const generateSalt = (username) => {
  const browserFingerprint = navigator.userAgent + navigator.language;
  return CryptoJS.SHA256(username + browserFingerprint + SECRET_KEY).toString();
};

/**
 * 加密密码
 * @param {string} password - 明文密码
 * @param {string} username - 用户名（用于生成盐值）
 * @returns {Object} 加密结果 { encryptedPassword, salt }
 */
export const encryptPassword = (password, username) => {
  try {
    const salt = generateSalt(username);
    const key = CryptoJS.PBKDF2(SECRET_KEY, salt, {
      keySize: 256 / 32,
      iterations: 1000
    }).toString();

    const iv = CryptoJS.lib.WordArray.random(128 / 8);
    const encrypted = CryptoJS.AES.encrypt(password, CryptoJS.enc.Hex.parse(key), {
      iv: iv,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7
    });

    return {
      encryptedPassword: encrypted.ciphertext.toString(CryptoJS.enc.Base64),
      iv: iv.toString(CryptoJS.enc.Base64)
    };
  } catch (error) {
    console.error('加密失败:', error);
    throw new Error('密码加密失败');
  }
};

/**
 * 解密密码
 * @param {string} encryptedPassword - 加密的密码
 * @param {string} iv - 初始化向量
 * @param {string} username - 用户名（用于生成盐值）
 * @returns {string} 明文密码
 */
export const decryptPassword = (encryptedPassword, iv, username) => {
  try {
    const salt = generateSalt(username);
    const key = CryptoJS.PBKDF2(SECRET_KEY, salt, {
      keySize: 256 / 32,
      iterations: 1000
    }).toString();

    const decrypted = CryptoJS.AES.decrypt(
      {
        ciphertext: CryptoJS.enc.Base64.parse(encryptedPassword)
      },
      CryptoJS.enc.Hex.parse(key),
      {
        iv: CryptoJS.enc.Base64.parse(iv),
        mode: CryptoJS.mode.CBC,
        padding: CryptoJS.pad.Pkcs7
      }
    );

    const plaintext = decrypted.toString(CryptoJS.enc.Utf8);
    if (!plaintext) {
      throw new Error('解密结果为空');
    }
    return plaintext;
  } catch (error) {
    console.error('解密失败:', error);
    throw new Error('密码解密失败，数据可能已损坏');
  }
};

/**
 * 保存登录凭证
 * @param {Object} values - 登录表单值 { username, password, remember }
 * @returns {boolean} 是否保存成功
 */
export const saveCredentials = (values) => {
  try {
    const { encryptedPassword, iv } = encryptPassword(values.password, values.username);

    const credentials = {
      username: values.username,
      encryptedPassword,
      iv,
      remember: values.remember,
      createdAt: Date.now(),
      expiresAt: Date.now() + CREDENTIAL_EXPIRY
    };

    const jsonString = JSON.stringify(credentials);
    localStorage.setItem(STORAGE_KEY, jsonString);

    return true;
  } catch (error) {
    console.error('保存凭证失败:', error);
    if (error.name === 'QuotaExceededError') {
      throw new Error('存储空间不足，请清理浏览器缓存后重试');
    }
    throw error;
  }
};

/**
 * 获取已保存的登录凭证
 * @returns {Object|null} 凭证对象 { username, password, remember } 或 null
 */
export const getSavedCredentials = () => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      return null;
    }

    const credentials = JSON.parse(saved);

    // 验证数据完整性
    if (!credentials.username || !credentials.encryptedPassword || !credentials.iv) {
      console.error('凭证数据不完整');
      clearCredentials();
      return null;
    }

    // 检查是否过期
    if (Date.now() > credentials.expiresAt) {
      console.log('凭证已过期');
      clearCredentials();
      return null;
    }

    // 解密密码
    const password = decryptPassword(
      credentials.encryptedPassword,
      credentials.iv,
      credentials.username
    );

    return {
      username: credentials.username,
      password,
      remember: credentials.remember || true,
      expiresAt: credentials.expiresAt
    };
  } catch (error) {
    console.error('获取凭证失败:', error);
    // 如果数据损坏，清除之
    clearCredentials();
    return null;
  }
};

/**
 * 清除已保存的登录凭证
 */
export const clearCredentials = () => {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch (error) {
    console.error('清除凭证失败:', error);
  }
};

/**
 * 检查是否有已保存的凭证
 * @returns {boolean}
 */
export const hasSavedCredentials = () => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    return !!saved;
  } catch {
    return false;
  }
};

/**
 * 获取凭证剩余有效时间（天）
 * @returns {number|null} 剩余天数，如果无凭证则返回 null
 */
export const getCredentialsDaysRemaining = () => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return null;

    const credentials = JSON.parse(saved);
    const remainingMs = credentials.expiresAt - Date.now();
    const remainingDays = Math.max(0, Math.ceil(remainingMs / (24 * 60 * 60 * 1000)));
    return remainingDays;
  } catch {
    return null;
  }
};

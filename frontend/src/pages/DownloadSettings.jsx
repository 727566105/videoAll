import { useState, useEffect } from 'react';
import { Card, Typography, Spin, message, Space, Alert } from 'antd';
import { SettingOutlined } from '@ant-design/icons';
import apiService from '../services/api';
import BilibiliQualitySettings from '../components/BilibiliQualitySettings';

const { Title, Text } = Typography;

const DownloadSettings = () => {
  const [settings, setSettings] = useState({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // 获取下载设置
  const fetchSettings = async () => {
    try {
      setLoading(true);
      const response = await apiService.downloadSettings.get();
      console.log('下载设置响应:', response);
      setSettings(response.data || {});
    } catch (error) {
      console.error('获取下载设置失败:', error);
      console.error('错误详情:', error.response?.data);

      // 即使获取失败也设置默认值，避免页面完全无法使用
      setSettings({
        bilibili: {
          preferred_quality: '1080P',
          auto_fallback: true
        }
      });

      // 只在不是401错误时显示提示
      if (error.response?.status !== 401) {
        message.error(error.response?.data?.message || '获取下载设置失败，使用默认配置');
      }
    } finally {
      setLoading(false);
    }
  };

  // 更新设置
  const handleUpdate = async (platform, preferences) => {
    try {
      setSaving(true);
      await apiService.downloadSettings.update({ platform, preferences });
      message.success('设置已保存，下次解析时生效');

      // 刷新设置
      await fetchSettings();
    } catch (error) {
      console.error('保存设置失败:', error);
      message.error(error.response?.data?.message || '保存设置失败');
    } finally {
      setSaving(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  if (loading) {
    return (
      <div style={{ padding: '24px', textAlign: 'center' }}>
        <Spin size="large" tip="加载中..." />
      </div>
    );
  }

  return (
    <div style={{ padding: '24px' }}>
      <Card>
        <div style={{ marginBottom: '24px' }}>
          <Title level={4}>
            <SettingOutlined style={{ marginRight: '8px' }} />
            下载偏好设置
          </Title>
          <Text type="secondary">
            配置各平台的下载偏好设置，如视频画质等。这些设置将在解析内容时自动应用。
          </Text>
        </div>

        <Space direction="vertical" size="large" style={{ width: '100%' }}>
          {/* 哔哩哔哩画质设置 */}
          <Card
            title="📺 哔哩哔哩"
            size="small"
            extra={
              settings.bilibili?.preferred_quality && (
                <Text type="secondary">
                  当前偏好: <Text strong>{settings.bilibili.preferred_quality}</Text>
                </Text>
              )
            }
          >
            <BilibiliQualitySettings
              settings={settings.bilibili}
              onUpdate={(preferences) => handleUpdate('bilibili', preferences)}
              loading={saving}
            />
          </Card>

          {/* 提示信息 */}
          <Alert
            message="提示"
            description={
              <ul style={{ margin: 0, paddingLeft: '20px' }}>
                <li>画质设置仅对哔哩哔哩平台生效</li>
                <li>大会员用户可以享受4K和1080P+高码率画质</li>
                <li>如果选择的画质不可用，系统会自动降级到可用画质</li>
                <li>设置将在下次解析哔哩哔哩链接时生效</li>
              </ul>
            }
            type="info"
            showIcon
          />
        </Space>
      </Card>
    </div>
  );
};

export default DownloadSettings;

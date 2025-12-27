import { useState, useEffect } from 'react';
import { Form, Select, Switch, Button, Space, Typography, Tag, Divider } from 'antd';
import { SaveOutlined, CrownOutlined } from '@ant-design/icons';

const { Text } = Typography;
const { Option } = Select;

const BilibiliQualitySettings = ({ settings, onUpdate, loading = false }) => {
  const [form] = Form.useForm();
  const [quality, setQuality] = useState('1080P');
  const [autoFallback, setAutoFallback] = useState(true);

  // 画质选项
  const qualityOptions = [
    {
      value: '4K',
      label: '4K 超清',
      premium: true,
      description: '3840x2160，大会员专享',
      recommended: false
    },
    {
      value: '1080P+',
      label: '1080P+ 高码率',
      premium: true,
      description: '1920x1080 高码率，大会员专享',
      recommended: false
    },
    {
      value: '1080P',
      label: '1080P 高清',
      premium: false,
      description: '1920x1080，推荐画质',
      recommended: true
    },
    {
      value: '720P',
      label: '720P 清晰',
      premium: false,
      description: '1280x720，流畅高清',
      recommended: false
    },
    {
      value: '480P',
      label: '480P 标清',
      premium: false,
      description: '854x480，节省流量',
      recommended: false
    },
    {
      value: '360P',
      label: '360P 流畅',
      premium: false,
      description: '640x360，快速加载',
      recommended: false
    }
  ];

  // 初始化表单值
  useEffect(() => {
    if (settings) {
      setQuality(settings.preferred_quality || '1080P');
      setAutoFallback(settings.auto_fallback !== undefined ? settings.auto_fallback : true);
      form.setFieldsValue({
        quality: settings.preferred_quality || '1080P',
        auto_fallback: settings.auto_fallback !== undefined ? settings.auto_fallback : true
      });
    } else {
      // 默认值
      form.setFieldsValue({
        quality: '1080P',
        auto_fallback: true
      });
    }
  }, [settings, form]);

  // 保存设置
  const handleSave = () => {
    const preferences = {
      preferred_quality: quality,
      auto_fallback: autoFallback
    };
    onUpdate(preferences);
  };

  return (
    <Form
      form={form}
      layout="vertical"
    >
      {/* 画质选择 */}
      <Form.Item label="偏好画质">
        <Select
          value={quality}
          onChange={setQuality}
          placeholder="选择偏好画质"
          style={{ width: '100%' }}
        >
          {qualityOptions.map(opt => (
            <Option key={opt.value} value={opt.value}>
              <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                <Space>
                  {opt.premium && <Tag icon={<CrownOutlined />} color="gold">大会员</Tag>}
                  {opt.recommended && <Tag color="blue">推荐</Tag>}
                  <span>{opt.label}</span>
                </Space>
                <Text type="secondary" style={{ fontSize: '12px' }}>
                  {opt.description}
                </Text>
              </Space>
            </Option>
          ))}
        </Select>
        <div style={{ marginTop: '8px' }}>
          <Text type="secondary" style={{ fontSize: '12px' }}>
            💡 提示：如果选择的画质不可用（如非大会员选择4K），系统会自动降级到可用画质
          </Text>
        </div>
      </Form.Item>

      {/* 自动降级开关 */}
      <Form.Item label="自动降级">
        <Space direction="vertical" size="small">
          <Switch
            checked={autoFallback}
            onChange={setAutoFallback}
            checkedChildren="开启"
            unCheckedChildren="关闭"
          />
          <Text type="secondary" style={{ fontSize: '12px' }}>
            当偏好画质不可用时，自动尝试更低画质（推荐开启）
          </Text>
        </Space>
      </Form.Item>

      <Divider />

      {/* 保存按钮 */}
      <Form.Item>
        <Button
          type="primary"
          icon={<SaveOutlined />}
          onClick={handleSave}
          loading={loading}
          block
        >
          保存设置
        </Button>
      </Form.Item>
    </Form>
  );
};

export default BilibiliQualitySettings;

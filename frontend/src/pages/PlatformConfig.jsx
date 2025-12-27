import { useState, useEffect } from 'react';
import { Card, Typography, Table, Button, Modal, Form, Input, Select, message, Space, Switch, Tag, Popconfirm, Alert, Spin } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, CheckOutlined, CloseOutlined, KeyOutlined, ThunderboltOutlined, LoadingOutlined } from '@ant-design/icons';
import apiService from '../services/api';

const { Title, Text } = Typography;
const { Option } = Select;
const { TextArea } = Input;

const PlatformConfig = () => {
  const [platforms, setPlatforms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalVisible, setModalVisible] = useState(false);
  const [form] = Form.useForm();
  const [currentPlatform, setCurrentPlatform] = useState(null);
  const [modalTitle, setModalTitle] = useState('添加平台账户');
  const [autoFetching, setAutoFetching] = useState(false);
  const [autoFetchMessage, setAutoFetchMessage] = useState('');
  const [selectedPlatform, setSelectedPlatform] = useState('');

  // 支持的平台列表
  const supportedPlatforms = [
    { value: 'xiaohongshu', label: '小红书', icon: '📱' },
    { value: 'douyin', label: '抖音', icon: '🎵' },
    { value: 'bilibili', label: '哔哩哔哩', icon: '📺' },
    { value: 'weibo', label: '微博', icon: '🐦' },
    { value: 'kuaishou', label: '快手', icon: '⚡' }
  ];

  // 表格列定义
  const columns = [
    {
      title: '平台',
      dataIndex: 'platform',
      key: 'platform',
      render: (platform) => {
        const platformInfo = supportedPlatforms.find(p => p.value === platform);
        return (
          <Space>
            <span style={{ fontSize: '18px' }}>{platformInfo?.icon}</span>
            <span>{platformInfo?.label || platform}</span>
          </Space>
        );
      }
    },
    {
      title: '账户别名',
      dataIndex: 'account_alias',
      key: 'account_alias'
    },
    {
      title: '状态',
      dataIndex: 'is_valid',
      key: 'is_valid',
      render: (isValid) => (
        <Tag color={isValid ? 'success' : 'error'}>
          {isValid ? '有效' : '无效'}
        </Tag>
      )
    },
    {
      title: '最后检查时间',
      dataIndex: 'last_checked_at',
      key: 'last_checked_at',
      render: (time) => time ? new Date(time).toLocaleString() : '未检查'
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (time) => new Date(time).toLocaleString()
    },
    {
      title: '操作',
      key: 'action',
      width: 250,
      render: (_, record) => (
        <Space size="small">
          <Button 
            type="link" 
            icon={<EditOutlined />} 
            onClick={() => handleEdit(record)}
          >
            编辑
          </Button>
          <Button 
            type="link" 
            icon={<CheckOutlined />} 
            onClick={() => handleTest(record.id)}
          >
            测试
          </Button>
          <Popconfirm
            title="确定要删除这个平台配置吗？"
            onConfirm={() => handleDelete(record.id)}
            okText="确定"
            cancelText="取消"
          >
            <Button 
              type="link" 
              danger 
              icon={<DeleteOutlined />}
            >
              删除
            </Button>
          </Popconfirm>
        </Space>
      )
    }
  ];

  // 获取平台配置列表
  const fetchPlatforms = async () => {
    try {
      setLoading(true);
      const response = await apiService.config.getPlatformCookies();
      setPlatforms(response.data || []);
    } catch (error) {
      console.error('获取平台配置失败:', error);
      message.error('获取平台配置失败');
    } finally {
      setLoading(false);
    }
  };

  // 添加平台配置
  const handleAdd = () => {
    setCurrentPlatform(null);
    setModalTitle('添加平台账户');
    form.resetFields();
    setSelectedPlatform('');
    setAutoFetchMessage('');
    setModalVisible(true);
  };

  // 平台选择变化
  const handlePlatformChange = (value) => {
    setSelectedPlatform(value);
  };

  // 编辑平台配置
  const handleEdit = (platform) => {
    setCurrentPlatform(platform);
    setModalTitle('编辑平台账户');
    form.setFieldsValue({
      platform: platform.platform,
      account_alias: platform.account_alias,
      cookies: '' // 不显示现有Cookie，需要重新输入
    });
    setModalVisible(true);
  };

  // 删除平台配置
  const handleDelete = async (id) => {
    try {
      await apiService.config.deletePlatformCookie(id);
      message.success('删除成功');
      fetchPlatforms();
    } catch (error) {
      console.error('删除失败:', error);
      message.error('删除失败');
    }
  };

  // 测试平台配置
  const handleTest = async (id) => {
    try {
      const response = await apiService.config.testPlatformCookie(id);
      if (response.success) {
        message.success('Cookie有效');
      } else {
        message.error('Cookie无效');
      }
      fetchPlatforms(); // 刷新列表以更新状态
    } catch (error) {
      console.error('测试失败:', error);
      message.error('测试失败');
    }
  };

  // 提交表单
  const handleSubmit = async (values) => {
    try {
      if (currentPlatform) {
        // 更新
        await apiService.config.updatePlatformCookie(currentPlatform.id, values);
        message.success('更新成功');
      } else {
        // 创建
        await apiService.config.createPlatformCookie(values);
        message.success('添加成功');
      }
      setModalVisible(false);
      fetchPlatforms();
    } catch (error) {
      console.error('操作失败:', error);
      message.error('操作失败');
    }
  };

  // 取消操作
  const handleCancel = () => {
    setModalVisible(false);
    form.resetFields();
    setCurrentPlatform(null);
    setSelectedPlatform('');
    setAutoFetchMessage('');
  };

  // 自动获取Cookie
  const handleAutoFetch = async () => {
    const platform = selectedPlatform;

    if (!platform) {
      message.warning('请先选择平台');
      return;
    }

    // 检查平台是否支持自动获取
    const supportedPlatforms = ['douyin', 'xiaohongshu'];
    if (!supportedPlatforms.includes(platform)) {
      message.warning(`暂不支持自动获取${platform}的Cookie，请手动获取`);
      return;
    }

    setAutoFetching(true);
    setAutoFetchMessage('正在启动浏览器，请扫码登录（60秒）...');

    try {
      const response = await apiService.config.autoFetchCookie(platform, false);

      console.log('🍪 Cookie获取响应:', response);

      // 检查响应数据结构
      if (response && response.data && response.data.cookie) {
        // 自动填充Cookie到表单
        form.setFieldValue('cookies', response.data.cookie);

        setAutoFetchMessage('');
        message.success(`Cookie获取成功！长度: ${response.data.length} 字符`);
      } else {
        console.error('❌ 响应数据格式不正确:', response);
        setAutoFetchMessage('');
        message.error('Cookie获取失败：返回数据格式不正确');
      }
    } catch (error) {
      console.error('❌ 自动获取Cookie失败:', error);
      setAutoFetchMessage('');
      message.error(`自动获取失败: ${error.message}`);
    } finally {
      setAutoFetching(false);
    }
  };

  useEffect(() => {
    fetchPlatforms();
  }, []);

  return (
    <div style={{ padding: '24px' }}>
      <Card>
        <div style={{ marginBottom: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <Title level={4} style={{ margin: 0 }}>
              <KeyOutlined style={{ marginRight: '8px' }} />
              平台账户配置
            </Title>
            <Text type="secondary" style={{ marginTop: '8px', display: 'block' }}>
              配置各平台的Cookie信息，用于解析需要登录的内容和去除水印
            </Text>
          </div>
          <Button 
            type="primary" 
            icon={<PlusOutlined />} 
            onClick={handleAdd}
          >
            添加平台账户
          </Button>
        </div>

        <Table
          columns={columns}
          dataSource={platforms}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
        />
      </Card>

      {/* 添加/编辑模态框 */}
      <Modal
        title={modalTitle}
        open={modalVisible}
        onCancel={handleCancel}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
        >
          <Form.Item
            name="platform"
            label="平台"
            rules={[{ required: true, message: '请选择平台' }]}
          >
            <Select
              placeholder="选择平台"
              onChange={handlePlatformChange}
            >
              {supportedPlatforms.map(platform => (
                <Option key={platform.value} value={platform.value}>
                  <Space>
                    <span style={{ fontSize: '16px' }}>{platform.icon}</span>
                    {platform.label}
                  </Space>
                </Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="account_alias"
            label="账户别名"
            rules={[{ required: true, message: '请输入账户别名' }]}
          >
            <Input placeholder="例如：主账号、测试账号等" />
          </Form.Item>

          <Form.Item
            name="cookies"
            label="Cookie"
            rules={[{ required: true, message: '请输入Cookie' }]}
          >
            <TextArea
              rows={6}
              placeholder="请输入完整的Cookie字符串，格式如：name1=value1; name2=value2; ..."
              disabled={autoFetching}
            />
          </Form.Item>

          {/* 自动获取Cookie提示 */}
          {selectedPlatform && ['douyin', 'xiaohongshu'].includes(selectedPlatform) && (
            <Alert
              message={
                <div>
                  <p style={{ margin: 0 }}>
                    <strong>💡 快捷方式：</strong>
                    支持"一键获取Cookie"功能，点击下方按钮自动打开浏览器获取Cookie
                  </p>
                  {autoFetchMessage && (
                    <p style={{ margin: '8px 0 0 0', color: '#1890ff' }}>
                      <LoadingOutlined /> {autoFetchMessage}
                    </p>
                  )}
                </div>
              }
              type="info"
              showIcon
              style={{ marginBottom: '16px' }}
            />
          )}

          {/* 自动获取按钮 */}
          {selectedPlatform && ['douyin', 'xiaohongshu'].includes(selectedPlatform) && (
            <Button
              type="dashed"
              icon={autoFetching ? <LoadingOutlined /> : <ThunderboltOutlined />}
              onClick={handleAutoFetch}
              loading={autoFetching}
              block
              style={{ marginBottom: '16px' }}
            >
              {autoFetching ? '正在获取Cookie...' : '一键获取Cookie'}
            </Button>
          )}

          <div style={{ marginTop: '24px', textAlign: 'right' }}>
            <Space>
              <Button onClick={handleCancel}>
                取消
              </Button>
              <Button type="primary" htmlType="submit">
                {currentPlatform ? '更新' : '添加'}
              </Button>
            </Space>
          </div>
        </Form>

        {/* Cookie获取说明 */}
        <Card 
          size="small" 
          title="Cookie获取方法" 
          style={{ marginTop: '16px', backgroundColor: '#f6f8fa' }}
        >
          <div style={{ fontSize: '12px', color: '#666' }}>
            <p><strong>1. 打开浏览器开发者工具（F12）</strong></p>
            <p><strong>2. 切换到 Network（网络）标签</strong></p>
            <p><strong>3. 登录对应平台并刷新页面</strong></p>
            <p><strong>4. 找到任意请求，查看 Request Headers</strong></p>
            <p><strong>5. 复制 Cookie 字段的完整值</strong></p>
            <p style={{ color: '#ff4d4f', marginTop: '8px' }}>
              ⚠️ 注意：Cookie包含敏感信息，请妥善保管，定期更新
            </p>
          </div>
        </Card>
      </Modal>
    </div>
  );
};

export default PlatformConfig;
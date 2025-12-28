/**
 * AI配置页面
 *
 * 管理AI API配置，包括Ollama本地部署和第三方API配置
 */

import { useState, useEffect } from 'react';
import {
  App,
  Card,
  Typography,
  Space,
  Form,
  Input,
  AutoComplete,
  Button,
  Table,
  Modal,
  message,
  Select,
  Switch,
  Divider,
  Tag,
  Spin,
  Alert,
  Tooltip,
  InputNumber,
  Row,
  Col,
  Collapse,
  Descriptions,
  Badge,
  Upload
} from 'antd';
import {
  RobotOutlined,
  ApiOutlined,
  SettingOutlined,
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  CheckOutlined,
  CloseOutlined,
  InfoCircleOutlined,
  ThunderboltOutlined,
  CloudServerOutlined,
  DesktopOutlined,
  KeyOutlined,
  CopyOutlined,
  HistoryOutlined,
  DownloadOutlined,
  UploadOutlined
} from '@ant-design/icons';
import apiService from '../services/api';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;

const AiConfig = () => {
  const { token } = App.useApp();

  // 状态管理
  const [configs, setConfigs] = useState([]);
  const [providers, setProviders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalVisible, setModalVisible] = useState(false);
  const [testingConnection, setTestingConnection] = useState(false);
  const [form] = Form.useForm();
  const [currentConfig, setCurrentConfig] = useState(null);
  const [modalTitle, setModalTitle] = useState('添加AI配置');
  const [ OllamaInstallVisible, setOllamaInstallVisible] = useState(false);
  const [keySecurityStatus, setKeySecurityStatus] = useState(null);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);
  const [testHistoryVisible, setTestHistoryVisible] = useState(false);
  const [testHistory, setTestHistory] = useState([]);

  // 获取AI配置列表
  const fetchConfigs = async () => {
    try {
      setLoading(true);
      const response = await apiService.aiConfig.getConfigs();
      if (response.success) {
        setConfigs(response.data || []);
      }
    } catch (error) {
      console.error('获取AI配置失败:', error);
      message.error(error.message || '获取AI配置失败');
    } finally {
      setLoading(false);
    }
  };

  // 获取提供商列表
  const fetchProviders = async () => {
    try {
      const response = await apiService.aiConfig.getProviders();
      if (response.success) {
        setProviders(response.data || []);
      }
    } catch (error) {
      console.error('获取提供商列表失败:', error);
    }
  };

  // 检查密钥安全状态
  const checkKeySecurity = async () => {
    try {
      const response = await apiService.aiConfig.getKeyStatus();
      if (response.success) {
        setKeySecurityStatus(response.data);
      }
    } catch (error) {
      console.error('获取密钥安全状态失败:', error);
      // 非管理员用户可能没有权限访问这个API
    }
  };

  // 初始化
  useEffect(() => {
    fetchConfigs();
    fetchProviders();
    checkKeySecurity();
  }, []);

  // 获取提供商信息
  const getProviderInfo = (providerId) => {
    return providers.find(p => p.id === providerId) || {};
  };

  // 获取启用的配置
  const enabledConfig = configs.find(c => c.is_enabled);
  const enabledProviderInfo = getProviderInfo(enabledConfig?.provider);

  // 表格列定义
  const columns = [
    {
      title: '状态',
      dataIndex: 'is_enabled',
      key: 'is_enabled',
      width: 80,
      render: (enabled) => (
        <Badge status={enabled ? 'success' : 'default'} text={enabled ? '启用' : '禁用'} />
      )
    },
    {
      title: '提供商',
      dataIndex: 'provider',
      key: 'provider',
      width: 150,
      render: (provider) => {
        const info = getProviderInfo(provider);
        return (
          <Space>
            {provider === 'ollama' && <DesktopOutlined />}
            {provider === 'openai' && <CloudServerOutlined />}
            {provider === 'anthropic' && <CloudServerOutlined />}
            {provider === 'custom' && <ApiOutlined />}
            <span>{info.name || provider}</span>
          </Space>
        );
      }
    },
    {
      title: '模型',
      dataIndex: 'model',
      key: 'model',
      width: 150,
      render: (model, record) => {
        const info = getProviderInfo(record.provider);
        const recommendedModel = info.recommendedModels?.find(m => m.name === model);
        return (
          <Space direction="vertical" size={0}>
            <span>{model || '-'}</span>
            {recommendedModel && (
              <Text type="secondary" style={{ fontSize: 12 }}>
                {recommendedModel.description}
              </Text>
            )}
          </Space>
        );
      }
    },
    {
      title: 'API端点',
      dataIndex: 'api_endpoint',
      key: 'api_endpoint',
      ellipsis: true,
      render: (endpoint) => endpoint || '-'
    },
    {
      title: '优先级',
      dataIndex: 'priority',
      key: 'priority',
      width: 80,
      sorter: (a, b) => a.priority - b.priority
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status) => {
        const colors = {
          active: 'success',
          inactive: 'default',
          testing: 'processing'
        };
        const labels = {
          active: '活跃',
          inactive: '停用',
          testing: '测试中'
        };
        return <Tag color={colors[status] || 'default'}>{labels[status] || status}</Tag>;
      }
    },
    {
      title: '最后测试',
      dataIndex: 'last_test_at',
      key: 'last_test_at',
      width: 150,
      render: (time) => time ? new Date(time).toLocaleString() : '未测试'
    },
    {
      title: '操作',
      key: 'action',
      width: 300,
      render: (_, record) => (
        <Space size="small" wrap>
          <Button
            type="link"
            icon={<CheckOutlined />}
            onClick={() => handleToggleEnable(record)}
          >
            {record.is_enabled ? '禁用' : '启用'}
          </Button>
          <Button type="link" icon={<EditOutlined />} onClick={() => handleEdit(record)}>编辑</Button>
          <Button type="link" icon={<CopyOutlined />} onClick={() => handleCopyConfig(record)}>复制</Button>
          <Button type="link" icon={<ThunderboltOutlined />} onClick={() => handleTest(record)}>测试</Button>
          <Button type="link" icon={<HistoryOutlined />} onClick={() => handleViewTestHistory(record.id)}>历史</Button>
          <Button type="link" danger icon={<DeleteOutlined />} onClick={() => handleDelete(record.id)}>删除</Button>
        </Space>
      )
    }
  ];

  // 添加配置
  const handleAdd = () => {
    setCurrentConfig(null);
    setModalTitle('添加AI配置');
    form.resetFields();
    form.setFieldsValue({
      provider: 'ollama',
      is_enabled: true,
      timeout: 60000,
      priority: configs.length
    });
    setModalVisible(true);
  };

  // 编辑配置
  const handleEdit = (config) => {
    setCurrentConfig(config);
    setModalTitle('编辑AI配置');
    form.setFieldsValue({
      provider: config.provider,
      api_endpoint: config.api_endpoint,
      api_key: '', // 不显示已加密的密钥
      model: config.model,
      timeout: config.timeout,
      is_enabled: config.is_enabled,
      priority: config.priority,
      preferences: config.preferences ? JSON.stringify(config.preferences, null, 2) : ''
    });
    setModalVisible(true);
  };

  // 删除配置
  const handleDelete = async (id) => {
    try {
      await Modal.confirm({
        title: '确认删除',
        content: '确定要删除此AI配置吗？此操作不可恢复。',
        okText: '确认删除',
        okType: 'danger',
        cancelText: '取消',
      });

      const response = await apiService.aiConfig.deleteConfig(id);
      if (response.success) {
        message.success('删除成功');
        fetchConfigs();
      } else {
        message.error(response.message || '删除失败');
      }
    } catch (error) {
      if (error !== 'cancel') {
        console.error('删除配置失败:', error);
        message.error(error.message || '删除失败');
      }
    }
  };

  // 切换启用状态
  const handleToggleEnable = async (config) => {
    try {
      const response = await apiService.aiConfig.updateConfig(config.id, {
        is_enabled: !config.is_enabled
      });

      if (response.success) {
        message.success(config.is_enabled ? '已禁用' : '已启用');
        fetchConfigs();
      } else {
        message.error(response.message || '操作失败');
      }
    } catch (error) {
      console.error('切换启用状态失败:', error);
      message.error(error.message || '操作失败');
    }
  };

  // 测试连接
  const handleTest = async (config) => {
    try {
      setTestingConnection(true);
      message.loading('正在测试连接...', 0);

      const response = await apiService.aiConfig.testConnection(config.id);

      message.destroy();

      if (response.success) {
        message.success(response.message || '连接成功');
      } else {
        message.warning(response.message || '连接失败');
      }
    } catch (error) {
      message.destroy();
      console.error('测试连接失败:', error);
      message.error(error.message || '测试连接失败');
    } finally {
      setTestingConnection(false);
    }
  };

  // 保存配置
  const handleSave = async (values) => {
    try {
      const data = {
        provider: values.provider,
        api_endpoint: values.api_endpoint,
        api_key: values.api_key,
        model: values.model,
        timeout: values.timeout,
        is_enabled: values.is_enabled,
        priority: values.priority,
        preferences: values.preferences ? JSON.parse(values.preferences) : null
      };

      console.log('准备保存配置:', data);

      let response;
      if (currentConfig) {
        response = await apiService.aiConfig.updateConfig(currentConfig.id, data);
      } else {
        response = await apiService.aiConfig.createConfig(data);
      }

      console.log('后端响应:', response);

      if (response.success) {
        message.success(currentConfig ? '更新成功' : '添加成功');
        setModalVisible(false);
        fetchConfigs();
      } else {
        // 显示详细的错误信息
        console.log('保存失败，错误信息:', response);
        if (response.errors && Array.isArray(response.errors)) {
          Modal.error({
            title: '配置验证失败',
            content: (
              <div>
                <p>请检查以下错误：</p>
                <ul>
                  {response.errors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              </div>
            ),
          });
        } else {
          message.error(response.message || '保存失败');
        }
      }
    } catch (error) {
      console.error('保存配置失败:', error);
      message.error(error.message || '保存失败');
    }
  };

  // 导出配置
  const handleExportConfig = async (config) => {
    try {
      const response = await apiService.aiConfig.exportConfig(config.id);

      if (response.success) {
        const exportData = response.data;

        // 创建并下载文件
        const blob = new Blob([JSON.stringify(exportData, null, 2)], {
          type: 'application/json'
        });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `ai-config-${config.provider}-${config.id}.json`;
        a.click();
        URL.revokeObjectURL(url);

        message.success('配置导出成功');
      } else {
        message.error(response.message || '导出失败');
      }
    } catch (error) {
      console.error('导出配置失败:', error);
      message.error(error.message || '导出失败');
    }
  };

  // 导入配置
  const handleImportConfig = async (file) => {
    try {
      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          const config = JSON.parse(e.target.result);

          // 发送到后端验证并导入
          const response = await apiService.aiConfig.importConfig(config);

          if (response.success) {
            message.success('配置导入成功');
            fetchConfigs();
          } else {
            message.error(response.message || '配置导入失败');
          }
        } catch (parseError) {
          message.error('配置文件格式不正确');
        }
      };
      reader.readAsText(file);
    } catch (error) {
      console.error('导入配置失败:', error);
      message.error('导入失败');
    }

    return false; // 阻止自动上传
  };

  // 批量启用/禁用
  const handleBatchToggleEnable = async (isEnabled) => {
    try {
      const response = await apiService.aiConfig.batchUpdate({
        config_ids: selectedRowKeys,
        is_enabled: isEnabled
      });

      if (response.success) {
        message.success(`批量${isEnabled ? '启用' : '禁用'}成功`);
        setSelectedRowKeys([]);
        fetchConfigs();
      } else {
        message.error(response.message || '批量操作失败');
      }
    } catch (error) {
      console.error('批量操作失败:', error);
      message.error(error.message || '批量操作失败');
    }
  };

  // 批量删除
  const handleBatchDelete = async () => {
    try {
      await Modal.confirm({
        title: '确认批量删除',
        content: `确定要删除选中的${selectedRowKeys.length}个配置吗？此操作不可恢复。`,
        okText: '确认删除',
        okType: 'danger',
        cancelText: '取消',
      });

      const response = await apiService.aiConfig.batchDelete({
        data: { config_ids: selectedRowKeys }
      });

      if (response.success) {
        message.success('批量删除成功');
        setSelectedRowKeys([]);
        fetchConfigs();
      } else {
        message.error(response.message || '批量删除失败');
      }
    } catch (error) {
      if (error !== 'cancel') {
        console.error('批量删除失败:', error);
        message.error(error.message || '批量删除失败');
      }
    }
  };

  // 复制配置
  const handleCopyConfig = async (config) => {
    try {
      const response = await apiService.aiConfig.copyConfig(config.id);

      if (response.success) {
        message.success('配置复制成功，请重新设置API密钥');
        fetchConfigs();
      } else {
        message.error(response.message || '配置复制失败');
      }
    } catch (error) {
      console.error('配置复制失败:', error);
      message.error(error.message || '配置复制失败');
    }
  };

  // 查看测试历史
  const handleViewTestHistory = async (configId) => {
    try {
      const response = await apiService.aiConfig.getTestHistory(configId);

      if (response.success) {
        setTestHistory(response.data || []);
        setTestHistoryVisible(true);
      } else {
        message.error(response.message || '获取测试历史失败');
      }
    } catch (error) {
      console.error('获取测试历史失败:', error);
      message.error(error.message || '获取测试历史失败');
    }
  };

  // 获取模型选项
  const getModelOptions = () => {
    const provider = form.getFieldValue('provider');
    const info = getProviderInfo(provider);

    if (info.recommendedModels) {
      return info.recommendedModels.map(m => ({
        value: m.name,
        label: (
          <Space>
            <span>{m.name}</span>
            {m.memory && <Text type="secondary" style={{ fontSize: 12 }}>({m.memory})</Text>}
            {m.cost && <Text type="secondary" style={{ fontSize: 12 }}>- {m.cost}</Text>}
          </Space>
        )
      }));
    }

    return [];
  };

  // 获取占位符
  const getEndpointPlaceholder = () => {
    const provider = form.getFieldValue('provider');
    const info = getProviderInfo(provider);
    return info.defaultEndpoint || '请输入API端点';
  };

  return (
    <Space direction="vertical" size="large" style={{ width: '100%' }}>
      {/* 密钥安全警告 */}
      {keySecurityStatus?.using_default_key && (
        <Alert
          type="error"
          showIcon
          banner
          closable
          message="安全警告"
          description={
            <Space direction="vertical" size={0}>
              <Text>检测到系统正在使用默认加密密钥，这可能导致API密钥泄露风险。</Text>
              <Text strong>请立即采取以下措施：</Text>
              <ul style={{ margin: '8px 0', paddingLeft: 20 }}>
                <li>在后端 .env 文件中设置 ENCRYPTION_KEY 环境变量</li>
                <li>使用强密钥（建议32字符以上，包含大小写字母、数字和特殊字符）</li>
                <li>重启后端服务使配置生效</li>
              </ul>
              <Text type="secondary">生成密钥命令: openssl rand -hex 32</Text>
            </Space>
          }
          style={{ marginBottom: 0 }}
        />
      )}

      {/* 当前配置状态 */}
      <Card title={<Space><RobotOutlined /> AI配置状态</Space>}>
        {enabledConfig ? (
          <Alert
            type="success"
            showIcon
            message={`当前启用: ${enabledProviderInfo.name || enabledConfig.provider}`}
            description={
              <Descriptions size="small" column={2} style={{ marginTop: 8 }}>
                <Descriptions.Item label="模型">{enabledConfig.model || '-'}</Descriptions.Item>
                <Descriptions.Item label="API端点">{enabledConfig.api_endpoint || '-'}</Descriptions.Item>
                <Descriptions.Item label="优先级">{enabledConfig.priority}</Descriptions.Item>
                <Descriptions.Item label="状态">
                  <Tag color="green">{enabledConfig.status}</Tag>
                </Descriptions.Item>
              </Descriptions>
            }
            action={
              <Button size="small" onClick={() => handleEdit(enabledConfig)}>
                查看详情
              </Button>
            }
          />
        ) : (
          <Alert
            type="warning"
            showIcon
            message="未配置AI服务"
            description="请添加AI配置以启用内容自动标签生成功能。推荐使用本地Ollama部署，完全免费且数据安全。"
            action={
              <Button type="primary" size="small" onClick={handleAdd}>
                添加配置
              </Button>
            }
          />
        )}
      </Card>

      {/* 配置列表 */}
      <Card
        title={<Space><SettingOutlined /> AI配置列表</Space>}
        extra={
          <Space>
            {selectedRowKeys.length > 0 && (
              <>
                <Button
                  icon={<CheckOutlined />}
                  onClick={() => handleBatchToggleEnable(true)}
                >
                  批量启用
                </Button>
                <Button
                  icon={<CloseOutlined />}
                  onClick={() => handleBatchToggleEnable(false)}
                >
                  批量禁用
                </Button>
                <Button
                  danger
                  icon={<DeleteOutlined />}
                  onClick={handleBatchDelete}
                >
                  批量删除
                </Button>
                <Divider type="vertical" />
              </>
            )}
            <Upload
              accept=".json"
              showUploadList={false}
              beforeUpload={handleImportConfig}
            >
              <Button icon={<UploadOutlined />}>导入配置</Button>
            </Upload>
            <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd}>
              添加配置
            </Button>
          </Space>
        }
      >
        <Table
          dataSource={configs}
          columns={columns}
          rowKey="id"
          loading={loading}
          rowSelection={{
            selectedRowKeys,
            onChange: (selectedKeys) => setSelectedRowKeys(selectedKeys),
          }}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条配置`
          }}
        />
      </Card>

      {/* 添加/编辑配置弹窗 */}
      <Modal
        title={modalTitle}
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        footer={null}
        width={700}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSave}
          initialValues={{
            provider: 'ollama',
            is_enabled: true,
            timeout: 60000,
            priority: configs.length
          }}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="provider"
                label="AI服务提供商"
                rules={[{ required: true, message: '请选择提供商' }]}
              >
                <Select
                  placeholder="选择AI服务提供商"
                  options={providers.map(p => ({
                    value: p.id,
                    label: (
                      <Space>
                        {p.id === 'ollama' && <DesktopOutlined />}
                        {p.id === 'openai' && <CloudServerOutlined />}
                        {p.id === 'anthropic' && <CloudServerOutlined />}
                        {p.id === 'custom' && <ApiOutlined />}
                        <span>{p.name}</span>
                      </Space>
                    )
                  }))}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="is_enabled"
                label="启用状态"
                valuePropName="checked"
              >
                <Switch checkedChildren="启用" unCheckedChildren="禁用" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item noStyle shouldUpdate>
            {() => {
              const provider = form.getFieldValue('provider');
              const providerInfo = getProviderInfo(provider);

              return (
                <Alert
                  type="info"
                  showIcon
                  message={providerInfo.name}
                  description={providerInfo.description}
                  style={{ marginBottom: 16 }}
                />
              );
            }}
          </Form.Item>

          <Form.Item
            name="api_endpoint"
            label="API端点"
            tooltip={getProviderInfo(form.getFieldValue('provider')).requiresEndpoint === false ? '此提供商使用默认端点' : undefined}
            rules={[{ required: !getProviderInfo(form.getFieldValue('provider')).requiresEndpoint === false, message: '请输入API端点' }]}
          >
            <Input
              placeholder={getEndpointPlaceholder()}
              prefix={<ApiOutlined />}
            />
          </Form.Item>

          <Form.Item
            noStyle
            shouldUpdate={(prevValues, currentValues) =>
              prevValues.provider !== currentValues.provider ||
              prevValues.api_endpoint !== currentValues.api_endpoint
            }
          >
            {({ getFieldValue }) => {
              const provider = getFieldValue('provider');
              const requiresApiKey = getProviderInfo(provider).requiresApiKey;

              return requiresApiKey && (
                <Form.Item
                  name="api_key"
                  label="API密钥"
                  rules={[{ required: true, message: '请输入API密钥' }]}
                  extra="密钥将加密存储，不会显示在列表中"
                >
                  <Input.Password
                    placeholder="请输入API密钥"
                    prefix={<KeyOutlined />}
                  />
                </Form.Item>
              );
            }}
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="model"
                label="模型名称"
                tooltip="可以从推荐列表选择，或直接手动输入模型名称"
              >
                <AutoComplete
                  placeholder="选择或输入模型名称"
                  allowClear
                  options={getModelOptions()}
                  filterOption={(input, option) =>
                    (option?.value ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="timeout"
                label="超时时间（毫秒）"
              >
                <InputNumber
                  style={{ width: '100%' }}
                  min={5000}
                  max={300000}
                  step={5000}
                  formatter={(value) => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="priority"
                label="优先级"
                tooltip="数值越小优先级越高"
              >
                <InputNumber style={{ width: '100%' }} min={0} max={100} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                noStyle
                shouldUpdate={(prevValues, currentValues) =>
                  prevValues.provider !== currentValues.provider
                }
              >
                {({ getFieldValue }) => {
                  const provider = getFieldValue('provider');
                  if (provider === 'ollama') {
                    return (
                      <Form.Item label=" ">
                        <Button
                          type="link"
                          onClick={() => setOllamaInstallVisible(true)}
                        >
                          查看Ollama安装指南
                        </Button>
                      </Form.Item>
                    );
                  }
                  return null;
                }}
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="preferences"
            label="高级设置（JSON格式）"
            tooltip="可选，包含温度、最大token数等参数"
          >
            <TextArea
              rows={4}
              placeholder={`{
  "temperature": 0.7,
  "max_tokens": 1000
}`}
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 0, textAlign: 'right' }}>
            <Space>
              <Button onClick={() => setModalVisible(false)}>取消</Button>
              <Button
                type="primary"
                htmlType="submit"
                loading={testingConnection}
                icon={<CheckOutlined />}
              >
                保存
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* Ollama安装指南弹窗 */}
      <Modal
        title="Ollama安装指南"
        open={OllamaInstallVisible}
        onCancel={() => setOllamaInstallVisible(false)}
        footer={[
          <Button key="close" onClick={() => setOllamaInstallVisible(false)}>
            关闭
          </Button>,
          <Button
            key="install"
            type="primary"
            onClick={() => {
              window.open('https://ollama.ai', '_blank');
            }}
          >
            访问官网
          </Button>
        ]}
        width={600}
      >
        <Collapse
          defaultActiveKey={['1', '2']}
          items={[
            {
              key: '1',
              label: '1. 安装Ollama',
              children: (
                <div>
                  <p>macOS/Linux:</p>
                  <pre style={{ background: '#f5f5f5', padding: 12, borderRadius: 4 }}>
{`curl -fsSL https://ollama.ai/install.sh | sh`}
                  </pre>
                  <p>Windows: 下载安装包 from https://ollama.ai</p>
                </div>
              )
            },
            {
              key: '2',
              label: '2. 下载AI模型',
              children: (
                <div>
                  <p>推荐模型：</p>
                  <ul>
                    <li><code>ollama pull qwen2.5:7b</code> - 通用标签生成（推荐，需要约8GB内存）</li>
                    <li><code>ollama pull llama3.2:3b</code> - 资源受限环境（约4GB内存）</li>
                    <li><code>ollama pull deepseek-r1:8b</code> - 推理能力强（约10GB内存）</li>
                    <li><code>ollama pull gemma3:4b</code> - 多语言支持（约6GB内存）</li>
                  </ul>
                </div>
              )
            },
            {
              key: '3',
              label: '3. 启动Ollama服务',
              children: (
                <pre style={{ background: '#f5f5f5', padding: 12, borderRadius: 4 }}>
{`# 启动服务（默认监听 http://localhost:11434）
ollama serve

# 或在后台运行
nohup ollama serve > ollama.log 2>&1 &`}
                </pre>
              )
            },
            {
              key: '4',
              label: '4. 验证安装',
              children: (
                <pre style={{ background: '#f5f5f5', padding: 12, borderRadius: 4 }}>
{`# 查看已下载的模型
curl http://localhost:11434/api/tags

# 测试模型响应
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "Hello"
}'`}
                </pre>
              )
            }
          ]}
        />
      </Modal>

      {/* 测试历史Modal */}
      <Modal
        title="测试历史"
        open={testHistoryVisible}
        onCancel={() => setTestHistoryVisible(false)}
        footer={[
          <Button key="close" onClick={() => setTestHistoryVisible(false)}>
            关闭
          </Button>
        ]}
        width={800}
      >
        <Table
          dataSource={testHistory}
          columns={[
            {
              title: '测试时间',
              dataIndex: 'created_at',
              render: (t) => new Date(t).toLocaleString(),
              width: 180
            },
            {
              title: '结果',
              dataIndex: 'test_result',
              render: (r) => (
                <Tag color={r ? 'success' : 'error'}>
                  {r ? '成功' : '失败'}
                </Tag>
              ),
              width: 80
            },
            {
              title: '响应时间',
              dataIndex: 'response_time',
              render: (t) => t ? `${t}ms` : '-',
              width: 100
            },
            {
              title: '错误信息',
              dataIndex: 'error_message',
              ellipsis: true
            }
          ]}
          rowKey="id"
          pagination={{
            pageSize: 10,
            showSizeChanger: true
          }}
          size="small"
        />
      </Modal>
    </Space>
  );
};

export default AiConfig;

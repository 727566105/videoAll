import { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Radio, Space, Tag, Popconfirm, message, Card, Statistic, Row, Col } from 'antd';
import { TagsOutlined, PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import apiService from '../services/api';

// 预设颜色
const PREDEFINED_COLORS = [
  '#f50', '#faad14', '#52c41a', '#1890ff',
  '#722ed1', '#eb2f96', '#fa8c16', '#a0d911',
  '#13c2c2', '#2f54eb', '#f759ab', '#9254de'
];

const TagManagement = () => {
  const [tags, setTags] = useState([]);
  const [loading, setLoading] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [editingTag, setEditingTag] = useState(null);
  const [searchText, setSearchText] = useState('');
  const [selectedColor, setSelectedColor] = useState(PREDEFINED_COLORS[0]);
  const [form] = Form.useForm();

  // 获取当前用户信息
  const currentUser = JSON.parse(localStorage.getItem('user'));
  const isAdmin = currentUser?.role === 'admin';

  // 获取所有标签
  const fetchTags = async () => {
    try {
      setLoading(true);
      const response = await apiService.tags.getAll();
      if (response && response.data) {
        setTags(response.data);
      }
    } catch (error) {
      console.error('获取标签失败:', error);
      message.error('获取标签失败');
    } finally {
      setLoading(false);
    }
  };

  // 组件挂载时获取标签
  useEffect(() => {
    fetchTags();
  }, []);

  // 打开创建标签 Modal
  const handleCreate = () => {
    setEditingTag(null);
    setSelectedColor(PREDEFINED_COLORS[0]);
    form.resetFields();
    form.setFieldsValue({ color: PREDEFINED_COLORS[0] });
    setModalVisible(true);
  };

  // 打开编辑标签 Modal
  const handleEdit = (tag) => {
    setEditingTag(tag);
    setSelectedColor(tag.color);
    form.setFieldsValue({
      name: tag.name,
      color: tag.color,
      description: tag.description || ''
    });
    setModalVisible(true);
  };

  // 删除标签
  const handleDelete = async (id) => {
    try {
      setLoading(true);
      await apiService.tags.delete(id);
      message.success('删除成功');
      fetchTags();
    } catch (error) {
      console.error('删除标签失败:', error);
      message.error(error.response?.data?.message || '删除失败');
    } finally {
      setLoading(false);
    }
  };

  // 提交表单
  const handleSubmit = async (values) => {
    try {
      setModalLoading(true);
      if (editingTag) {
        // 更新标签
        await apiService.tags.update(editingTag.id, values);
        message.success('更新成功');
      } else {
        // 创建标签
        await apiService.tags.create(values);
        message.success('创建成功');
      }
      setModalVisible(false);
      fetchTags();
    } catch (error) {
      console.error('提交失败:', error);
      message.error(error.response?.data?.message || (editingTag ? '更新失败' : '创建失败'));
    } finally {
      setModalLoading(false);
    }
  };

  // 过滤标签
  const filteredTags = tags.filter(tag =>
    tag.name.toLowerCase().includes(searchText.toLowerCase())
  );

  // 计算统计数据
  const totalTags = tags.length;
  const totalUsage = tags.reduce((sum, tag) => sum + (tag.usage_count || 0), 0);
  const avgUsage = totalTags > 0 ? Math.round(totalUsage / totalTags) : 0;

  // 表格列定义
  const columns = [
    {
      title: '预览',
      dataIndex: 'name',
      key: 'preview',
      width: 120,
      render: (name, record) => (
        <Tag color={record.color}>{name}</Tag>
      )
    },
    {
      title: '名称',
      dataIndex: 'name',
      key: 'name',
      sorter: (a, b) => a.name.localeCompare(b.name)
    },
    {
      title: '描述',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
      render: (text) => text || '-'
    },
    {
      title: '使用次数',
      dataIndex: 'usage_count',
      key: 'usage_count',
      width: 120,
      sorter: (a, b) => (a.usage_count || 0) - (b.usage_count || 0),
      defaultSortOrder: 'descend'
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 180,
      sorter: (a, b) => new Date(a.created_at) - new Date(b.created_at),
      render: (text) => new Date(text).toLocaleString('zh-CN')
    },
    {
      title: '操作',
      key: 'action',
      width: 180,
      fixed: 'right',
      render: (_, record) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          >
            编辑
          </Button>
          {isAdmin && (
            <Popconfirm
              title={`确定删除标签"${record.name}"吗？该操作不会影响已关联的内容。`}
              onConfirm={() => handleDelete(record.id)}
              okText="确定"
              cancelText="取消"
            >
              <Button type="link" danger icon={<DeleteOutlined />}>
                删除
              </Button>
            </Popconfirm>
          )}
        </Space>
      )
    }
  ];

  return (
    <div style={{ padding: '24px' }}>
      {/* 页面标题 */}
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 600, margin: 0 }}>
          <TagsOutlined style={{ marginRight: '8px' }} />
          标签管理
        </h1>
        <p style={{ color: '#666', marginTop: '8px' }}>
          创建和管理内容标签，用于分类和组织您的内容
        </p>
      </div>

      {/* 统计卡片 */}
      <Row gutter={16} style={{ marginBottom: '24px' }}>
        <Col span={8}>
          <Card>
            <Statistic
              title="标签总数"
              value={totalTags}
              suffix="个"
              styles={{ content: { color: '#1890ff' } }}
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="总使用次数"
              value={totalUsage}
              suffix="次"
              styles={{ content: { color: '#52c41a' } }}
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="平均使用率"
              value={avgUsage}
              suffix="次/标签"
              styles={{ content: { color: '#faad14' } }}
            />
          </Card>
        </Col>
      </Row>

      {/* 操作栏 */}
      <Card style={{ marginBottom: '16px' }}>
        <Row justify="space-between" align="middle">
          <Col>
            <Input
              placeholder="搜索标签名称"
              prefix={<SearchOutlined />}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              style={{ width: 300 }}
              allowClear
            />
          </Col>
          <Col>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleCreate}
            >
              创建标签
            </Button>
          </Col>
        </Row>
      </Card>

      {/* 标签列表 */}
      <Card>
        <Table
          columns={columns}
          dataSource={filteredTags}
          rowKey="id"
          loading={loading}
          pagination={{
            total: filteredTags.length,
            pageSize: 10,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 个标签`
          }}
          locale={{
            emptyText: searchText ? '未找到匹配的标签' : '暂无标签，点击"创建标签"开始创建'
          }}
        />
      </Card>

      {/* 创建/编辑 Modal */}
      <Modal
        title={
          <Space>
            <TagsOutlined />
            {editingTag ? '编辑标签' : '创建标签'}
          </Space>
        }
        open={modalVisible}
        onCancel={() => {
          setModalVisible(false);
          form.resetFields();
        }}
        footer={null}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{ color: PREDEFINED_COLORS[0] }}
        >
          <Form.Item
            label="标签名称"
            name="name"
            rules={[
              { required: true, message: '请输入标签名称' },
              { max: 50, message: '标签名称最多50个字符' },
              { pattern: /^[^\s]+$/, message: '标签名称不能包含空格' }
            ]}
          >
            <Input
              placeholder="输入标签名称"
              maxLength={50}
              showCount
            />
          </Form.Item>

          <Form.Item
            label="颜色"
            name="color"
            rules={[{ required: true, message: '请选择颜色' }]}
          >
            <Radio.Group
              value={selectedColor}
              onChange={(e) => setSelectedColor(e.target.value)}
            >
              <Space wrap>
                {PREDEFINED_COLORS.map(color => (
                  <Radio.Button
                    key={color}
                    value={color}
                    style={{
                      backgroundColor: color,
                      borderColor: color,
                      color: '#fff',
                      width: 36,
                      height: 36,
                      borderRadius: '50%',
                      padding: 0,
                      minWidth: 'auto'
                    }}
                  >
                    {selectedColor === color && '✓'}
                  </Radio.Button>
                ))}
              </Space>
            </Radio.Group>
          </Form.Item>

          <Form.Item
            label="描述"
            name="description"
            rules={[{ max: 200, message: '描述最多200个字符' }]}
          >
            <Input.TextArea
              placeholder="输入标签描述（可选）"
              maxLength={200}
              rows={3}
              showCount
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 0, textAlign: 'right' }}>
            <Space>
              <Button onClick={() => setModalVisible(false)}>
                取消
              </Button>
              <Button
                type="primary"
                htmlType="submit"
                loading={modalLoading}
              >
                {editingTag ? '保存修改' : '创建标签'}
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default TagManagement;

import { useEffect, useState } from 'react';
import { Modal, Select, Tag, Radio, Space, message, Spin, Alert } from 'antd';
import { TagOutlined } from '@ant-design/icons';
import apiService from '../services/api';

const { Option } = Select;

const BatchTagModal = ({ visible, onCancel, onConfirm, selectedCount }) => {
  const [tags, setTags] = useState([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [operation, setOperation] = useState('add');
  const [selectedTags, setSelectedTags] = useState([]);

  // 获取所有标签
  useEffect(() => {
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

    if (visible) {
      fetchTags();
    }
  }, [visible]);

  // 重置表单
  useEffect(() => {
    if (!visible) {
      setOperation('add');
      setSelectedTags([]);
    }
  }, [visible]);

  // 确认操作
  const handleOk = async () => {
    if (selectedTags.length === 0) {
      message.warning('请选择至少一个标签');
      return;
    }

    try {
      setSubmitting(true);
      await onConfirm({
        operation,
        tag_ids: selectedTags
      });
      // 成功后关闭并重置
      setOperation('add');
      setSelectedTags([]);
    } catch (error) {
      console.error('批量操作失败:', error);
    } finally {
      setSubmitting(false);
    }
  };

  // 操作说明
  const getOperationDescription = () => {
    switch (operation) {
      case 'add':
        return '为选中的内容添加所选标签（保留原有标签）';
      case 'remove':
        return '从选中的内容中移除所选标签';
      case 'replace':
        return '清除选中内容的所有标签，只保留所选标签';
      default:
        return '';
    }
  };

  // 渲染标签选项
  const renderTagOption = (tag) => (
    <Option key={tag.id} value={tag.id}>
      <Space>
        <Tag color={tag.color}>{tag.name}</Tag>
        <span style={{ color: '#999', fontSize: '12px' }}>
          {tag.usage_count || 0} 次
        </span>
      </Space>
    </Option>
  );

  return (
    <Modal
      title={
        <Space>
          <TagOutlined />
          批量标签操作
        </Space>
      }
      open={visible}
      onCancel={onCancel}
      onOk={handleOk}
      confirmLoading={submitting}
      width={600}
      okText="确认操作"
      cancelText="取消"
    >
      <div style={{ marginBottom: '16px' }}>
        <Alert
          message={`已选择 ${selectedCount} 个内容`}
          type="info"
          showIcon
        />
      </div>

      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>
          操作类型
        </label>
        <Radio.Group
          value={operation}
          onChange={(e) => setOperation(e.target.value)}
          style={{ width: '100%' }}
        >
          <Space direction="vertical" style={{ width: '100%' }}>
            <Radio value="add">添加标签</Radio>
            <Radio value="remove">移除标签</Radio>
            <Radio value="replace">替换标签</Radio>
          </Space>
        </Radio.Group>
        <div style={{ marginTop: '8px', fontSize: '12px', color: '#666' }}>
          {getOperationDescription()}
        </div>
      </div>

      <div>
        <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>
          选择标签
        </label>
        {loading ? (
          <div style={{ textAlign: 'center', padding: '20px' }}>
            <Spin size="small" tip="加载标签..." />
          </div>
        ) : (
          <Select
            mode="multiple"
            style={{ width: '100%' }}
            placeholder="选择要操作的标签（可多选）"
            value={selectedTags}
            onChange={setSelectedTags}
            filterOption={(input, option) => {
              const tag = tags.find(t => t.id === option.value);
              return tag && tag.name.toLowerCase().includes(input.toLowerCase());
            }}
            maxTagCount="responsive"
          >
            {tags.map(renderTagOption)}
          </Select>
        )}
      </div>

      {operation === 'replace' && (
        <Alert
          message="替换操作将清除所选内容的所有现有标签，仅保留你选择的标签"
          type="warning"
          showIcon
          style={{ marginTop: '16px' }}
        />
      )}
    </Modal>
  );
};

export default BatchTagModal;

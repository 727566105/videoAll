import { useEffect, useState } from 'react';
import { Select, Tag, Spin, Space } from 'antd';
import { TagsOutlined } from '@ant-design/icons';
import apiService from '../services/api';

const { Option } = Select;

const TagFilter = ({ value, onChange }) => {
  const [tags, setTags] = useState([]);
  const [loading, setLoading] = useState(true);

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
      } finally {
        setLoading(false);
      }
    };

    fetchTags();
  }, []);

  // 渲染标签选项
  const renderTagOption = (tag) => (
    <Option key={tag.id} value={tag.id}>
      <Space>
        <Tag color={tag.color}>{tag.name}</Tag>
        <span style={{ color: '#999', fontSize: '12px' }}>
          {tag.usage_count || 0} 次使用
        </span>
      </Space>
    </Option>
  );

  // 渲染选中的标签
  const renderTagPreview = (tagId) => {
    const tag = tags.find(t => t.id === tagId);
    if (!tag) return tagId;
    return (
      <Tag color={tag.color}>
        {tag.name}
      </Tag>
    );
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '20px' }}>
        <Spin size="small" />
        <div style={{ marginTop: '8px', fontSize: '12px', color: '#999' }}>加载标签...</div>
      </div>
    );
  }

  return (
    <div>
      <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>
        <TagsOutlined style={{ marginRight: '4px' }} />
        标签筛选
      </label>
      <Select
        mode="multiple"
        style={{ width: '100%' }}
        placeholder="选择标签进行筛选（可多选）"
        value={value}
        onChange={onChange}
        allowClear
        filterOption={(input, option) => {
          const tag = tags.find(t => t.id === option.value);
          return tag && tag.name.toLowerCase().includes(input.toLowerCase());
        }}
      >
        {tags.map(renderTagOption)}
      </Select>
      {value && value.length > 0 && (
        <div style={{ marginTop: '8px', fontSize: '12px', color: '#666' }}>
          已选择 {value.length} 个标签
        </div>
      )}
    </div>
  );
};

export default TagFilter;

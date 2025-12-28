import React, { useState, useCallback } from 'react';
import { Modal, Table, Tag, Space, Empty, Spin, message, Button, Typography } from 'antd';
import { FileTextOutlined, LoadingOutlined } from '@ant-design/icons';
import apiService from '../../services/api';

const { Text } = Typography;

const RelatedContentModal = ({ visible, onClose, keyword, platform, platformConfig }) => {
  const [loading, setLoading] = useState(false);
  const [contents, setContents] = useState([]);

  // 平台信息映射
  const getPlatformInfo = (platformKey) => {
    return platformConfig[platformKey] || {
      name: platformKey,
      icon: '📱',
      color: '#1890ff'
    };
  };

  // 获取关联内容
  const fetchRelatedContent = useCallback(async () => {
    if (!keyword || !platform) return;

    try {
      setLoading(true);
      // 调用内容管理API，使用关键词过滤
      const result = await apiService.content.getList({
        keyword,
        platform,
        pageSize: 50
      });

      if (result && result.data) {
        setContents(result.data);
      }
    } catch (error) {
      console.error('获取关联内容失败:', error);
      message.error(error.message || '获取关联内容失败');
      setContents([]);
    } finally {
      setLoading(false);
    }
  }, [keyword, platform]);

  // Modal打开时加载数据
  React.useEffect(() => {
    if (visible) {
      fetchRelatedContent();
    }
  }, [visible, fetchRelatedContent]);

  // 表格列配置
  const columns = [
    {
      title: '标题',
      dataIndex: 'title',
      key: 'title',
      width: 300,
      ellipsis: true,
      render: (text) => (
        <Space>
          <FileTextOutlined style={{ color: '#1890ff' }} />
          <Text ellipsis style={{ maxWidth: 250 }}>
            {text || '无标题'}
          </Text>
        </Space>
      )
    },
    {
      title: '平台',
      dataIndex: 'platform',
      key: 'platform',
      width: 100,
      render: (platformKey) => {
        const platformInfo = getPlatformInfo(platformKey);
        return (
          <Tag color={platformInfo.color} style={{ fontSize: 12 }}>
            {platformInfo.icon} {platformInfo.name}
          </Tag>
        );
      }
    },
    {
      title: '类型',
      dataIndex: 'type',
      key: 'type',
      width: 80,
      render: (type) => {
        const typeMap = {
          video: { text: '视频', color: 'blue' },
          image: { text: '图文', color: 'green' },
          live: { text: '直播', color: 'red' }
        };
        const config = typeMap[type] || { text: type, color: 'default' };
        return <Tag color={config.color}>{config.text}</Tag>;
      }
    },
    {
      title: '作者',
      dataIndex: 'author',
      key: 'author',
      width: 120,
      ellipsis: true,
      render: (author) => <Text ellipsis style={{ maxWidth: 100 }}>{author || '-'}</Text>
    },
    {
      title: '发布时间',
      dataIndex: 'publish_time',
      key: 'publish_time',
      width: 120,
      render: (time) => {
        if (!time) return '-';
        const date = new Date(time);
        return date.toLocaleDateString('zh-CN');
      }
    },
    {
      title: '数据',
      key: 'stats',
      width: 150,
      render: (_, record) => (
        <Space size={4} wrap>
          <Tag color="red">❤️ {(record.like_count || 0).toLocaleString()}</Tag>
          <Tag color="orange">⭐ {(record.collect_count || 0).toLocaleString()}</Tag>
        </Space>
      )
    }
  ];

  return (
    <Modal
      title={`关键词"${keyword}"的关联内容`}
      open={visible}
      onCancel={onClose}
      width={1000}
      footer={[
        <Button key="close" onClick={onClose}>
          关闭
        </Button>,
        <Button
          key="refresh"
          type="primary"
          icon={<LoadingOutlined />}
          onClick={fetchRelatedContent}
          loading={loading}
        >
          刷新
        </Button>
      ]}
    >
      <Spin spinning={loading}>
        {contents.length > 0 ? (
          <Table
            columns={columns}
            dataSource={contents}
            rowKey="id"
            pagination={{
              pageSize: 10,
              showTotal: (total) => `共 ${total} 条关联内容`
            }}
            scroll={{ y: 400 }}
            size="small"
          />
        ) : (
          <Empty
            description={
              <div>
                <p>暂无与"{keyword}"相关的采集内容</p>
                <Text type="secondary" style={{ fontSize: 12 }}>
                  可以使用"解析"按钮采集相关内容
                </Text>
              </div>
            }
            image={Empty.PRESENTED_IMAGE_SIMPLE}
          />
        )}
      </Spin>
    </Modal>
  );
};

export default RelatedContentModal;

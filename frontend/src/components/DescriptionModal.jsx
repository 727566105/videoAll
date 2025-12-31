/**
 * AI生成的描述查看Modal
 *
 * 显示OCR提取的文字和AI生成的完整描述
 */

import React, { useState } from 'react';
import { Modal, List, Tag, Typography, Button, message, Tabs, Empty } from 'antd';

const { Title, Paragraph, Text } = Typography;

const DescriptionModal = ({ visible, data, onClose }) => {
  const [copyLoading, setCopyLoading] = useState(false);

  // 复制描述文本到剪贴板
  const copyToClipboard = async (text) => {
    try {
      setCopyLoading(true);
      await navigator.clipboard.writeText(text);
      message.success('描述已复制到剪贴板');
    } catch (error) {
      message.error('复制失败，请手动复制');
    } finally {
      setCopyLoading(false);
    }
  };

  // 获取置信度颜色
  const getConfidenceColor = (confidence) => {
    if (confidence >= 0.8) return 'success';
    if (confidence >= 0.6) return 'warning';
    return 'error';
  };

  // 格式化执行时间
  const formatExecutionTime = (ms) => {
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(2)}s`;
  };

  const ocrResults = data?.ocr_results || [];
  const hasOcrResults = ocrResults.length > 0 && ocrResults.some(r => r.text && r.text.length > 0);

  const tabItems = [
    {
      key: 'description',
      label: '生成的描述',
      children: (
        <div>
          <Paragraph
            style={{
              padding: 16,
              backgroundColor: 'var(--bg-secondary, #f5f5f5)',
              borderRadius: 8,
              whiteSpace: 'pre-wrap',
              lineHeight: 1.8,
              fontSize: 14,
              maxHeight: 400,
              overflow: 'auto'
            }}
          >
            {data?.description || '暂无描述'}
          </Paragraph>

          {/* 元信息 */}
          <div style={{ marginTop: 16 }}>
            <Text type="secondary" style={{ fontSize: 12 }}>
              执行时间: {formatExecutionTime(data?.execution_time || 0)}
            </Text>
            <br />
            <Text type="secondary" style={{ fontSize: 12 }}>
              AI模型: {data?.ai_model || '未知'}
            </Text>
            <br />
            <Text type="secondary" style={{ fontSize: 12 }}>
              处理图片: {data?.image_count || 0} 张
            </Text>
            {data?.cached && (
              <>
                <br />
                <Tag color="blue" style={{ fontSize: 12 }}>
                  使用缓存
                </Tag>
              </>
            )}
          </div>
        </div>
      )
    }
  ];

  // 如果有OCR结果，添加OCR标签页
  if (hasOcrResults) {
    tabItems.push({
      key: 'ocr',
      label: `图片提取文字 (${ocrResults.filter(r => r.text && r.text.length > 0).length})`,
      children: (
        <List
          dataSource={ocrResults.filter(r => r.text && r.text.length > 0)}
          renderItem={(item, index) => (
            <List.Item key={index}>
              <div style={{ width: '100%' }}>
                <Paragraph
                  style={{
                    marginBottom: 8,
                    padding: 12,
                    backgroundColor: 'var(--bg-secondary, #fafafa)',
                    borderRadius: 6,
                    whiteSpace: 'pre-wrap',
                    fontSize: 13
                  }}
                >
                  {item.text}
                </Paragraph>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <Tag color={getConfidenceColor(item.confidence)}>
                    置信度: {(item.confidence * 100).toFixed(0)}%
                  </Tag>
                  {item.imagePath && (
                    <Text type="secondary" style={{ fontSize: 12 }}>
                      {item.imagePath.split('/').pop()}
                    </Text>
                  )}
                </div>
              </div>
            </List.Item>
          )}
          locale={{ emptyText: <Empty description="未提取到文字" /> }}
        />
      )
    });
  }

  return (
    <Modal
      title="AI描述详情"
      open={visible}
      onCancel={onClose}
      width={800}
      footer={[
        <Button
          key="copy"
          type="primary"
          loading={copyLoading}
          onClick={() => copyToClipboard(data?.description || '')}
        >
          复制描述
        </Button>,
        <Button key="close" onClick={onClose}>
          关闭
        </Button>
      ]}
    >
      <Tabs defaultActiveKey="description" items={tabItems} />
    </Modal>
  );
};

export default DescriptionModal;

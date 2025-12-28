import React from 'react';
import { Card, Tag, Typography, Space, Spin, Empty, Button } from 'antd';
import { FireOutlined, RiseOutlined, FallOutlined, MinusOutlined, InfoCircleOutlined, FileSearchOutlined } from '@ant-design/icons';

const { Text } = Typography;

const PlatformHotSearchCard = ({
  platform,
  platformName,
  platformColor,
  platformIcon,
  data = [],
  lastUpdate,
  loading = false,
  error = null,
  maxDisplay = 10,
  onKeywordClick,
  onRelatedContent
}) => {
  const getTrendIcon = (trend) => {
    switch (trend) {
      case '上升':
        return <RiseOutlined style={{ color: '#52c41a', fontSize: 14 }} />;
      case '下降':
        return <FallOutlined style={{ color: '#ff4d4f', fontSize: 14 }} />;
      case '持平':
        return <MinusOutlined style={{ color: '#faad14', fontSize: 14 }} />;
      case '新晋':
        return <Tag color="blue" style={{ marginLeft: 4 }}>新</Tag>;
      default:
        return null;
    }
  };

  const getRankStyle = (rank) => {
    if (rank <= 3) {
      return {
        background: platformColor || '#ff4d4f',
        color: '#fff',
        fontWeight: 'bold',
        boxShadow: `0 2px 4px ${platformColor ? platformColor + '40' : 'rgba(255, 77, 79, 0.4)'}`
      };
    }
    return {
      background: '#f0f0f0',
      color: '#666'
    };
  };

  const handleKeywordClick = (keyword, url) => {
    if (onKeywordClick) {
      onKeywordClick(keyword, url);
    } else {
      window.open(url, '_blank');
    }
  };

  if (error) {
    return (
      <Card
        title={
          <Space>
            <span>{platformIcon}</span>
            <span style={{ color: platformColor }}>{platformName}</span>
          </Space>
        }
        size="small"
        hoverable
        style={{ height: '100%' }}
      >
        <Empty
          description={error || '加载失败'}
          image={Empty.PRESENTED_IMAGE_SIMPLE}
        />
      </Card>
    );
  }

  return (
    <Card
      title={
        <Space>
          <span style={{ fontSize: 18 }}>{platformIcon}</span>
          <span style={{ color: platformColor, fontWeight: 600, fontSize: 15 }}>{platformName}</span>
          <Tag color={platformColor} style={{ marginLeft: 4, fontSize: 12, fontWeight: 500 }}>
            Top {data.length}
          </Tag>
        </Space>
      }
      size="small"
      hoverable
      style={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        borderRadius: 8,
        boxShadow: '0 1px 2px rgba(0,0,0,0.06)',
        transition: 'all 0.3s'
      }}
      styles={{ body: { padding: '16px' } }}
    >
      <Spin spinning={loading}>
        {data.length > 0 ? (
          <div>
            {data.slice(0, maxDisplay).map((item) => (
              <div
                key={item.rank}
                style={{
                  padding: '10px 0',
                  borderBottom: '1px solid #f0f0f0',
                  transition: 'background 0.2s'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = '#fafafa';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                }}
              >
                <div style={{ display: 'flex', gap: 12 }}>
                  {/* 排名徽章 */}
                  <div
                    style={{
                      ...getRankStyle(item.rank),
                      minWidth: 28,
                      height: 28,
                      borderRadius: 6,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 13,
                      fontWeight: 'bold',
                      textAlign: 'center',
                      boxShadow: item.rank <= 3 ? `0 2px 6px ${platformColor}40` : 'none',
                      flexShrink: 0
                    }}
                  >
                    {item.rank}
                  </div>

                  {/* 内容区域 */}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    {/* 标题行 */}
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginBottom: 6 }}>
                      <Space size={6} style={{ flex: 1, minWidth: 0 }}>
                        <Text
                          ellipsis
                          style={{
                            maxWidth: '100%',
                            fontWeight: 600,
                            fontSize: 14,
                            cursor: 'pointer',
                            transition: 'color 0.2s'
                          }}
                          title={item.keyword}
                          onClick={() => handleKeywordClick(item.keyword, item.url)}
                        >
                          {item.keyword}
                        </Text>
                        {getTrendIcon(item.trend)}
                      </Space>
                      <Space size={4}>
                        {onRelatedContent && (
                          <Button
                            type="text"
                            size="small"
                            icon={<InfoCircleOutlined />}
                            onClick={(e) => {
                              e.stopPropagation();
                              onRelatedContent(item.keyword, platform);
                            }}
                            style={{ fontSize: 11, padding: '0 4px', height: 22, color: '#1890ff' }}
                          >
                            关联
                          </Button>
                        )}
                        <Button
                          type="text"
                          size="small"
                          icon={<FileSearchOutlined />}
                          onClick={(e) => {
                            e.stopPropagation();
                            handleKeywordClick(item.keyword, item.url);
                          }}
                          style={{ fontSize: 11, padding: '0 4px', height: 22, color: '#52c41a' }}
                        >
                          解析
                        </Button>
                      </Space>
                    </div>

                    {/* 描述行 */}
                    <Space size={8} style={{ fontSize: 12 }}>
                      <Space size={4}>
                        <FireOutlined style={{ color: '#ff4d4f', fontSize: 11 }} />
                        <Text type="secondary" style={{ fontSize: 12 }}>
                          {(item.heat || 0).toLocaleString()}
                        </Text>
                      </Space>
                      {item.category && (
                        <Tag style={{
                          fontSize: 11,
                          padding: '0 6px',
                          borderRadius: 4,
                          height: 18,
                          lineHeight: '18px'
                        }} color="default">
                          {item.category}
                        </Tag>
                      )}
                    </Space>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <Empty
            description="暂无数据"
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            style={{ margin: '40px 0' }}
          />
        )}

        {data.length > maxDisplay && (
          <div style={{
            textAlign: 'center',
            marginTop: 16,
            paddingTop: 12,
            borderTop: '1px dashed #f0f0f0'
          }}>
            <Text type="secondary" style={{ fontSize: 12 }}>
              还有 {data.length - maxDisplay} 条热搜...
            </Text>
          </div>
        )}

        {lastUpdate && (
          <div style={{
            marginTop: 12,
            paddingTop: 12,
            borderTop: '1px solid #f0f0f0',
            textAlign: 'center'
          }}>
            <Text type="secondary" style={{ fontSize: 11 }}>
              更新时间: {new Date(lastUpdate).toLocaleString('zh-CN', {
              month: '2-digit',
              day: '2-digit',
              hour: '2-digit',
              minute: '2-digit'
            })}
            </Text>
          </div>
        )}
      </Spin>
    </Card>
  );
};

export default PlatformHotSearchCard;

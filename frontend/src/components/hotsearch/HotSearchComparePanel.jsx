import React, { useState, useEffect } from 'react';
import { Card, DatePicker, Spin, Space, Table, Tag, Statistic, Row, Col, Alert } from 'antd';
import { SyncOutlined } from '@ant-design/icons';
import apiService from '../../services/api';
import dayjs from 'dayjs';

const { RangePicker } = DatePicker;

const HotSearchComparePanel = ({ platforms }) => {
  const [loading, setLoading] = useState(false);
  const [date, setDate] = useState(dayjs());
  const [compareData, setCompareData] = useState(null);
  const [stats, setStats] = useState(null);

  // 保存平台列表引用，避免在render函数中与data中的platforms字段冲突
  const platformsList = platforms;

  useEffect(() => {
    if (date) {
      fetchCompareData();
    }
  }, [date]);

  const fetchCompareData = async () => {
    try {
      setLoading(true);
      const dateStr = date.format('YYYY-MM-DD');
      const result = await apiService.hotsearch.compare({ date: dateStr });

      if (result && result.data) {
        setCompareData(result.data);
        setStats(result.data.stats);
      }
    } catch (error) {
      console.error('获取对比数据失败', error);
    } finally {
      setLoading(false);
    }
  };

  const commonColumns = [
    {
      title: '排名',
      key: 'rank',
      render: (_, record, index) => index + 1
    },
    {
      title: '关键词',
      dataIndex: 'keyword',
      key: 'keyword',
      width: 200,
      render: (text) => <strong>{text}</strong>
    },
    {
      title: '出现平台',
      dataIndex: 'platforms',
      key: 'platforms',
      render: (platforms) => (
        <Space size={4} wrap>
          {platforms.map(p => {
            const platformInfo = platformsList.find(pl => pl.key === p);
            return (
              <Tag key={p} color={platformInfo?.color || 'default'}>
                {platformInfo?.icon} {platformInfo?.name || p}
              </Tag>
            );
          })}
        </Space>
      )
    },
    {
      title: '各平台热度',
      dataIndex: 'heats',
      key: 'heats',
      render: (heats) => (
        <Space size={8} wrap>
          {Object.entries(heats).map(([platform, heat]) => {
            const platformInfo = platformsList.find(pl => pl.key === platform);
            return (
              <Tag key={platform} color={platformInfo?.color || 'default'}>
                {platformInfo?.name}: {(heat || 0).toLocaleString()}
              </Tag>
            );
          })}
        </Space>
      )
    },
    {
      title: '总热度',
      key: 'totalHeat',
      render: (_, record) => {
        const total = Object.values(record.heats || {}).reduce((sum, heat) => sum + (heat || 0), 0);
        return <span style={{ fontWeight: 'bold' }}>{total.toLocaleString()}</span>;
      }
    }
  ];

  const platformStatsColumns = [
    {
      title: '平台',
      dataIndex: 'platform',
      key: 'platform',
      render: (text) => {
        const platformInfo = platformsList.find(p => p.key === text);
        return (
          <Space>
            <span>{platformInfo?.icon}</span>
            <span style={{ color: platformInfo?.color }}>{platformInfo?.name}</span>
          </Space>
        );
      }
    },
    {
      title: '特有热搜数',
      dataIndex: 'count',
      key: 'count',
      render: (text) => <Tag color="blue">{text}</Tag>
    }
  ];

  const platformStatsData = stats
    ? Object.entries(stats.platformSpecific).map(([platform, count]) => ({
        platform,
        count
      }))
    : [];

  return (
    <Spin spinning={loading}>
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        {/* 控制面板 */}
        <Card size="small">
          <Space>
            <span>对比日期:</span>
            <DatePicker
              value={date}
              onChange={(newDate) => setDate(newDate)}
              format="YYYY-MM-DD"
              allowClear={false}
            />
            <Tag icon={<SyncOutlined />} color="blue" onClick={fetchCompareData} style={{ cursor: 'pointer' }}>
              刷新
            </Tag>
          </Space>
        </Card>

        {/* 统计概览 */}
        {stats && (
          <Row gutter={16}>
            <Col xs={24} sm={6}>
              <Card>
                <Statistic
                  title="总热搜数"
                  value={stats.totalUnique}
                  suffix="条"
                  valueStyle={{ color: '#3f8600' }}
                />
              </Card>
            </Col>
            <Col xs={24} sm={6}>
              <Card>
                <Statistic
                  title="共同热搜"
                  value={stats.commonCount}
                  suffix="条"
                  valueStyle={{ color: '#cf1322' }}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12}>
              <Card>
                <Statistic
                  title="平台覆盖率"
                  value={stats.totalUnique > 0 ? ((stats.commonCount / stats.totalUnique) * 100).toFixed(1) : 0}
                  suffix="%"
                  valueStyle={{
                    color: ((stats.commonCount / stats.totalUnique) * 100) >= 50 ? '#3f8600' : '#faad14'
                  }}
                />
              </Card>
            </Col>
          </Row>
        )}

        {/* 共同热搜表格 */}
        {compareData && compareData.commonKeywords && compareData.commonKeywords.length > 0 ? (
          <Card title={`共同热搜 (${compareData.commonKeywords.length}条)`} bodyStyle={{ padding: '8px' }}>
            <Alert
              message={`在 ${date.format('YYYY-MM-DD')}，共有 ${compareData.commonKeywords.length} 个关键词同时出现在多个平台的热搜榜上`}
              type="info"
              showIcon
              style={{ marginBottom: 16 }}
            />
            <Table
              columns={commonColumns}
              dataSource={compareData.commonKeywords}
              rowKey="keyword"
              pagination={false}
              size="small"
              scroll={{ y: 400 }}
            />
          </Card>
        ) : (
          <Card>
            <Alert
              message={`在 ${date.format('YYYY-MM-DD')} 暂无共同热搜数据`}
              type="warning"
              showIcon
            />
          </Card>
        )}

        {/* 平台特有热搜统计 */}
        {stats && (
          <Card title="平台特有热搜分布" bodyStyle={{ padding: '8px' }}>
            <Table
              columns={platformStatsColumns}
              dataSource={platformStatsData}
              rowKey="platform"
              pagination={false}
              size="small"
            />
          </Card>
        )}
      </Space>
    </Spin>
  );
};

export default HotSearchComparePanel;

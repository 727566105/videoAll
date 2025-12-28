import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Select, Spin, Space, Statistic } from 'antd';
import { Line, Column, WordCloud } from '@ant-design/charts';
import { ArrowUpOutlined, ArrowDownOutlined } from '@ant-design/icons';
import apiService from '../../services/api';

const { Option } = Select;

const HotSearchTrendChart = ({ platforms }) => {
  const [loading, setLoading] = useState(false);
  const [selectedPlatform, setSelectedPlatform] = useState('douyin');
  const [days, setDays] = useState(7);
  const [trendData, setTrendData] = useState([]);
  const [heatDistribution, setHeatDistribution] = useState([]);
  const [stats, setStats] = useState({ total: 0, avgHeat: 0, topKeyword: '' });

  useEffect(() => {
    fetchTrendData();
  }, [selectedPlatform, days]);

  const fetchTrendData = async () => {
    try {
      setLoading(true);

      // 获取趋势数据
      const result = await apiService.hotsearch.getTrends(selectedPlatform, { days });

      if (result && result.data) {
        // 处理趋势数据
        const processedData = result.data.flatMap(day => {
          if (!day.data) return [];
          return day.data.slice(0, 10).map(item => ({
            date: day.date,
            keyword: item.keyword,
            heat: item.heat || 0,
            rank: item.rank
          }));
        });

        setTrendData(processedData);

        // 处理热度分布（最新数据）
        const latestData = result.data[days - 1]?.data || [];
        const distribution = latestData.slice(0, 20).map(item => ({
          keyword: item.keyword,
          heat: item.heat || 0
        }));
        setHeatDistribution(distribution);

        // 计算统计数据
        const totalHeat = latestData.reduce((sum, item) => sum + (item.heat || 0), 0);
        const avgHeat = latestData.length > 0 ? Math.round(totalHeat / latestData.length) : 0;
        const topKeyword = latestData[0]?.keyword || '-';

        setStats({
          total: latestData.length,
          avgHeat,
          topKeyword
        });
      }
    } catch (error) {
      console.error('获取趋势数据失败', error);
    } finally {
      setLoading(false);
    }
  };

  // 折线图配置
  const lineConfig = {
    data: trendData,
    xField: 'date',
    yField: 'heat',
    seriesField: 'keyword',
    smooth: true,
    animation: {
      appear: {
        animation: 'path-in',
        duration: 1000
      }
    },
    legend: {
      position: 'top',
      maxRow: 2
    },
    tooltip: {
      fields: ['date', 'keyword', 'heat', 'rank'],
      formatter: (datum) => ({
        name: datum.keyword,
        value: `热度: ${datum.heat?.toLocaleString()}\n排名: ${datum.rank}`
      })
    },
    yAxis: {
      label: {
        formatter: (v) => `${(v / 10000).toFixed(1)}w`
      }
    }
  };

  // 柱状图配置
  const columnConfig = {
    data: heatDistribution,
    xField: 'keyword',
    yField: 'heat',
    label: {
      position: 'top',
      style: {
        fill: '#000',
        fontSize: 10,
        opacity: 0.85
      },
      formatter: (v) => `${(v / 10000).toFixed(1)}w`
    },
    xAxis: {
      label: {
        autoHide: true,
        autoRotate: true,
        style: {
          fontSize: 11
        }
      }
    },
    meta: {
      heat: {
        alias: '热度'
      }
    }
  };

  // 词云图配置
  const wordCloudConfig = {
    data: heatDistribution,
    wordField: 'keyword',
    weightField: 'heat',
    wordStyle: {
      fontSize: [12, 50],
      rotation: 0,
      active: {
        style: {
          cursor: 'pointer'
        }
      }
    },
    random: Math.random
  };

  const platformOptions = platforms.map(p => (
    <Option key={p.key} value={p.key}>
      {p.icon} {p.name}
    </Option>
  ));

  return (
    <Spin spinning={loading}>
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        {/* 统计卡片 */}
        <Row gutter={16}>
          <Col xs={24} sm={8}>
            <Card>
              <Statistic
                title="热搜总数"
                value={stats.total}
                suffix="条"
                valueStyle={{ color: '#3f8600' }}
              />
            </Card>
          </Col>
          <Col xs={24} sm={8}>
            <Card>
              <Statistic
                title="平均热度"
                value={stats.avgHeat}
                suffix={<span style={{ fontSize: 14 }}>万</span>}
                valueStyle={{ color: '#cf1322' }}
              />
            </Card>
          </Col>
          <Col xs={24} sm={8}>
            <Card>
              <Statistic
                title="热门关键词"
                value={stats.topKeyword}
                valueStyle={{ fontSize: 18, fontWeight: 'bold' }}
              />
            </Card>
          </Col>
        </Row>

        {/* 控制面板 */}
        <Card size="small">
          <Space>
            <span>平台:</span>
            <Select
              value={selectedPlatform}
              onChange={setSelectedPlatform}
              style={{ width: 150 }}
            >
              {platformOptions}
            </Select>
            <span>时间范围:</span>
            <Select
              value={days}
              onChange={setDays}
              style={{ width: 100 }}
            >
              <Option value={3}>近3天</Option>
              <Option value={7}>近7天</Option>
              <Option value={30}>近30天</Option>
            </Select>
          </Space>
        </Card>

        {/* 趋势折线图 */}
        <Row gutter={16}>
          <Col xs={24}>
            <Card title="热度趋势分析（Top 10）" bodyStyle={{ padding: '16px 24px 0' }}>
              <Line {...lineConfig} height={350} />
            </Card>
          </Col>
        </Row>

        {/* 热度分布和词云 */}
        <Row gutter={16}>
          <Col xs={24} lg={12}>
            <Card title="当前热度分布（Top 20）" bodyStyle={{ padding: '16px 24px 0' }}>
              <Column {...columnConfig} height={300} />
            </Card>
          </Col>
          <Col xs={24} lg={12}>
            <Card title="关键词云" bodyStyle={{ padding: '16px 24px 0' }}>
              <WordCloud {...wordCloudConfig} height={300} />
            </Card>
          </Col>
        </Row>
      </Space>
    </Spin>
  );
};

export default HotSearchTrendChart;

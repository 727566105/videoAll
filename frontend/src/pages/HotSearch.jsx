import { useState, useEffect } from 'react';
import { Card, Tabs, Button, message, Space, Row, Col, Spin } from 'antd';
import { SyncOutlined } from '@ant-design/icons';
import apiService from '../services/api';
import PlatformHotSearchCard from '../components/hotsearch/PlatformHotSearchCard';
import HotSearchTrendChart from '../components/hotsearch/HotSearchTrendChart';
import HotSearchComparePanel from '../components/hotsearch/HotSearchComparePanel';

const HotSearch = () => {
  // 平台配置
  const [platforms, setPlatforms] = useState([]);
  const [platformConfig, setPlatformConfig] = useState({});

  // 数据状态
  const [allHotsearchData, setAllHotsearchData] = useState({});
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // 获取平台列表
  const fetchPlatforms = async () => {
    try {
      const result = await apiService.hotsearch.getPlatforms();
      const platformList = Array.isArray(result) ? result : result.data || [];

      // 构建平台配置
      const config = {
        douyin: {
          key: 'douyin',
          name: '抖音',
          icon: '🎵',
          color: '#000000'
        },
        xiaohongshu: {
          key: 'xiaohongshu',
          name: '小红书',
          icon: '📕',
          color: '#ff2442'
        },
        weibo: {
          key: 'weibo',
          name: '微博',
          icon: '📱',
          color: '#e6162d'
        },
        bilibili: {
          key: 'bilibili',
          name: 'B站',
          icon: '📺',
          color: '#00a1d6'
        }
      };

      setPlatforms(platformList);
      setPlatformConfig(config);
    } catch (error) {
      console.error('获取平台列表失败:', error);
      message.error('获取平台列表失败');

      // 使用默认配置
      const defaultConfig = {
        douyin: { key: 'douyin', name: '抖音', icon: '🎵', color: '#000000' },
        xiaohongshu: { key: 'xiaohongshu', name: '小红书', icon: '📕', color: '#ff2442' },
        weibo: { key: 'weibo', name: '微博', icon: '📱', color: '#e6162d' },
        bilibili: { key: 'bilibili', name: 'B站', icon: '📺', color: '#00a1d6' }
      };
      setPlatformConfig(defaultConfig);
      setPlatforms(['douyin', 'xiaohongshu', 'weibo', 'bilibili']);
    }
  };

  // 获取所有平台热搜数据
  const fetchAllHotsearchData = async () => {
    try {
      setLoading(true);
      const result = await apiService.hotsearch.getAllPlatforms();

      if (result && result.data) {
        setAllHotsearchData(result.data);
      }
    } catch (error) {
      console.error('获取热搜数据失败:', error);
      message.error('获取热搜数据失败');
      setAllHotsearchData({});
    } finally {
      setLoading(false);
    }
  };

  // 刷新所有平台数据（仅重新获取，不触发后端采集）
  const refreshAllData = async () => {
    try {
      setRefreshing(true);
      // 直接重新获取数据，不调用 refresh API（耗时太长）
      await fetchAllHotsearchData();
      message.success('刷新成功');
    } catch (error) {
      console.error('刷新失败:', error);
      message.error(error.message || '刷新失败');
    } finally {
      setRefreshing(false);
    }
  };

  // 处理关键词点击 - 解析
  const handleKeywordClick = (keyword, platform) => {
    message.info(`开始解析关键词: ${keyword}`);
    // 可以跳转到解析页面
    console.log('Parse keyword:', keyword, 'from platform:', platform);
  };

  // 处理关联内容查询
  const handleGetRelatedContent = async (keyword, platform) => {
    try {
      message.info(`查询 ${keyword} 的关联内容`);
      // TODO: 后续可以添加 Modal 或跳转到内容管理页面
      console.log('Get related content for:', keyword, 'from platform:', platform);
    } catch (error) {
      console.error('获取关联内容失败:', error);
      message.error(error.message || '获取关联内容失败');
    }
  };

  // 初始化加载
  useEffect(() => {
    fetchPlatforms();
  }, []);

  // 加载热搜数据
  useEffect(() => {
    if (platforms.length > 0) {
      fetchAllHotsearchData();
    }
  }, [platforms]);

  // 自动刷新（每5分钟）
  useEffect(() => {
    const interval = setInterval(() => {
      fetchAllHotsearchData();
    }, 5 * 60 * 1000);

    return () => clearInterval(interval);
  }, [platforms]);

  // 获取平台列表（用于组件props）
  const platformList = Object.values(platformConfig);

  return (
    <Spin spinning={loading}>
      <Space orientation="vertical" size="large" style={{ width: '100%' }}>
        {/* 顶部操作栏 */}
        <Card size="small" style={{ borderRadius: 8, boxShadow: '0 1px 2px rgba(0,0,0,0.06)' }}>
          <Space size="large">
            <span style={{ fontSize: 16, fontWeight: 600 }}>🔥 四平台实时热搜</span>
            <Button
              type="primary"
              icon={<SyncOutlined spin={refreshing} />}
              onClick={refreshAllData}
              loading={refreshing}
              style={{ borderRadius: 6 }}
            >
              刷新全部
            </Button>
          </Space>
        </Card>

        {/* 主内容区域 - Tabs */}
        <Card style={{ borderRadius: 8, boxShadow: '0 1px 2px rgba(0,0,0,0.06)' }}>
          <Tabs
            defaultActiveKey="realtime"
            size="large"
            items={[
              {
                key: 'realtime',
                label: '实时热搜',
                children: (
                  <Row gutter={[20, 20]}>
                    {platformList.map(platform => (
                      <Col xs={24} sm={12} lg={6} key={platform.key}>
                        <PlatformHotSearchCard
                          platform={platform.key}
                          platformName={platform.name}
                          platformColor={platform.color}
                          platformIcon={platform.icon}
                          data={allHotsearchData[platform.key]?.data || []}
                          loading={refreshing}
                          error={allHotsearchData[platform.key]?.error || null}
                          maxDisplay={10}
                          onKeywordClick={handleKeywordClick}
                          onRelatedContent={handleGetRelatedContent}
                        />
                      </Col>
                    ))}
                  </Row>
                )
              },
              {
                key: 'trends',
                label: '趋势分析',
                children: <HotSearchTrendChart platforms={platformList} />
              },
              {
                key: 'compare',
                label: '跨平台对比',
                children: <HotSearchComparePanel platforms={platformList} />
              }
            ]}
          />
        </Card>

        {/* 关联内容 Modal - 保留原有功能 */}
        {/* 这里可以添加关联内容展示的 Modal */}
        {/* 由于 Modal 组件在原代码中，可以保留或单独抽离成组件 */}
      </Space>
    </Spin>
  );
};

export default HotSearch;

import { useState, useEffect } from 'react';
import { App, Card, Typography, Space, Table, Button, Input, Select, DatePicker, message, Modal, Image, Tag, Badge, Tooltip, Spin, Tabs, List, Empty, Progress, Dropdown, Checkbox } from 'antd';
import { SearchOutlined, DownloadOutlined, DeleteOutlined, ReloadOutlined, TagOutlined, RobotOutlined, ExperimentOutlined, FileTextOutlined, SettingOutlined, UserOutlined, GlobalOutlined, VideoCameraOutlined, ClockCircleOutlined, LinkOutlined, LikeOutlined, StarOutlined, MessageOutlined, ShareAltOutlined, EyeOutlined } from '@ant-design/icons';
import apiService from '../services/api';
import TagFilter from '../components/TagFilter';
import BatchTagModal from '../components/BatchTagModal';
import DescriptionModal from '../components/DescriptionModal';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

// 定义所有可配置的列（不包括固定的AI分析和操作列）
const ALL_COLUMNS = [
  { key: 'cover_url', title: '封面', defaultVisible: true },
  { key: 'title', title: '标题', defaultVisible: true },
  { key: 'author', title: '作者', defaultVisible: true },
  { key: 'platform', title: '平台', defaultVisible: true },
  { key: 'media_type', title: '类型', defaultVisible: true },
  { key: 'source_type', title: '来源', defaultVisible: true },
  { key: 'created_at', title: '采集时间', defaultVisible: true }
];

const ContentManagement = () => {
  const { token } = App.useApp();
  // State management
  const [contentList, setContentList] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);
  const [filters, setFilters] = useState({
    keyword: '',
    platform: '',
    media_type: '',
    source_type: '',
    date_range: null,
    tags: []
  });
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10
  });
  // Preview modal state
  const [previewVisible, setPreviewVisible] = useState(false);
  const [previewContent, setPreviewContent] = useState(null);
  const [refreshingStats, setRefreshingStats] = useState(false);
  // Batch tag modal state
  const [batchTagModalVisible, setBatchTagModalVisible] = useState(false);
  // AI analysis state - 按内容ID分别存储
  const [aiAnalysisStatusMap, setAiAnalysisStatusMap] = useState({});
  const [aiAnalyzing, setAiAnalyzing] = useState(false);
  const [aiLoading, setAiLoading] = useState({});
  // AI description modal state
  const [descriptionModalVisible, setDescriptionModalVisible] = useState(false);
  const [currentDescription, setCurrentDescription] = useState(null);

  // Column visibility state
  // 从localStorage加载列配置
  const loadColumnConfig = () => {
    try {
      const saved = localStorage.getItem('content-table-columns');
      if (saved) {
        return JSON.parse(saved);
      }
    } catch (error) {
      console.error('加载列配置失败:', error);
    }
    // 返回默认配置
    return ALL_COLUMNS.reduce((acc, col) => {
      acc[col.key] = col.defaultVisible;
      return acc;
    }, {});
  };

  const [visibleColumns, setVisibleColumns] = useState(() => loadColumnConfig());

  // 保存列配置到localStorage
  const saveColumnConfig = (config) => {
    try {
      localStorage.setItem('content-table-columns', JSON.stringify(config));
    } catch (error) {
      console.error('保存列配置失败:', error);
    }
  };

  // 处理列显示/隐藏切换
  const handleColumnToggle = (columnKey) => {
    const currentVisibleCount = Object.values(visibleColumns).filter(Boolean).length;
    const isCurrentlyVisible = visibleColumns[columnKey];

    // 如果当前只有1列可见且用户要隐藏它，给出提示
    if (currentVisibleCount === 1 && isCurrentlyVisible) {
      message.warning('至少需要保留一列');
      return;
    }

    const newConfig = {
      ...visibleColumns,
      [columnKey]: !isCurrentlyVisible
    };
    setVisibleColumns(newConfig);
    saveColumnConfig(newConfig);
  };

  // 重置列配置
  const resetColumnConfig = () => {
    const defaultConfig = ALL_COLUMNS.reduce((acc, col) => {
      acc[col.key] = col.defaultVisible;
      return acc;
    }, {});
    setVisibleColumns(defaultConfig);
    saveColumnConfig(defaultConfig);
    message.success('已恢复默认列设置');
  };

  // Get filtered columns based on user preferences
  const getFilteredColumns = () => {
    // 基础列（根据用户配置显示）
    const baseColumns = [
      {
        title: '封面',
        dataIndex: 'cover_url',
        key: 'cover_url',
        width: 100,
        render: (cover_url, record) => {
          // 优先使用本地图片：GET /api/v1/content/:id/local-media?type=cover
          const localCoverUrl = `/api/v1/content/${record.id}/local-media?type=cover`;

          return (
            <img
              src={localCoverUrl}
              alt="封面"
              style={{ width: 80, height: 60, objectFit: 'cover', borderRadius: 4, cursor: 'pointer' }}
              onClick={() => handlePreview(record)}
              onError={(e) => {
                console.log('本地封面加载失败，使用远程代理');
                e.target.src = `/api/v1/content/proxy-image?url=${encodeURIComponent(cover_url)}`;
                e.target.onError = () => {
                  e.target.src = 'https://via.placeholder.com/80x60?text=加载失败';
                };
              }}
            />
          );
        }
      },
      {
        title: '标题',
        dataIndex: 'title',
        key: 'title',
        ellipsis: true,
        width: 280,
        render: (title, record) => (
          <Space orientation="vertical" size={0}>
            <span>{title}</span>
            {record.is_missing && <Tag color="error">已消失</Tag>}
            {/* 显示标签 */}
            {record.tags && record.tags.length > 0 && (
              <div style={{ marginTop: 4, display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                {record.tags.slice(0, 5).map(tag => (
                  <Tag key={tag.id} color={tag.color}>
                    {tag.name}
                  </Tag>
                ))}
                {record.tags.length > 5 && (
                  <Tag>+{record.tags.length - 5}</Tag>
                )}
              </div>
            )}
          </Space>
        )
      },
      {
        title: '作者',
        dataIndex: 'author',
        key: 'author',
        width: 120
      },
      {
        title: '平台',
        dataIndex: 'platform',
        key: 'platform',
        width: 100
      },
      {
        title: '类型',
        dataIndex: 'media_type',
        key: 'media_type',
        width: 120,
        render: (type) => {
          return type === 'video' ? '视频' : '图片';
        }
      },
      {
        title: '来源',
        dataIndex: 'source_type',
        key: 'source_type',
        width: 120,
        render: (type) => type === 1 ? '单链接解析' : '监控任务'
      },
      {
        title: '采集时间',
        dataIndex: 'created_at',
        key: 'created_at',
        width: 160,
        render: (time) => {
          const date = new Date(time);
          return date.toLocaleString('zh-CN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
          });
        }
      }
    ];

    // 固定列（始终显示）
    const fixedColumns = [
      {
        title: '操作',
        key: 'action',
        width: 180,
        fixed: 'right',
        render: (_, record) => (
          <Space size="small" wrap>
            <Button type="link" icon={<DownloadOutlined />} onClick={() => handleDownload(record)}>下载</Button>
            <Button
              type="link"
              danger
              icon={<DeleteOutlined />}
              onClick={() => handleDelete(record.id)}
            >
              删除
            </Button>
          </Space>
        )
      }
    ];

    // 过滤用户选择的列，然后加上固定列
    const visibleBaseColumns = baseColumns.filter(col =>
      visibleColumns[col.key]
    );

    return [...visibleBaseColumns, ...fixedColumns];
  };

  // Column settings menu
  const columnSettingsMenu = (
    <div style={{
      padding: '8px',
      minWidth: '150px',
      backgroundColor: 'white',
      borderRadius: '6px',
      boxShadow: '0 3px 6px -4px rgba(0, 0, 0, 0.12), 0 6px 16px 0 rgba(0, 0, 0, 0.08)',
      border: '1px solid #f0f0f0'
    }}>
      <Space direction="vertical" style={{ width: '100%' }}>
        {ALL_COLUMNS.map(column => (
          <Checkbox
            key={column.key}
            checked={visibleColumns[column.key]}
            onChange={() => handleColumnToggle(column.key)}
          >
            {column.title}
          </Checkbox>
        ))}
        <div style={{ marginTop: '8px', paddingTop: '8px', borderTop: '1px solid #f0f0f0' }}>
          <Button
            type="link"
            size="small"
            onClick={resetColumnConfig}
            style={{ padding: 0 }}
          >
            恢复默认
          </Button>
        </div>
      </Space>
    </div>
  );

  // Row selection configuration
  const rowSelection = {
    selectedRowKeys,
    onChange: setSelectedRowKeys
  };

  // Get content list from backend (带重试机制)
  const getContentList = async (retryCount = 0) => {
    try {
      setLoading(true);

      // Build query params - only include non-empty values to ensure proper filtering
      const params = {
        page: pagination.current,
        page_size: pagination.pageSize
      };

      // Only add filter parameters if they have values (not empty strings or null)
      if (filters.keyword && filters.keyword.trim()) {
        params.keyword = filters.keyword.trim();
      }
      if (filters.platform) {
        params.platform = filters.platform;
      }
      if (filters.media_type) {
        params.media_type = filters.media_type;
      }
      if (filters.source_type) {
        params.source_type = filters.source_type;
      }

      // Add date range if selected
      if (filters.date_range && filters.date_range.length === 2) {
        params.start_date = filters.date_range[0].format('YYYY-MM-DD');
        params.end_date = filters.date_range[1].format('YYYY-MM-DD');
      }

      // Add tags filter if selected
      if (filters.tags && filters.tags.length > 0) {
        params.tags = filters.tags.join(',');
      }

      // Call backend API
      const result = await apiService.content.getList(params);

      // Update state with real data or fallback structure
      const contentData = result.data || result;
      setContentList(contentData.list || []);
      setTotal(contentData.total || 0);
    } catch (error) {
      console.error('Get content list error:', error);

      // 对于临时性错误，自动重试（最多2次）
      const isRetryableError =
        error.code === 'ETIMEDOUT' ||
        error.code === 'ECONNRESET' ||
        error.response?.status >= 500;

      if (isRetryableError && retryCount < 2) {
        console.log(`重试获取列表... (${retryCount + 1}/2)`);
        setTimeout(() => {
          getContentList(retryCount + 1);
        }, 1000 * (retryCount + 1)); // 递增延迟：1秒、2秒
        return;
      }

      // 根据错误类型提供更详细的提示
      let errorMessage = '获取内容列表失败';

      if (error.message) {
        errorMessage += `: ${error.message}`;
      } else if (error.code === 'ECONNREFUSED') {
        errorMessage += ': 后端服务未启动，请先启动后端服务';
      } else if (error.code === 'ETIMEDOUT') {
        errorMessage += ': 请求超时，请检查网络连接或稍后重试';
      } else if (error.response?.status === 500) {
        errorMessage += ': 服务器内部错误，请稍后重试';
      } else if (error.response?.status === 503) {
        errorMessage += ': 数据库连接不可用，请检查数据库服务';
      }

      // Show empty list when API fails instead of mock data
      setContentList([]);
      setTotal(0);
      message.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // Delete content by ID
  const handleDelete = async (id) => {
    try {
      await apiService.content.delete(id);
      message.success('删除成功');
      // Refresh content list
      getContentList();
    } catch (error) {
      console.error('Delete content error:', error);
      message.error(error.message || '删除失败');
    }
  };

  // Batch delete contents
  const handleBatchDelete = async () => {
    if (selectedRowKeys.length === 0) {
      message.warning('请选择要删除的内容');
      return;
    }
    
    try {
      await apiService.content.batchDelete({ ids: selectedRowKeys });
      message.success('批量删除成功');
      // Refresh content list and clear selection
      getContentList();
      setSelectedRowKeys([]);
    } catch (error) {
      console.error('Batch delete error:', error);
      message.error(error.message || '批量删除失败');
    }
  };

  // Handle filter changes
  const handleFilterChange = (key, value) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }));
  };

  // Handle search - automatically trigger when filters change
  const handleSearch = () => {
    setPagination(prev => ({
      ...prev,
      current: 1 // Reset to first page when searching
    }));
    getContentList();
  };

  // Handle reset filters
  const handleReset = () => {
    setFilters({
      keyword: '',
      platform: '',
      media_type: '',
      source_type: '',
      date_range: null,
      tags: []
    });
    setPagination({
      current: 1,
      pageSize: 10
    });
    // Automatically reload content after reset
    setTimeout(() => {
      getContentList();
    }, 0);
  };

  // Check if any filters are active
  const hasActiveFilters = () => {
    return !!(
      (filters.keyword && filters.keyword.trim()) ||
      filters.platform ||
      filters.media_type ||
      filters.source_type ||
      filters.date_range ||
      (filters.tags && filters.tags.length > 0)
    );
  };

  // Get filter status text for user feedback
  const getFilterStatusText = () => {
    if (!hasActiveFilters()) {
      return '显示所有内容';
    }

    const activeFilters = [];
    if (filters.keyword && filters.keyword.trim()) activeFilters.push('关键词');
    if (filters.platform) activeFilters.push('平台');
    if (filters.media_type) activeFilters.push('类型');
    if (filters.source_type) activeFilters.push('来源');
    if (filters.date_range) activeFilters.push('日期范围');
    if (filters.tags && filters.tags.length > 0) activeFilters.push(`标签(${filters.tags.length}个)`);

    return `已应用筛选条件: ${activeFilters.join(', ')}`;
  };

  // Handle pagination change
  const handlePaginationChange = (page, pageSize) => {
    setPagination({
      current: page,
      pageSize
    });
  };

  // Handle content preview
  const handlePreview = (record) => {
    // 调试：打印预览数据
    console.log('预览内容数据:', record);
    console.log('all_videos 类型:', typeof record.all_videos);
    console.log('all_videos 值:', record.all_videos);
    console.log('all_videos 长度:', record.all_videos?.length);

    // 解析 all_videos 和 all_images（它们可能是JSON字符串）
    const processedRecord = {
      ...record,
      all_videos: typeof record.all_videos === 'string'
        ? JSON.parse(record.all_videos || '[]')
        : (record.all_videos || []),
      all_images: typeof record.all_images === 'string'
        ? JSON.parse(record.all_images || '[]')
        : (record.all_images || []),
    };

    setPreviewContent(processedRecord);
    setPreviewVisible(true);

    // 获取AI分析状态
    fetchAiStatus(record.id);
  };

  // Handle refresh statistics
  const handleRefreshStats = async () => {
    if (!previewContent?.source_url) {
      message.warning('没有源链接，无法刷新统计数据');
      return;
    }

    setRefreshingStats(true);
    try {
      // 调用后端 API 刷新统计数据
      const response = await apiService.content.refreshStats(previewContent.id);

      if (response.success) {
        // 更新预览内容中的统计数据
        setPreviewContent({
          ...previewContent,
          like_count: response.data.like_count,
          collect_count: response.data.collect_count,
          comment_count: response.data.comment_count,
          share_count: response.data.share_count,
          view_count: response.data.view_count,
          is_missing: response.data.is_missing
        });

        // 同时更新列表中的数据
        setContentList(prevList =>
          prevList.map(item =>
            item.id === previewContent.id
              ? { ...item, ...response.data }
              : item
          )
        );

        if (response.data.is_missing) {
          message.warning('笔记已消失，但保留了已有数据');
        } else {
          message.success('统计数据已更新');
        }
      } else {
        message.error(response.message || '刷新统计数据失败');
      }
    } catch (error) {
      console.error('刷新统计数据失败:', error);
      message.error(error.response?.data?.message || error.message || '刷新统计数据失败');
    } finally {
      setRefreshingStats(false);
    }
  };

  // Handle content download
  const handleDownload = async (record) => {
    try {
      const blob = await apiService.content.download(record.id);

      // 从响应头获取文件名，或使用默认文件名
      let fileName = `${record.title || 'content'}_${record.platform || 'unknown'}.zip`;

      // 创建下载链接
      const url = window.URL.createObjectURL(new Blob([blob], { type: 'application/zip' }));
      const link = document.createElement('a');
      link.href = url;
      link.download = fileName;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      message.success('下载成功');
    } catch (error) {
      console.error('Download content error:', error);
      message.error(error.message || '下载失败');
    }
  };

  // Handle batch download
  const handleBatchDownload = async () => {
    if (selectedRowKeys.length === 0) {
      message.warning('请选择要下载的内容');
      return;
    }

    // 获取选中的内容记录
    const selectedContents = contentList.filter(item => selectedRowKeys.includes(item.id));

    if (selectedContents.length === 0) {
      message.warning('未找到选中的内容');
      return;
    }

    message.info(`开始下载 ${selectedContents.length} 个文件...`);

    // 逐个下载，避免浏览器阻止多个下载
    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < selectedContents.length; i++) {
      const record = selectedContents[i];
      try {
        const blob = await apiService.content.download(record.id);
        const fileName = `${record.title || 'content'}_${record.platform || 'unknown'}.zip`;
        const url = window.URL.createObjectURL(new Blob([blob], { type: 'application/zip' }));

        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // 延迟释放 URL，确保下载开始
        setTimeout(() => window.URL.revokeObjectURL(url), 100);

        successCount++;

        // 添加延迟，避免浏览器阻止多个下载
        if (i < selectedContents.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 300));
        }
      } catch (error) {
        console.error(`Download ${record.id} error:`, error);
        failCount++;
      }
    }

    if (failCount === 0) {
      message.success(`批量下载完成，共下载 ${successCount} 个文件`);
    } else {
      message.warning(`批量下载完成，成功 ${successCount} 个，失败 ${failCount} 个`);
    }
  };

  // Handle batch tag operation
  const handleBatchTagOperation = async ({ operation, tag_ids }) => {
    try {
      await apiService.tags.batchUpdateTags({
        content_ids: selectedRowKeys,
        tag_ids,
        operation
      });
      message.success('批量标签操作成功');
      // Refresh content list and clear selection
      getContentList();
      setSelectedRowKeys([]);
      setBatchTagModalVisible(false);
    } catch (error) {
      console.error('Batch tag operation error:', error);
      message.error(error.message || '批量标签操作失败');
    }
  };

  // Handle AI analysis for a single content (unified - tags + description)
  const handleAiAnalyze = async (contentId) => {
    try {
      setAiLoading(prev => ({ ...prev, [contentId]: true }));

      // 启动分析（不等待完成）
      apiService.aiAnalysis.analyzeContent(contentId, {
        tags: true,
        description: true,
        ocr: true
      }).then(async (result) => {
        message.destroy();

        // 显示详细的阶段性结果
        const { stages, tags, description } = result.data;
        const successCount = Object.values(stages).filter(s => s.success).length;
        const totalCount = Object.keys(stages).length;

        if (successCount === totalCount) {
          message.success(`AI分析完成：标签${tags?.length || 0}个，描述已生成`);

          // 刷新内容列表
          getContentList();

          // 如果当前预览的就是这个内容，刷新AI状态
          if (previewContent?.id === contentId) {
            await fetchAiStatus(contentId);
          }
        } else {
          message.warning(`AI分析部分完成（${successCount}/${totalCount}成功）`);
        }

        setAiLoading(prev => ({ ...prev, [contentId]: false }));
      }).catch((error) => {
        message.destroy();
        console.error('AI分析失败:', error);
        message.error(error.message || 'AI分析失败');
        setAiLoading(prev => ({ ...prev, [contentId]: false }));
      });

      // 开始轮询进度
      startProgressPolling(contentId);
    } catch (error) {
      message.destroy();
      console.error('启动AI分析失败:', error);
      message.error(error.message || '启动AI分析失败');
      setAiLoading(prev => ({ ...prev, [contentId]: false }));
    }
  };

  // 轮询分析进度
  const startProgressPolling = (contentId) => {
    const pollInterval = setInterval(async () => {
      try {
        const response = await apiService.aiAnalysis.getContentStatus(contentId);
        if (response.success) {
          const { is_processing, current_stage } = response.data;

          // 更新AI状态 - 按内容ID分别存储
          setAiAnalysisStatusMap(prev => ({
            ...prev,
            [contentId]: response.data
          }));

          // 如果不在处理中，停止轮询
          if (!is_processing) {
            clearInterval(pollInterval);
            setAiLoading(prev => ({ ...prev, [contentId]: false }));
          }
        }
      } catch (error) {
        console.error('轮询进度失败:', error);
        clearInterval(pollInterval);
        setAiLoading(prev => ({ ...prev, [contentId]: false }));
      }
    }, 1000); // 每秒轮询一次

    // 清理定时器
    return () => clearInterval(pollInterval);
  };

  // Fetch AI analysis status when opening preview
  const fetchAiStatus = async (contentId) => {
    try {
      const response = await apiService.aiAnalysis.getContentStatus(contentId);
      if (response.success) {
        setAiAnalysisStatusMap(prev => ({
          ...prev,
          [contentId]: response.data
        }));
      }
    } catch (error) {
      console.error('获取AI状态失败:', error);
      // 设置空状态，避免渲染错误
      setAiAnalysisStatusMap(prev => ({
        ...prev,
        [contentId]: {
          has_analysis: false,
          ai_tags: [],
          description: null,
          ocr_results: [],
          stages: null
        }
      }));
    }
  };

  // Show description modal with analysis result
  const showDescriptionModal = (data) => {
    setCurrentDescription({
      description: data.description || '暂无描述',
      ocr_results: data.ocr_results || [],
      execution_time: data.stages ? Object.values(data.stages).reduce((sum, s) => sum + s.duration, 0) : 0,
      ai_model: '未知',
      image_count: data.ocr_results?.length || 0,
      stages: data.stages
    });
    setDescriptionModalVisible(true);
  };

  // Render Basic Info Tab
  const renderBasicInfoTab = () => {
    return (
      <Space orientation="vertical" size="middle" style={{ width: '100%' }}>
        {/* 视频预览 */}
        {previewContent.all_videos && previewContent.all_videos.length > 0 && (
          <div>
            <h4>
              🎥 视频预览
              <span style={{ color: token?.colorError, marginLeft: 8, fontSize: 14 }}>
                共 {previewContent.all_videos.length} 个视频
              </span>
            </h4>
            {/* 主视频预览 - 优先使用本地文件 */}
            <video
              key={`main-video-${previewContent.all_videos[0]}`}
              src={`/api/v1/content/${previewContent.id}/local-media?type=video&index=1`}
              controls
              style={{ width: '100%', maxHeight: '400px', borderRadius: 8 }}
              onError={(e) => {
                console.log('本地视频加载失败，使用远程代理');
                e.target.src = `/api/v1/content/proxy-download?url=${encodeURIComponent(previewContent.all_videos[0])}`;
              }}
            />

            {/* 多视频缩略图列表 */}
            {previewContent.all_videos.length > 1 && (
              <div style={{ marginTop: 15 }}>
                <div style={{ fontSize: 13, color: token?.colorTextTertiary, marginBottom: 8 }}>更多视频：</div>
                <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 10 }}>
                  {previewContent.all_videos.slice(1).map((videoUrl, index) => (
                    <div
                      key={index + 1}
                      style={{
                        flex: '0 0 auto',
                        cursor: 'pointer',
                        borderRadius: 8,
                        overflow: 'hidden',
                        border: `2px solid ${token?.colorBorderSecondary}`,
                        transition: 'all 0.3s'
                      }}
                      onClick={() => {
                        const videoEl = document.querySelector('video');
                        const localVideoUrl = `/api/v1/content/${previewContent.id}/local-media?type=video&index=${index + 2}`;
                        if (videoEl) {
                          videoEl.src = localVideoUrl;
                          videoEl.style.display = 'block';
                          videoEl.onerror = () => {
                            console.log('本地视频加载失败，使用远程代理');
                            videoEl.src = `/api/v1/content/proxy-download?url=${encodeURIComponent(videoUrl)}`;
                          };
                        }
                      }}
                    >
                      <video
                        src={`/api/v1/content/${previewContent.id}/local-media?type=video&index=${index + 2}`}
                        style={{ width: 120, height: 90, objectFit: 'cover', display: 'block' }}
                        muted
                        onError={(e) => {
                          e.target.src = `/api/v1/content/proxy-download?url=${encodeURIComponent(videoUrl)}`;
                        }}
                      />
                      <div style={{ padding: '4px 8px', backgroundColor: token?.colorBgContainer, fontSize: 11, color: token?.colorTextTertiary, textAlign: 'center' }}>
                        视频 {index + 2}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* 图片预览 */}
        {previewContent.all_images && previewContent.all_images.length > 0 && (
          <div style={{ marginTop: previewContent.all_videos && previewContent.all_videos.length > 0 ? 15 : 0 }}>
            <h4>
              📸 图片预览
              <span style={{ color: token?.colorPrimary, marginLeft: 8, fontSize: 14 }}>
                共 {previewContent.all_images.length} 张
              </span>
            </h4>
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))',
              gap: 10,
              maxHeight: '400px',
              overflowY: 'auto',
              padding: '10px',
              backgroundColor: token?.colorFillSecondary,
              borderRadius: '8px'
            }}>
              {previewContent.all_images.map((imgUrl, index) => (
                <div key={index} style={{ textAlign: 'center' }}>
                  <Image
                    src={`/api/v1/content/${previewContent.id}/local-media?type=image&index=${index + 1}`}
                    alt={`图片 ${index + 1}`}
                    style={{
                      width: '100%',
                      height: '120px',
                      objectFit: 'cover',
                      borderRadius: '6px',
                      cursor: 'pointer'
                    }}
                    fallback="https://via.placeholder.com/120x120?text=加载失败"
                    onError={(e) => {
                      console.log('本地图片加载失败，使用远程代理');
                      e.target.src = `/api/v1/content/proxy-image?url=${encodeURIComponent(imgUrl)}`;
                    }}
                  />
                  <div style={{ fontSize: '11px', color: token?.colorTextTertiary, marginTop: '4px' }}>
                    图片 {index + 1}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 如果没有视频也没有图片，显示封面 */}
        {(!previewContent.all_videos || previewContent.all_videos.length === 0) &&
         (!previewContent.all_images || previewContent.all_images.length === 0) && (
          <Image
            src={`/api/v1/content/${previewContent.id}/local-media?type=cover`}
            alt={previewContent.title}
            style={{ maxWidth: '100%', maxHeight: '400px' }}
            fallback="https://via.placeholder.com/400x300?text=图片加载失败"
            onError={(e) => {
              console.log('本地封面加载失败，使用远程代理');
              e.target.src = `/api/v1/content/proxy-image?url=${encodeURIComponent(previewContent.cover_url)}`;
            }}
          />
        )}

        {/* 基本信息 */}
        <div style={{
          padding: '16px',
          backgroundColor: token?.colorBgContainer,
          border: `1px solid ${token?.colorBorderSecondary}`,
          borderRadius: token?.borderRadiusLG || 8,
          boxShadow: token?.boxShadow,
          marginBottom: '16px'
        }}>
          <h4 style={{
            marginTop: 0,
            fontSize: '15px',
            fontWeight: 600,
            color: token?.colorText,
            marginBottom: '12px',
            paddingBottom: '8px',
            borderBottom: `1px solid ${token?.colorBorderSecondary}`,
            display: 'flex',
            alignItems: 'center'
          }}>
            ℹ️ 核心信息
          </h4>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px 24px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <div style={{ fontSize: '13px', color: token?.colorTextTertiary, display: 'flex', alignItems: 'center', gap: '6px' }}>
                <UserOutlined style={{ fontSize: '14px' }} />
                <span>作者</span>
              </div>
              <div style={{ fontSize: '15px', fontWeight: 600, color: token?.colorText }}>
                {previewContent.author || '未知'}
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <div style={{ fontSize: '13px', color: token?.colorTextTertiary, display: 'flex', alignItems: 'center', gap: '6px' }}>
                <GlobalOutlined style={{ fontSize: '14px' }} />
                <span>平台</span>
              </div>
              <div style={{ fontSize: '15px', fontWeight: 600, color: token?.colorText }}>
                {previewContent.platform || '未知'}
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <div style={{ fontSize: '13px', color: token?.colorTextTertiary, display: 'flex', alignItems: 'center', gap: '6px' }}>
                <VideoCameraOutlined style={{ fontSize: '14px' }} />
                <span>类型</span>
              </div>
              <div style={{ fontSize: '14px', fontWeight: 500, color: token?.colorText }}>
                {previewContent.media_type === 'video' ? '视频' : '图片'}
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <div style={{ fontSize: '13px', color: token?.colorTextTertiary, display: 'flex', alignItems: 'center', gap: '6px' }}>
                <DownloadOutlined style={{ fontSize: '14px' }} />
                <span>来源</span>
              </div>
              <div style={{ fontSize: '14px', fontWeight: 500, color: token?.colorText }}>
                {previewContent.source_type === 1 ? '单链接解析' : '监控任务'}
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <div style={{ fontSize: '13px', color: token?.colorTextTertiary, display: 'flex', alignItems: 'center', gap: '6px' }}>
                <ClockCircleOutlined style={{ fontSize: '14px' }} />
                <span>采集时间</span>
              </div>
              <div style={{ fontSize: '14px', fontWeight: 500, color: token?.colorText }}>
                {new Date(previewContent.created_at).toLocaleString()}
              </div>
            </div>
            {previewContent.publish_time && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <div style={{ fontSize: '13px', color: token?.colorTextTertiary, display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <ClockCircleOutlined style={{ fontSize: '14px' }} />
                  <span>发布时间</span>
                </div>
                <div style={{ fontSize: '14px', fontWeight: 500, color: token?.colorText }}>
                  {new Date(previewContent.publish_time).toLocaleString()}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* 内容描述（AI生成的描述）*/}
        {previewContent.description && (
          <div style={{
            padding: '16px',
            backgroundColor: `${token?.colorSuccess}15`,
            border: `1px solid ${token?.colorSuccess}40`,
            borderRadius: token?.borderRadiusLG || 8,
            marginBottom: '16px'
          }}>
            <h4 style={{
              marginTop: 0,
              marginBottom: '12px',
              fontSize: '15px',
              fontWeight: 600,
              color: token?.colorSuccess,
              display: 'flex',
              alignItems: 'center'
            }}>
              📝 内容描述
            </h4>
            <p style={{
              margin: 0,
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-word',
              lineHeight: '1.8',
              color: token?.colorText,
              fontSize: '14px'
            }}>
              {previewContent.description}
            </p>
          </div>
        )}

        {/* 统计数据 */}
        {(previewContent.like_count || previewContent.collect_count ||
          previewContent.comment_count || previewContent.share_count ||
          previewContent.view_count) && (
          <div style={{
            padding: '16px',
            backgroundColor: token?.colorFillSecondary,
            borderRadius: token?.borderRadiusLG || 8,
            border: `1px solid ${token?.colorBorderSecondary}`,
            marginBottom: '16px'
          }}>
            <h4 style={{
              marginTop: 0,
              fontSize: '15px',
              fontWeight: 600,
              color: token?.colorText,
              marginBottom: '12px'
            }}>
              📊 互动数据
            </h4>
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(4, 1fr)',
              gap: '12px'
            }}>
              {previewContent.like_count !== undefined && previewContent.like_count !== null && (
                <div
                  style={{
                    backgroundColor: token?.colorBgContainer,
                    padding: '12px',
                    borderRadius: token?.borderRadius || 6,
                    border: `1px solid ${token?.colorBorder}`,
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    cursor: 'default'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = token?.colorPrimary;
                    e.currentTarget.style.boxShadow = token?.boxShadow;
                    e.currentTarget.style.transform = 'translateY(-2px)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = 'transparent';
                    e.currentTarget.style.boxShadow = 'none';
                    e.currentTarget.style.transform = 'translateY(0)';
                  }}
                >
                  <LikeOutlined style={{ fontSize: '24px', marginBottom: '8px', display: 'block', color: token?.colorTextSecondary }} />
                  <div style={{ fontSize: '13px', color: token?.colorTextSecondary, marginBottom: '6px' }}>点赞</div>
                  <div style={{ fontSize: '20px', fontWeight: 700, color: token?.colorText, fontFamily: 'SF Mono, Monaco, Consolas, monospace' }}>
                    {previewContent.like_count.toLocaleString()}
                  </div>
                </div>
              )}
              {previewContent.collect_count !== undefined && previewContent.collect_count !== null && (
                <div
                  style={{
                    backgroundColor: token?.colorBgContainer,
                    padding: '12px',
                    borderRadius: token?.borderRadius || 6,
                    border: `1px solid ${token?.colorBorder}`,
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    cursor: 'default'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = token?.colorPrimary;
                    e.currentTarget.style.boxShadow = token?.boxShadow;
                    e.currentTarget.style.transform = 'translateY(-2px)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = 'transparent';
                    e.currentTarget.style.boxShadow = 'none';
                    e.currentTarget.style.transform = 'translateY(0)';
                  }}
                >
                  <StarOutlined style={{ fontSize: '24px', marginBottom: '8px', display: 'block', color: token?.colorTextSecondary }} />
                  <div style={{ fontSize: '13px', color: token?.colorTextSecondary, marginBottom: '6px' }}>收藏</div>
                  <div style={{ fontSize: '20px', fontWeight: 700, color: token?.colorText, fontFamily: 'SF Mono, Monaco, Consolas, monospace' }}>
                    {previewContent.collect_count.toLocaleString()}
                  </div>
                </div>
              )}
              {previewContent.comment_count !== undefined && previewContent.comment_count !== null && (
                <div
                  style={{
                    backgroundColor: token?.colorBgContainer,
                    padding: '12px',
                    borderRadius: token?.borderRadius || 6,
                    border: `1px solid ${token?.colorBorder}`,
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    cursor: 'default'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = token?.colorPrimary;
                    e.currentTarget.style.boxShadow = token?.boxShadow;
                    e.currentTarget.style.transform = 'translateY(-2px)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = 'transparent';
                    e.currentTarget.style.boxShadow = 'none';
                    e.currentTarget.style.transform = 'translateY(0)';
                  }}
                >
                  <MessageOutlined style={{ fontSize: '24px', marginBottom: '8px', display: 'block', color: token?.colorTextSecondary }} />
                  <div style={{ fontSize: '13px', color: token?.colorTextSecondary, marginBottom: '6px' }}>评论</div>
                  <div style={{ fontSize: '20px', fontWeight: 700, color: token?.colorText, fontFamily: 'SF Mono, Monaco, Consolas, monospace' }}>
                    {previewContent.comment_count.toLocaleString()}
                  </div>
                </div>
              )}
              {previewContent.share_count !== undefined && previewContent.share_count !== null && (
                <div
                  style={{
                    backgroundColor: token?.colorBgContainer,
                    padding: '12px',
                    borderRadius: token?.borderRadius || 6,
                    border: `1px solid ${token?.colorBorder}`,
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    cursor: 'default'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = token?.colorPrimary;
                    e.currentTarget.style.boxShadow = token?.boxShadow;
                    e.currentTarget.style.transform = 'translateY(-2px)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = 'transparent';
                    e.currentTarget.style.boxShadow = 'none';
                    e.currentTarget.style.transform = 'translateY(0)';
                  }}
                >
                  <ShareAltOutlined style={{ fontSize: '24px', marginBottom: '8px', display: 'block', color: token?.colorTextSecondary }} />
                  <div style={{ fontSize: '13px', color: token?.colorTextSecondary, marginBottom: '6px' }}>分享</div>
                  <div style={{ fontSize: '20px', fontWeight: 700, color: token?.colorText, fontFamily: 'SF Mono, Monaco, Consolas, monospace' }}>
                    {previewContent.share_count.toLocaleString()}
                  </div>
                </div>
              )}
              {previewContent.view_count !== undefined && previewContent.view_count !== null && (
                <div
                  style={{
                    backgroundColor: token?.colorBgContainer,
                    padding: '12px',
                    borderRadius: token?.borderRadius || 6,
                    border: `1px solid ${token?.colorBorder}`,
                    textAlign: 'center',
                    transition: 'all 0.3s ease',
                    cursor: 'default',
                    gridColumn: 'span 1'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = token?.colorPrimary;
                    e.currentTarget.style.boxShadow = token?.boxShadow;
                    e.currentTarget.style.transform = 'translateY(-2px)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = 'transparent';
                    e.currentTarget.style.boxShadow = 'none';
                    e.currentTarget.style.transform = 'translateY(0)';
                  }}
                >
                  <EyeOutlined style={{ fontSize: '24px', marginBottom: '8px', display: 'block', color: token?.colorTextSecondary }} />
                  <div style={{ fontSize: '13px', color: token?.colorTextSecondary, marginBottom: '6px' }}>浏览</div>
                  <div style={{ fontSize: '20px', fontWeight: 700, color: token?.colorText, fontFamily: 'SF Mono, Monaco, Consolas, monospace' }}>
                    {previewContent.view_count.toLocaleString()}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* 标签 */}
        {((previewContent.tags && previewContent.tags.length > 0) ||
          (aiAnalysisStatusMap[previewContent?.id]?.ai_tags &&
           aiAnalysisStatusMap[previewContent?.id]?.ai_tags.length > 0)) && (
          <div style={{
            padding: '16px',
            backgroundColor: `${token?.colorPrimary}10`,
            border: `1px solid ${token?.colorPrimary}40`,
            borderRadius: token?.borderRadiusLG || 8,
            marginBottom: '16px'
          }}>
            <h4 style={{
              marginTop: 0,
              marginBottom: '12px',
              fontSize: '15px',
              fontWeight: 600,
              color: token?.colorPrimary
            }}>
              🏷️ 标签管理
            </h4>
            <Space direction="vertical" size="small" style={{ width: '100%' }}>
              {/* 手动添加的标签 */}
              {previewContent.tags && previewContent.tags.length > 0 && (
                <div style={{ marginBottom: '12px' }}>
                  <div style={{
                    fontSize: '13px',
                    color: token?.colorTextSecondary,
                    marginBottom: '8px',
                    fontWeight: 500
                  }}>
                    手动标签
                  </div>
                  <Space size="small" wrap>
                    {previewContent.tags.map((tag) => (
                      <Tag key={tag.id} color={tag.color}>
                        {tag.name}
                      </Tag>
                    ))}
                  </Space>
                </div>
              )}
              {/* AI生成的标签 */}
              {aiAnalysisStatusMap[previewContent?.id]?.ai_tags &&
               aiAnalysisStatusMap[previewContent?.id]?.ai_tags.length > 0 && (
                <>
                  {previewContent.tags && previewContent.tags.length > 0 && (
                    <div style={{
                      borderTop: `1px solid ${token?.colorBorderSecondary}`,
                      margin: '8px 0'
                    }} />
                  )}
                  <div>
                    <div style={{
                      fontSize: '13px',
                      color: token?.colorTextSecondary,
                      marginBottom: '8px',
                      fontWeight: 500
                    }}>
                      🤖 AI标签
                    </div>
                    <Space size="small" wrap>
                      {aiAnalysisStatusMap[previewContent?.id].ai_tags.map((tag) => (
                        <Tag key={`ai-${tag}`} color="blue">
                          {tag}
                        </Tag>
                      ))}
                    </Space>
                  </div>
                </>
              )}
            </Space>
          </div>
        )}

        {/* 原始链接 */}
        {previewContent.source_url && (
          <div style={{
            padding: '12px 0',
            borderTop: `1px solid ${token?.colorBorderSecondary}`,
            marginTop: '16px'
          }}>
            <a
              href={previewContent.source_url}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                color: token?.colorLink,
                textDecoration: 'none',
                fontSize: '13px',
                wordBreak: 'break-all',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.textDecoration = 'underline';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.textDecoration = 'none';
              }}
            >
              <LinkOutlined />
              {previewContent.source_url}
            </a>
          </div>
        )}
      </Space>
    );
  };

  // 获取分析阶段标签
  const getStageLabel = (stage) => {
    const stageLabels = {
      'initializing': '初始化中...',
      'ocr': 'OCR提取文字中...',
      'generating_tags': '生成标签中...',
      'generating_description': '生成描述中...'
    };
    return stageLabels[stage] || stage;
  };

  // 获取分析阶段进度百分比
  const getStageProgress = (stage) => {
    const stageProgress = {
      'initializing': 10,
      'ocr': 35,
      'generating_tags': 70,
      'generating_description': 95
    };
    return stageProgress[stage] || 0;
  };

  const renderAiAnalysisTab = () => {
    // 从 aiAnalysisStatusMap 获取当前内容的分析结果
    const currentAiStatus = aiAnalysisStatusMap[previewContent?.id] || {};
    const hasAiAnalysis = currentAiStatus?.has_analysis;
    const aiTags = currentAiStatus?.ai_tags || [];
    const aiDescription = currentAiStatus?.description || previewContent?.description || '';
    const ocrResults = currentAiStatus?.ocr_results || [];
    const stages = currentAiStatus?.stages || {};

    return (
      <Space orientation="vertical" size="middle" style={{ width: '100%' }}>
        {/* 分析状态总览 */}
        <div style={{ padding: '12px', backgroundColor: `${token?.colorPrimary}10`, border: `1px solid ${token?.colorPrimary}`, borderRadius: '8px' }}>
          <h4 style={{ marginTop: 0, color: token?.colorPrimary }}>⚙️ 分析状态</h4>
          <Space direction="vertical" size="small" style={{ width: '100%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Space>
                <Badge
                  status={
                    currentAiStatus?.is_processing ? 'processing' :
                    hasAiAnalysis ? 'success' : 'default'
                  }
                  text={
                    currentAiStatus?.is_processing ? '分析中' :
                    hasAiAnalysis ? '已分析' : '未分析'
                  }
                />
                {currentAiStatus?.execution_time && (
                  <span style={{ color: token?.colorTextTertiary, fontSize: 12 }}>
                    (总耗时: {currentAiStatus.execution_time}ms)
                  </span>
                )}
              </Space>
            </div>

            {/* 进度条 */}
            {currentAiStatus?.is_processing && (
              <div style={{ marginTop: 8 }}>
                <div style={{ marginBottom: 4, fontSize: 12, color: token?.colorTextTertiary }}>
                  当前阶段: {getStageLabel(currentAiStatus.current_stage)}
                </div>
                <Progress
                  percent={getStageProgress(currentAiStatus.current_stage)}
                  status="active"
                  strokeColor={{
                    '0%': token?.colorPrimary,
                    '100%': token?.colorSuccess,
                  }}
                />
              </div>
            )}

            {/* 各阶段状态 */}
            {hasAiAnalysis && stages && (
              <div style={{ marginTop: 8 }}>
                <Space size="small" wrap>
                  <Badge
                    status={stages.ocr?.success ? 'success' : 'error'}
                    text={`OCR提取${stages.ocr?.duration ? ` (${stages.ocr.duration}ms)` : ''}`}
                  />
                  <Badge
                    status={stages.tags?.success ? 'success' : 'error'}
                    text={`标签生成${stages.tags?.duration ? ` (${stages.tags.duration}ms)` : ''}`}
                  />
                  <Badge
                    status={stages.description?.success ? 'success' : 'error'}
                    text={`描述生成${stages.description?.duration ? ` (${stages.description.duration}ms)` : ''}`}
                  />
                </Space>
              </div>
            )}
          </Space>
        </div>

        {/* AI生成的标签 */}
        {aiTags.length > 0 && (
          <div style={{ padding: '12px', backgroundColor: '#f0f5ff', border: '1px solid #adc6ff', borderRadius: '8px' }}>
            <h4 style={{ marginTop: 0, color: '#2f54eb' }}>🏷️ AI生成的标签</h4>
            <div style={{ marginTop: 8 }}>
              <Space size="small" wrap>
                {aiTags.map((tag, index) => (
                  <Tag
                    key={index}
                    color={tag.color || 'blue'}
                    style={{ marginBottom: 4, fontSize: 14 }}
                  >
                    {tag.name}
                  </Tag>
                ))}
              </Space>
            </div>
          </div>
        )}

        {/* AI生成的描述 */}
        {aiDescription && (
          <div style={{ padding: '12px', backgroundColor: `${token?.colorSuccess}10`, border: `1px solid ${token?.colorSuccess}`, borderRadius: '8px' }}>
            <h4 style={{ marginTop: 0, color: token?.colorSuccess }}>📝 AI生成的描述</h4>
            <p style={{
              margin: 0,
              marginTop: 8,
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-word',
              lineHeight: '1.8',
              color: '#262626',
              fontSize: 14
            }}>
              {aiDescription}
            </p>
          </div>
        )}

        {/* OCR识别结果 */}
        {ocrResults.length > 0 && (
          <div style={{ padding: '12px', backgroundColor: '#fff7e6', border: '1px solid #ffd591', borderRadius: '8px' }}>
            <h4 style={{ marginTop: 0, color: '#fa8c16' }}>
              🔍 图片中提取的文字
              <span style={{ fontSize: 12, color: token?.colorTextTertiary }}>
                ({ocrResults.length}张图片)
              </span>
            </h4>
            <List
              size="small"
              dataSource={ocrResults.filter(r => r.text && r.text.length > 0)}
              renderItem={(item, index) => (
                <List.Item key={index}>
                  <Space direction="vertical" size={0} style={{ width: '100%' }}>
                    <div style={{ fontSize: 12, color: token?.colorTextTertiary }}>
                      图片 {index + 1}
                    </div>
                    <div style={{
                      padding: '8px',
                      backgroundColor: 'white',
                      borderRadius: '4px',
                      fontSize: 13,
                      lineHeight: '1.6'
                    }}>
                      {item.text}
                    </div>
                    {item.confidence && (
                      <div style={{ fontSize: 11, color: token?.colorTextTertiary }}>
                        置信度: {Math.round(item.confidence * 100)}%
                      </div>
                    )}
                  </Space>
                </List.Item>
              )}
            />
          </div>
        )}

        {/* 未分析状态提示 */}
        {!hasAiAnalysis && (
          <Empty
            description={
              <Space direction="vertical" size="small">
                <Text type="secondary">该内容尚未进行AI分析</Text>
                <Text type="secondary" style={{ fontSize: 12 }}>
                  点击上方"AI分析"按钮开始分析
                </Text>
              </Space>
            }
            image={Empty.PRESENTED_IMAGE_SIMPLE}
          />
        )}
      </Space>
    );
  };

  // Load content list on component mount and when pagination changes
  useEffect(() => {
    getContentList();
  }, [pagination]);

  // Load content list on initial mount (show all content by default)
  useEffect(() => {
    getContentList();
  }, []); // Empty dependency array ensures this runs only once on mount

  return (
    <div style={{ width: '100%', maxWidth: 'none' }}>
      <Space orientation="vertical" size="large" style={{ width: '100%' }}>
      <Card title="筛选条件">
        <Space wrap>
          <Input 
            placeholder="搜索标题/作者" 
            prefix={<SearchOutlined />} 
            style={{ width: 300 }}
            value={filters.keyword}
            onChange={(e) => handleFilterChange('keyword', e.target.value)}
            onPressEnter={handleSearch}
            allowClear
          />
          <Select 
            placeholder="选择平台" 
            style={{ width: 150 }}
            value={filters.platform || undefined}
            onChange={(value) => handleFilterChange('platform', value)}
            allowClear
          >
            <Select.Option value="douyin">抖音</Select.Option>
            <Select.Option value="xiaohongshu">小红书</Select.Option>
            <Select.Option value="kuaishou">快手</Select.Option>
            <Select.Option value="bilibili">B站</Select.Option>
            <Select.Option value="weibo">微博</Select.Option>
          </Select>
          <Select 
            placeholder="选择类型" 
            style={{ width: 120 }}
            value={filters.media_type || undefined}
            onChange={(value) => handleFilterChange('media_type', value)}
            allowClear
          >
            <Select.Option value="video">视频</Select.Option>
            <Select.Option value="image">图片</Select.Option>
          </Select>
          <Select 
            placeholder="选择来源" 
            style={{ width: 150 }}
            value={filters.source_type || undefined}
            onChange={(value) => handleFilterChange('source_type', value)}
            allowClear
          >
            <Select.Option value="1">单链接解析</Select.Option>
            <Select.Option value="2">监控任务</Select.Option>
          </Select>
          <RangePicker
            placeholder={['开始日期', '结束日期']}
            style={{ width: 300 }}
            value={filters.date_range}
            onChange={(date) => handleFilterChange('date_range', date)}
          />
          <Button type="primary" onClick={handleSearch}>筛选</Button>
          <Button onClick={handleReset}>重置</Button>
        </Space>

        {/* Tag Filter - 独立一行 */}
        <div style={{ marginTop: '16px' }}>
          <TagFilter
            value={filters.tags}
            onChange={(value) => handleFilterChange('tags', value)}
          />
        </div>

        
        {/* Filter status indicator */}
        <div style={{ 
          marginTop: '12px', 
          padding: '8px 12px', 
          backgroundColor: hasActiveFilters() ? '#e6f7ff' : '#f6ffed',
          border: `1px solid ${hasActiveFilters() ? '#91d5ff' : '#b7eb8f'}`,
          borderRadius: '6px',
          fontSize: '14px',
          color: hasActiveFilters() ? '#1890ff' : '#52c41a'
        }}>
          <span style={{ fontWeight: '500' }}>
            {getFilterStatusText()}
          </span>
          {total > 0 && (
            <span style={{ marginLeft: '8px', color: token?.colorTextTertiary }}>
              (共 {total} 条记录)
            </span>
          )}
        </div>
      </Card>
      
      <Card>
        <Space orientation="vertical" size="middle" style={{ width: '100%' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
            <Space wrap>
              <Button
                type="primary"
                danger
                onClick={handleBatchDelete}
                disabled={selectedRowKeys.length === 0}
              >
                批量删除 ({selectedRowKeys.length})
              </Button>
              <Button
                icon={<TagOutlined />}
                onClick={() => setBatchTagModalVisible(true)}
                disabled={selectedRowKeys.length === 0}
              >
                批量打标签 ({selectedRowKeys.length})
              </Button>
              <Button
                type="primary"
                icon={<DownloadOutlined />}
                onClick={handleBatchDownload}
                disabled={selectedRowKeys.length === 0}
              >
                批量下载 ({selectedRowKeys.length})
              </Button>
            </Space>
            <Dropdown
              trigger={['click']}
              placement="bottomRight"
              popupRender={() => columnSettingsMenu}
            >
              <Button icon={<SettingOutlined />}>
                列设置
              </Button>
            </Dropdown>
          </div>
          
          <Table
            dataSource={contentList}
            columns={getFilteredColumns()} 
            rowKey="id"
            pagination={{
              current: pagination.current,
              pageSize: pagination.pageSize,
              total,
              onChange: handlePaginationChange,
              showSizeChanger: true,
              pageSizeOptions: ['10', '20', '50', '100'],
              showTotal: (total, range) => 
                `显示第 ${range[0]}-${range[1]} 条记录，共 ${total} 条`,
            }}
            rowSelection={rowSelection}
            loading={loading}
            locale={{
              emptyText: hasActiveFilters() 
                ? '没有找到符合筛选条件的内容' 
                : '暂无内容数据，请先添加一些内容'
            }}
          />
        </Space>
      </Card>

      {/* Content Preview Modal */}
      <Modal
        title={
          <Space>
            <span>{previewContent?.title || '内容预览'}</span>
            {previewContent?.is_missing && (
              <Tag color="error">已消失</Tag>
            )}
          </Space>
        }
        open={previewVisible}
        onCancel={() => setPreviewVisible(false)}
        footer={null}
        width={900}
      >
        {previewContent && (
          <Space orientation="vertical" size="middle" style={{ width: '100%' }}>
            {/* 顶部操作栏 */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid #f0f0f0' }}>
              <Space>
                {previewContent?.is_missing && <Tag color="error">⚠️ 笔记已消失</Tag>}
              </Space>
              <Space>
                <Button
                  icon={<ReloadOutlined />}
                  onClick={handleRefreshStats}
                  loading={refreshingStats}
                  type="default"
                  size="small"
                >
                  刷新统计数据
                </Button>
                <Button
                  type="primary"
                  icon={<RobotOutlined />}
                  loading={aiLoading[previewContent?.id]}
                  onClick={() => handleAiAnalyze(previewContent?.id)}
                >
                  AI分析
                </Button>
              </Space>
            </div>

            {/* Tabs内容 */}
            <Tabs
              defaultActiveKey="basic"
              items={[
                {
                  key: 'basic',
                  label: '基本信息',
                  children: renderBasicInfoTab()
                },
                {
                  key: 'ai-analysis',
                  label: 'AI分析总结',
                  children: renderAiAnalysisTab()
                }
              ]}
            />
          </Space>
        )}
      </Modal>

      {/* Batch Tag Modal */}
      <BatchTagModal
        visible={batchTagModalVisible}
        onCancel={() => setBatchTagModalVisible(false)}
        onConfirm={handleBatchTagOperation}
        selectedCount={selectedRowKeys.length}
      />

      {/* AI Description Modal */}
      <DescriptionModal
        visible={descriptionModalVisible}
        data={currentDescription}
        onClose={() => setDescriptionModalVisible(false)}
      />
    </Space>
    </div>
  );
};

export default ContentManagement;
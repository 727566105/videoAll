import { useState, useEffect } from 'react';
import { Card, Typography, Space, Table, Button, Input, Select, DatePicker, message, Modal, Image } from 'antd';
import { SearchOutlined, DownloadOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import apiService from '../services/api';

const { Title } = Typography;
const { RangePicker } = DatePicker;

const ContentManagement = () => {
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
    date_range: null
  });
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10
  });
  // Preview modal state
  const [previewVisible, setPreviewVisible] = useState(false);
  const [previewContent, setPreviewContent] = useState(null);

  // Columns definition
  const columns = [
    {
      title: '封面',
      dataIndex: 'cover_url',
      key: 'cover_url',
      render: (cover_url) => (
        <img 
          src={`/api/v1/content/proxy-image?url=${encodeURIComponent(cover_url)}`} 
          alt="封面" 
          style={{ width: 80, height: 60, objectFit: 'cover', borderRadius: 4 }}
          onError={(e) => {
            e.target.src = 'https://via.placeholder.com/80x60?text=加载失败';
          }}
        />
      )
    },
    {
      title: '标题',
      dataIndex: 'title',
      key: 'title',
      ellipsis: true
    },
    {
      title: '作者',
      dataIndex: 'author',
      key: 'author'
    },
    {
      title: '平台',
      dataIndex: 'platform',
      key: 'platform'
    },
    {
      title: '类型',
      dataIndex: 'media_type',
      key: 'media_type',
      render: (type, record) => {
        if (type === 'video') {
          const videoCount = record.all_videos && record.all_videos.length > 0 ? record.all_videos.length : 1;
          return `视频 (${videoCount}个)`;
        } else {
          const imageCount = record.all_images && record.all_images.length > 0 ? record.all_images.length : 1;
          return type === 'image' && imageCount > 1 ? `图片 (${imageCount}张)` : '图片';
        }
      }
    },
    {
      title: '来源',
      dataIndex: 'source_type',
      key: 'source_type',
      render: (type) => type === 1 ? '单链接解析' : '监控任务'
    },
    {
      title: '采集时间',
      dataIndex: 'created_at',
      key: 'created_at',
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
    },
    {
      title: '操作',
      key: 'action',
      width: 180,
      fixed: 'right',
      render: (_, record) => (
        <Space size="small" wrap>
          <Button type="link" icon={<EyeOutlined />} onClick={() => handlePreview(record)}>预览</Button>
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

  // Row selection configuration
  const rowSelection = {
    selectedRowKeys,
    onChange: setSelectedRowKeys
  };

  // Get content list from backend
  const getContentList = async () => {
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
      
      // Call backend API
      const result = await apiService.content.getList(params);
      
      // Update state with real data or fallback structure
      const contentData = result.data || result;
      setContentList(contentData.list || []);
      setTotal(contentData.total || 0);
    } catch (error) {
      console.error('Get content list error:', error);
      // Show empty list when API fails instead of mock data
      setContentList([]);
      setTotal(0);
      message.error('获取内容列表失败，请检查后端服务是否正常运行');
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
      date_range: null
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
      filters.date_range
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
    setPreviewContent(record);
    setPreviewVisible(true);
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

  // Load content list on component mount and when pagination changes
  useEffect(() => {
    getContentList();
  }, [pagination]);

  // Load content list on initial mount (show all content by default)
  useEffect(() => {
    getContentList();
  }, []); // Empty dependency array ensures this runs only once on mount

  return (
    <Space direction="vertical" size="large" style={{ width: '100%' }}>
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
            <span style={{ marginLeft: '8px', color: '#666' }}>
              (共 {total} 条记录)
            </span>
          )}
        </div>
      </Card>
      
      <Card>
        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
          <Space wrap style={{ justifyContent: 'flex-end' }}>
            <Button
              type="primary"
              danger
              onClick={handleBatchDelete}
              disabled={selectedRowKeys.length === 0}
            >
              批量删除 ({selectedRowKeys.length})
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
          
          <Table 
            dataSource={contentList} 
            columns={columns} 
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
        title={previewContent?.title || '内容预览'}
        open={previewVisible}
        onCancel={() => setPreviewVisible(false)}
        footer={null}
        width={900}
      >
        {previewContent && (
          <Space direction="vertical" size="middle" style={{ width: '100%' }}>
          {previewContent.media_type === 'video' ? (
            <div>
              <h4>视频预览</h4>
              {/* 主视频预览 */}
              <video 
                src={previewContent.file_path ? `/media/${previewContent.file_path}` : `/api/v1/content/proxy-download?url=${encodeURIComponent(previewContent.media_url || previewContent.cover_url)}`} 
                controls 
                style={{ width: '100%', maxHeight: '400px', marginBottom: '15px' }}
              />
              
              {/* 显示所有视频URL */}
              {previewContent.all_videos && previewContent.all_videos.length > 0 && (
                <div>
                  <h5>可用视频链接 ({previewContent.all_videos.length}个):</h5>
                  <div style={{ backgroundColor: '#f9f9f9', padding: '15px', borderRadius: '8px' }}>
                    {previewContent.all_videos.map((videoUrl, index) => (
                      <div key={index} style={{ 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'space-between',
                        padding: '8px 0',
                        borderBottom: index < previewContent.all_videos.length - 1 ? '1px solid #e8e8e8' : 'none'
                      }}>
                        <div style={{ flex: 1 }}>
                          <span style={{ fontWeight: 'bold' }}>
                            视频 {index + 1}: 
                          </span>
                          <span style={{ fontSize: 12, color: '#999', marginLeft: 8 }}>
                            {videoUrl.includes('sns-video-hw') ? '主服务器' : 
                             videoUrl.includes('sns-bak-v1') ? '备用服务器1' :
                             videoUrl.includes('sns-bak-v6') ? '备用服务器6' : '其他服务器'}
                          </span>
                        </div>
                        <Space>
                          <Button 
                            size="small" 
                            type="link"
                            onClick={() => window.open(videoUrl, '_blank')}
                          >
                            打开链接
                          </Button>
                        </Space>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ) : (
            <>
              {/* 显示所有图片 */}
              {previewContent.all_images && previewContent.all_images.length > 0 ? (
                <div>
                  <h4>图片列表 ({previewContent.all_images.length}张)</h4>
                  <div style={{ 
                    display: 'grid', 
                    gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', 
                    gap: '10px',
                    maxHeight: '500px',
                    overflowY: 'auto',
                    padding: '10px',
                    backgroundColor: '#f5f5f5',
                    borderRadius: '8px'
                  }}>
                    {previewContent.all_images.map((imgUrl, index) => (
                      <div key={index} style={{ textAlign: 'center' }}>
                        <Image
                          src={`/api/v1/content/proxy-image?url=${encodeURIComponent(imgUrl)}`}
                          alt={`图片 ${index + 1}`}
                          style={{ 
                            width: '100%', 
                            height: '150px', 
                            objectFit: 'cover', 
                            borderRadius: '4px',
                            cursor: 'pointer'
                          }}
                          fallback="https://via.placeholder.com/150x150?text=加载失败"
                        />
                        <div style={{ fontSize: '12px', color: '#666', marginTop: '5px' }}>
                          图片 {index + 1}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <Image
                  src={`/api/v1/content/proxy-image?url=${encodeURIComponent(previewContent.cover_url)}`}
                  alt={previewContent.title}
                  style={{ maxWidth: '100%', maxHeight: '400px' }}
                  fallback="https://via.placeholder.com/400x300?text=图片加载失败"
                />
              )}
            </>
          )}
            <div style={{ marginBottom: '16px' }}>
              <h4>基本信息</h4>
              <div>作者: {previewContent.author || '未知'}</div>
              <div>平台: {previewContent.platform || '未知'}</div>
              <div>类型: {previewContent.media_type === 'video' ? '视频' : '图片'}</div>
              <div>来源: {previewContent.source_type === 1 ? '单链接解析' : '监控任务'}</div>
              <div>采集时间: {new Date(previewContent.created_at).toLocaleString()}</div>
            </div>
            {previewContent.description && (
              <div>
                <h4>描述</h4>
                <p>{previewContent.description}</p>
              </div>
            )}
            {previewContent.source_url && (
              <div>
                <h4>原始链接</h4>
                <a href={previewContent.source_url} target="_blank" rel="noopener noreferrer">
                  {previewContent.source_url}
                </a>
              </div>
            )}
          </Space>
        )}
      </Modal>
    </Space>
  );
};

export default ContentManagement;
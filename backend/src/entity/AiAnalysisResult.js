/**
 * AI分析结果实体
 *
 * 存储AI对内容的分析结果，包括生成的标签、置信度分数、分析状态等
 * 支持重试机制和缓存功能
 */

const { EntitySchema } = require('typeorm');

module.exports = new EntitySchema({
  name: 'AiAnalysisResult',
  tableName: 'ai_analysis_results',
  columns: {
    id: {
      primary: true,
      type: 'uuid',
      generated: 'uuid',
    },
    // 关联的内容ID
    content_id: {
      type: 'uuid',
      nullable: false,
      comment: '关联的内容ID'
    },
    // 使用的AI配置ID
    ai_config_id: {
      type: 'uuid',
      nullable: true,
      comment: '使用的AI配置ID'
    },
    // AI分析结果（JSON格式，存储原始分析结果）
    analysis_result: {
      type: 'json',
      nullable: true,
      comment: 'AI分析原始结果'
    },
    // 生成的标签（JSON格式）
    generated_tags: {
      type: 'json',
      nullable: true,
      comment: 'AI生成的标签列表'
    },
    // 置信度分数（JSON格式）
    confidence_scores: {
      type: 'json',
      nullable: true,
      comment: '各标签的置信度分数'
    },
    // 分析状态
    status: {
      type: 'varchar',
      length: 20,
      default: 'pending',
      comment: '分析状态：pending-等待中、processing-处理中、completed-完成、failed-失败'
    },
    // 当前分析阶段
    current_stage: {
      type: 'varchar',
      length: 50,
      nullable: true,
      comment: '当前分析阶段：initializing-初始化、ocr-OCR提取、generating_tags-生成标签、generating_description-生成描述'
    },
    // 重试次数
    retry_count: {
      type: 'int',
      default: 0,
      comment: '已重试次数'
    },
    // 错误信息
    error_message: {
      type: 'text',
      nullable: true,
      comment: '错误信息'
    },
    // 分析耗时（毫秒）
    execution_time: {
      type: 'int',
      nullable: true,
      comment: 'AI分析耗时（毫秒）'
    },
    // 消耗的token数量
    tokens_used: {
      type: 'int',
      nullable: true,
      comment: '消耗的token数量'
    },
    // 分析类型
    analysis_type: {
      type: 'varchar',
      length: 50,
      default: 'tag_generation',
      comment: '分析类型：tag_generation-标签生成、content_summary-内容摘要、sentiment_analysis-情感分析'
    },
    // 创建时间
    created_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
    },
    // 更新时间
    updated_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      onUpdate: true,
    },
    // 完成时间
    completed_at: {
      type: 'timestamp',
      nullable: true,
      comment: '分析完成时间'
    },
  },
  indices: [
    {
      name: 'IDX_AI_RESULT_CONTENT',
      columns: ['content_id'],
    },
    {
      name: 'IDX_AI_RESULT_CONFIG',
      columns: ['ai_config_id'],
    },
    {
      name: 'IDX_AI_RESULT_STATUS',
      columns: ['status'],
    },
    {
      name: 'IDX_AI_RESULT_CREATED',
      columns: ['created_at'],
    },
    {
      name: 'IDX_AI_RESULT_CONTENT_STATUS',
      columns: ['content_id', 'status'],
    },
  ],
  relations: {
    // 关联内容
    content: {
      type: 'many-to-one',
      target: 'Content',
      joinColumn: {
        name: 'content_id',
        referencedColumnName: 'id',
      },
      onDelete: 'CASCADE',
    },
    // 关联AI配置
    aiConfig: {
      type: 'many-to-one',
      target: 'AiConfig',
      joinColumn: {
        name: 'ai_config_id',
        referencedColumnName: 'id',
      },
      onDelete: 'SET NULL',
    },
  },
});

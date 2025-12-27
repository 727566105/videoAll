/**
 * AI配置实体
 *
 * 存储AI API配置信息，包括提供商、API端点、加密的API密钥等
 * 支持多种AI服务提供商（Ollama、OpenAI、Anthropic等）
 */

const { EntitySchema } = require('typeorm');

module.exports = new EntitySchema({
  name: 'AiConfig',
  tableName: 'ai_configs',
  columns: {
    id: {
      primary: true,
      type: 'uuid',
      generated: 'uuid',
    },
    // 提供商名称（ollama, openai, anthropic, custom等）
    provider: {
      type: 'varchar',
      length: 50,
      nullable: false,
      comment: 'AI服务提供商'
    },
    // API端点URL
    api_endpoint: {
      type: 'varchar',
      length: 500,
      nullable: true,
      comment: 'API端点URL'
    },
    // 加密的API密钥
    api_key_encrypted: {
      type: 'text',
      nullable: true,
      comment: '加密的API密钥'
    },
    // 模型名称
    model: {
      type: 'varchar',
      length: 100,
      nullable: true,
      comment: '模型名称，如 qwen2.5:7b、gpt-4o'
    },
    // 超时时间（毫秒）
    timeout: {
      type: 'int',
      default: 60000,
      comment: 'API调用超时时间（毫秒）'
    },
    // 是否启用AI分析
    is_enabled: {
      type: 'boolean',
      default: false,
      comment: '是否启用AI分析功能'
    },
    // 优先级（数值越小优先级越高）
    priority: {
      type: 'int',
      default: 0,
      comment: '配置优先级，用于多配置场景'
    },
    // 其他偏好设置（JSON格式）
    preferences: {
      type: 'json',
      nullable: true,
      comment: '其他偏好设置，包括温度、最大token数等'
    },
    // 状态
    status: {
      type: 'varchar',
      length: 20,
      default: 'active',
      comment: '配置状态：active-活跃、inactive-停用、testing-测试中'
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
    // 最后测试时间
    last_test_at: {
      type: 'timestamp',
      nullable: true,
      comment: '最后测试连接时间'
    },
  },
  indices: [
    {
      name: 'IDX_AI_CONFIG_PROVIDER',
      columns: ['provider'],
    },
    {
      name: 'IDX_AI_CONFIG_ENABLED',
      columns: ['is_enabled'],
    },
    {
      name: 'IDX_AI_CONFIG_STATUS',
      columns: ['status'],
    },
    {
      name: 'IDX_AI_CONFIG_PRIORITY',
      columns: ['priority'],
    },
  ],
});

/**
 * AI测试历史实体
 *
 * 记录每次AI配置测试的结果，便于追踪配置历史状态和问题排查
 */

const { EntitySchema } = require('typeorm');

module.exports = new EntitySchema({
  name: 'AiTestHistory',
  tableName: 'ai_test_history',
  columns: {
    id: {
      primary: true,
      type: 'uuid',
      generated: 'uuid',
    },
    ai_config_id: {
      type: 'uuid',
      nullable: false,
      comment: '关联的AI配置ID'
    },
    test_result: {
      type: 'boolean',
      comment: '测试是否成功'
    },
    response_time: {
      type: 'int',
      nullable: true,
      comment: '响应时间（毫秒）'
    },
    error_message: {
      type: 'text',
      nullable: true,
      comment: '错误信息'
    },
    details: {
      type: 'json',
      nullable: true,
      comment: '详细信息（可用模型、token使用等）'
    },
    created_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      comment: '测试时间'
    },
  },
  indices: [
    {
      name: 'IDX_AI_TEST_CONFIG',
      columns: ['ai_config_id'],
    },
    {
      name: 'IDX_AI_TEST_CREATED',
      columns: ['created_at'],
    },
  ],
  relations: {
    aiConfig: {
      type: 'many-to-one',
      target: 'AiConfig',
      joinColumn: {
        name: 'ai_config_id',
        referencedColumnName: 'id',
      },
      onDelete: 'CASCADE',
    },
  },
});

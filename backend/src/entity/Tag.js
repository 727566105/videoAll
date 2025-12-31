const { EntitySchema } = require('typeorm');

module.exports = new EntitySchema({
  name: 'Tag',
  tableName: 'tags',
  columns: {
    id: {
      primary: true,
      type: 'uuid',
      generated: 'uuid',
    },
    name: {
      type: 'varchar',
      length: 50,
      nullable: false,
      unique: true,
    },
    color: {
      type: 'varchar',
      length: 7,
      nullable: false,
      default: '#1890ff',
      comment: '十六进制颜色代码',
    },
    description: {
      type: 'varchar',
      length: 200,
      nullable: true,
    },
    usage_count: {
      type: 'int',
      default: 0,
      comment: '使用次数统计',
    },
    created_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
    },
    updated_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
    },
  },
  indices: [
    { name: 'IDX_TAG_NAME', columns: ['name'], unique: true },
    { name: 'IDX_TAG_USAGE_COUNT', columns: ['usage_count'] },
  ],
});

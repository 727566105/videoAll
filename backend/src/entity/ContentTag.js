const { EntitySchema } = require('typeorm');

module.exports = new EntitySchema({
  name: 'ContentTag',
  tableName: 'content_tags',
  columns: {
    id: {
      primary: true,
      type: 'uuid',
      generated: 'uuid',
    },
    content_id: {
      type: 'uuid',
      nullable: false,
    },
    tag_id: {
      type: 'uuid',
      nullable: false,
    },
    created_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
    },
  },
  indices: [
    { name: 'IDX_CONTENT_TAG_CONTENT', columns: ['content_id'] },
    { name: 'IDX_CONTENT_TAG_TAG', columns: ['tag_id'] },
    { name: 'IDX_CONTENT_TAG_UNIQUE', columns: ['content_id', 'tag_id'], unique: true },
  ],
});

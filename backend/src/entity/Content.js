const { EntitySchema } = require('typeorm');

// Content entity schema for TypeORM
module.exports = new EntitySchema({
  name: 'Content',
  tableName: 'contents',
  columns: {
    id: {
      primary: true,
      type: 'uuid',
      generated: 'uuid',
    },
    platform: {
      type: 'varchar',
      length: 20,
      nullable: false,
    },
    content_id: {
      type: 'varchar',
      length: 100,
      nullable: false,
    },
    title: {
      type: 'varchar',
      length: 500,
      nullable: false,
    },
    author: {
      type: 'varchar',
      length: 100,
      nullable: false,
    },
    description: {
      type: 'text',
      nullable: true,
      default: '',
    },
    media_type: {
      type: 'varchar',
      length: 10,
      nullable: false,
      enum: ['video', 'image'],
    },
    file_path: {
      type: 'varchar',
      length: 500,
      nullable: false,
    },
    cover_url: {
      type: 'varchar',
      length: 500,
      nullable: false,
    },
    all_images: {
      type: 'text',
      nullable: true,
      comment: 'JSON array of all image URLs',
    },
    all_videos: {
      type: 'text',
      nullable: true,
      comment: 'JSON array of all video URLs',
    },
    source_url: {
      type: 'varchar',
      length: 500,
      nullable: false,
    },
    source_type: {
      type: 'int',
      nullable: false,
      enum: [1, 2], // 1-单链接解析，2-监控任务
      default: 1,
    },
    like_count: {
      type: 'int',
      nullable: true,
      default: 0,
      comment: '点赞数量',
    },
    comment_count: {
      type: 'int',
      nullable: true,
      default: 0,
      comment: '评论数量',
    },
    share_count: {
      type: 'int',
      nullable: true,
      default: 0,
      comment: '分享数量',
    },
    publish_time: {
      type: 'timestamp',
      nullable: true,
      comment: '发布时间',
    },
    tags: {
      type: 'text',
      nullable: true,
      comment: 'JSON array of tags',
    },
    created_at: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
    },
  },
  relations: {
    task: {
      type: 'many-to-one',
      target: 'CrawlTask',
      joinColumn: { name: 'task_id' },
      nullable: true,
    },
  },
  indices: [
    {
      name: 'IDX_CONTENT_PLATFORM_CONTENT_ID',
      columns: ['platform', 'content_id'],
      unique: true,
    },
  ],
});

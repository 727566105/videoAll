const { AppDataSource } = require('../utils/db');
const taskScheduler = require('../services/TaskSchedulerService');
const authorCrawlerService = require('../services/AuthorCrawlerService');
const logger = require('../utils/logger');

class TaskController {
  // Create a new crawl task
  static async createTask(req, res) {
    try {
      const { name, platform, target_identifier, frequency, status, config } = req.body;

      // 验证必填字段
      if (!name || !platform || !target_identifier || !frequency) {
        return res.status(400).json({
          message: '缺少必填字段',
          code: 'MISSING_REQUIRED_FIELDS'
        });
      }

      const CrawlTaskRepository = AppDataSource.getRepository('CrawlTask');

      // 创建新任务
      const newTask = CrawlTaskRepository.create({
        name,
        platform,
        target_identifier,
        frequency,
        status: status !== undefined ? status : 1,
        config: config || {}
      });

      const savedTask = await CrawlTaskRepository.save(newTask);

      // 如果任务状态为启用，添加到调度器
      if (savedTask.status === 1) {
        await taskScheduler.addOrUpdateTask(savedTask);
      }

      logger.info(`Task created: ${savedTask.id} - ${savedTask.name}`);

      res.status(201).json({
        message: '任务创建成功',
        data: {
          id: savedTask.id,
          name: savedTask.name,
          platform: savedTask.platform,
          target_identifier: savedTask.target_identifier,
          frequency: savedTask.frequency,
          status: savedTask.status,
          last_run_at: savedTask.last_run_at,
          next_run_at: savedTask.next_run_at,
          created_at: savedTask.created_at
        }
      });
    } catch (error) {
      logger.error('Create task error:', error);
      res.status(500).json({ message: '创建任务失败' });
    }
  }

  // Get all tasks with pagination and filters
  static async getTasks(req, res) {
    try {
      const { page = 1, limit = 10, platform, status } = req.query;

      const CrawlTaskRepository = AppDataSource.getRepository('CrawlTask');

      // 构建查询条件
      const where = {};
      if (platform) where.platform = platform;
      if (status !== undefined) where.status = parseInt(status);

      // 查询任务
      const [tasks, total] = await CrawlTaskRepository.findAndCount({
        where,
        order: { created_at: 'DESC' },
        skip: (page - 1) * limit,
        take: parseInt(limit)
      });

      res.json({
        message: '获取任务列表成功',
        data: {
          list: tasks.map(task => ({
            id: task.id,
            name: task.name,
            platform: task.platform,
            target_identifier: task.target_identifier,
            frequency: task.frequency,
            status: task.status,
            last_run_at: task.last_run_at,
            next_run_at: task.next_run_at,
            created_at: task.created_at
          })),
          total,
          page: parseInt(page),
          limit: parseInt(limit)
        }
      });
    } catch (error) {
      logger.error('Get tasks error:', error);
      res.status(500).json({ message: '获取任务列表失败' });
    }
  }

  // Get task by ID
  static async getTaskById(req, res) {
    try {
      const { id } = req.params;

      const CrawlTaskRepository = AppDataSource.getRepository('CrawlTask');
      const task = await CrawlTaskRepository.findOne({ where: { id } });

      if (!task) {
        return res.status(404).json({ message: '任务不存在' });
      }

      res.json({
        message: '获取任务详情成功',
        data: {
          id: task.id,
          name: task.name,
          platform: task.platform,
          target_identifier: task.target_identifier,
          frequency: task.frequency,
          status: task.status,
          config: task.config,
          last_run_at: task.last_run_at,
          next_run_at: task.next_run_at,
          created_at: task.created_at
        }
      });
    } catch (error) {
      logger.error('Get task by ID error:', error);
      res.status(500).json({ message: '获取任务详情失败' });
    }
  }

  // Update task
  static async updateTask(req, res) {
    try {
      const { id } = req.params;
      const { name, platform, target_identifier, frequency, status, config } = req.body;

      const CrawlTaskRepository = AppDataSource.getRepository('CrawlTask');
      const task = await CrawlTaskRepository.findOne({ where: { id } });

      if (!task) {
        return res.status(404).json({ message: '任务不存在' });
      }

      // 更新任务字段
      if (name) task.name = name;
      if (platform) task.platform = platform;
      if (target_identifier) task.target_identifier = target_identifier;
      if (frequency) task.frequency = frequency;
      if (status !== undefined) task.status = status;
      if (config) task.config = config;

      const updatedTask = await CrawlTaskRepository.save(task);

      // 更新调度器
      await taskScheduler.addOrUpdateTask(updatedTask);

      logger.info(`Task updated: ${updatedTask.id} - ${updatedTask.name}`);

      res.json({
        message: '任务更新成功',
        data: {
          id: updatedTask.id,
          name: updatedTask.name,
          platform: updatedTask.platform,
          target_identifier: updatedTask.target_identifier,
          frequency: updatedTask.frequency,
          status: updatedTask.status,
          last_run_at: updatedTask.last_run_at,
          next_run_at: updatedTask.next_run_at
        }
      });
    } catch (error) {
      logger.error('Update task error:', error);
      res.status(500).json({ message: '更新任务失败' });
    }
  }

  // Delete task
  static async deleteTask(req, res) {
    try {
      const { id } = req.params;

      const CrawlTaskRepository = AppDataSource.getRepository('CrawlTask');
      const task = await CrawlTaskRepository.findOne({ where: { id } });

      if (!task) {
        return res.status(404).json({ message: '任务不存在' });
      }

      // 从调度器中移除任务
      taskScheduler.removeTask(id);

      // 删除任务
      await CrawlTaskRepository.remove(task);

      logger.info(`Task deleted: ${id}`);

      res.json({ message: '任务删除成功' });
    } catch (error) {
      logger.error('Delete task error:', error);
      res.status(500).json({ message: '删除任务失败' });
    }
  }

  // Toggle task status (enable/disable)
  static async toggleTaskStatus(req, res) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (status === undefined) {
        return res.status(400).json({ message: '缺少状态参数' });
      }

      const CrawlTaskRepository = AppDataSource.getRepository('CrawlTask');
      const task = await CrawlTaskRepository.findOne({ where: { id } });

      if (!task) {
        return res.status(404).json({ message: '任务不存在' });
      }

      // 更新状态
      task.status = parseInt(status);
      const updatedTask = await CrawlTaskRepository.save(task);

      // 更新调度器
      await taskScheduler.addOrUpdateTask(updatedTask);

      logger.info(`Task status toggled: ${id} - status: ${status}`);

      res.json({
        message: '任务状态切换成功',
        data: {
          id: updatedTask.id,
          status: updatedTask.status
        }
      });
    } catch (error) {
      logger.error('Toggle task status error:', error);
      res.status(500).json({ message: '切换任务状态失败' });
    }
  }

  // Run task immediately
  static async runTaskImmediately(req, res) {
    try {
      const { id } = req.params;

      const result = await taskScheduler.runTaskImmediately(id);

      if (result.success) {
        res.json({ message: '任务执行成功', data: result });
      } else {
        res.status(500).json({ message: result.message || '任务执行失败' });
      }
    } catch (error) {
      logger.error('Run task immediately error:', error);
      res.status(500).json({ message: '立即执行任务失败' });
    }
  }

  // Get task logs with pagination and filters
  static async getTaskLogs(req, res) {
    try {
      const { id } = req.params;
      const { page = 1, limit = 20 } = req.query;

      const TaskLogRepository = AppDataSource.getRepository('TaskLog');

      const [logs, total] = await TaskLogRepository.findAndCount({
        where: { task_id: id },
        order: { start_time: 'DESC' },
        skip: (page - 1) * limit,
        take: parseInt(limit)
      });

      res.json({
        message: '获取任务日志成功',
        data: {
          list: logs,
          total,
          page: parseInt(page),
          limit: parseInt(limit)
        }
      });
    } catch (error) {
      logger.error('Get task logs error:', error);
      res.status(500).json({ message: '获取任务日志失败' });
    }
  }

  // Get logs for a specific task
  static async getLogsForTask(req, res) {
    try {
      const { id } = req.params;
      const { page = 1, limit = 20 } = req.query;

      const TaskLogRepository = AppDataSource.getRepository('TaskLog');

      const [logs, total] = await TaskLogRepository.findAndCount({
        where: { task_id: id },
        order: { start_time: 'DESC' },
        skip: (page - 1) * limit,
        take: parseInt(limit)
      });

      res.json({
        message: '获取任务日志成功',
        data: {
          list: logs,
          total,
          page: parseInt(page),
          limit: parseInt(limit)
        }
      });
    } catch (error) {
      logger.error('Get logs for task error:', error);
      res.status(500).json({ message: '获取任务日志失败' });
    }
  }

  // Get all logs across all tasks
  static async getAllLogs(req, res) {
    try {
      const { page = 1, limit = 20, platform, status } = req.query;

      const TaskLogRepository = AppDataSource.getRepository('TaskLog');

      const where = {};
      if (platform) where.platform = platform;
      if (status) where.status = status;

      const [logs, total] = await TaskLogRepository.findAndCount({
        where,
        order: { start_time: 'DESC' },
        skip: (page - 1) * limit,
        take: parseInt(limit)
      });

      res.json({
        message: '获取所有日志成功',
        data: {
          list: logs,
          total,
          page: parseInt(page),
          limit: parseInt(limit)
        }
      });
    } catch (error) {
      logger.error('Get all logs error:', error);
      res.status(500).json({ message: '获取所有日志失败' });
    }
  }

  // Run hotsearch task immediately
  static async runHotsearchTask(req, res) {
    try {
      const result = await taskScheduler.executeHotsearchTask();

      if (result.success) {
        res.json({ message: '热搜任务执行成功', data: result });
      } else {
        res.status(500).json({ message: result.error || '热搜任务执行失败' });
      }
    } catch (error) {
      logger.error('Run hotsearch task error:', error);
      res.status(500).json({ message: '执行热搜任务失败' });
    }
  }

  // Get hotsearch logs
  static async getHotsearchLogs(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;

      const TaskLogRepository = AppDataSource.getRepository('TaskLog');

      const [logs, total] = await TaskLogRepository.findAndCount({
        where: { type: 'hotsearch' },
        order: { start_time: 'DESC' },
        skip: (page - 1) * limit,
        take: parseInt(limit)
      });

      res.json({
        message: '获取热搜日志成功',
        data: {
          list: logs,
          total,
          page: parseInt(page),
          limit: parseInt(limit)
        }
      });
    } catch (error) {
      logger.error('Get hotsearch logs error:', error);
      res.status(500).json({ message: '获取热搜日志失败' });
    }
  }
}

module.exports = TaskController;

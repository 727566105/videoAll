const express = require('express');
const router = express.Router();
const { AppDataSource } = require('../utils/db');

// 健康检查端点
router.get('/', async (req, res) => {
  try {
    const healthCheck = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: process.env.npm_package_version || '1.0.0',
      services: {
        database: 'unknown',
        memory: {
          used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
          total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
          external: Math.round(process.memoryUsage().external / 1024 / 1024)
        },
        cpu: {
          usage: process.cpuUsage()
        }
      }
    };

    // 检查数据库连接
    try {
      if (AppDataSource && AppDataSource.isInitialized) {
        await AppDataSource.query('SELECT 1');
        healthCheck.services.database = 'connected';
      } else {
        healthCheck.services.database = 'disconnected';
        healthCheck.status = 'degraded';
      }
    } catch (dbError) {
      healthCheck.services.database = 'error';
      healthCheck.status = 'unhealthy';
      healthCheck.errors = healthCheck.errors || [];
      healthCheck.errors.push({
        service: 'database',
        message: dbError.message
      });
    }

    // 根据状态设置HTTP状态码
    const statusCode = healthCheck.status === 'ok' ? 200 : 
                      healthCheck.status === 'degraded' ? 200 : 503;

    res.status(statusCode).json(healthCheck);
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// 就绪检查端点
router.get('/ready', async (req, res) => {
  try {
    // 检查关键服务是否就绪
    const checks = [];

    // 数据库检查
    try {
      if (AppDataSource && AppDataSource.isInitialized) {
        await AppDataSource.query('SELECT 1');
        checks.push({ name: 'database', status: 'ready' });
      } else {
        checks.push({ name: 'database', status: 'not_ready' });
      }
    } catch (error) {
      checks.push({ name: 'database', status: 'error', error: error.message });
    }

    const allReady = checks.every(check => check.status === 'ready');

    res.status(allReady ? 200 : 503).json({
      status: allReady ? 'ready' : 'not_ready',
      timestamp: new Date().toISOString(),
      checks
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// 存活检查端点
router.get('/live', (req, res) => {
  res.status(200).json({
    status: 'alive',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

module.exports = router;
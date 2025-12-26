import { useState, useEffect, useRef } from 'react';
import { Form, Input, Button, Card, Typography, Space, Checkbox, Alert, Spin, Modal, message, App } from 'antd';
import { LockOutlined, UserOutlined, DeleteOutlined, SettingOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import apiService from '../services/api';
import {
  saveCredentials,
  getSavedCredentials,
  clearCredentials,
  getCredentialsDaysRemaining
} from '../utils/credentials';

const { Title, Text } = Typography;

const Login = ({ onLogin }) => {
  const { token } = App.useApp();
  const [form] = Form.useForm();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [checkingSystem, setCheckingSystem] = useState(true);
  const [systemStatus, setSystemStatus] = useState(null);
  const [isInitialSetup, setIsInitialSetup] = useState(false);

  // 使用 useRef 避免竞态条件
  const isInitializedRef = useRef(false);
  const previousRememberStateRef = useRef(null);

  // Check system status on component mount
  useEffect(() => {
    checkSystemStatus();
  }, []);

  const checkSystemStatus = async () => {
    try {
      setCheckingSystem(true);
      const response = await apiService.auth.checkSystemStatus();
      setSystemStatus(response.data);
      setIsInitialSetup(response.data.needsInitialSetup);
    } catch (error) {
      console.error('System status check failed:', error);
      // If system check fails, assume normal login mode
      setSystemStatus({ hasUsers: true, needsInitialSetup: false });
      setIsInitialSetup(false);
    } finally {
      setCheckingSystem(false);
    }
  };

  // 清除已保存的登录凭证
  const clearSavedCredentials = () => {
    Modal.confirm({
      title: '确认清除',
      content: '确定要清除已保存的登录凭证吗？清除后需要重新输入用户名和密码。',
      okText: '确定',
      cancelText: '取消',
      okType: 'danger',
      onOk: () => {
        try {
          clearCredentials();
          // 只清除密码，保留用户名（提升用户体验）
          form.setFieldsValue({ password: '', remember: false });
          previousRememberStateRef.current = false;
          message.success('已清除已保存的密码');
        } catch (error) {
          message.error('清除失败，请重试');
        }
      }
    });
  };

  // 自动填充登录凭证（使用 ref 避免竞态条件）
  useEffect(() => {
    if (!isInitialSetup && !isInitializedRef.current) {
      isInitializedRef.current = true;

      const credentials = getSavedCredentials();
      if (credentials) {
        form.setFieldsValue({
          username: credentials.username,
          password: credentials.password,
          remember: credentials.remember
        });
        previousRememberStateRef.current = credentials.remember;

        // 显示凭证有效期提示
        const daysRemaining = getCredentialsDaysRemaining();
        if (daysRemaining !== null) {
          message.info(`已自动填充登录凭证（剩余 ${daysRemaining} 天有效）`, 2);
        }
      } else {
        form.setFieldsValue({ remember: false });
        previousRememberStateRef.current = false;
      }
    }
  }, [form, isInitialSetup]);

  const handleSubmit = async (values) => {
    try {
      setLoading(true);

      let response;
      if (isInitialSetup) {
        // Initial system setup
        response = await apiService.auth.initialSetup({
          username: values.username,
          password: values.password
        });
      } else {
        // Normal login
        response = await apiService.auth.login({
          username: values.username,
          password: values.password
        });
      }

      // Store user info and token in localStorage
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('user', JSON.stringify(response.data.user));

      // 处理"记住密码"逻辑（修复状态管理）
      if (!isInitialSetup) {
        const currentState = values.remember;
        const previousState = previousRememberStateRef.current;

        if (currentState === true) {
          // 勾选了记住密码：保存凭证
          try {
            saveCredentials(values);
            previousRememberStateRef.current = true;
            message.success('登录凭证已保存，下次访问将自动填充');
          } catch (error) {
            // 保存失败不影响登录
            console.error('保存凭证失败:', error);
            message.warning('登录成功，但凭证保存失败：' + error.message);
          }
        } else if (currentState === false && previousState === true) {
          // 明确取消了记住密码：清除凭证
          clearCredentials();
          previousRememberStateRef.current = false;
          message.info('已取消记住密码，已清除保存的凭证');
        }
        // 其他情况：状态未改变，不操作
      }

      // Call onLogin prop to update parent component state
      onLogin(response.data.user);

      // Navigate to dashboard after successful login/setup
      navigate('/dashboard');
    } catch (error) {
      console.error('登录/设置错误:', error);
      // Error is already handled by the API interceptor
    } finally {
      setLoading(false);
    }
  };

  if (checkingSystem) {
    return (
      <Card style={{ width: 400, boxShadow: token.boxShadowSecondary }}>
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size="large" />
          <div style={{ marginTop: 16, color: token.colorTextSecondary }}>
            <Text>正在检查系统状态...</Text>
          </div>
        </div>
      </Card>
    );
  }

  return (
    <Card
      style={{ width: 400, boxShadow: token.boxShadowSecondary }}
      title={
        <Space orientation="vertical" align="center" size="small" style={{ width: '100%' }}>
          <Title level={2} style={{ margin: 0, color: token.colorPrimary }}>
            内容管理系统
          </Title>
          {isInitialSetup && (
            <Space>
              <SettingOutlined style={{ color: token.colorSuccess }} />
              <Text type="success">系统初始化</Text>
            </Space>
          )}
        </Space>
      }
    >
      {isInitialSetup && (
        <Alert
          message="欢迎使用内容管理系统"
          description="系统检测到这是首次使用，请创建管理员账户来完成初始化设置。"
          type="info"
          showIcon
          style={{ marginBottom: 24 }}
        />
      )}

      <Form
        form={form}
        name={isInitialSetup ? "initial-setup" : "login"}
        onFinish={handleSubmit}
        style={{ maxWidth: 360, margin: '0 auto' }}
      >
        <Form.Item
          name="username"
          rules={[
            { required: true, message: '请输入用户名!' },
            { min: 3, message: '用户名至少3个字符!' },
            { max: 20, message: '用户名不能超过20个字符!' }
          ]}
        >
          <Input
            prefix={<UserOutlined className="site-form-item-icon" />}
            placeholder={isInitialSetup ? "管理员用户名" : "用户名"}
            size="large"
          />
        </Form.Item>

        <Form.Item
          name="password"
          rules={[
            { required: true, message: '请输入密码!' },
            { min: 6, message: '密码至少6个字符!' }
          ]}
        >
          <Input.Password
            prefix={<LockOutlined className="site-form-item-icon" />}
            placeholder={isInitialSetup ? "管理员密码" : "密码"}
            size="large"
          />
        </Form.Item>

        {!isInitialSetup && (
          <Form.Item
            name="remember"
            valuePropName="checked"
            wrapperCol={{ offset: 0, span: 24 }}
          >
            <Space style={{ width: '100%', justifyContent: 'space-between' }}>
              <Checkbox>记住密码（7天）</Checkbox>
              <Button
                type="link"
                size="small"
                icon={<DeleteOutlined />}
                onClick={clearSavedCredentials}
              >
                清除已保存密码
              </Button>
            </Space>
          </Form.Item>
        )}

        <Form.Item>
          <Button
            type="primary"
            htmlType="submit"
            loading={loading}
            style={{ width: '100%', height: 40, fontSize: 16 }}
          >
            {isInitialSetup ? '创建管理员账户' : '登录'}
          </Button>
        </Form.Item>
      </Form>

      {systemStatus && !isInitialSetup && (
        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <Text type="secondary" style={{ fontSize: 12 }}>
            系统用户数: {systemStatus.userCount}
          </Text>
        </div>
      )}
    </Card>
  );
};

export default Login;

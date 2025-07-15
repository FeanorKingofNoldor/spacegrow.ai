#!/usr/bin/env node

const axios = require('axios');
const chalk = require('chalk');

const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 10000
};

const log = {
  info: (msg) => console.log(chalk.blue('ℹ️  ' + msg)),
  success: (msg) => console.log(chalk.green('✅ ' + msg)),
  error: (msg) => console.log(chalk.red('❌ ' + msg)),
  warning: (msg) => console.log(chalk.yellow('⚠️  ' + msg)),
  section: (msg) => console.log(chalk.magenta.bold('\n🔸 ' + msg.toUpperCase())),
  debug: (msg) => console.log(chalk.gray('🔍 ' + msg))
};

async function verboseDeviceTest() {
  const api = axios.create({
    baseURL: config.baseUrl,
    timeout: config.timeout,
    headers: { 'Content-Type': 'application/json' }
  });
  
  log.section('Starting Verbose Device Test');
  log.info(`Base URL: ${config.baseUrl}`);
  
  // Step 1: Create User
  log.section('Step 1: Creating User');
  const userEmail = `verbose_test_${Date.now()}@example.com`;
  const userPayload = {
    user: { 
      email: userEmail, 
      password: 'Password123!', 
      password_confirmation: 'Password123!' 
    }
  };
  
  log.debug(`User payload: ${JSON.stringify(userPayload, null, 2)}`);
  
  try {
    const userResponse = await api.post('/api/v1/auth/signup', userPayload);
    log.success('User created successfully');
    log.debug(`User response status: ${userResponse.status}`);
    log.debug(`User response data: ${JSON.stringify(userResponse.data, null, 2)}`);
    
    const token = userResponse.data.token;
    log.info(`Token received: ${token ? 'YES' : 'NO'}`);
    log.debug(`Token (first 20 chars): ${token?.substring(0, 20)}...`);
    
    // Step 2: Try Order Creation
    log.section('Step 2: Attempting Order Creation');
    const orderPayload = {
      order: {
        line_items: [{
          product_id: 1,
          quantity: 1,
          price: 299.99
        }],
        total: 299.99,
        status: 'paid'
      }
    };
    
    log.debug(`Order payload: ${JSON.stringify(orderPayload, null, 2)}`);
    log.debug(`Order URL: ${config.baseUrl}/api/v1/store/orders`);
    
    try {
      const orderResponse = await api.post('/api/v1/store/orders', orderPayload, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      log.success('Order created successfully');
      log.debug(`Order response status: ${orderResponse.status}`);
      log.debug(`Order response data: ${JSON.stringify(orderResponse.data, null, 2)}`);
      
      const orderId = orderResponse.data.data?.id;
      log.info(`Order ID: ${orderId}`);
      
      // Step 3a: Create Device WITH Order
      log.section('Step 3a: Creating Device WITH Order');
      const deviceWithOrderPayload = {
        device: {
          name: 'VerboseDeviceWithOrder',
          device_type_id: 1,
          order_id: orderId
        }
      };
      
      log.debug(`Device payload (with order): ${JSON.stringify(deviceWithOrderPayload, null, 2)}`);
      log.debug(`Device URL: ${config.baseUrl}/api/v1/frontend/devices`);
      
      const deviceResponse = await api.post('/api/v1/frontend/devices', deviceWithOrderPayload, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      log.success('Device with order created successfully!');
      log.debug(`Device response status: ${deviceResponse.status}`);
      log.debug(`Device response data: ${JSON.stringify(deviceResponse.data, null, 2)}`);
      
    } catch (orderError) {
      log.warning('Order creation failed');
      log.error(`Order error status: ${orderError.response?.status}`);
      log.error(`Order error headers: ${JSON.stringify(orderError.response?.headers, null, 2)}`);
      log.error(`Order error data: ${JSON.stringify(orderError.response?.data, null, 2)}`);
      log.error(`Order error message: ${orderError.message}`);
      
      // Step 3b: Create Device WITHOUT Order
      log.section('Step 3b: Creating Device WITHOUT Order');
      const deviceWithoutOrderPayload = {
        device: {
          name: 'VerboseDeviceWithoutOrder',
          device_type_id: 1
          // No order_id
        }
      };
      
      log.debug(`Device payload (without order): ${JSON.stringify(deviceWithoutOrderPayload, null, 2)}`);
      log.debug(`Device URL: ${config.baseUrl}/api/v1/frontend/devices`);
      
      try {
        const deviceResponse = await api.post('/api/v1/frontend/devices', deviceWithoutOrderPayload, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        
        log.success('Device without order created successfully!');
        log.debug(`Device response status: ${deviceResponse.status}`);
        log.debug(`Device response data: ${JSON.stringify(deviceResponse.data, null, 2)}`);
        
      } catch (deviceError) {
        log.error('Device creation failed');
        log.error(`Device error status: ${deviceError.response?.status}`);
        log.error(`Device error status text: ${deviceError.response?.statusText}`);
        log.error(`Device error headers: ${JSON.stringify(deviceError.response?.headers, null, 2)}`);
        log.error(`Device error data: ${JSON.stringify(deviceError.response?.data, null, 2)}`);
        log.error(`Device error message: ${deviceError.message}`);
        log.error(`Full error object: ${JSON.stringify(deviceError.toJSON?.() || 'No toJSON method', null, 2)}`);
        
        // Step 4: Debug the controller issue
        log.section('Step 4: Debugging Controller Issue');
        log.debug('The error suggests the controller is calling device.order');
        log.debug('This means the controller expects every device to have an order association');
        log.debug('Check the devices_controller.rb for lines like:');
        log.debug('  - device.order.present?');
        log.debug('  - DeviceActivationTokenService.generate_for_order(device.order)');
      }
    }
    
  } catch (userError) {
    log.error('User creation failed');
    log.error(`User error status: ${userError.response?.status}`);
    log.error(`User error data: ${JSON.stringify(userError.response?.data, null, 2)}`);
  }
  
  log.section('Verbose Test Complete');
}

verboseDeviceTest().catch(error => {
  log.error('Test runner crashed');
  console.error(error);
});
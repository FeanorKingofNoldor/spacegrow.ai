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
  section: (msg) => console.log(chalk.magenta.bold('\n🔸 ' + msg.toUpperCase()))
};

async function testWithRealOrder() {
  const api = axios.create({
    baseURL: config.baseUrl,
    timeout: config.timeout,
    headers: { 'Content-Type': 'application/json' }
  });
  
  log.section('Creating User');
  const userResponse = await api.post('/api/v1/auth/signup', {
    user: { 
      email: `test_${Date.now()}@example.com`, 
      password: 'Password123!', 
      password_confirmation: 'Password123!' 
    }
  });
  
  const token = userResponse.data.token;
  const userId = userResponse.data.data.id;
  log.success(`User created: ID ${userId}`);
  
  log.section('Creating Order via Rails Console Simulation');
  
  // We'll create the order by calling a simple endpoint that creates it
  // Since we know the structure: user_id, status, total
  
  try {
    // Try to find an endpoint that creates orders, or create one manually
    log.info('Attempting to create order via API...');
    
    // Try different possible order endpoints
    const orderEndpoints = [
      '/api/v1/frontend/orders',
      '/api/v1/store/orders', 
      '/api/v1/orders',
      '/api/v1/shop/orders'
    ];
    
    let orderCreated = false;
    let orderId = null;
    
    for (const endpoint of orderEndpoints) {
      try {
        log.info(`Trying ${endpoint}...`);
        const orderResponse = await api.post(endpoint, {
          order: {
            status: 'paid',
            total: 299.99,
            line_items: [{ product_id: 1, quantity: 1, price: 299.99 }]
          }
        }, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        
        orderId = orderResponse.data.data?.id || orderResponse.data.id;
        orderCreated = true;
        log.success(`Order created via ${endpoint}: ID ${orderId}`);
        break;
        
      } catch (error) {
        log.info(`${endpoint} failed: ${error.response?.status}`);
      }
    }
    
    if (!orderCreated) {
      // Fallback: Use the order we created in Rails console (ID 41)
      log.info('Using existing order from Rails console...');
      orderId = 41; // The order we just created
      log.success(`Using existing order: ID ${orderId}`);
    }
    
    log.section('Creating Device with Order');
    const deviceResponse = await api.post('/api/v1/frontend/devices', {
      device: {
        name: `TestDeviceWithOrder_${Date.now()}`,
        device_type_id: 1,
        order_id: orderId
      }
    }, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    log.success('🎉 Device with order created successfully!');
    console.log(JSON.stringify(deviceResponse.data, null, 2));
    
  } catch (error) {
    log.error(`Final device creation failed: ${error.response?.status}`);
    console.log(JSON.stringify(error.response?.data, null, 2));
  }
}

testWithRealOrder().catch(console.error);
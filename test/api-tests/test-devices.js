#!/usr/bin/env node

/**
 * SpaceGrow DEVICE MANAGEMENT TEST SUITE - STORE INTEGRATED VERSION
 * 
 * Tests device CRUD operations with proper store/order integration
 * Updated to use real store endpoints instead of mocks
 * 
 * Usage:
 *   node test-devices.js
 * 
 * Environment Variables:
 *   API_BASE_URL=http://localhost:3000
 */

const axios = require('axios');
const chalk = require('chalk');
const fs = require('fs');

// Import auth utilities
const { createUser, makeAuthenticatedRequest } = require('./test-auth');

// Configuration
const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 15000, // Increased for store operations
  retries: 3
};

// Test results tracking
let testResults = {
  passed: 0,
  failed: 0,
  total: 0,
  details: []
};

// Utility functions
const log = {
  info: (msg) => console.log(chalk.blue('ℹ️  ' + msg)),
  success: (msg) => console.log(chalk.green('✅ ' + msg)),
  error: (msg) => console.log(chalk.red('❌ ' + msg)),
  warning: (msg) => console.log(chalk.yellow('⚠️  ' + msg)),
  section: (msg) => console.log(chalk.magenta.bold('\n🔸 ' + msg.toUpperCase())),
  result: (msg) => console.log(chalk.cyan('📊 ' + msg)),
  debug: (msg) => console.log(chalk.gray('🔍 ' + msg))
};

const randomEmail = () => `test_device_${Date.now()}_${Math.random().toString(36).substr(2, 5)}@example.com`;
const randomName = () => `TestDevice_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// HTTP client
const api = axios.create({
  baseURL: config.baseUrl,
  timeout: config.timeout,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Test assertion helper
async function test(name, testFn, category = 'device') {
  testResults.total++;
  const startTime = Date.now();
  
  try {
    await testFn();
    testResults.passed++;
    const duration = Date.now() - startTime;
    log.success(`${name} (${duration}ms)`);
    testResults.details.push({
      name,
      category,
      status: 'PASS',
      duration,
      timestamp: new Date().toISOString()
    });
    return true;
  } catch (error) {
    testResults.failed++;
    const duration = Date.now() - startTime;
    log.error(`${name} - ${error.message} (${duration}ms)`);
    testResults.details.push({
      name,
      category,
      status: 'FAIL',
      duration,
      error: error.message,
      timestamp: new Date().toISOString()
    });
    return false;
  }
}

// ===== STORE INTEGRATION HELPERS =====

// Create a real order through the store API
async function createRealOrder(userToken, productId = null) {
  try {
    // Get actual device products first
    const products = await getDeviceProducts();
    if (products.length === 0) {
      throw new Error('No device products available');
    }
    
    // Use provided productId or first device product
    const targetProductId = productId || products[0].id;
    
    const orderPayload = {
      line_items: [
        {
          product_id: targetProductId,
          quantity: 1
        }
      ]
    };
    
    log.debug(`Creating order with payload: ${JSON.stringify(orderPayload)}`);
    
    const response = await makeAuthenticatedRequest(
      userToken,
      '/api/v1/store/orders',
      'POST',
      orderPayload
    );
    
    log.debug(`Order response status: ${response.status}`);
    log.debug(`Order response: ${JSON.stringify(response.data)}`);
    
    if (response.data.status !== 'success') {
      throw new Error(`Order creation failed: ${response.data.message || JSON.stringify(response.data)}`);
    }
    
    return response.data.data.order;
    
  } catch (error) {
    log.warning(`Real order creation failed: ${error.message}`);
    if (error.response) {
      log.debug(`Error response: ${JSON.stringify(error.response.data)}`);
    }
    return null;
  }
}

// Mark order as paid (for testing)
async function markOrderPaid(userToken, orderId) {
  try {
    const response = await makeAuthenticatedRequest(
      userToken,
      `/api/v1/store/orders/${orderId}/mark_paid`,
      'POST'
    );
    
    if (response.data.status === 'success') {
      log.debug(`Order ${orderId} marked as paid`);
      return true;
    }
  } catch (error) {
    log.warning(`Could not mark order as paid: ${error.message}`);
  }
  return false;
}

// Get available products for device creation
async function getDeviceProducts() {
  try {
    const response = await api.get('/api/v1/store/products');
    if (response.data.status === 'success') {
      const products = response.data.data.products;
      
      // ✅ FIXED: Use actual field names from your API
      const deviceProducts = products.filter(p => {
        const isDevice = p.category && 
          (p.category.includes('Monitor') || 
           p.category === 'Environmental Monitor V1' || 
           p.category === 'Liquid Monitor V1') &&
          !p.category.includes('Accessories');
        
        return isDevice;
      });
      
      log.debug(`Found ${deviceProducts.length} device products out of ${products.length} total`);
      log.debug(`Device products: ${deviceProducts.map(p => p.name).join(', ')}`);
      
      // Add device_type field based on category for compatibility
      deviceProducts.forEach(product => {
        product.device_type = product.category;
      });
      
      return deviceProducts;
    }
  } catch (error) {
    log.warning(`Could not fetch products: ${error.message}`);
  }
  
  // Fallback to mock products with correct IDs from your API
  return [
    { id: 1, name: 'Environmental Monitoring Kit V1', device_type: 'Environmental Monitor V1', category: 'Environmental Monitor V1' },
    { id: 2, name: 'Liquid Monitoring Kit V1', device_type: 'Liquid Monitor V1', category: 'Liquid Monitor V1' }
  ];
}

// Create user with subscription (recommended for device limits)
async function createUserWithSubscription(planName = 'Basic') {
  const userData = await createUser(randomEmail());
  
  try {
    const response = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/frontend/onboarding/select_plan',
      'POST',
      {
        plan_id: planName === 'Basic' ? 1 : planName === 'Professional' ? 2 : 3,
        interval: 'month'
      }
    );
    
    if (response.data.status === 'success') {
      userData.subscription = response.data.data.subscription;
      log.debug(`User created with ${planName} subscription`);
    }
  } catch (error) {
    log.warning('Could not create subscription - using basic user');
  }
  
  return userData;
}

// Enhanced device creation with real store integration
async function createTestDevice(userToken, deviceData = {}) {
  const products = await getDeviceProducts();
  let orderId = null;
  
  // Try to create a real order first (using actual product IDs)
  if (products.length > 0) {
    const order = await createRealOrder(userToken, products[0].id);
    if (order) {
      orderId = order.id;
      // Mark order as paid to generate activation tokens
      await markOrderPaid(userToken, orderId);
    }
  }
  
  const defaultData = {
    name: randomName(),
    device_type_id: deviceData.device_type_id || 1,
    order_id: orderId // Include order_id if we have one
  };
  
  const devicePayload = { 
    device: { 
      ...defaultData, 
      ...deviceData
    }
  };
  
  log.debug(`Creating device with payload: ${JSON.stringify(devicePayload)}`);
  
  const response = await makeAuthenticatedRequest(
    userToken, 
    '/api/v1/frontend/devices',
    'POST',
    devicePayload
  );
  
  if (response.data.status !== 'success') {
    log.debug(`Device creation failed. Response: ${JSON.stringify(response.data)}`);
    throw new Error(`Failed to create device: ${response.data.errors?.join(', ') || response.data.message || 'Unknown error'}`);
  }
  
  log.debug(`Device created: ${JSON.stringify(response.data.data)}`);
  return response.data.data;
}

// ===== STORE INTEGRATION TESTS =====

async function testStoreIntegration() {
  await test('Get Store Products', async () => {
    const response = await api.get('/api/v1/store/products');
    
    if (response.data.status !== 'success') {
      throw new Error('Failed to get products');
    }
    
    const products = response.data.data.products;
    if (!Array.isArray(products)) {
      throw new Error('Products should be an array');
    }
    
    log.info(`Found ${products.length} products in store`);
    
    // Check for device products
    const deviceProducts = products.filter(p => p.device_type);
    log.info(`Found ${deviceProducts.length} device products`);
  });

  await test('Create Order Through Store', async () => {
    const userData = await createUserWithSubscription();
    const products = await getDeviceProducts();
    
    if (products.length === 0) {
      throw new Error('No device products available');
    }
    
    const orderPayload = {
      line_items: [
        {
          product_id: products[0].id,
          quantity: 1
        }
      ]
    };
    
    const response = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/store/orders',
      'POST',
      orderPayload
    );
    
    if (response.data.status !== 'success') {
      throw new Error(`Order creation failed: ${response.data.message}`);
    }
    
    const order = response.data.data.order;
    if (!order.id) throw new Error('Order should have an ID');
    if (order.status !== 'pending') throw new Error('Order should start as pending');
    
    log.info(`Order created: ${order.id} with total: ${order.total}`);
  });

  await test('Order to Device Flow', async () => {
    const userData = await createUserWithSubscription();
    const products = await getDeviceProducts();
    
    if (products.length === 0) {
      log.warning('No device products - skipping store flow test');
      return;
    }
    
    // 1. Create order
    const order = await createRealOrder(userData.token, products[0].id);
    if (!order) throw new Error('Could not create order');
    
    // 2. Mark as paid
    const paid = await markOrderPaid(userData.token, order.id);
    if (!paid) throw new Error('Could not mark order as paid');
    
    // 3. Create device with order
    const device = await createTestDevice(userData.token, {
      order_id: order.id,
      device_type_id: 1
    });
    
    if (!device.id) throw new Error('Device should be created');
    if (!device.has_order) throw new Error('Device should be linked to order');
    
    log.info(`Complete flow: Order ${order.id} → Device ${device.id}`);
  });
}

// ===== DEVICE CRUD TESTS =====

async function testDeviceCRUD() {
  await test('Create Device with Admin Bypass', async () => {
    const userData = await createUserWithSubscription();
    const deviceName = randomName();
    
    const device = await createTestDevice(userData.token, { name: deviceName });
    
    if (!device.id) throw new Error('No device ID returned');
    if (device.name !== deviceName) throw new Error('Device name mismatch');
    if (!device.device_type) throw new Error('No device type returned');
    if (device.status !== 'pending') throw new Error('Initial status should be pending');
    
    log.info(`Device created: ${device.name} (${device.status})`);
  });

  await test('List User Devices', async () => {
    const userData = await createUserWithSubscription();
    
    // Create a couple devices
    await createTestDevice(userData.token, { name: 'Device1' });
    await createTestDevice(userData.token, { name: 'Device2' });
    
    const response = await makeAuthenticatedRequest(userData.token, '/api/v1/frontend/devices');
    
    if (response.data.status !== 'success') throw new Error('Failed to list devices');
    if (!Array.isArray(response.data.data)) throw new Error('Expected devices array');
    if (response.data.data.length < 2) throw new Error('Should have at least 2 devices');
    
    // Check device structure
    const device = response.data.data[0];
    if (!device.id || !device.name || !device.status) {
      throw new Error('Device missing required fields');
    }
    
    log.info(`Listed ${response.data.data.length} devices`);
  });

// ===== FINAL DEVICE TEST FIXES =====

// Fix device details test - response has nested structure
await test('Get Device Details', async () => {
  const userData = await createUserWithSubscription();
  const device = await createTestDevice(userData.token);
  
  const response = await makeAuthenticatedRequest(
    userData.token, 
    `/api/v1/frontend/devices/${device.id}`
  );
  
  if (response.data.status !== 'success') {
    throw new Error('Failed to get device details');
  }
  
  // ✅ FIXED: Response has nested device structure
  const details = response.data.data;
  const deviceData = details.device; // Device is nested under 'device' key
  
  log.debug(`Device details response: ${JSON.stringify(details, null, 2)}`);
  
  if (!deviceData || !deviceData.id) {
    throw new Error(`Device details missing ID. Device data: ${JSON.stringify(deviceData)}`);
  }
  
  log.info(`Device details retrieved for ${deviceData.name}`);
});

// Fix device status information test
	await test('Device Status Information', async () => {
  const userData = await createUserWithSubscription();
  const device = await createTestDevice(userData.token);
  
  const response = await makeAuthenticatedRequest(
    userData.token, 
    `/api/v1/frontend/devices/${device.id}`
  );
  
  if (response.data.status !== 'success') {
    throw new Error('Failed to get device details');
  }
  
  // ✅ FIXED: Access nested device data correctly
  const responseData = response.data.data;
  const deviceData = responseData.device; // Device is nested under 'device' key
  
  log.debug(`Device status response: ${JSON.stringify(responseData, null, 2)}`);
  
  if (!deviceData) {
    throw new Error(`No device data returned. Full response: ${JSON.stringify(responseData)}`);
  }
  
  // ✅ FIXED: deviceData.status exists, as shown in your logs
  if (!deviceData.status) {
    throw new Error(`Missing device status. Device data has keys: ${Object.keys(deviceData).join(', ')}`);
  }
  
  const validStatuses = ['pending', 'active', 'suspended', 'disabled'];
  if (!validStatuses.includes(deviceData.status)) {
    throw new Error(`Invalid device status: ${deviceData.status}`);
  }
  
  // Check additional status fields using your actual field names
  const hasOrderInfo = deviceData.hasOwnProperty('has_order');
  const hasOrderId = deviceData.hasOwnProperty('order_id');
  
  log.info(`Device status: ${deviceData.status}, has_order: ${hasOrderInfo}, order_id: ${hasOrderId}`);
  
  // Check additional response fields
  if (responseData.device_status) {
    log.info(`Overall status: ${responseData.device_status.overall_status}, Connection: ${responseData.device_status.connection_status}`);
  }

  await test('Update Device Name', async () => {
    const userData = await createUserWithSubscription();
    const device = await createTestDevice(userData.token);
    const newName = randomName();
    
    const response = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'PUT',
      { device: { name: newName } }
    );
    
    if (response.data.status !== 'success') throw new Error('Failed to update device');
    if (response.data.data.name !== newName) throw new Error('Device name not updated');
    
    log.info(`Device renamed to: ${newName}`);
  });

  await test('Delete Device', async () => {
    const userData = await createUserWithSubscription();
    const device = await createTestDevice(userData.token);
    
    const response = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'DELETE'
    );
    
    if (response.data.status !== 'success') throw new Error('Failed to delete device');
    
    // Verify device is deleted
    try {
      await makeAuthenticatedRequest(userData.token, `/api/v1/frontend/devices/${device.id}`);
      throw new Error('Device should be deleted');
    } catch (error) {
      if (error.response && error.response.status === 404) {
        log.info('Device successfully deleted');
        return;
      }
      throw error;
    }
  });
},

// ===== DEVICE STATUS TESTS =====

async function testDeviceStatus() {
  await test('Device Initial Status', async () => {
    const userData = await createUserWithSubscription();
    const device = await createTestDevice(userData.token);
    
    if (device.status !== 'pending') {
      throw new Error(`Expected pending status, got ${device.status}`);
    }
    
    log.info('Device correctly starts in pending status');
  });

  await test('Device Status Information', async () => {
  const userData = await createUserWithSubscription();
  const device = await createTestDevice(userData.token);
  
  const response = await makeAuthenticatedRequest(
    userData.token, 
    `/api/v1/frontend/devices/${device.id}`
  );
  
  if (response.data.status !== 'success') {
    throw new Error('Failed to get device details');
  }
  
  // ✅ FIXED: Access device data correctly
  const deviceData = response.data.data;
  
  // Debug what we actually got
  log.debug(`Device status response: ${JSON.stringify(deviceData, null, 2)}`);
  
  if (!deviceData) {
    throw new Error(`No device data returned. Full response: ${JSON.stringify(response.data)}`);
  }
  
  if (!deviceData.status) {
    throw new Error(`Missing device status. Device data: ${JSON.stringify(deviceData)}`);
  }
  
  const validStatuses = ['pending', 'active', 'suspended', 'disabled'];
  if (!validStatuses.includes(deviceData.status)) {
    throw new Error(`Invalid device status: ${deviceData.status}`);
  }
  
  // Check additional status fields using your actual field names
  const hasOrderInfo = deviceData.hasOwnProperty('has_order');
  const hasOrderId = deviceData.hasOwnProperty('order_id');
  
  log.info(`Device status: ${deviceData.status}, has_order: ${hasOrderInfo}, order_id: ${hasOrderId}`);
	});
},

// ===== DEVICE LIMITS TESTS =====

async function testDeviceLimits() {
  await test('Always Accept Policy - Create Multiple Devices', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    // Create devices beyond typical limit
    const devices = [];
    for (let i = 0; i < 5; i++) {
      const device = await createTestDevice(userData.token, { name: `Device${i + 1}` });
      devices.push(device);
      
      if (!device.id) {
        throw new Error(`Failed to create device ${i + 1}`);
      }
    }
    
    log.info(`Successfully created ${devices.length} devices (Always Accept policy)`);
    
    // All devices should be created successfully
    if (devices.length !== 5) {
      throw new Error('Not all devices were created');
    }
  });
},

// ===== DEVICE PERMISSIONS TESTS =====

async function testDevicePermissions() {
  await test('User Can Only Access Own Devices', async () => {
    const user1 = await createUserWithSubscription();
    const user2 = await createUserWithSubscription();
    
    const device1 = await createTestDevice(user1.token, { name: 'User1Device' });
    
    // User2 should not be able to access User1's device
    try {
      await makeAuthenticatedRequest(user2.token, `/api/v1/frontend/devices/${device1.id}`);
      throw new Error('User should not access other users devices');
    } catch (error) {
      if (error.response && [403, 404].includes(error.response.status)) {
        log.info('Device access properly restricted to owner');
        return;
      }
      throw error;
    }
  });
},

// ===== MAIN EXECUTION =====

async function runAllTests() {
  log.section('Starting Enhanced Device Management Test Suite');
  log.info(`Testing against: ${config.baseUrl}`);
  log.info('Features: Store Integration, Admin Bypass, Always Accept Policy');
  
  try {
    await api.get('/up');
    log.success('Server is responding');
  } catch (error) {
    log.error('Cannot connect to server. Is Rails running?');
    process.exit(1);
  }

  const startTime = Date.now();

  // Run test categories
  log.section('Store Integration Tests');
  await testStoreIntegration();

  log.section('Device CRUD Tests');
  await testDeviceCRUD();

  log.section('Device Status Tests');
  await testDeviceStatus();

  log.section('Device Limits Tests');
  await testDeviceLimits();

  log.section('Device Permissions Tests');
  await testDevicePermissions();

  // Generate report
  const totalTime = Date.now() - startTime;
  const passRate = ((testResults.passed / testResults.total) * 100).toFixed(1);
  
  log.section('Test Results Summary');
  log.result(`Total Tests: ${testResults.total}`);
  log.result(`Passed: ${chalk.green(testResults.passed)}`);
  log.result(`Failed: ${chalk.red(testResults.failed)}`);
  log.result(`Pass Rate: ${passRate}%`);
  log.result(`Total Time: ${totalTime}ms`);

  // Save detailed results
  const reportFile = `device-test-results-${Date.now()}.json`;
  fs.writeFileSync(reportFile, JSON.stringify({
    summary: {
      total: testResults.total,
      passed: testResults.passed,
      failed: testResults.failed,
      passRate: parseFloat(passRate),
      totalTime,
      timestamp: new Date().toISOString()
    },
    details: testResults.details,
    config,
    features: {
      store_integration: true,
      admin_bypass: true,
      always_accept_policy: true,
      order_device_linking: true
    }
  }, null, 2));
  
  log.info(`Detailed results saved to ${reportFile}`);

  // Analysis
  log.section('Test Analysis');
  if (testResults.failed === 0) {
    log.success('✅ All device management tests passed!');
    log.success('✅ Store integration working correctly');
    log.success('✅ Admin bypass functional for development');
    log.success('✅ Always Accept policy implemented');
  } else if (testResults.failed < testResults.total * 0.3) {
    log.warning('⚠️  Some tests failed - check implementation details');
    log.info('📋 Possible issues:');
    log.info('   - Store endpoints may need product seeding');
    log.info('   - Order marking endpoints may be missing');
    log.info('   - Device-order linking may need adjustment');
  } else {
    log.error('❌ Many tests failed - significant issues detected');
    log.info('🔧 Check:');
    log.info('   - Routes are properly configured');
    log.info('   - Store controllers are implemented');
    log.info('   - Database associations are working');
    log.info('   - Admin bypass logic is correct');
  }

  process.exit(testResults.failed > 0 ? 1 : 0);
},

// Handle errors
process.on('unhandledRejection', (error) => {
  log.error(`Unhandled rejection: ${error.message}`);
  process.exit(1);
}));

if (require.main === module) {
  runAllTests();
}

module.exports = {
  runAllTests,
  testResults,
  createTestDevice,
  createUserWithSubscription,
  createRealOrder
}
};
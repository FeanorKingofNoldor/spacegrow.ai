#!/usr/bin/env node

/**
 * XSPACEGROW DEVICE MANAGEMENT TEST SUITE
 * 
 * Tests device CRUD, sensor data, status calculations, activation flow, and device limits
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

// Import auth utilities from auth test
const { createUser, loginUser, makeAuthenticatedRequest } = require('./test-auth');

// Configuration
const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 15000,
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
  result: (msg) => console.log(chalk.cyan('📊 ' + msg))
};

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
async function test(name, testFn, category = 'devices') {
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

// Device management helper functions
async function createTestDevice(userToken, deviceData = {}) {
  const defaultData = {
    name: randomName(),
    device_type_id: 1, // Assuming Environmental Monitor V1
    status: 'pending'
  };
  
  const devicePayload = { ...defaultData, ...deviceData };
  
  const response = await makeAuthenticatedRequest(
    userToken, 
    '/api/v1/frontend/devices',
    'POST',
    { device: devicePayload }
  );
  
  if (response.data.status !== 'success') {
    throw new Error(`Failed to create device: ${response.data.error || 'Unknown error'}`);
  }
  
  return response.data.data;
}

async function sendSensorData(deviceToken, sensorData) {
  const response = await api.post('/api/v1/esp32/sensor_data', sensorData, {
    headers: { 
      'Authorization': `Bearer ${deviceToken}`,
      'Content-Type': 'application/json'
    }
  });
  
  return response;
}

async function getDeviceCommands(deviceToken) {
  const response = await api.get('/api/v1/esp32/devices/commands', {
    headers: { 
      'Authorization': `Bearer ${deviceToken}`
    }
  });
  
  return response.data;
}

// ===== DEVICE CRUD TESTS =====

async function testDeviceCRUD() {
  await test('Create Device with Valid Data', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const deviceName = randomName();
    
    const device = await createTestDevice(userData.token, { name: deviceName });
    
    if (!device.id) throw new Error('No device ID returned');
    if (device.name !== deviceName) throw new Error('Device name mismatch');
    if (!device.device_type) throw new Error('No device type returned');
    if (device.status !== 'pending') throw new Error('Initial status should be pending');
  });

  await test('List User Devices', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    
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
  });

  await test('Get Device Details', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const device = await createTestDevice(userData.token);
    
    const response = await makeAuthenticatedRequest(
      userData.token, 
      `/api/v1/frontend/devices/${device.id}`
    );
    
    if (response.data.status !== 'success') throw new Error('Failed to get device details');
    
    const details = response.data.data;
    if (!details.device) throw new Error('No device data in response');
    if (!details.sensor_groups) throw new Error('No sensor groups in response');
    if (!details.latest_readings) throw new Error('No latest readings in response');
    if (!details.device_status) throw new Error('No device status in response');
    
    log.info(`Device has ${Object.keys(details.sensor_groups).length} sensor groups`);
  });

  await test('Update Device', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
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
  });

  await test('Update Device Status', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const device = await createTestDevice(userData.token);
    
    const response = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}/update_status`,
      'PATCH',
      { device: { status: 'active' } }
    );
    
    if (response.data.status !== 'success') throw new Error('Failed to update device status');
    if (response.data.data.status !== 'active') throw new Error('Device status not updated');
  });

  await test('Delete Device', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
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
        return; // Expected - device not found
      }
      throw error;
    }
  });
}

// ===== DEVICE LIMITS & SUBSCRIPTION TESTS =====

async function testDeviceLimits() {
  await test('Basic User Device Limit (2 devices)', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    
    // Create 2 devices (should work)
    await createTestDevice(userData.token, { name: 'Device1' });
    await createTestDevice(userData.token, { name: 'Device2' });
    
    // Try to create 3rd device (should fail for basic user)
    try {
      await createTestDevice(userData.token, { name: 'Device3' });
      throw new Error('Should have failed due to device limit');
    } catch (error) {
      if (error.response && error.response.status === 422) {
        return; // Expected - device limit exceeded
      }
      throw error;
    }
  });

  await test('Dashboard Device Limit Information', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    
    const response = await makeAuthenticatedRequest(userData.token, '/api/v1/frontend/dashboard');
    
    if (response.data.status !== 'success') throw new Error('Failed to get dashboard');
    
    const data = response.data.data;
    if (!data.deviceSlots) throw new Error('No device slots information');
    if (!Array.isArray(data.deviceSlots)) throw new Error('Device slots should be array');
    if (!data.tierInfo) throw new Error('No tier information');
    
    // Check tier info structure
    const tierInfo = data.tierInfo;
    if (typeof tierInfo.baseLimit !== 'number') throw new Error('Missing base limit');
    if (typeof tierInfo.usedSlots !== 'number') throw new Error('Missing used slots');
    
    log.info(`User has ${tierInfo.baseLimit} device slots, using ${tierInfo.usedSlots}`);
  });
}

// ===== SENSOR DATA TESTS =====

async function testSensorData() {
  await test('Send Sensor Data (Mock ESP32)', async () => {
    // This test simulates ESP32 sending sensor data
    // We need a device with activation token for this
    
    // Note: This test might need actual device activation flow
    // For now, we'll test the endpoint structure
    
    const mockSensorData = {
      timestamp: Math.floor(Date.now() / 1000),
      temp: 23.5,
      hum: 65.0
    };
    
    try {
      await sendSensorData('mock-device-token', mockSensorData);
    } catch (error) {
      if (error.response && error.response.status === 401) {
        // Expected - invalid device token
        log.info('Sensor data endpoint correctly rejects invalid tokens');
        return;
      }
      throw error;
    }
  });

  await test('Get Device Commands (Mock ESP32)', async () => {
    try {
      await getDeviceCommands('mock-device-token');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        // Expected - invalid device token
        log.info('Commands endpoint correctly rejects invalid tokens');
        return;
      }
      throw error;
    }
  });
}

// ===== DEVICE STATUS & ALERT TESTS =====

async function testDeviceStatus() {
  await test('Device Alert Status Calculation', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const device = await createTestDevice(userData.token);
    
    // Get device details to check status calculation
    const response = await makeAuthenticatedRequest(
      userData.token, 
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const details = response.data.data;
    const deviceStatus = details.device_status;
    
    if (!deviceStatus.overall_status) throw new Error('Missing overall status');
    if (!deviceStatus.alert_level) throw new Error('Missing alert level');
    if (typeof deviceStatus.connection_status === 'undefined') {
      throw new Error('Missing connection status');
    }
    
    log.info(`Device status: ${deviceStatus.overall_status}, Alert: ${deviceStatus.alert_level}`);
  });

  await test('Device Connection Status', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const device = await createTestDevice(userData.token);
    
    // Update last connection
    await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'PUT',
      { device: { name: device.name } } // Trigger update
    );
    
    const response = await makeAuthenticatedRequest(
      userData.token, 
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceStatus = response.data.data.device_status;
    
    // Connection status should be calculated based on last_connection
    if (!['online', 'offline'].includes(deviceStatus.connection_status)) {
      throw new Error(`Invalid connection status: ${deviceStatus.connection_status}`);
    }
  });
}

// ===== DEVICE PERMISSIONS TESTS =====

async function testDevicePermissions() {
  await test('User Can Only Access Own Devices', async () => {
    const user1 = await createUser(`test1_${Date.now()}@example.com`);
    const user2 = await createUser(`test2_${Date.now()}@example.com`);
    
    const device1 = await createTestDevice(user1.token, { name: 'User1Device' });
    
    // User2 should not be able to access User1's device
    try {
      await makeAuthenticatedRequest(user2.token, `/api/v1/frontend/devices/${device1.id}`);
      throw new Error('User should not access other users devices');
    } catch (error) {
      if (error.response && [403, 404].includes(error.response.status)) {
        return; // Expected - access denied or not found
      }
      throw error;
    }
  });

  await test('User Can Only Update Own Devices', async () => {
    const user1 = await createUser(`test1_${Date.now()}@example.com`);
    const user2 = await createUser(`test2_${Date.now()}@example.com`);
    
    const device1 = await createTestDevice(user1.token, { name: 'User1Device' });
    
    // User2 should not be able to update User1's device
    try {
      await makeAuthenticatedRequest(
        user2.token,
        `/api/v1/frontend/devices/${device1.id}`,
        'PUT',
        { device: { name: 'HackedName' } }
      );
      throw new Error('User should not update other users devices');
    } catch (error) {
      if (error.response && [403, 404].includes(error.response.status)) {
        return; // Expected - access denied or not found
      }
      throw error;
    }
  });
}

// ===== DEVICE COMMAND TESTS =====

async function testDeviceCommands() {
  await test('Send Device Command', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const device = await createTestDevice(userData.token);
    
    const commandData = {
      command: 'on',
      args: { target: 'lights' }
    };
    
    const response = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}/commands`,
      'POST',
      commandData
    );
    
    if (response.data.status !== 'success') {
      throw new Error(`Failed to send command: ${response.data.error}`);
    }
    
    log.info('Command queued successfully');
  });

  await test('Send Invalid Device Command', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    const device = await createTestDevice(userData.token);
    
    const invalidCommand = {
      command: 'invalid_command',
      args: {}
    };
    
    try {
      await makeAuthenticatedRequest(
        userData.token,
        `/api/v1/frontend/devices/${device.id}/commands`,
        'POST',
        invalidCommand
      );
      throw new Error('Should have rejected invalid command');
    } catch (error) {
      if (error.response && error.response.status === 422) {
        return; // Expected - validation error
      }
      throw error;
    }
  });
}

// ===== PERFORMANCE TESTS =====

async function testDevicePerformance() {
  await test('Device List Performance', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    
    // Create several devices
    const devicePromises = [];
    for (let i = 0; i < 5; i++) {
      devicePromises.push(createTestDevice(userData.token, { name: `PerfDevice${i}` }));
    }
    await Promise.all(devicePromises);
    
    const startTime = Date.now();
    const response = await makeAuthenticatedRequest(userData.token, '/api/v1/frontend/devices');
    const duration = Date.now() - startTime;
    
    if (duration > 1000) {
      throw new Error(`Device list too slow: ${duration}ms`);
    }
    
    if (response.data.data.length < 5) {
      throw new Error('Not all devices returned');
    }
    
    log.info(`Listed ${response.data.data.length} devices in ${duration}ms`);
  });

  await test('Concurrent Device Creation', async () => {
    const userData = await createUser(`test_${Date.now()}@example.com`);
    
    // Try to create 2 devices concurrently (within user limit)
    const promises = [
      createTestDevice(userData.token, { name: 'Concurrent1' }),
      createTestDevice(userData.token, { name: 'Concurrent2' })
    ];
    
    const startTime = Date.now();
    const devices = await Promise.all(promises);
    const duration = Date.now() - startTime;
    
    if (devices.length !== 2) throw new Error('Not all devices created');
    if (devices[0].name === devices[1].name) throw new Error('Device names should be unique');
    
    log.info(`Created ${devices.length} devices concurrently in ${duration}ms`);
  });
}

// ===== MAIN EXECUTION =====

async function runAllTests() {
  log.section('Starting Device Management Test Suite');
  log.info(`Testing against: ${config.baseUrl}`);
  
  try {
    // Test server connectivity
    await api.get('/up');
    log.success('Server is responding');
  } catch (error) {
    log.error('Cannot connect to server. Is Rails running?');
    process.exit(1);
  }

  const startTime = Date.now();

  // Run test categories
  log.section('Device CRUD Tests');
  await testDeviceCRUD();

  log.section('Device Limits & Subscription Tests');
  await testDeviceLimits();

  log.section('Sensor Data Tests');
  await testSensorData();

  log.section('Device Status & Alert Tests');
  await testDeviceStatus();

  log.section('Device Permissions Tests');
  await testDevicePermissions();

  log.section('Device Command Tests');
  await testDeviceCommands();

  log.section('Device Performance Tests');
  await testDevicePerformance();

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
    config
  }, null, 2));
  
  log.info(`Detailed results saved to ${reportFile}`);

  // Exit with appropriate code
  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Handle uncaught errors
process.on('unhandledRejection', (error) => {
  log.error(`Unhandled rejection: ${error.message}`);
  process.exit(1);
});

// Run the tests
if (require.main === module) {
  runAllTests();
}

module.exports = {
  runAllTests,
  testResults,
  createTestDevice,
  sendSensorData,
  getDeviceCommands
};
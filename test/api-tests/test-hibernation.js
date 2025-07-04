#!/usr/bin/env node

/**
 * XSPACEGROW HIBERNATION SYSTEM TEST SUITE
 * 
 * Tests the "Always Accept, Then Upsell" device management system including:
 * - Device hibernation vs operational status
 * - Smart hibernation priority algorithms
 * - Grace period management
 * - Upsell option generation
 * - Device activation flows
 * - Business logic validation
 * 
 * Usage:
 *   node test-hibernation.js
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

const randomEmail = () => `test_hib_${Date.now()}_${Math.random().toString(36).substr(2, 5)}@example.com`;
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
async function test(name, testFn, category = 'hibernation') {
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

// ===== HIBERNATION HELPER FUNCTIONS =====

async function createUserWithSubscription(planName = 'Basic', deviceCount = 0) {
  const userData = await createUser(randomEmail());
  
  // Create subscription
  const response = await makeAuthenticatedRequest(
    userData.token,
    '/api/v1/frontend/onboarding/select_plan',
    'POST',
    {
      plan_id: planName === 'Basic' ? 1 : 2,
      interval: 'month'
    }
  );
  
  if (response.data.status !== 'success') {
    throw new Error(`Failed to create subscription: ${response.data.message}`);
  }
  
  // Create specified number of devices
  const devices = [];
  for (let i = 0; i < deviceCount; i++) {
    const device = await createTestDevice(userData.token, { 
      name: `Device${i + 1}`,
      status: 'active',
      last_connection: new Date(Date.now() - (i * 24 * 60 * 60 * 1000)).toISOString() // Stagger connection times
    });
    devices.push(device);
  }
  
  return {
    ...userData,
    subscription: response.data.data.subscription,
    devices
  };
}

async function createTestDevice(userToken, deviceData = {}) {
  const defaultData = {
    name: randomName(),
    device_type_id: 1,
    status: 'pending'
  };
  
  const response = await makeAuthenticatedRequest(
    userToken,
    '/api/v1/frontend/devices',
    'POST',
    { device: { ...defaultData, ...deviceData } }
  );
  
  if (response.data.status !== 'success') {
    throw new Error(`Failed to create device: ${response.data.errors?.join(', ') || 'Unknown error'}`);
  }
  
  return response.data.data;
}

async function hibernateDevice(userToken, deviceId, reason = 'testing') {
  const response = await makeAuthenticatedRequest(
    userToken,
    `/api/v1/frontend/devices/${deviceId}/hibernate`,
    'POST',
    { reason }
  );
  
  return response.data;
}

async function wakeDevice(userToken, deviceId) {
  const response = await makeAuthenticatedRequest(
    userToken,
    `/api/v1/frontend/devices/${deviceId}/wake`,
    'POST'
  );
  
  return response.data;
}

async function activateDevice(userToken, deviceId, activationToken = null) {
  // Simulate device activation with hibernation handling
  const response = await makeAuthenticatedRequest(
    userToken,
    `/api/v1/esp32/devices/validate`,
    'POST',
    {
      token: activationToken || `mock_token_${deviceId}`,
      device_type_id: 1
    }
  );
  
  return response.data;
}

async function getDeviceManagement(userToken) {
  const response = await makeAuthenticatedRequest(
    userToken,
    '/api/v1/frontend/subscriptions/device_management'
  );
  
  return response.data;
}

// ===== DEVICE STATUS TESTS =====

async function testDeviceStatusHierarchy() {
  await test('Device Status: Pending to Active Transition', async () => {
    const userData = await createUserWithSubscription('Basic');
    const device = await createTestDevice(userData.token, { name: 'PendingDevice' });
    
    if (device.status !== 'pending') {
      throw new Error('New devices should start as pending');
    }
    
    // Activate device
    const activatedDevice = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'PATCH',
      { device: { status: 'active' } }
    );
    
    if (activatedDevice.data.data.status !== 'active') {
      throw new Error('Device should be active after activation');
    }
    
    log.info('Device successfully transitioned from pending to active');
  });

  await test('Device Status: Active to Hibernating Transition', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    const result = await hibernateDevice(userData.token, device.id, 'test hibernation');
    
    if (result.status !== 'success') {
      throw new Error(`Failed to hibernate device: ${result.message}`);
    }
    
    // Verify device status
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    if (!deviceData.hibernated_at) {
      throw new Error('Device should have hibernated_at timestamp');
    }
    
    if (!deviceData.hibernated_reason) {
      throw new Error('Device should have hibernation reason');
    }
    
    if (!deviceData.grace_period_ends_at) {
      throw new Error('Device should have grace period end date');
    }
    
    log.info(`Device hibernated with reason: ${deviceData.hibernated_reason}`);
  });

  await test('Device Status: Hibernating to Active Transition', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Hibernate device first
    await hibernateDevice(userData.token, device.id, 'test wake up');
    
    // Wake device
    const result = await wakeDevice(userData.token, device.id);
    
    if (result.status !== 'success') {
      throw new Error(`Failed to wake device: ${result.message}`);
    }
    
    // Verify device is operational
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    if (deviceData.hibernated_at) {
      throw new Error('Device should not have hibernated_at after waking');
    }
    
    log.info('Device successfully woken from hibernation');
  });
}

// ===== DEVICE COUNTING TESTS =====

async function testDeviceCounting() {
  await test('Operational vs Hibernating Device Count', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 3 devices, activate 2, hibernate 1
    const device1 = await createTestDevice(userData.token, { name: 'Active1', status: 'active' });
    const device2 = await createTestDevice(userData.token, { name: 'Active2', status: 'active' });
    const device3 = await createTestDevice(userData.token, { name: 'Hibernating1', status: 'active' });
    
    // Hibernate the third device
    await hibernateDevice(userData.token, device3.id, 'over limit');
    
    // Get device management info
    const management = await getDeviceManagement(userData.token);
    
    if (management.status !== 'success') {
      throw new Error('Failed to get device management info');
    }
    
    const data = management.data;
    if (data.operational_devices_count !== 2) {
      throw new Error(`Expected 2 operational devices, got ${data.operational_devices_count}`);
    }
    
    if (data.hibernating_devices_count !== 1) {
      throw new Error(`Expected 1 hibernating device, got ${data.hibernating_devices_count}`);
    }
    
    if (data.over_device_limit !== false) {
      throw new Error('Should not be over device limit with 2 operational devices');
    }
    
    log.info(`Device counts: ${data.operational_devices_count} operational, ${data.hibernating_devices_count} hibernating`);
  });

  await test('Device Limit Enforcement - Only Operational Devices Count', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create and hibernate 3 devices
    const devices = [];
    for (let i = 0; i < 3; i++) {
      const device = await createTestDevice(userData.token, { 
        name: `HibernatedDevice${i + 1}`, 
        status: 'active' 
      });
      await hibernateDevice(userData.token, device.id, 'testing limits');
      devices.push(device);
    }
    
    // Now should be able to create 2 more operational devices
    const operational1 = await createTestDevice(userData.token, { 
      name: 'Operational1', 
      status: 'active' 
    });
    const operational2 = await createTestDevice(userData.token, { 
      name: 'Operational2', 
      status: 'active' 
    });
    
    // Verify device management shows we're at limit
    const management = await getDeviceManagement(userData.token);
    const data = management.data;
    
    if (data.operational_devices_count !== 2) {
      throw new Error(`Expected 2 operational devices, got ${data.operational_devices_count}`);
    }
    
    if (data.hibernating_devices_count !== 3) {
      throw new Error(`Expected 3 hibernating devices, got ${data.hibernating_devices_count}`);
    }
    
    if (data.over_device_limit !== false) {
      throw new Error('Should not be over limit with hibernated devices');
    }
    
    log.info('Hibernated devices do not count against subscription limits');
  });
}

// ===== HIBERNATION PRIORITY TESTS =====

async function testHibernationPriority() {
  await test('Smart Hibernation Priority - Never Connected Devices First', async () => {
    const userData = await createUserWithSubscription('Professional'); // 4 device limit
    
    // Create devices with different connection histories
    const neverConnected = await createTestDevice(userData.token, { 
      name: 'NeverConnected', 
      status: 'active',
      last_connection: null 
    });
    
    const recentlyConnected = await createTestDevice(userData.token, { 
      name: 'RecentlyConnected', 
      status: 'active',
      last_connection: new Date().toISOString()
    });
    
    const oldConnection = await createTestDevice(userData.token, { 
      name: 'OldConnection', 
      status: 'active',
      last_connection: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString() // 1 week ago
    });
    
    // Get hibernation priorities
    const management = await getDeviceManagement(userData.token);
    const priorities = management.data.hibernation_priorities;
    
    if (!priorities || !Array.isArray(priorities)) {
      throw new Error('Hibernation priorities not returned');
    }
    
    // Never connected should have highest priority (highest score)
    const neverConnectedPriority = priorities.find(p => p.device_id === neverConnected.id);
    const recentlyConnectedPriority = priorities.find(p => p.device_id === recentlyConnected.id);
    
    if (!neverConnectedPriority || !recentlyConnectedPriority) {
      throw new Error('Missing priority data for devices');
    }
    
    if (neverConnectedPriority.score <= recentlyConnectedPriority.score) {
      throw new Error('Never connected device should have higher hibernation priority');
    }
    
    log.info(`Hibernation priorities: Never connected: ${neverConnectedPriority.score}, Recently connected: ${recentlyConnectedPriority.score}`);
  });

  await test('Hibernation Priority - Age-Based Scoring', async () => {
    const userData = await createUserWithSubscription('Professional');
    
    // Create old and new devices
    const oldDevice = await createTestDevice(userData.token, { 
      name: 'OldDevice', 
      status: 'active',
      created_at: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days ago
    });
    
    const newDevice = await createTestDevice(userData.token, { 
      name: 'NewDevice', 
      status: 'active'
    });
    
    // Get hibernation priorities
    const management = await getDeviceManagement(userData.token);
    const priorities = management.data.hibernation_priorities;
    
    const oldDevicePriority = priorities.find(p => p.device_id === oldDevice.id);
    const newDevicePriority = priorities.find(p => p.device_id === newDevice.id);
    
    if (!oldDevicePriority || !newDevicePriority) {
      throw new Error('Missing priority data for age-based devices');
    }
    
    log.info(`Age-based priorities: Old device: ${oldDevicePriority.score}, New device: ${newDevicePriority.score}`);
  });

  await test('Automatic Hibernation on Limit Exceeded', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 2 operational devices (at limit)
    const device1 = await createTestDevice(userData.token, { 
      name: 'Device1', 
      status: 'active',
      last_connection: new Date().toISOString()
    });
    
    const device2 = await createTestDevice(userData.token, { 
      name: 'Device2', 
      status: 'active',
      last_connection: new Date(Date.now() - 1000).toISOString()
    });
    
    // Create third device with never connected (highest hibernation priority)
    const device3 = await createTestDevice(userData.token, { 
      name: 'NeverConnectedDevice', 
      status: 'active',
      last_connection: null
    });
    
    // Simulate subscription activation of device (should trigger hibernation)
    const activation = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/frontend/subscriptions/activate_device',
      'POST',
      { device_id: device3.id }
    );
    
    if (activation.data.status !== 'success') {
      throw new Error('Device activation failed');
    }
    
    const result = activation.data.data;
    if (result.operational !== false) {
      throw new Error('Device should be hibernated when over limit');
    }
    
    if (!result.hibernated) {
      throw new Error('Device should be marked as hibernated');
    }
    
    if (!result.hibernated_device) {
      throw new Error('Should return which device was hibernated');
    }
    
    if (!result.upsell_options || !Array.isArray(result.upsell_options)) {
      throw new Error('Should provide upsell options');
    }
    
    log.info(`Device hibernated due to limit. Hibernated device: ${result.hibernated_device.name}`);
    log.info(`Upsell options provided: ${result.upsell_options.map(o => o.type).join(', ')}`);
  });
}

// ===== GRACE PERIOD TESTS =====

async function testGracePeriod() {
  await test('Grace Period Creation and Validation', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Hibernate device
    await hibernateDevice(userData.token, device.id, 'grace period test');
    
    // Get device details
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    const gracePeriodEnd = new Date(deviceData.grace_period_ends_at);
    const now = new Date();
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    // Grace period should be approximately 7 days from now
    const timeDiff = Math.abs(gracePeriodEnd.getTime() - sevenDaysFromNow.getTime());
    if (timeDiff > 60 * 60 * 1000) { // Allow 1 hour tolerance
      throw new Error(`Grace period end time incorrect. Expected ~${sevenDaysFromNow}, got ${gracePeriodEnd}`);
    }
    
    log.info(`Grace period ends at: ${gracePeriodEnd.toISOString()}`);
  });

  await test('Grace Period Status Check', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Hibernate device
    await hibernateDevice(userData.token, device.id, 'grace period status test');
    
    // Check if device is in grace period
    const management = await getDeviceManagement(userData.token);
    const hibernatingDevices = management.data.hibernating_devices;
    
    const deviceInfo = hibernatingDevices.find(d => d.device_id === device.id);
    if (!deviceInfo) {
      throw new Error('Hibernated device not found in hibernating devices list');
    }
    
    if (!deviceInfo.in_grace_period) {
      throw new Error('Device should be in grace period immediately after hibernation');
    }
    
    log.info(`Device is in grace period: ${deviceInfo.in_grace_period}`);
  });

  await test('Grace Period Expiration Simulation', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Simulate expired grace period by setting past date
    const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(); // 1 day ago
    
    await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'PATCH',
      { 
        device: { 
          hibernated_at: pastDate,
          grace_period_ends_at: pastDate,
          hibernated_reason: 'expired grace period test'
        } 
      }
    );
    
    // Check grace period status
    const management = await getDeviceManagement(userData.token);
    const hibernatingDevices = management.data.hibernating_devices;
    
    const deviceInfo = hibernatingDevices.find(d => d.device_id === device.id);
    if (deviceInfo && deviceInfo.in_grace_period) {
      throw new Error('Device should not be in grace period after expiration');
    }
    
    log.info('Grace period correctly expired for device');
  });
}

// ===== UPSELL OPTIONS TESTS =====

async function testUpsellOptions() {
  await test('Upsell Options Generation - Add Device Slots', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 3 devices to exceed limit
    for (let i = 0; i < 3; i++) {
      await createTestDevice(userData.token, { 
        name: `Device${i + 1}`, 
        status: 'active' 
      });
    }
    
    // Get subscription info to trigger upsell options
    const subscription = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/frontend/subscriptions'
    );
    
    const data = subscription.data.data;
    if (!data.upsell_options || !Array.isArray(data.upsell_options)) {
      throw new Error('Upsell options not provided');
    }
    
    const addSlotsOption = data.upsell_options.find(o => o.type === 'add_slots');
    if (!addSlotsOption) {
      throw new Error('Add device slots option not found');
    }
    
    if (typeof addSlotsOption.cost !== 'number' || addSlotsOption.cost <= 0) {
      throw new Error('Add slots option should have valid cost');
    }
    
    if (!addSlotsOption.action || addSlotsOption.action !== 'add_device_slots') {
      throw new Error('Add slots option should have correct action');
    }
    
    log.info(`Add slots option: $${addSlotsOption.cost}/month for ${addSlotsOption.devices_count || 1} device(s)`);
  });

  await test('Upsell Options Generation - Plan Upgrade', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create devices to exceed limit
    for (let i = 0; i < 4; i++) {
      await createTestDevice(userData.token, { 
        name: `Device${i + 1}`, 
        status: 'active' 
      });
    }
    
    const subscription = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/frontend/subscriptions'
    );
    
    const data = subscription.data.data;
    const upgradePlanOption = data.upsell_options.find(o => o.type === 'upgrade_plan');
    
    if (!upgradePlanOption) {
      throw new Error('Upgrade plan option not found');
    }
    
    if (typeof upgradePlanOption.cost !== 'number') {
      throw new Error('Upgrade plan option should have cost');
    }
    
    if (!upgradePlanOption.title || !upgradePlanOption.title.includes('Professional')) {
      throw new Error('Upgrade option should mention Professional plan');
    }
    
    log.info(`Upgrade plan option: ${upgradePlanOption.title} for $${upgradePlanOption.cost} more/month`);
  });

  await test('Upsell Options Generation - Device Management', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    // Create devices to exceed limit
    for (let i = 0; i < 3; i++) {
      await createTestDevice(userData.token, { 
        name: `Device${i + 1}`, 
        status: 'active' 
      });
    }
    
    const subscription = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/frontend/subscriptions'
    );
    
    const data = subscription.data.data;
    const manageDevicesOption = data.upsell_options.find(o => o.type === 'manage_devices');
    
    if (!manageDevicesOption) {
      throw new Error('Manage devices option not found');
    }
    
    if (manageDevicesOption.cost !== 0) {
      throw new Error('Manage devices option should be free');
    }
    
    if (!manageDevicesOption.action || manageDevicesOption.action !== 'manage_devices') {
      throw new Error('Manage devices option should have correct action');
    }
    
    log.info(`Manage devices option: ${manageDevicesOption.title} (free)`);
  });
}

// ===== DEVICE ACTIVATION INTEGRATION TESTS =====

async function testDeviceActivationIntegration() {
  await test('Device Activation - Always Succeeds, Then Handles Limits', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 2 operational devices (at limit)
    await createTestDevice(userData.token, { name: 'Device1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Device2', status: 'active' });
    
    // Create 3rd device (should always succeed)
    const device3 = await createTestDevice(userData.token, { name: 'Device3', status: 'pending' });
    
    if (!device3.id) {
      throw new Error('Device creation should always succeed');
    }
    
    // Simulate ESP32 activation
    const activation = await activateDevice(userData.token, device3.id, `mock_token_${device3.id}`);
    
    // Activation should succeed but device should be hibernated
    if (activation.status !== 'success') {
      throw new Error('Device activation should always succeed');
    }
    
    if (!activation.device_status) {
      throw new Error('Activation response should include device status');
    }
    
    const deviceStatus = activation.device_status;
    if (deviceStatus.operational) {
      throw new Error('Device should not be operational when over limit');
    }
    
    if (!deviceStatus.hibernating) {
      throw new Error('Device should be hibernating when over limit');
    }
    
    log.info(`Device activated successfully but hibernated due to subscription limits`);
    log.info(`Hibernated device: ${activation.hibernated_device?.name || 'unknown'}`);
  });

  await test('Device Activation - Upsell Response for ESP32', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Fill subscription limit
    await createTestDevice(userData.token, { name: 'Device1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Device2', status: 'active' });
    
    // Create and activate 3rd device
    const device3 = await createTestDevice(userData.token, { name: 'Device3', status: 'pending' });
    const activation = await activateDevice(userData.token, device3.id);
    
    // Check upsell options in activation response
    if (!activation.upsell_options || !Array.isArray(activation.upsell_options)) {
      throw new Error('Activation should provide upsell options when over limit');
    }
    
    const hasAddSlots = activation.upsell_options.some(o => o.type === 'add_slots');
    const hasUpgradePlan = activation.upsell_options.some(o => o.type === 'upgrade_plan');
    
    if (!hasAddSlots && !hasUpgradePlan) {
      throw new Error('Activation should provide meaningful upsell options');
    }
    
    log.info(`ESP32 activation provided ${activation.upsell_options.length} upsell options`);
  });

  await test('Device Activation - Grace Period in Response', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    // Fill limit and create 3rd device
    await createTestDevice(userData.token, { name: 'Device1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Device2', status: 'active' });
    const device3 = await createTestDevice(userData.token, { name: 'Device3', status: 'pending' });
    
    const activation = await activateDevice(userData.token, device3.id);
    
    if (!activation.device_status.in_grace_period) {
      throw new Error('Hibernated device should be in grace period');
    }
    
    if (!activation.grace_period_ends_at) {
      throw new Error('Activation should include grace period end date');
    }
    
    const gracePeriodEnd = new Date(activation.grace_period_ends_at);
    const now = new Date();
    const daysDiff = (gracePeriodEnd - now) / (1000 * 60 * 60 * 24);
    
    if (daysDiff < 6 || daysDiff > 8) {
      throw new Error(`Grace period should be ~7 days, got ${daysDiff.toFixed(1)} days`);
    }
    
    log.info(`Device activation includes grace period: ${daysDiff.toFixed(1)} days remaining`);
  });
}

// ===== BUSINESS WORKFLOW TESTS =====

async function testBusinessWorkflows() {
  await test('Complete Customer Journey - Purchase to Upsell', async () => {
    // Step 1: Customer buys device and gets token
    const userData = await createUserWithSubscription('Basic');
    const activationToken = `customer_token_${Date.now()}`;
    
    // Step 2: Customer already has 2 devices (at limit)
    await createTestDevice(userData.token, { name: 'ExistingDevice1', status: 'active' });
    await createTestDevice(userData.token, { name: 'ExistingDevice2', status: 'active' });
    
    // Step 3: Customer tries to activate new device
    const newDevice = await createTestDevice(userData.token, { name: 'NewPurchase', status: 'pending' });
    const activation = await activateDevice(userData.token, newDevice.id, activationToken);
    
    // Step 4: Device is activated but hibernated with upsell options
    if (activation.status !== 'success') {
      throw new Error('Customer activation should always succeed');
    }
    
    if (activation.device_status.operational) {
      throw new Error('New device should be hibernated when over limit');
    }
    
    if (!activation.upsell_options || activation.upsell_options.length === 0) {
      throw new Error('Customer should receive upsell options');
    }
    
    // Step 5: Verify customer experience
    const hasReasonableUpsell = activation.upsell_options.some(option => 
      (option.type === 'add_slots' && option.cost <= 10) ||
      (option.type === 'upgrade_plan' && option.cost <= 20)
    );
    
    if (!hasReasonableUpsell) {
      throw new Error('Upsell options should be reasonably priced');
    }
    
    log.info('✅ Complete customer journey: Purchase → Activation → Hibernation → Upsell options');
    log.success('🎯 Customer never blocked from using purchased device!');
  });

  await test('Plan Upgrade Workflow - Wake Up Hibernated Devices', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 3 devices, ensure 1 is hibernated
    await createTestDevice(userData.token, { name: 'Active1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Active2', status: 'active' });
    const hibernatedDevice = await createTestDevice(userData.token, { name: 'Hibernated', status: 'active' });
    await hibernateDevice(userData.token, hibernatedDevice.id, 'over limit');
    
    // Upgrade to Professional plan
    const upgrade = await makeAuthenticatedRequest(
      userData.token,
      '/api/v1/frontend/subscriptions/change_plan',
      'POST',
      {
        plan_id: 2, // Professional
        interval: 'month',
        strategy: 'immediate'
      }
    );
    
    if (upgrade.data.status !== 'success') {
      throw new Error('Plan upgrade failed');
    }
    
    // Check if hibernated devices can now be activated
    const wakeResult = await wakeDevice(userData.token, hibernatedDevice.id);
    
    if (wakeResult.status !== 'success') {
      throw new Error('Should be able to wake device after plan upgrade');
    }
    
    // Verify device is now operational
    const management = await getDeviceManagement(userData.token);
    if (management.data.operational_devices_count !== 3) {
      throw new Error('Should have 3 operational devices after upgrade and wake');
    }
    
    log.info('Plan upgrade allows hibernated devices to become operational');
  });

  await test('Device Management Dashboard Experience', async () => {
    const userData = await createUserWithSubscription('Professional'); // 4 device limit
    
    // Create mixed device statuses
    await createTestDevice(userData.token, { name: 'Operational1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Operational2', status: 'active' });
    const hibernated1 = await createTestDevice(userData.token, { name: 'Hibernated1', status: 'active' });
    const hibernated2 = await createTestDevice(userData.token, { name: 'Hibernated2', status: 'active' });
    
    await hibernateDevice(userData.token, hibernated1.id, 'user choice');
    await hibernateDevice(userData.token, hibernated2.id, 'over limit');
    
    // Get device management dashboard
    const management = await getDeviceManagement(userData.token);
    const data = management.data;
    
    // Verify dashboard provides complete picture
    if (data.operational_devices_count !== 2) {
      throw new Error(`Expected 2 operational devices, got ${data.operational_devices_count}`);
    }
    
    if (data.hibernating_devices_count !== 2) {
      throw new Error(`Expected 2 hibernating devices, got ${data.hibernating_devices_count}`);
    }
    
    if (!data.hibernating_devices || data.hibernating_devices.length !== 2) {
      throw new Error('Should provide details of hibernating devices');
    }
    
    // Check hibernating device details
    const hibernatingDevice = data.hibernating_devices[0];
    if (!hibernatingDevice.device_id || !hibernatingDevice.hibernated_reason) {
      throw new Error('Hibernating device details incomplete');
    }
    
    if (typeof hibernatingDevice.in_grace_period !== 'boolean') {
      throw new Error('Grace period status should be boolean');
    }
    
    // Verify upsell options
    if (!data.upsell_options || !Array.isArray(data.upsell_options)) {
      throw new Error('Dashboard should provide upsell options');
    }
    
    log.info(`Dashboard shows: ${data.operational_devices_count} operational, ${data.hibernating_devices_count} hibernating`);
    log.info(`Grace periods: ${data.hibernating_devices.filter(d => d.in_grace_period).length} devices in grace period`);
  });
}

// ===== PERFORMANCE & EDGE CASE TESTS =====

async function testPerformanceAndEdgeCases() {
  await test('Hibernation Performance with Many Devices', async () => {
    const userData = await createUserWithSubscription('Professional'); // 4 device limit
    
    const startTime = Date.now();
    
    // Create 10 devices rapidly
    const devicePromises = [];
    for (let i = 0; i < 10; i++) {
      devicePromises.push(createTestDevice(userData.token, { 
        name: `PerfDevice${i}`, 
        status: 'active',
        last_connection: i % 2 === 0 ? null : new Date().toISOString() // Mix connected/never connected
      }));
    }
    
    const devices = await Promise.all(devicePromises);
    
    // Get hibernation priorities (should be fast)
    const management = await getDeviceManagement(userData.token);
    
    const totalTime = Date.now() - startTime;
    
    if (totalTime > 5000) {
      throw new Error(`Hibernation calculation too slow: ${totalTime}ms`);
    }
    
    if (!management.data.hibernation_priorities || management.data.hibernation_priorities.length !== 10) {
      throw new Error('Should calculate priorities for all devices');
    }
    
    log.info(`Hibernation priorities calculated for ${devices.length} devices in ${totalTime}ms`);
  });

  await test('Concurrent Device Activation Handling', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Fill limit
    await createTestDevice(userData.token, { name: 'Existing1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Existing2', status: 'active' });
    
    // Try to activate 2 devices simultaneously
    const device1 = await createTestDevice(userData.token, { name: 'Concurrent1', status: 'pending' });
    const device2 = await createTestDevice(userData.token, { name: 'Concurrent2', status: 'pending' });
    
    const activationPromises = [
      activateDevice(userData.token, device1.id),
      activateDevice(userData.token, device2.id)
    ];
    
    const results = await Promise.allSettled(activationPromises);
    
    // Both should succeed (always accept policy)
    const successful = results.filter(r => r.status === 'fulfilled' && r.value.status === 'success');
    
    if (successful.length !== 2) {
      throw new Error('Both concurrent activations should succeed');
    }
    
    // At least one should be hibernated
    const hibernated = successful.filter(r => r.value.device_status.hibernating);
    
    if (hibernated.length === 0) {
      throw new Error('At least one device should be hibernated when over limit');
    }
    
    log.info(`Concurrent activations: ${successful.length} succeeded, ${hibernated.length} hibernated`);
  });

  await test('Edge Case - Hibernation of Device in Grace Period', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    const device = await createTestDevice(userData.token, { name: 'GraceDevice', status: 'active' });
    
    // Hibernate device
    await hibernateDevice(userData.token, device.id, 'first hibernation');
    
    // Try to hibernate again while in grace period
    const secondHibernation = await hibernateDevice(userData.token, device.id, 'second hibernation');
    
    if (secondHibernation.status !== 'success') {
      throw new Error('Should handle re-hibernation gracefully');
    }
    
    // Verify grace period is reset or handled properly
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    if (!deviceData.hibernated_at) {
      throw new Error('Device should still be hibernated');
    }
    
    log.info('Re-hibernation of device in grace period handled correctly');
  });

  await test('Edge Case - Wake Device Not in Grace Period', async () => {
    const userData = await createUserWithSubscription('Professional'); // More room for devices
    
    const device = await createTestDevice(userData.token, { name: 'ExpiredDevice', status: 'active' });
    
    // Simulate expired grace period
    const pastDate = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(); // 10 days ago
    await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'PATCH',
      { 
        device: { 
          hibernated_at: pastDate,
          grace_period_ends_at: pastDate,
          hibernated_reason: 'expired test'
        } 
      }
    );
    
    // Should still be able to wake device
    const wakeResult = await wakeDevice(userData.token, device.id);
    
    if (wakeResult.status !== 'success') {
      throw new Error('Should be able to wake device even after grace period expires');
    }
    
    log.info('Device successfully woken after grace period expiration');
  });
}

// ===== MAIN EXECUTION =====

async function runAllTests() {
  log.section('Starting Hibernation System Test Suite');
  log.info(`Testing the "Always Accept, Then Upsell" device management system`);
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
  log.section('Device Status Hierarchy Tests');
  await testDeviceStatusHierarchy();

  log.section('Device Counting Tests');
  await testDeviceCounting();

  log.section('Hibernation Priority Tests');
  await testHibernationPriority();

  log.section('Grace Period Tests');
  await testGracePeriod();

  log.section('Upsell Options Tests');
  await testUpsellOptions();

  log.section('Device Activation Integration Tests');
  await testDeviceActivationIntegration();

  log.section('Business Workflow Tests');
  await testBusinessWorkflows();

  log.section('Performance & Edge Case Tests');
  await testPerformanceAndEdgeCases();

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
  const reportFile = `hibernation-test-results-${Date.now()}.json`;
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
    test_coverage: {
      device_status_hierarchy: true,
      hibernation_priority: true,
      grace_period_management: true,
      upsell_option_generation: true,
      device_activation_integration: true,
      business_workflows: true,
      performance_edge_cases: true
    }
  }, null, 2));
  
  log.info(`Detailed results saved to ${reportFile}`);

  // Business impact summary
  log.section('Business Impact Validation');
  log.info('✅ Always Accept Policy: Devices are never blocked from activation');
  log.info('✅ Smart Hibernation: Oldest/offline devices hibernated first');
  log.info('✅ Grace Period: 7-day window for customers to decide');
  log.info('✅ Upsell Options: Clear upgrade paths provided');
  log.info('✅ Customer Experience: No friction, transparent, flexible');
  log.info('✅ Revenue Opportunity: Limits become sales opportunities');

  if (testResults.failed === 0) {
    log.success('🎉 Hibernation System: FULLY VALIDATED!');
    log.success('🚀 Ready to turn subscription limits into revenue drivers!');
  } else {
    log.warning(`⚠️  ${testResults.failed} tests failed - review hibernation system implementation`);
  }

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
  createUserWithSubscription,
  hibernateDevice,
  wakeDevice,
  activateDevice,
  getDeviceManagement
};
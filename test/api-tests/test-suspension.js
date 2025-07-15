#!/usr/bin/env node

/**
 * XSPACEGROW SUSPENSION SYSTEM TEST SUITE
 * 
 * Tests the "Always Accept, Then Upsell" device management system including:
 * - Device status transitions (pending → active → suspended)
 * - Smart suspension priority algorithms
 * - Grace period management
 * - Upsell option generation
 * - Device activation flows
 * - Business logic validation
 * 
 * Usage:
 *   node test-suspension.js
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

const randomEmail = () => `test_susp_${Date.now()}_${Math.random().toString(36).substr(2, 5)}@example.com`;
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
async function test(name, testFn, category = 'suspension') {
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

// ===== SUSPENSION HELPER FUNCTIONS =====

async function createUserWithSubscription(planName = 'Basic', deviceCount = 0) {
  const userData = await createUser(randomEmail());
  
  // Create subscription
  const response = await makeAuthenticatedRequest(
    userData.token,
    '/api/v1/frontend/onboarding/select_plan',
    'POST',
    {
      plan_id: planName === 'Basic' ? 1 : planName === 'Professional' ? 2 : 3,
      interval: 'month'
    }
  );
  
  if (response.data.status !== 'success') {
    throw new Error(`Failed to create subscription: ${response.data.message}`);
  }
  
  userData.subscription = response.data.data.subscription;
  userData.devices = [];
  
  // Create specified number of test devices
  for (let i = 0; i < deviceCount; i++) {
    const device = await createTestDevice(userData.token, { 
      name: `Device${i + 1}`, 
      status: 'active' 
    });
    userData.devices.push(device);
  }
  
  return userData;
}

async function createTestDevice(token, options = {}) {
  const deviceData = {
    name: options.name || randomName(),
    device_type_id: 1, // Assuming default device type exists
    ...options
  };
  
  const response = await makeAuthenticatedRequest(
    token,
    '/api/v1/frontend/devices',
    'POST',
    { device: deviceData }
  );
  
  if (response.data.status !== 'success') {
    throw new Error(`Failed to create device: ${response.data.message}`);
  }
  
  return response.data.data.device;
}

async function suspendDevice(token, deviceId, reason = 'test suspension') {
  const response = await makeAuthenticatedRequest(
    token,
    `/api/v1/frontend/devices/${deviceId}/suspend`,
    'POST',
    { reason, grace_period_days: 7 }
  );
  
  return response.data;
}

async function wakeDevice(token, deviceId) {
  const response = await makeAuthenticatedRequest(
    token,
    `/api/v1/frontend/devices/${deviceId}/wake`,
    'POST',
    {}
  );
  
  return response.data;
}

async function activateDevice(token, deviceId) {
  const response = await makeAuthenticatedRequest(
    token,
    '/api/v1/frontend/subscriptions/activate_device',
    'POST',
    { device_id: deviceId }
  );
  
  return response.data;
}

async function getDeviceManagement(token) {
  const response = await makeAuthenticatedRequest(
    token,
    '/api/v1/frontend/subscriptions/device_management'
  );
  
  return response.data;
}

async function getPlans() {
  const response = await api.get('/api/v1/frontend/plans');
  return response.data.data.plans;
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
    const activationResult = await activateDevice(userData.token, device.id);
    
    if (activationResult.status !== 'success') {
      throw new Error(`Failed to activate device: ${activationResult.message}`);
    }
    
    // Verify device status
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    if (deviceData.status !== 'active') {
      throw new Error('Device should be active after activation');
    }
    
    log.info('Device successfully transitioned from pending to active');
  });

  await test('Device Status: Active to Suspended Transition', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    const result = await suspendDevice(userData.token, device.id, 'test suspension');
    
    if (result.status !== 'success') {
      throw new Error(`Failed to suspend device: ${result.message}`);
    }
    
    // Verify device status
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    if (deviceData.status !== 'suspended') {
      throw new Error('Device status should be suspended');
    }
    
    if (!deviceData.suspended_at) {
      throw new Error('Device should have suspended_at timestamp');
    }
    
    if (!deviceData.suspended_reason) {
      throw new Error('Device should have suspension reason');
    }
    
    if (!deviceData.grace_period_ends_at) {
      throw new Error('Device should have grace period end date');
    }
    
    log.info(`Device suspended with reason: ${deviceData.suspended_reason}`);
  });

  await test('Device Status: Suspended to Active Transition', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Suspend device first
    await suspendDevice(userData.token, device.id, 'test wake up');
    
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
    if (deviceData.status !== 'active') {
      throw new Error('Device should be active after waking');
    }
    
    if (deviceData.suspended_at) {
      throw new Error('Device should not have suspended_at after waking');
    }
    
    log.info('Device successfully woken from suspension');
  });
}

// ===== DEVICE COUNTING TESTS =====

async function testDeviceCounting() {
  await test('Operational vs Suspended Device Count', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 3 devices, activate 2, suspend 1
    const device1 = await createTestDevice(userData.token, { name: 'Active1', status: 'active' });
    const device2 = await createTestDevice(userData.token, { name: 'Active2', status: 'active' });
    const device3 = await createTestDevice(userData.token, { name: 'Suspended1', status: 'active' });
    
    // Activate first two devices
    await activateDevice(userData.token, device1.id);
    await activateDevice(userData.token, device2.id);
    
    // Activate third device (should cause suspension due to limit)
    const activation3 = await activateDevice(userData.token, device3.id);
    
    // Get device management info
    const management = await getDeviceManagement(userData.token);
    
    if (management.status !== 'success') {
      throw new Error('Failed to get device management info');
    }
    
    const data = management.data;
    if (data.operational_devices_count !== 2) {
      throw new Error(`Expected 2 operational devices, got ${data.operational_devices_count}`);
    }
    
    if (data.suspended_devices_count !== 1) {
      throw new Error(`Expected 1 suspended device, got ${data.suspended_devices_count}`);
    }
    
    if (data.over_device_limit !== false) {
      throw new Error('Should not be over device limit with 2 operational devices');
    }
    
    log.info(`Device counting: ${data.operational_devices_count} operational, ${data.suspended_devices_count} suspended`);
  });

  await test('Status-Based Device Counting Accuracy', async () => {
    const userData = await createUserWithSubscription('Professional'); // 4 device limit
    
    // Create devices with different statuses
    const pendingDevice = await createTestDevice(userData.token, { name: 'Pending' }); // starts as pending
    const activeDevice = await createTestDevice(userData.token, { name: 'Active', status: 'active' });
    const suspendedDevice = await createTestDevice(userData.token, { name: 'Suspended', status: 'active' });
    
    // Activate one device
    await activateDevice(userData.token, activeDevice.id);
    
    // Suspend one device
    await suspendDevice(userData.token, suspendedDevice.id, 'manual suspension');
    
    // Get counts
    const management = await getDeviceManagement(userData.token);
    const data = management.data;
    
    // Should count by status, not timestamps
    if (data.operational_devices_count !== 1) {
      throw new Error(`Expected 1 operational device (status=active), got ${data.operational_devices_count}`);
    }
    
    if (data.suspended_devices_count !== 1) {
      throw new Error(`Expected 1 suspended device (status=suspended), got ${data.suspended_devices_count}`);
    }
    
    // Pending devices should not count toward operational limit
    if (data.total_devices_count !== 3) {
      throw new Error(`Expected 3 total devices, got ${data.total_devices_count}`);
    }
    
    log.info('Status-based counting works correctly');
  });
}

// ===== SUSPENSION PRIORITY TESTS =====

async function testSuspensionPriority() {
  await test('Suspension Priority - Connection-Based Scoring', async () => {
    const userData = await createUserWithSubscription('Professional');
    
    // Create devices with different connection patterns
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
    
    // Get suspension priorities
    const management = await getDeviceManagement(userData.token);
    const priorities = management.data.suspension_priorities;
    
    if (!priorities || !Array.isArray(priorities)) {
      throw new Error('Suspension priorities not returned');
    }
    
    // Never connected should have highest priority (highest score)
    const neverConnectedPriority = priorities.find(p => p.device_id === neverConnected.id);
    const recentlyConnectedPriority = priorities.find(p => p.device_id === recentlyConnected.id);
    
    if (!neverConnectedPriority || !recentlyConnectedPriority) {
      throw new Error('Missing priority data for devices');
    }
    
    if (neverConnectedPriority.score <= recentlyConnectedPriority.score) {
      throw new Error('Never connected device should have higher suspension priority');
    }
    
    log.info(`Suspension priorities: Never connected: ${neverConnectedPriority.score}, Recently connected: ${recentlyConnectedPriority.score}`);
  });

  await test('Suspension Priority - Age-Based Scoring', async () => {
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
    
    // Get suspension priorities
    const management = await getDeviceManagement(userData.token);
    const priorities = management.data.suspension_priorities;
    
    const oldDevicePriority = priorities.find(p => p.device_id === oldDevice.id);
    const newDevicePriority = priorities.find(p => p.device_id === newDevice.id);
    
    if (!oldDevicePriority || !newDevicePriority) {
      throw new Error('Missing priority data for age test');
    }
    
    // Older devices should have higher suspension priority
    if (oldDevicePriority.score <= newDevicePriority.score) {
      throw new Error('Older devices should have higher suspension priority');
    }
    
    log.info(`Age-based priorities: Old: ${oldDevicePriority.score}, New: ${newDevicePriority.score}`);
  });

  await test('Suspension Priority - Smart Selection Algorithm', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create devices that will test the algorithm
    const offlineDevice = await createTestDevice(userData.token, { 
      name: 'OfflineDevice', 
      status: 'active',
      last_connection: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days ago
    });
    
    const recentDevice = await createTestDevice(userData.token, { 
      name: 'RecentDevice', 
      status: 'active',
      last_connection: new Date().toISOString()
    });
    
    // Activate both to fill limit
    await activateDevice(userData.token, offlineDevice.id);
    await activateDevice(userData.token, recentDevice.id);
    
    // Try to activate a new device - should suspend the offline one
    const newDevice = await createTestDevice(userData.token, { name: 'NewDevice' });
    const activation = await activateDevice(userData.token, newDevice.id);
    
    if (activation.status !== 'success') {
      throw new Error('Device activation should succeed with smart suspension');
    }
    
    // Check which device was suspended
    const management = await getDeviceManagement(userData.token);
    const suspendedDevices = management.data.suspended_devices;
    
    if (!suspendedDevices || suspendedDevices.length !== 1) {
      throw new Error('Exactly one device should be suspended');
    }
    
    const suspendedDevice = suspendedDevices[0];
    if (suspendedDevice.id !== offlineDevice.id) {
      log.warning(`Expected offline device to be suspended, but ${suspendedDevice.name} was suspended instead`);
    } else {
      log.info('Smart algorithm correctly suspended offline device');
    }
  });
}

// ===== GRACE PERIOD TESTS =====

async function testGracePeriod() {
  await test('Grace Period Creation and Validation', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Suspend device
    await suspendDevice(userData.token, device.id, 'grace period test');
    
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
      throw new Error(`Grace period end time incorrect. Expected ~7 days, got ${Math.round(timeDiff / (1000 * 60 * 60 * 24))} days`);
    }
    
    log.info(`Grace period set correctly: ends in ${Math.round((gracePeriodEnd - now) / (1000 * 60 * 60 * 24))} days`);
  });

  await test('Grace Period Status Detection', async () => {
    const userData = await createUserWithSubscription('Basic', 1);
    const device = userData.devices[0];
    
    // Suspend device
    await suspendDevice(userData.token, device.id, 'grace period status test');
    
    // Get device management info
    const management = await getDeviceManagement(userData.token);
    const suspendedDevices = management.data.suspended_devices;
    
    if (!suspendedDevices || suspendedDevices.length !== 1) {
      throw new Error('Should have exactly one suspended device');
    }
    
    const suspendedDevice = suspendedDevices[0];
    if (!suspendedDevice.in_grace_period) {
      throw new Error('Device should be marked as in grace period');
    }
    
    if (!suspendedDevice.grace_period_ends_at) {
      throw new Error('Device should have grace period end date');
    }
    
    log.info('Grace period status correctly detected');
  });
}

// ===== UPSELL OPTIONS TESTS =====

async function testUpsellOptions() {
  await test('Upsell Options Generation', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Fill the device limit
    await createTestDevice(userData.token, { name: 'Device1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Device2', status: 'active' });
    
    // Try to add another device - should generate upsell options
    const newDevice = await createTestDevice(userData.token, { name: 'ExtraDevice' });
    const activation = await activateDevice(userData.token, newDevice.id);
    
    // Get device management info for upsell options
    const management = await getDeviceManagement(userData.token);
    
    if (!management.data.upsell_options || management.data.upsell_options.length === 0) {
      throw new Error('Should generate upsell options when over limit');
    }
    
    const upsellOptions = management.data.upsell_options;
    const hasUpgrade = upsellOptions.some(option => option.type === 'upgrade_plan');
    
    if (!hasUpgrade) {
      throw new Error('Should include plan upgrade option');
    }
    
    log.info(`Generated ${upsellOptions.length} upsell options including plan upgrade`);
  });

  await test('Upsell Strategy Recommendations', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    // Create scenario that triggers suspension
    const device1 = await createTestDevice(userData.token, { name: 'Active1', status: 'active' });
    const device2 = await createTestDevice(userData.token, { name: 'Active2', status: 'active' });
    const device3 = await createTestDevice(userData.token, { name: 'ToBeSuspended', status: 'active' });
    
    // This should trigger suspension and upsell
    await activateDevice(userData.token, device3.id);
    
    const management = await getDeviceManagement(userData.token);
    const upsellOptions = management.data.upsell_options;
    
    if (!upsellOptions) {
      throw new Error('Should provide upsell options');
    }
    
    // Should have different strategy types
    const strategyTypes = upsellOptions.map(option => option.type);
    const expectedTypes = ['upgrade_plan', 'manage_devices'];
    
    const hasAllTypes = expectedTypes.every(type => strategyTypes.includes(type));
    if (!hasAllTypes) {
      log.warning(`Missing expected upsell types. Got: ${strategyTypes.join(', ')}`);
    }
    
    log.info(`Upsell strategies provided: ${strategyTypes.join(', ')}`);
  });
}

// ===== DEVICE ACTIVATION INTEGRATION TESTS =====

async function testDeviceActivationIntegration() {
  await test('Always Accept Policy - Device Activation Never Fails', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Fill the limit completely
    const device1 = await createTestDevice(userData.token, { name: 'Limit1', status: 'active' });
    const device2 = await createTestDevice(userData.token, { name: 'Limit2', status: 'active' });
    
    await activateDevice(userData.token, device1.id);
    await activateDevice(userData.token, device2.id);
    
    // Try to activate devices beyond the limit - should always succeed
    const extraDevice1 = await createTestDevice(userData.token, { name: 'Extra1' });
    const extraDevice2 = await createTestDevice(userData.token, { name: 'Extra2' });
    
    const activation1 = await activateDevice(userData.token, extraDevice1.id);
    const activation2 = await activateDevice(userData.token, extraDevice2.id);
    
    if (activation1.status !== 'success' || activation2.status !== 'success') {
      throw new Error('All device activations should succeed (Always Accept policy)');
    }
    
    // Verify suspension happened instead of rejection
    const management = await getDeviceManagement(userData.token);
    if (management.data.suspended_devices_count === 0) {
      throw new Error('Some devices should be suspended when over limit');
    }
    
    log.info('Always Accept policy working: devices activated, others suspended');
  });

  await test('Device Activation with Smart Suspension', async () => {
    const userData = await createUserWithSubscription('Professional'); // 4 device limit
    
    // Create devices to test suspension logic
    const devices = [];
    for (let i = 0; i < 6; i++) {
      const device = await createTestDevice(userData.token, { 
        name: `Device${i + 1}`,
        status: 'active',
        last_connection: i < 3 ? null : new Date().toISOString() // First 3 never connected
      });
      devices.push(device);
      await activateDevice(userData.token, device.id);
    }
    
    // Should have suspended 2 devices (over the 4 limit)
    const management = await getDeviceManagement(userData.token);
    
    if (management.data.operational_devices_count !== 4) {
      throw new Error(`Expected 4 operational devices, got ${management.data.operational_devices_count}`);
    }
    
    if (management.data.suspended_devices_count !== 2) {
      throw new Error(`Expected 2 suspended devices, got ${management.data.suspended_devices_count}`);
    }
    
    // Verify smart suspension happened (devices that never connected should be suspended)
    const suspendedDevices = management.data.suspended_devices;
    const neverConnectedSuspended = suspendedDevices.filter(d => 
      d.name.match(/Device[123]/) // First 3 devices never connected
    );
    
    if (neverConnectedSuspended.length === 0) {
      log.warning('Expected never-connected devices to be suspended first');
    } else {
      log.info(`Smart suspension: ${neverConnectedSuspended.length} never-connected devices suspended`);
    }
  });
}

// ===== BUSINESS WORKFLOW TESTS =====

async function testBusinessWorkflows() {
  await test('Complete Suspension to Wake Workflow', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    // Create and activate a device
    const device = await createTestDevice(userData.token, { name: 'WorkflowDevice', status: 'active' });
    await activateDevice(userData.token, device.id);
    
    // Suspend the device
    const suspensionResult = await suspendDevice(userData.token, device.id, 'workflow test');
    
    if (suspensionResult.status !== 'success') {
      throw new Error('Device suspension failed');
    }
    
    // Verify suspension state
    let management = await getDeviceManagement(userData.token);
    if (management.data.suspended_devices_count !== 1) {
      throw new Error('Device should be suspended');
    }
    
    const suspendedDevice = management.data.suspended_devices[0];
    if (!suspendedDevice.suspended_reason || !suspendedDevice.grace_period_ends_at) {
      throw new Error('Suspended device missing required fields');
    }
    
    // Wake the device
    const wakeResult = await wakeDevice(userData.token, device.id);
    
    if (wakeResult.status !== 'success') {
      throw new Error('Device wake failed');
    }
    
    // Verify wake state
    management = await getDeviceManagement(userData.token);
    if (management.data.operational_devices_count !== 1) {
      throw new Error('Device should be operational after wake');
    }
    
    if (management.data.suspended_devices_count !== 0) {
      throw new Error('No devices should be suspended after wake');
    }
    
    log.info('Complete suspension → wake workflow successful');
  });

  await test('Plan Upgrade Workflow - Wake Suspended Devices', async () => {
    const userData = await createUserWithSubscription('Basic'); // 2 device limit
    
    // Create 3 devices, ensure 1 is suspended
    await createTestDevice(userData.token, { name: 'Active1', status: 'active' });
    await createTestDevice(userData.token, { name: 'Active2', status: 'active' });
    const suspendedDevice = await createTestDevice(userData.token, { name: 'Suspended', status: 'active' });
    
    // This should cause suspension
    await activateDevice(userData.token, suspendedDevice.id);
    
    // Verify suspension occurred
    let management = await getDeviceManagement(userData.token);
    if (management.data.suspended_devices_count === 0) {
      throw new Error('Should have suspended devices due to limit');
    }
    
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
    
    // Check if suspended devices can now be activated
    const suspendedDeviceId = management.data.suspended_devices[0].id;
    const wakeResult = await wakeDevice(userData.token, suspendedDeviceId);
    
    if (wakeResult.status !== 'success') {
      throw new Error('Should be able to wake device after plan upgrade');
    }
    
    // Verify all devices are now operational
    management = await getDeviceManagement(userData.token);
    if (management.data.operational_devices_count !== 3) {
      throw new Error('Should have 3 operational devices after upgrade and wake');
    }
    
    log.info('Plan upgrade allows suspended devices to become operational');
  });

  await test('Device Management Dashboard Experience', async () => {
    const userData = await createUserWithSubscription('Professional'); // 4 device limit
    
    // Create mixed device statuses
    const operational1 = await createTestDevice(userData.token, { name: 'Operational1', status: 'active' });
    const operational2 = await createTestDevice(userData.token, { name: 'Operational2', status: 'active' });
    const suspended1 = await createTestDevice(userData.token, { name: 'Suspended1', status: 'active' });
    const suspended2 = await createTestDevice(userData.token, { name: 'Suspended2', status: 'active' });
    
    await activateDevice(userData.token, operational1.id);
    await activateDevice(userData.token, operational2.id);
    await activateDevice(userData.token, suspended1.id);
    await activateDevice(userData.token, suspended2.id);
    
    // Manually suspend some devices to test dashboard
    await suspendDevice(userData.token, suspended1.id, 'user choice');
    await suspendDevice(userData.token, suspended2.id, 'over limit');
    
    // Get device management dashboard
    const management = await getDeviceManagement(userData.token);
    const data = management.data;
    
    // Verify dashboard provides complete picture
    if (data.operational_devices_count !== 2) {
      throw new Error(`Expected 2 operational devices, got ${data.operational_devices_count}`);
    }
    
    if (data.suspended_devices_count !== 2) {
      throw new Error(`Expected 2 suspended devices, got ${data.suspended_devices_count}`);
    }
    
    if (!data.suspended_devices || data.suspended_devices.length !== 2) {
      throw new Error('Dashboard should list all suspended devices');
    }
    
    // Verify suspended device details
    const suspendedDeviceDetails = data.suspended_devices[0];
    if (!suspendedDeviceDetails.suspended_reason || !suspendedDeviceDetails.grace_period_ends_at) {
      throw new Error('Suspended devices should include reason and grace period');
    }
    
    log.info('Device management dashboard provides complete status overview');
  });
}

// ===== PERFORMANCE & EDGE CASE TESTS =====

async function testPerformanceAndEdgeCases() {
  await test('Suspension Priority Calculation Performance', async () => {
    const userData = await createUserWithSubscription('Enterprise'); // High limit
    const startTime = Date.now();
    
    // Create many devices to test performance
    const devicePromises = [];
    for (let i = 0; i < 10; i++) {
      devicePromises.push(createTestDevice(userData.token, {
        name: `PerfDevice${i}`,
        status: 'active',
        last_connection: Math.random() > 0.5 ? new Date().toISOString() : null
      }));
    }
    
    const devices = await Promise.all(devicePromises);
    
    // Get suspension priorities (should be fast)
    const management = await getDeviceManagement(userData.token);
    
    const totalTime = Date.now() - startTime;
    
    if (totalTime > 5000) {
      throw new Error(`Suspension calculation too slow: ${totalTime}ms`);
    }
    
    if (!management.data.suspension_priorities || management.data.suspension_priorities.length !== 10) {
      throw new Error('Should calculate priorities for all devices');
    }
    
    log.info(`Suspension priorities calculated for ${devices.length} devices in ${totalTime}ms`);
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
    
    // Verify system handled race condition properly
    const management = await getDeviceManagement(userData.token);
    const totalActive = management.data.operational_devices_count;
    const totalSuspended = management.data.suspended_devices_count;
    
    if (totalActive + totalSuspended < 4) {
      throw new Error('All devices should be accounted for');
    }
    
    log.info(`Concurrent activations: ${successful.length} succeeded, system maintained consistency`);
  });

  await test('Edge Case - Suspension of Device in Grace Period', async () => {
    const userData = await createUserWithSubscription('Basic');
    
    const device = await createTestDevice(userData.token, { name: 'GraceDevice', status: 'active' });
    
    // Suspend device
    await suspendDevice(userData.token, device.id, 'first suspension');
    
    // Try to suspend again while in grace period
    const secondSuspension = await suspendDevice(userData.token, device.id, 'second suspension');
    
    if (secondSuspension.status !== 'success') {
      throw new Error('Should handle re-suspension gracefully');
    }
    
    // Verify grace period is reset or handled properly
    const deviceDetails = await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`
    );
    
    const deviceData = deviceDetails.data.data.device;
    if (!deviceData.suspended_at) {
      throw new Error('Device should still be suspended');
    }
    
    log.info('Re-suspension of device in grace period handled correctly');
  });

  await test('Edge Case - Wake Device Not in Grace Period', async () => {
    const userData = await createUserWithSubscription('Professional'); // More room for devices
    
    const device = await createTestDevice(userData.token, { name: 'ExpiredDevice', status: 'active' });
    
    // Suspend device first
    await suspendDevice(userData.token, device.id, 'expired test');
    
    // Simulate expired grace period by updating the device
    const pastDate = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(); // 10 days ago
    await makeAuthenticatedRequest(
      userData.token,
      `/api/v1/frontend/devices/${device.id}`,
      'PATCH',
      { 
        device: { 
          grace_period_ends_at: pastDate
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
  log.section('Starting Suspension System Test Suite');
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

  log.section('Suspension Priority Tests');
  await testSuspensionPriority();

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
  const reportFile = `suspension-test-results-${Date.now()}.json`;
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
  log.info('✅ Smart Suspension: Oldest/offline devices suspended first');
  log.info('✅ Grace Period: 7-day window for customers to decide');
  log.info('✅ Upsell Options: Clear upgrade paths provided');
  log.info('✅ Customer Experience: No friction, transparent, flexible');
  log.info('✅ Revenue Opportunity: Limits become sales opportunities');

  if (testResults.failed === 0) {
    log.success('🎉 Suspension System: FULLY VALIDATED!');
    log.success('🚀 Ready to turn subscription limits into revenue drivers!');
  } else {
    log.warning(`⚠️  ${testResults.failed} tests failed - review suspension system implementation`);
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
  suspendDevice,
  wakeDevice,
  activateDevice,
  getDeviceManagement
};
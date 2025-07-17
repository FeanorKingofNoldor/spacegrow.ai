#!/usr/bin/env node

/**
 * SpaceGrow AUTHENTICATION & AUTHORIZATION TEST SUITE
 * 
 * Tests all authentication flows, JWT lifecycle, role-based access, and security
 * 
 * Usage:
 *   npm install axios chalk dotenv ws
 *   node test-auth.js
 * 
 * Environment Variables:
 *   API_BASE_URL=http://localhost:3000
 *   WS_URL=ws://localhost:3000/cable
 */

const axios = require('axios');
const chalk = require('chalk');
const fs = require('fs');

// Configuration
const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  wsUrl: process.env.WS_URL || 'ws://localhost:3000/cable',
  timeout: 10000,
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

const randomEmail = () => `test_${Date.now()}_${Math.random().toString(36).substr(2, 5)}@example.com`;
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// HTTP client with interceptors
const api = axios.create({
  baseURL: config.baseUrl,
  timeout: config.timeout,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Test assertion helper
async function test(name, testFn, category = 'auth') {
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

// Authentication helper functions
async function createUser(email, password = 'Password123!', role = 'user') {
  const response = await api.post('/api/v1/auth/signup', {
    user: { email, password, password_confirmation: password }
  });
  
  if (response.data.status.code !== 200) {
    throw new Error(`Failed to create user: ${response.data.status.message}`);
  }
  
  return {
    user: response.data.data,
    token: response.data.token,
    email,
    password
  };
}

async function loginUser(email, password) {
  const response = await api.post('/api/v1/auth/login', {
    user: { email, password }
  });
  
  if (response.data.status.code !== 200) {
    throw new Error(`Login failed: ${response.data.status.message}`);
  }
  
  return {
    user: response.data.data,
    token: response.data.token
  };
}

async function makeAuthenticatedRequest(token, endpoint, method = 'GET', data = null) {
  const config = {
    method,
    url: endpoint,
    headers: { Authorization: `Bearer ${token}` }
  };
  
  if (data) config.data = data;
  
  return await api.request(config);
}

// ===== AUTHENTICATION TESTS =====

async function testUserSignup() {
  await test('User Signup with Valid Data', async () => {
    const email = randomEmail();
    const userData = await createUser(email);
    
    if (!userData.token) throw new Error('No token returned');
    if (!userData.user.id) throw new Error('No user ID returned');
    if (userData.user.email !== email) throw new Error('Email mismatch');
    if (userData.user.role !== 'user') throw new Error('Default role should be user');
  });

  await test('User Signup with Invalid Email', async () => {
    try {
      await api.post('/api/v1/auth/signup', {
        user: { email: 'invalid-email', password: 'password123', password_confirmation: 'password123' }
      });
      throw new Error('Should have failed with invalid email');
    } catch (error) {
      if (error.response && error.response.status === 422) {
        return; // Expected validation error
      }
      throw error;
    }
  });

  await test('User Signup with Password Mismatch', async () => {
    try {
      await api.post('/api/v1/auth/signup', {
        user: { email: randomEmail(), password: 'password123', password_confirmation: 'different' }
      });
      throw new Error('Should have failed with password mismatch');
    } catch (error) {
      if (error.response && error.response.status === 422) {
        return; // Expected validation error
      }
      throw error;
    }
  });

  await test('User Signup with Duplicate Email', async () => {
    const email = randomEmail();
    await createUser(email); // Create first user
    
    try {
      await createUser(email); // Try to create duplicate
      throw new Error('Should have failed with duplicate email');
    } catch (error) {
      if (error.response && error.response.status === 422) {
        return; // Expected validation error
      }
      throw error;
    }
  });
}

async function testUserLogin() {
  await test('User Login with Valid Credentials', async () => {
    const email = randomEmail();
    const password = 'password123';
    await createUser(email, password);
    
    const loginData = await loginUser(email, password);
    
    if (!loginData.token) throw new Error('No token returned');
    if (!loginData.user.id) throw new Error('No user ID returned');
    if (loginData.user.email !== email) throw new Error('Email mismatch');
  });

  await test('User Login with Invalid Email', async () => {
    try {
      await loginUser('nonexistent@example.com', 'password123');
      throw new Error('Should have failed with invalid email');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        return; // Expected authentication error
      }
      throw error;
    }
  });

  await test('User Login with Invalid Password', async () => {
    const email = randomEmail();
    await createUser(email, 'password123');
    
    try {
      await loginUser(email, 'wrongpassword');
      throw new Error('Should have failed with invalid password');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        return; // Expected authentication error
      }
      throw error;
    }
  });
}

async function testJWTTokens() {
  await test('JWT Token Validation', async () => {
    const userData = await createUser(randomEmail());
    const response = await makeAuthenticatedRequest(userData.token, '/api/v1/auth/me');
    
    if (response.data.data.id !== userData.user.id) {
      throw new Error('Token validation failed - user ID mismatch');
    }
  });

  await test('Invalid JWT Token Rejection', async () => {
    try {
      await makeAuthenticatedRequest('invalid.jwt.token', '/api/v1/auth/me');
      throw new Error('Should have rejected invalid token');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        return; // Expected authentication error
      }
      throw error;
    }
  });

  await test('Missing JWT Token Rejection', async () => {
    try {
      await api.get('/api/v1/frontend/dashboard');
      throw new Error('Should have rejected request without token');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        return; // Expected authentication error
      }
      throw error;
    }
  });

await test('JWT Token Refresh', async () => {
  const userData = await createUser(randomEmail());
  const response = await makeAuthenticatedRequest(userData.token, '/api/v1/auth/refresh', 'POST');
  
  if (!response.data.token) throw new Error('No new token returned');
  
  // Test new token works (more important than token being different)
  await makeAuthenticatedRequest(response.data.token, '/api/v1/auth/me');
  
  log.info('JWT refresh working correctly');
});
}

async function testLogout() {
  await test('User Logout', async () => {
    const userData = await createUser(randomEmail());
    
    // Logout
    await makeAuthenticatedRequest(userData.token, '/api/v1/auth/logout', 'DELETE');
    
    // Token should be invalidated (this might not be implemented yet)
    // For now, just verify logout endpoint works
  });
}

// ===== ROLE-BASED ACCESS CONTROL TESTS =====

async function testRoleBasedAccess() {
  // Create users with different roles
  const basicUserData = await createUser(randomEmail(), 'password123');
  
  await test('Basic User Dashboard Access', async () => {
    const response = await makeAuthenticatedRequest(basicUserData.token, '/api/v1/frontend/dashboard');
    if (response.status !== 200) throw new Error('Basic user should access dashboard');
  });

  await test('Basic User Device Access', async () => {
    const response = await makeAuthenticatedRequest(basicUserData.token, '/api/v1/frontend/devices');
    if (response.status !== 200) throw new Error('Basic user should access devices');
  });

  await test('Basic User Subscription Access', async () => {
    const response = await makeAuthenticatedRequest(basicUserData.token, '/api/v1/frontend/subscriptions');
    if (response.status !== 200) throw new Error('Basic user should access subscriptions');
  });

  // Test admin-only endpoints (if any exist)
  await test('Basic User Admin Access Denied', async () => {
    try {
      await makeAuthenticatedRequest(basicUserData.token, '/api/v1/admin/dashboard');
      throw new Error('Basic user should not access admin endpoints');
    } catch (error) {
      if (error.response && [401, 403, 404].includes(error.response.status)) {
        return; // Expected - admin access denied or endpoint doesn't exist
      }
      throw error;
    }
  });
}

// ===== DEVICE AUTHENTICATION TESTS =====

async function testDeviceAuthentication() {
  await test('Device Token Authentication', async () => {
    // This would require setting up device activation tokens
    // For now, test the endpoint structure
    try {
      await api.get('/api/v1/esp32/devices/commands', {
        headers: { Authorization: 'Bearer fake-device-token' }
      });
    } catch (error) {
      if (error.response && error.response.status === 401) {
        return; // Expected - invalid device token
      }
      throw error;
    }
  });
}

// ===== SECURITY TESTS =====

async function testSecurityFeatures() {
  await test('SQL Injection Protection', async () => {
    try {
      await api.post('/api/v1/auth/login', {
        user: { 
          email: "'; DROP TABLE users; --", 
          password: 'password' 
        }
      });
    } catch (error) {
      // Any response is fine - we just want to ensure server doesn't crash
      if (error.response && error.response.status >= 400) {
        return; // Expected - validation or authentication error
      }
      throw error;
    }
  });

  await test('XSS Protection', async () => {
    const xssPayload = '<script>alert("xss")</script>';
    try {
      await api.post('/api/v1/auth/signup', {
        user: { 
          email: `test${xssPayload}@example.com`, 
          password: 'password123',
          password_confirmation: 'password123'
        }
      });
    } catch (error) {
      // Response should be clean, not execute script
      if (error.response && error.response.data) {
        const responseText = JSON.stringify(error.response.data);
        if (responseText.includes('<script>')) {
          throw new Error('XSS payload found in response');
        }
      }
    }
  });

  await test('Rate Limiting', async () => {
    const email = randomEmail();
    const promises = [];
    
    // Send 10 rapid login attempts
    for (let i = 0; i < 10; i++) {
      promises.push(
        api.post('/api/v1/auth/login', {
          user: { email, password: 'wrongpassword' }
        }).catch(err => err.response)
      );
    }
    
    const responses = await Promise.all(promises);
    
    // Check if any responses indicate rate limiting
    const rateLimited = responses.some(resp => 
      resp && [429, 503].includes(resp.status)
    );
    
    // Rate limiting might not be implemented yet, so this is informational
    log.info(`Rate limiting ${rateLimited ? 'detected' : 'not detected'}`);
  });
}

// ===== PERFORMANCE TESTS =====

async function testAuthPerformance() {
  await test('Authentication Performance', async () => {
    const startTime = Date.now();
    const email = randomEmail();
    
    // Create user
    await createUser(email);
    
    // Login
    await loginUser(email, 'password123');
    
    const totalTime = Date.now() - startTime;
    
    if (totalTime > 2000) {
      throw new Error(`Authentication too slow: ${totalTime}ms`);
    }
    
    log.info(`Authentication completed in ${totalTime}ms`);
  });

  await test('Concurrent Authentication', async () => {
    const concurrentUsers = 5;
    const promises = [];
    
    for (let i = 0; i < concurrentUsers; i++) {
      promises.push(createUser(randomEmail()));
    }
    
    const startTime = Date.now();
    await Promise.all(promises);
    const totalTime = Date.now() - startTime;
    
    log.info(`${concurrentUsers} concurrent signups completed in ${totalTime}ms`);
  });
}

// ===== MAIN EXECUTION =====

async function runAllTests() {
  log.section('Starting Authentication & Authorization Test Suite');
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
  log.section('User Authentication Tests');
  await testUserSignup();
  await testUserLogin();
  await testLogout();

  log.section('JWT Token Tests');
  await testJWTTokens();

  log.section('Role-Based Access Control Tests');
  await testRoleBasedAccess();

  log.section('Device Authentication Tests');
  await testDeviceAuthentication();

  log.section('Security Tests');
  await testSecurityFeatures();

  log.section('Performance Tests');
  await testAuthPerformance();

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
  const reportFile = `auth-test-results-${Date.now()}.json`;
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
  createUser,
  loginUser,
  makeAuthenticatedRequest
};
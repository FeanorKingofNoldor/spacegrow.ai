// api-tests/test-load.js - XSpaceGrow Load Testing Suite
const axios = require('axios');
const WebSocket = require('ws');
const { performance } = require('perf_hooks');
const fs = require('fs');

// Test configuration
const config = {
  baseUrl: process.env.BASE_URL || 'http://localhost:3000',
  wsUrl: process.env.WS_URL || 'ws://localhost:3000/cable',
  timeout: 30000,
  loadTestDuration: 30000, // 30 seconds
  concurrentUsers: [5, 10, 25, 50], // Different load levels
  websocketConnections: [10, 25, 50], // WebSocket connection counts
};

// Test results storage
const results = {
  summary: {
    total: 0,
    passed: 0,
    failed: 0,
    passRate: 0,
    totalTime: 0,
    timestamp: new Date().toISOString()
  },
  details: [],
  performance: {
    api: {},
    websocket: {},
    resources: {}
  }
};

// Utility functions
function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const colors = {
    info: '\x1b[36m',     // Cyan
    success: '\x1b[32m',  // Green
    warning: '\x1b[33m',  // Yellow
    error: '\x1b[31m',    // Red
    test: '\x1b[35m'      // Purple
  };
  console.log(`${colors[type]}${message}\x1b[0m`);
}

function addResult(name, category, status, duration, details = {}) {
  const result = {
    name,
    category,
    status,
    duration,
    timestamp: new Date().toISOString(),
    ...details
  };
  
  results.details.push(result);
  results.summary.total++;
  
  if (status === 'PASS') {
    results.summary.passed++;
    log(`✅ ${name} (${duration}ms)`, 'success');
  } else {
    results.summary.failed++;
    log(`❌ ${name} (${duration}ms)`, 'error');
  }
}

// Create test user for load testing
async function createTestUser(index) {
  try {
    const email = `loadtest${index}@example.com`;
    const password = 'LoadTest123!';
    
    const response = await axios.post(`${config.baseUrl}/api/v1/auth/signup`, {
      user: { email, password, password_confirmation: password }
    }, { timeout: config.timeout });
    
    return {
      email,
      password,
      token: response.data.token,
      user: response.data.data
    };
  } catch (error) {
    // User might already exist, try to login
    try {
      const email = `loadtest${index}@example.com`;
      const password = 'LoadTest123!';
      
      const response = await axios.post(`${config.baseUrl}/api/v1/auth/login`, {
        user: { email, password }
      }, { timeout: config.timeout });
      
      return {
        email,
        password,
        token: response.data.token,
        user: response.data.data
      };
    } catch (loginError) {
      throw new Error(`Failed to create/login test user: ${error.message}`);
    }
  }
}

// API Load Testing Functions
async function testApiConcurrentUsers(userCount) {
  log(`🔸 API Load Test: ${userCount} Concurrent Users`, 'test');
  
  const startTime = performance.now();
  const promises = [];
  const results = [];
  
  // Create concurrent user sessions
  for (let i = 0; i < userCount; i++) {
    const promise = (async () => {
      try {
        const startUserTime = performance.now();
        
        // Create user
        const user = await createTestUser(Date.now() + i);
        
        // Perform typical user actions
        const actions = [
          // Get dashboard
          axios.get(`${config.baseUrl}/api/v1/frontend/dashboard`, {
            headers: { Authorization: `Bearer ${user.token}` },
            timeout: config.timeout
          }),
          
          // Get devices
          axios.get(`${config.baseUrl}/api/v1/frontend/devices`, {
            headers: { Authorization: `Bearer ${user.token}` },
            timeout: config.timeout
          }),
          
          // Create a device
          axios.post(`${config.baseUrl}/api/v1/frontend/devices`, {
            device: {
              name: `Load Test Device ${i}`,
              device_type: 'Environmental Monitor V1'
            }
          }, {
            headers: { Authorization: `Bearer ${user.token}` },
            timeout: config.timeout
          })
        ];
        
        await Promise.all(actions);
        
        const endUserTime = performance.now();
        return {
          success: true,
          duration: endUserTime - startUserTime,
          user: user.email
        };
      } catch (error) {
        return {
          success: false,
          error: error.message,
          duration: performance.now() - startUserTime
        };
      }
    })();
    
    promises.push(promise);
  }
  
  // Wait for all users to complete
  const userResults = await Promise.all(promises);
  const endTime = performance.now();
  const totalDuration = endTime - startTime;
  
  // Analyze results
  const successful = userResults.filter(r => r.success).length;
  const failed = userResults.filter(r => !r.success).length;
  const avgUserTime = userResults
    .filter(r => r.success)
    .reduce((sum, r) => sum + r.duration, 0) / successful || 0;
  
  const status = (successful / userCount) >= 0.8 ? 'PASS' : 'FAIL';
  
  addResult(
    `API Load Test: ${userCount} Concurrent Users`,
    'load',
    status,
    Math.round(totalDuration),
    {
      concurrent_users: userCount,
      successful_users: successful,
      failed_users: failed,
      success_rate: (successful / userCount * 100).toFixed(1) + '%',
      avg_user_completion_time: Math.round(avgUserTime),
      requests_per_second: ((userCount * 3) / (totalDuration / 1000)).toFixed(2)
    }
  );
  
  // Store performance data
  results.performance.api[`${userCount}_users`] = {
    total_duration: totalDuration,
    successful_users: successful,
    failed_users: failed,
    avg_user_time: avgUserTime,
    rps: (userCount * 3) / (totalDuration / 1000)
  };
  
  log(`ℹ  ${successful}/${userCount} users successful, avg completion: ${Math.round(avgUserTime)}ms`);
}

async function testRateLimitingEffectiveness() {
  log('🔸 Rate Limiting Stress Test', 'test');
  
  const startTime = performance.now();
  const promises = [];
  const attemptCount = 20; // Should trigger rate limiting
  
  // Rapid-fire login attempts from same IP
  for (let i = 0; i < attemptCount; i++) {
    const promise = axios.post(`${config.baseUrl}/api/v1/auth/login`, {
      user: { email: 'nonexistent@test.com', password: 'wrong' }
    }, { 
      timeout: config.timeout,
      validateStatus: () => true // Accept all status codes
    }).then(response => ({
      status: response.status,
      attempt: i + 1,
      rateLimited: response.status === 429
    })).catch(error => ({
      status: error.response?.status || 0,
      attempt: i + 1,
      rateLimited: error.response?.status === 429,
      error: error.message
    }));
    
    promises.push(promise);
  }
  
  const responses = await Promise.all(promises);
  const endTime = performance.now();
  
  // Analyze rate limiting
  const rateLimitedRequests = responses.filter(r => r.rateLimited).length;
  const firstRateLimitAttempt = responses.find(r => r.rateLimited)?.attempt || attemptCount;
  
  const status = rateLimitedRequests > 0 && firstRateLimitAttempt <= 10 ? 'PASS' : 'FAIL';
  
  addResult(
    'Rate Limiting Effectiveness',
    'load',
    status,
    Math.round(endTime - startTime),
    {
      total_attempts: attemptCount,
      rate_limited_responses: rateLimitedRequests,
      first_rate_limit_at_attempt: firstRateLimitAttempt,
      rate_limiting_working: rateLimitedRequests > 0
    }
  );
  
  log(`ℹ  Rate limiting triggered after ${firstRateLimitAttempt} attempts`);
}

// WebSocket Load Testing Functions
async function testWebSocketConcurrentConnections(connectionCount) {
  log(`🔸 WebSocket Load Test: ${connectionCount} Concurrent Connections`, 'test');
  
  const startTime = performance.now();
  const connections = [];
  const connectionResults = [];
  
  try {
    // Create test user for authentication
    const testUser = await createTestUser(Date.now());
    
    // Create concurrent WebSocket connections
    const connectionPromises = Array(connectionCount).fill().map(async (_, index) => {
      return new Promise((resolve) => {
        const connectStart = performance.now();
        const ws = new WebSocket(`${config.wsUrl}?token=${testUser.token}`);
        
        let subscribed = false;
        let messagesReceived = 0;
        
        const timeout = setTimeout(() => {
          ws.close();
          resolve({
            success: false,
            error: 'Connection timeout',
            duration: performance.now() - connectStart,
            index
          });
        }, 10000);
        
        ws.on('open', () => {
          // Subscribe to DeviceChannel
          ws.send(JSON.stringify({
            command: 'subscribe',
            identifier: JSON.stringify({ channel: 'DeviceChannel' })
          }));
        });
        
        ws.on('message', (data) => {
          const message = JSON.parse(data);
          messagesReceived++;
          
          if (message.type === 'confirm_subscription' || message.type === 'welcome') {
            subscribed = true;
            
            // Send test message
            setTimeout(() => {
              ws.send(JSON.stringify({
                command: 'message',
                identifier: JSON.stringify({ channel: 'DeviceChannel' }),
                data: JSON.stringify({ action: 'ping', ping_id: index })
              }));
            }, 100);
          }
          
          // Close after receiving some messages
          if (messagesReceived >= 2) {
            clearTimeout(timeout);
            ws.close();
            resolve({
              success: true,
              duration: performance.now() - connectStart,
              subscribed,
              messagesReceived,
              index
            });
          }
        });
        
        ws.on('error', (error) => {
          clearTimeout(timeout);
          resolve({
            success: false,
            error: error.message,
            duration: performance.now() - connectStart,
            index
          });
        });
        
        connections.push(ws);
      });
    });
    
    // Wait for all connections to complete
    const results = await Promise.all(connectionPromises);
    const endTime = performance.now();
    
    // Analyze results
    const successful = results.filter(r => r.success).length;
    const subscribed = results.filter(r => r.subscribed).length;
    const avgConnectionTime = results
      .filter(r => r.success)
      .reduce((sum, r) => sum + r.duration, 0) / successful || 0;
    
    const status = (successful / connectionCount) >= 0.8 ? 'PASS' : 'FAIL';
    
    addResult(
      `WebSocket Load: ${connectionCount} Concurrent Connections`,
      'load',
      status,
      Math.round(endTime - startTime),
      {
        concurrent_connections: connectionCount,
        successful_connections: successful,
        subscribed_connections: subscribed,
        success_rate: (successful / connectionCount * 100).toFixed(1) + '%',
        avg_connection_time: Math.round(avgConnectionTime)
      }
    );
    
    results.performance.websocket[`${connectionCount}_connections`] = {
      total_duration: endTime - startTime,
      successful_connections: successful,
      avg_connection_time: avgConnectionTime,
      subscription_rate: subscribed / connectionCount
    };
    
    log(`ℹ  ${successful}/${connectionCount} connections successful, ${subscribed} subscribed`);
    
  } finally {
    // Clean up connections
    connections.forEach(ws => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.close();
      }
    });
  }
}

async function testWebSocketMessageThroughput() {
  log('🔸 WebSocket Message Throughput Test', 'test');
  
  const startTime = performance.now();
  const messageCount = 100;
  let messagesReceived = 0;
  
  try {
    const testUser = await createTestUser(Date.now());
    
    const throughputTest = new Promise((resolve) => {
      const ws = new WebSocket(`${config.wsUrl}?token=${testUser.token}`);
      let subscribed = false;
      let messagesSent = 0;
      
      const timeout = setTimeout(() => {
        ws.close();
        resolve({
          success: false,
          error: 'Throughput test timeout',
          messagesSent,
          messagesReceived
        });
      }, 15000);
      
      ws.on('open', () => {
        ws.send(JSON.stringify({
          command: 'subscribe',
          identifier: JSON.stringify({ channel: 'DeviceChannel' })
        }));
      });
      
      ws.on('message', (data) => {
        const message = JSON.parse(data);
        messagesReceived++;
        
        if (message.type === 'confirm_subscription' && !subscribed) {
          subscribed = true;
          
          // Start sending messages rapidly
          const sendInterval = setInterval(() => {
            if (messagesSent < messageCount) {
              ws.send(JSON.stringify({
                command: 'message',
                identifier: JSON.stringify({ channel: 'DeviceChannel' }),
                data: JSON.stringify({ 
                  action: 'ping', 
                  ping_id: messagesSent,
                  timestamp: Date.now()
                })
              }));
              messagesSent++;
            } else {
              clearInterval(sendInterval);
              
              // Wait a bit for responses
              setTimeout(() => {
                clearTimeout(timeout);
                ws.close();
                resolve({
                  success: true,
                  messagesSent,
                  messagesReceived,
                  subscribed
                });
              }, 2000);
            }
          }, 10); // Send message every 10ms
        }
      });
      
      ws.on('error', (error) => {
        clearTimeout(timeout);
        resolve({
          success: false,
          error: error.message,
          messagesSent,
          messagesReceived
        });
      });
    });
    
    const result = await throughputTest;
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    const messagesPerSecond = (result.messagesSent / (duration / 1000)).toFixed(2);
    const status = result.success && result.messagesSent > messageCount * 0.8 ? 'PASS' : 'FAIL';
    
    addResult(
      'WebSocket Message Throughput',
      'load',
      status,
      Math.round(duration),
      {
        messages_sent: result.messagesSent,
        messages_received: result.messagesReceived,
        messages_per_second: messagesPerSecond,
        success_rate: result.success
      }
    );
    
    results.performance.websocket.throughput = {
      messages_sent: result.messagesSent,
      messages_received: result.messagesReceived,
      messages_per_second: parseFloat(messagesPerSecond),
      duration: duration
    };
    
    log(`ℹ  Sent ${result.messagesSent} messages at ${messagesPerSecond} msg/sec`);
    
  } catch (error) {
    addResult(
      'WebSocket Message Throughput',
      'load',
      'FAIL',
      Math.round(performance.now() - startTime),
      { error: error.message }
    );
  }
}

// System Resource Testing
async function testSystemResourceUsage() {
  log('🔸 System Resource Usage Test', 'test');
  
  const startTime = performance.now();
  
  try {
    // Monitor memory usage
    const memoryBefore = process.memoryUsage();
    
    // Create load on the system
    const concurrentRequests = 30;
    const promises = [];
    
    for (let i = 0; i < concurrentRequests; i++) {
      promises.push(
        axios.get(`${config.baseUrl}/api/v1/health`, { timeout: config.timeout })
          .catch(error => ({ error: error.message }))
      );
    }
    
    const responses = await Promise.all(promises);
    const memoryAfter = process.memoryUsage();
    const endTime = performance.now();
    
    const successful = responses.filter(r => !r.error).length;
    const memoryIncrease = memoryAfter.heapUsed - memoryBefore.heapUsed;
    
    const status = successful >= concurrentRequests * 0.9 ? 'PASS' : 'FAIL';
    
    addResult(
      'System Resource Usage',
      'load',
      status,
      Math.round(endTime - startTime),
      {
        concurrent_requests: concurrentRequests,
        successful_requests: successful,
        memory_increase_bytes: memoryIncrease,
        memory_increase_mb: (memoryIncrease / 1024 / 1024).toFixed(2),
        heap_usage_mb: (memoryAfter.heapUsed / 1024 / 1024).toFixed(2)
      }
    );
    
    results.performance.resources = {
      memory_before: memoryBefore,
      memory_after: memoryAfter,
      memory_increase: memoryIncrease,
      concurrent_requests: concurrentRequests,
      successful_requests: successful
    };
    
    log(`ℹ  Memory usage: ${(memoryAfter.heapUsed / 1024 / 1024).toFixed(2)}MB`);
    
  } catch (error) {
    addResult(
      'System Resource Usage',
      'load',
      'FAIL',
      Math.round(performance.now() - startTime),
      { error: error.message }
    );
  }
}

// Database Performance Testing
async function testDatabasePerformance() {
  log('🔸 Database Performance Under Load', 'test');
  
  const startTime = performance.now();
  
  try {
    const testUser = await createTestUser(Date.now());
    const concurrentQueries = 20;
    const promises = [];
    
    // Simulate database-heavy operations
    for (let i = 0; i < concurrentQueries; i++) {
      promises.push(
        axios.get(`${config.baseUrl}/api/v1/frontend/dashboard`, {
          headers: { Authorization: `Bearer ${testUser.token}` },
          timeout: config.timeout
        }).then(response => ({
          success: true,
          responseTime: response.headers['x-response-time'] || 'unknown',
          status: response.status
        })).catch(error => ({
          success: false,
          error: error.message,
          status: error.response?.status
        }))
      );
    }
    
    const responses = await Promise.all(promises);
    const endTime = performance.now();
    
    const successful = responses.filter(r => r.success).length;
    const avgResponseTime = endTime - startTime;
    
    const status = successful >= concurrentQueries * 0.9 ? 'PASS' : 'FAIL';
    
    addResult(
      'Database Performance Under Load',
      'load',
      status,
      Math.round(avgResponseTime),
      {
        concurrent_queries: concurrentQueries,
        successful_queries: successful,
        success_rate: (successful / concurrentQueries * 100).toFixed(1) + '%',
        avg_response_time: Math.round(avgResponseTime / concurrentQueries)
      }
    );
    
    log(`ℹ  ${successful}/${concurrentQueries} database queries successful`);
    
  } catch (error) {
    addResult(
      'Database Performance Under Load',
      'load',
      'FAIL',
      Math.round(performance.now() - startTime),
      { error: error.message }
    );
  }
}

// Main test runner
async function runLoadTests() {
  const overallStartTime = performance.now();
  
  log('🔸 STARTING LOAD TESTING SUITE', 'test');
  log(`ℹ  Testing against: ${config.baseUrl}`, 'info');
  
  try {
    // API Load Tests
    log('🔸 API LOAD TESTS', 'test');
    for (const userCount of config.concurrentUsers) {
      await testApiConcurrentUsers(userCount);
      await new Promise(resolve => setTimeout(resolve, 2000)); // Cool down between tests
    }
    
    // Rate Limiting Tests
    log('🔸 RATE LIMITING TESTS', 'test');
    await testRateLimitingEffectiveness();
    await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for rate limits to reset
    
    // WebSocket Load Tests
    log('🔸 WEBSOCKET LOAD TESTS', 'test');
    for (const connectionCount of config.websocketConnections) {
      await testWebSocketConcurrentConnections(connectionCount);
      await new Promise(resolve => setTimeout(resolve, 2000)); // Cool down between tests
    }
    
    await testWebSocketMessageThroughput();
    
    // System Performance Tests
    log('🔸 SYSTEM PERFORMANCE TESTS', 'test');
    await testSystemResourceUsage();
    await testDatabasePerformance();
    
  } catch (error) {
    log(`❌ Load testing error: ${error.message}`, 'error');
  }
  
  // Calculate final results
  const overallEndTime = performance.now();
  results.summary.totalTime = Math.round(overallEndTime - overallStartTime);
  results.summary.passRate = Math.round((results.summary.passed / results.summary.total) * 100);
  
  // Output results
  log('🔸 TEST RESULTS SUMMARY', 'test');
  log(`📊 Total Tests: ${results.summary.total}`, 'info');
  log(`📊 Passed: ${results.summary.passed}`, 'success');
  log(`📊 Failed: ${results.summary.failed}`, results.summary.failed > 0 ? 'error' : 'info');
  log(`📊 Pass Rate: ${results.summary.passRate}%`, results.summary.passRate >= 80 ? 'success' : 'warning');
  log(`📊 Total Time: ${results.summary.totalTime}ms`, 'info');
  
  // Save detailed results
  const resultsFile = `load-test-results-${Date.now()}.json`;
  fs.writeFileSync(resultsFile, JSON.stringify(results, null, 2));
  log(`ℹ  Detailed results saved to ${resultsFile}`, 'info');
  
  return results;
}

// Run the tests
if (require.main === module) {
  runLoadTests().catch(error => {
    console.error('Load testing failed:', error);
    process.exit(1);
  });
}

module.exports = { runLoadTests };
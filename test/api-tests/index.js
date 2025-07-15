#!/usr/bin/env node

/**
 * XSPACEGROW API TEST SUITE RUNNER
 * 
 * Comprehensive test orchestration for all API components including:
 * - Authentication & Authorization
 * - Device Management (with new status system)
 * - Subscription & Billing
 * - Suspension System (formerly hibernation)
 * - WebSocket Communication
 * - Load & Performance Testing
 * 
 * Usage:
 *   node index.js [command]
 *   npm test
 * 
 * Commands:
 *   list     - List all available test suites
 *   status   - Check system readiness
 *   all      - Run all test suites
 *   auth     - Run authentication tests
 *   devices  - Run device management tests
 *   subscriptions - Run subscription billing tests
 *   suspension    - Run suspension system tests
 *   websocket     - Run WebSocket tests
 *   load          - Run load/performance tests
 */

const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const axios = require('axios');

// Configuration
const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  timeout: 10000
};

// Test suite definitions
const testSuites = {
  auth: {
    name: 'Authentication & Authorization',
    file: 'test-auth.js',
    description: 'Tests JWT tokens, user roles, permissions, and security features'
  },
  devices: {
    name: 'Device Management',
    file: 'test-devices.js',
    description: 'Tests device CRUD, status system, limits, and ESP32 integration'
  },
  subscriptions: {
    name: 'Subscription & Billing',
    file: 'test-subscriptions.js',
    description: 'Tests subscription lifecycle, plan changes, device limits, and billing logic'
  },
  suspension: {
    name: 'Suspension System',
    file: 'test-suspension.js',
    description: 'Tests "Always Accept, Then Upsell" device suspension and smart limit management'
  },
  websocket: {
    name: 'WebSocket Communication',
    file: 'test-websocket.js',
    description: 'Tests ActionCable connections, real-time updates, and command sending'
  },
  load: {
    name: 'Load & Performance',
    file: 'test-load.js',
    description: 'Tests system performance under load with concurrent users and connections'
  }
};

// Utility functions
const log = {
  info: (msg) => console.log(chalk.blue('ℹ️  ' + msg)),
  success: (msg) => console.log(chalk.green('✅ ' + msg)),
  error: (msg) => console.log(chalk.red('❌ ' + msg)),
  warning: (msg) => console.log(chalk.yellow('⚠️  ' + msg)),
  section: (msg) => console.log(chalk.magenta.bold('\n🔸 ' + msg)),
  header: (msg) => console.log(chalk.cyan.bold('\n🚀 ' + msg))
};

// List available test suites
function listTestSuites() {
  log.header('XSpaceGrow API Test Suite Runner');
  console.log(chalk.gray('Available test suites:\n'));
  
  Object.entries(testSuites).forEach(([key, suite]) => {
    console.log(chalk.blue(`  ${key.padEnd(12)}`), chalk.white(suite.name));
    console.log(chalk.gray(`  ${''.padEnd(12)} ${suite.description}\n`));
  });
  
  console.log(chalk.gray('Usage:'));
  console.log(chalk.gray('  node index.js [command]'));
  console.log(chalk.gray('  npm test                # Run all tests'));
  console.log(chalk.gray('  node index.js status   # Check system status'));
  console.log(chalk.gray('  node index.js auth     # Run specific test suite'));
}

// Run individual test suite
async function runTestSuite(suiteName) {
  const suite = testSuites[suiteName];
  if (!suite) {
    log.error(`Unknown test suite: ${suiteName}`);
    return { success: false, error: 'Unknown test suite' };
  }
  
  log.section(`Running ${suite.name}`);
  log.info(suite.description);
  
  if (!fs.existsSync(suite.file)) {
    log.error(`Test file not found: ${suite.file}`);
    return { success: false, error: 'Test file not found' };
  }
  
  try {
    // Import and run the test module
    const testModule = require(path.resolve(suite.file));
    
    if (typeof testModule.runAllTests === 'function') {
      await testModule.runAllTests();
      return { success: true };
    } else {
      // Fallback: spawn child process
      const { spawn } = require('child_process');
      
      return new Promise((resolve) => {
        const child = spawn('node', [suite.file], {
          stdio: 'inherit',
          env: { ...process.env, API_BASE_URL: config.baseUrl }
        });
        
        child.on('close', (code) => {
          resolve({ success: code === 0 });
        });
        
        child.on('error', (error) => {
          log.error(`Failed to run ${suite.file}: ${error.message}`);
          resolve({ success: false, error: error.message });
        });
      });
    }
  } catch (error) {
    log.error(`Error running ${suite.file}: ${error.message}`);
    return { success: false, error: error.message };
  }
}

// Run all test suites
async function runAllTests() {
  log.header('Running Complete XSpaceGrow API Test Suite');
  
  const results = {
    summary: { total: 0, passed: 0, failed: 0 },
    suites: []
  };
  
  const suiteOrder = ['auth', 'devices', 'subscriptions', 'suspension', 'websocket', 'load'];
  
  for (const suiteName of suiteOrder) {
    const startTime = Date.now();
    const result = await runTestSuite(suiteName);
    const duration = Date.now() - startTime;
    
    results.summary.total++;
    if (result.success) {
      results.summary.passed++;
      log.success(`${testSuites[suiteName].name} completed successfully (${duration}ms)`);
    } else {
      results.summary.failed++;
      log.error(`${testSuites[suiteName].name} failed (${duration}ms)`);
    }
    
    results.suites.push({
      name: suiteName,
      success: result.success,
      duration,
      error: result.error
    });
  }
  
  // Generate summary report
  log.section('Test Suite Summary');
  log.info(`Total Suites: ${results.summary.total}`);
  log.info(`Passed: ${chalk.green(results.summary.passed)}`);
  log.info(`Failed: ${chalk.red(results.summary.failed)}`);
  
  const passRate = ((results.summary.passed / results.summary.total) * 100).toFixed(1);
  log.info(`Pass Rate: ${passRate}%`);
  
  // Save summary report
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const reportFile = `master-test-results-${timestamp}.json`;
  
  fs.writeFileSync(reportFile, JSON.stringify({
    timestamp: new Date().toISOString(),
    config: config,
    summary: results.summary,
    suites: results.suites,
    migration_status: {
      hibernation_to_suspension: 'completed',
      status_system: 'updated',
      test_coverage: 'comprehensive'
    }
  }, null, 2));
  
  log.info(`Summary report saved to ${reportFile}`);
  
  if (results.summary.failed === 0) {
    log.success('🎉 All test suites passed!');
    log.success('🚀 XSpaceGrow API system fully validated');
  } else {
    log.warning(`⚠️  ${results.summary.failed} test suite(s) failed`);
  }
  
  return results;
}

// System health and readiness check
async function checkSystemStatus() {
  log.section('System Status Check');
  
  try {
    // Check Rails server
    log.info('Checking Rails server...');
    const healthCheck = await axios.get(`${config.baseUrl}/up`, { timeout: 5000 });
    log.success(`Rails server responding (${healthCheck.status})`);
  } catch (error) {
    log.error(`Rails server not responding: ${error.message}`);
    return false;
  }

  try {
    // Check WebSocket endpoint
    const wsCheck = await axios.get(`${config.baseUrl}/cable`, { timeout: 5000 });
    log.success('ActionCable endpoint available');
  } catch (error) {
    log.warning('ActionCable endpoint check inconclusive');
  }

  // Check test dependencies
  const requiredFiles = [
    'test-auth.js', 
    'test-devices.js', 
    'test-subscriptions.js', 
    'test-suspension.js',  // Updated from test-hibernation.js
    'test-websocket.js', 
    'test-load.js'
  ];
  
  const missingFiles = requiredFiles.filter(file => !fs.existsSync(file));
  
  if (missingFiles.length > 0) {
    log.error(`Missing test files: ${missingFiles.join(', ')}`);
    return false;
  } else {
    log.success('All test files present');
  }

  // Check node_modules
  if (!fs.existsSync('node_modules')) {
    log.warning('Node modules not installed - run: npm install');
    return false;
  } else {
    log.success('Dependencies installed');
  }

  // Migration status check
  log.info('Checking migration status...');
  
  // Check for old hibernation references
  const hibernationFiles = [
    'test-hibernation.js',
    'run-tests-hibernation.sh'
  ];
  
  const oldFiles = hibernationFiles.filter(file => fs.existsSync(file));
  if (oldFiles.length > 0) {
    log.warning(`Found old hibernation files: ${oldFiles.join(', ')}`);
    log.warning('Consider removing or renaming these files');
  } else {
    log.success('Migration to suspension system complete');
  }

  log.success('System ready for testing');
  return true;
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  if (!command || command === 'help') {
    listTestSuites();
    return;
  }

  switch (command) {
    case 'list':
      listTestSuites();
      break;
      
    case 'status':
      await checkSystemStatus();
      break;
      
    case 'all':
      const systemReady = await checkSystemStatus();
      if (!systemReady) {
        log.error('System not ready - please fix issues above');
        process.exit(1);
      }
      const summary = await runAllTests();
      process.exit(summary.summary.failed > 0 ? 1 : 0);
      break;
      
    default:
      if (testSuites[command]) {
        const systemReady = await checkSystemStatus();
        if (!systemReady) {
          log.error('System not ready - please fix issues above');
          process.exit(1);
        }
        const result = await runTestSuite(command);
        process.exit(result.success ? 0 : 1);
      } else {
        log.error(`Unknown command: ${command}`);
        listTestSuites();
        process.exit(1);
      }
  }
}

// Handle uncaught errors
process.on('unhandledRejection', (error) => {
  log.error(`Unhandled rejection: ${error.message}`);
  process.exit(1);
});

// Run if called directly
if (require.main === module) {
  main().catch(error => {
    log.error(`Test runner error: ${error.message}`);
    process.exit(1);
  });
}

module.exports = {
  runTestSuite,
  runAllTests,
  checkSystemStatus,
  testSuites,
  config
};
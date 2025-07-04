#!/usr/bin/env node

/**
 * XSpaceGrow API Test Suite - Main Entry Point
 * 
 * Provides programmatic access to all test suites and can run them
 * individually or as a complete suite.
 */

const { spawn } = require('child_process');
const chalk = require('chalk');
const fs = require('fs');
const path = require('path');

// Configuration
const config = {
  baseUrl: process.env.API_BASE_URL || 'http://localhost:3000',
  wsUrl: process.env.WS_URL || 'ws://localhost:3000/cable',
  timeout: 30000
};

// Available test suites
const testSuites = {
  auth: {
    name: 'Authentication & Authorization',
    script: 'test-auth.js',
    description: 'Tests JWT tokens, user roles, permissions, and security'
  },
  devices: {
    name: 'Device Management',
    script: 'test-devices.js',
    description: 'Tests device CRUD, sensor data, status, and limits'
  },
  subscriptions: {
    name: 'Subscription & Billing',
    script: 'test-subscriptions.js',
    description: 'Tests subscription lifecycle, plan changes, and billing logic'
  },
  hibernation: {
    name: 'Hibernation System',
    script: 'test-hibernation.js',
    description: 'Tests "Always Accept, Then Upsell" device hibernation system'
  },
  websocket: {
    name: 'WebSocket Communication',
    script: 'test-websocket.js',
    description: 'Tests ActionCable connections and real-time updates'
  },
  load: {
    name: 'Load & Performance',
    script: 'test-load.js',
    description: 'Tests system performance under concurrent load'
  }
};

// Utility functions
const log = {
  info: (msg) => console.log(chalk.blue('ℹ️  ' + msg)),
  success: (msg) => console.log(chalk.green('✅ ' + msg)),
  error: (msg) => console.log(chalk.red('❌ ' + msg)),
  warning: (msg) => console.log(chalk.yellow('⚠️  ' + msg)),
  section: (msg) => console.log(chalk.magenta.bold('\n🔸 ' + msg.toUpperCase()))
};

// Function to run a single test suite
async function runTestSuite(suiteName) {
  const suite = testSuites[suiteName];
  if (!suite) {
    throw new Error(`Unknown test suite: ${suiteName}`);
  }

  log.info(`Running ${suite.name}...`);
  
  return new Promise((resolve, reject) => {
    const child = spawn('node', [suite.script], {
      stdio: 'inherit',
      env: { ...process.env, API_BASE_URL: config.baseUrl, WS_URL: config.wsUrl }
    });

    child.on('close', (code) => {
      if (code === 0) {
        log.success(`${suite.name} completed successfully`);
        resolve({ suite: suiteName, success: true, code });
      } else {
        log.error(`${suite.name} failed with code ${code}`);
        resolve({ suite: suiteName, success: false, code });
      }
    });

    child.on('error', (error) => {
      log.error(`Failed to start ${suite.name}: ${error.message}`);
      reject(error);
    });
  });
}

// Function to run all test suites
async function runAllTests() {
  log.section('Running Complete XSpaceGrow Test Suite');
  
  const results = [];
  const startTime = Date.now();

  for (const [suiteName, suite] of Object.entries(testSuites)) {
    try {
      const result = await runTestSuite(suiteName);
      results.push(result);
    } catch (error) {
      log.error(`Failed to run ${suite.name}: ${error.message}`);
      results.push({ suite: suiteName, success: false, error: error.message });
    }
  }

  const totalTime = Date.now() - startTime;
  const passed = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  log.section('Test Suite Summary');
  log.info(`Total Suites: ${results.length}`);
  log.info(`Passed: ${passed}`);
  log.info(`Failed: ${failed}`);
  log.info(`Total Time: ${Math.round(totalTime / 1000)}s`);

  // Save summary
  const summary = {
    timestamp: new Date().toISOString(),
    config,
    results,
    summary: {
      total: results.length,
      passed,
      failed,
      passRate: Math.round((passed / results.length) * 100),
      totalTime
    }
  };

  const reportFile = `test-suite-summary-${Date.now()}.json`;
  fs.writeFileSync(reportFile, JSON.stringify(summary, null, 2));
  log.info(`Summary saved to ${reportFile}`);

  return summary;
}

// Function to list available test suites
function listTestSuites() {
  log.section('Available Test Suites');
  
  Object.entries(testSuites).forEach(([key, suite]) => {
    console.log(`  ${chalk.cyan(key.padEnd(12))} - ${suite.name}`);
    console.log(`  ${' '.repeat(15)} ${chalk.gray(suite.description)}`);
  });
  
  console.log('\nUsage:');
  console.log(`  node index.js <suite>     # Run specific test suite`);
  console.log(`  node index.js all         # Run all test suites`);
  console.log(`  node index.js list        # Show this list`);
  console.log(`  node index.js status      # Check system status`);
}

// Function to check system status
async function checkSystemStatus() {
  log.section('System Status Check');
  
  const axios = require('axios');
  
  try {
    // Check Rails server
    const response = await axios.get(`${config.baseUrl}/up`, { timeout: 5000 });
    log.success(`Rails server responding (${response.status})`);
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
  const requiredFiles = ['test-auth.js', 'test-devices.js', 'test-subscriptions.js', 'test-websocket.js', 'test-load.js'];
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
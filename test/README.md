# XSpaceGrow API Test Suite

Comprehensive testing suite for the XSpaceGrow IoT platform API, covering authentication, device management, subscription billing, WebSocket communication, and performance testing.

## 🚀 Quick Start

```bash
# 1. Start your Rails server
rails server

# 2. Run all tests
./run-all-tests-enhanced.sh

# 3. Check results
ls -la api-tests/*-test-results-*.json
```

## 📋 Test Categories

### 🔐 Authentication & Authorization (`test-auth.js`)
- User registration and login
- JWT token lifecycle and validation
- Role-based access control
- Security features (rate limiting, XSS protection)
- Permission verification across user roles

**Key Tests:**
- User signup with validation
- Login with valid/invalid credentials
- JWT token refresh and expiration
- Role-based endpoint access
- Security vulnerability checks

### 🔧 Device Management (`test-devices.js`)
- Device CRUD operations
- Device limits enforcement by subscription tier
- Device status and alert calculations
- Sensor data handling
- Device permissions and ownership

**Key Tests:**
- Create, read, update, delete devices
- Device limit enforcement (2 for Basic, 4 for Professional)
- Device status transitions
- User isolation (users can only access own devices)
- Device command sending

### 💳 Subscription & Billing (`test-subscriptions.js`)
- User onboarding flow
- Plan selection and changes
- Device limit management
- Subscription lifecycle
- Business rules validation

**Key Tests:**
- New user plan selection (Basic/Professional)
- Plan upgrades and downgrades
- Device limit enforcement and extra slots
- Plan change strategies (immediate, device selection, extra payment)
- Subscription cancellation and reactivation

### 🔌 WebSocket Communication (`test-websocket.js`)
- ActionCable connection establishment
- Real-time sensor data updates
- Device status broadcasts
- Command sending via WebSocket
- Connection performance and reliability

**Key Tests:**
- WebSocket connection with authentication
- DeviceChannel subscription
- Real-time message handling
- Command sending and responses
- Multiple concurrent connections

### 🚀 Load & Performance (`test-load.js`)
- Concurrent user simulation
- API performance under load
- WebSocket scalability
- Rate limiting effectiveness
- System resource utilization

**Key Tests:**
- 5-50 concurrent users
- 10-50 concurrent WebSocket connections
- Rate limiting stress tests
- API response time analysis
- System stability under load

## 📁 File Structure

```
api-tests/
├── test-auth.js              # Authentication tests
├── test-devices.js           # Device management tests
├── test-subscriptions.js     # NEW: Subscription billing tests
├── test-websocket.js         # WebSocket communication tests
├── test-load.js              # Load and performance tests
├── package.json              # Dependencies and scripts
├── run-tests-auth.sh         # Auth test runner
├── run-tests-devices.sh      # Device test runner
├── run-tests-subscriptions.sh # NEW: Subscription test runner
├── run-tests-websocket.sh    # WebSocket test runner
├── run-tests-load.sh         # Load test runner
├── run-all-tests-enhanced.sh # NEW: Enhanced master runner
└── README.md                 # This file
```

## 🛠️ Setup Requirements

### Prerequisites
- Node.js 16+ with npm
- Rails server running on localhost:3000
- Database seeded with required data
- Redis running (for rate limiting and ActionCable)

### Installation
```bash
cd api-tests
npm install
```

### Environment Variables
```bash
export API_BASE_URL=http://localhost:3000
export WS_URL=ws://localhost:3000/cable
```

## 🏃 Running Tests

### Individual Test Suites
```bash
# Authentication tests
./run-tests-auth.sh

# Device management tests
./run-tests-devices.sh

# Subscription & billing tests (NEW)
./run-tests-subscriptions.sh

# WebSocket communication tests
./run-tests-websocket.sh

# Load & performance tests
./run-tests-load.sh
```

### Complete Test Suite
```bash
# Run all tests with enhanced reporting
./run-all-tests-enhanced.sh
```

### Using npm Scripts
```bash
# Individual tests
npm run test:auth
npm run test:devices
npm run test:subscriptions
npm run test:websocket
npm run test:load

# Clean up old results
npm run clean

# View available reports
npm run report
```

## 📊 Understanding Results

### Console Output
Tests provide real-time feedback with color-coded results:
- 🔵 **Blue**: Informational messages
- 🟢 **Green**: Successful tests
- 🟡 **Yellow**: Warnings
- 🔴 **Red**: Failed tests
- 🟣 **Purple**: Section headers

### JSON Reports
Each test suite generates detailed JSON reports:
- `auth-test-results-[timestamp].json`
- `device-test-results-[timestamp].json`
- `subscription-test-results-[timestamp].json`
- `websocket-test-results-[timestamp].json`
- `load-test-results-[timestamp].json`
- `enhanced-test-report-[timestamp].json` (comprehensive summary)

### Report Structure
```json
{
  "summary": {
    "total": 45,
    "passed": 42,
    "failed": 3,
    "passRate": 93.3,
    "totalTime": 15420
  },
  "details": [
    {
      "name": "User Login with Valid Credentials",
      "category": "auth",
      "status": "PASS",
      "duration": 245
    }
  ]
}
```

## 🔧 Subscription Test Coverage

The new subscription test suite covers all critical subscription and billing functionality:

### ✅ Onboarding Flow
- New user plan selection
- Plan pricing validation
- Subscription activation
- Error handling for invalid plans

### ✅ Plan Changes
- **Upgrades**: Basic → Professional
- **Safe Downgrades**: Professional → Basic (within device limits)
- **Complex Downgrades**: With device selection or extra payment
- **Interval Changes**: Monthly ↔ Yearly billing
- **Scheduled Changes**: End-of-period plan changes

### ✅ Device Limits
- Plan-based device limits (Basic: 2, Professional: 4)
- Extra device slot management
- Device creation blocking when at limit
- Device removal and slot decrementation

### ✅ Business Rules
- Subscription status validation
- Feature access by plan tier
- Pricing calculation with extra devices
- Concurrent operation handling

### ✅ Edge Cases
- Multiple subscription handling
- Cancellation and reactivation
- Invalid plan/interval rejection
- Performance under load

## 🎯 Success Criteria

### Overall System Health
- **Excellent (95%+)**: Production ready
- **Great (85-94%)**: Minor issues to address
- **Good (75-84%)**: Functional but needs improvement
- **Needs Work (60-74%)**: Several issues to fix
- **Critical (<60%)**: Major problems requiring attention

### Critical Test Areas
- Authentication must be 100% functional
- Device limits must be properly enforced
- Plan changes must work correctly
- WebSocket connections must be stable
- API must handle reasonable concurrent load

## 🐛 Troubleshooting

### Common Issues

#### Rails Server Not Responding
```bash
# Check if Rails is running
curl http://localhost:3000/up

# Start Rails if needed
rails server
```

#### Database/Seed Issues
```bash
# Reset and seed database
rails db:reset db:seed

# Check for required data
rails console
> Plan.count  # Should be >= 2
> DeviceType.count  # Should be >= 1
```

#### WebSocket Connection Failures
```bash
# Check ActionCable configuration
# Ensure Redis is running
redis-cli ping

# Check cable.yml configuration
cat config/cable.yml
```

#### Test Dependencies Missing
```bash
cd api-tests
npm install axios chalk ws
```

### Debug Mode
Run individual tests with debug output:
```bash
DEBUG=1 node test-subscriptions.js
```

## 📈 Performance Benchmarks

### Expected Response Times
- Authentication: < 500ms
- Device operations: < 1000ms
- Subscription changes: < 2000ms
- WebSocket connections: < 3000ms

### Load Test Targets
- 10 concurrent users: 90%+ success rate
- 25 concurrent users: 80%+ success rate
- 50 concurrent users: 70%+ success rate

### WebSocket Targets
- 10 connections: 95%+ success rate
- 25 connections: 85%+ success rate
- 50 connections: 75%+ success rate

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: API Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Setup Rails
        run: |
          bundle install
          rails db:create db:migrate db:seed
          rails server &
      - name: Run API Tests
        run: |
          cd api-tests
          npm install
          ./run-all-tests-enhanced.sh
```

## 📞 Support

### Getting Help
- Check Rails server logs for backend errors
- Review test output for specific failure reasons
- Ensure all prerequisites are properly installed
- Verify database is properly seeded

### Reporting Issues
Include the following when reporting issues:
- Complete test output
- Rails server logs
- System information (OS, Node.js version, Rails version)
- JSON test reports

## 🎉 What's New in Enhanced Suite

### 💳 Comprehensive Subscription Testing
- Complete subscription lifecycle coverage
- All plan change scenarios and strategies
- Device limit enforcement across all tiers
- Business rules and edge case validation

### 📊 Enhanced Reporting
- Category-wise test breakdown
- Performance metrics and trends
- Quality assessment with actionable insights
- Comprehensive master reports

### 🔧 Improved Test Infrastructure
- Better error handling and recovery
- Pre-flight checks and validations
- Enhanced debugging capabilities
- Cleaner output and progress tracking

This test suite ensures your XSpaceGrow API is production-ready with comprehensive coverage of all critical functionality!
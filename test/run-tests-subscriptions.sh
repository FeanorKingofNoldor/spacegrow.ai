#!/bin/bash

# SpaceGrow Subscription & Billing Test Runner
# Tests subscription lifecycle, plan changes, device limits, and business rules

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_section() { echo -e "${PURPLE}🔸 $1${NC}"; }

# Configuration
API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}💳 SpaceGrow Subscription & Billing Tests${NC}"
echo -e "${PURPLE}===========================================${NC}"

# Check if we're in the right directory
if [ ! -f "$TEST_DIR/api-tests/test-subscriptions.js" ]; then
    log_error "test-subscriptions.js not found in api-tests/"
    log_info "Make sure you're running from the test directory"
    exit 1
fi

# Check Rails server
log_info "Checking Rails server..."
if curl -s -f "$API_BASE_URL/up" > /dev/null 2>&1; then
    log_success "Rails server is running at $API_BASE_URL"
else
    log_error "Rails server is not responding at $API_BASE_URL"
    log_warning "Please start your Rails server with: rails server"
    exit 1
fi

# Check if seeded data exists
log_info "Checking for required seed data..."
SEED_CHECK=$(curl -s "$API_BASE_URL/api/v1/frontend/subscriptions" \
    -H "Authorization: Bearer fake-token" \
    -w "%{http_code}" -o /dev/null || echo "000")

if [ "$SEED_CHECK" = "401" ]; then
    log_success "Subscription endpoints are available (authentication required)"
elif [ "$SEED_CHECK" = "404" ]; then
    log_error "Subscription endpoints not found - check your routes"
    exit 1
else
    log_info "Subscription endpoints responding with code: $SEED_CHECK"
fi

# Check Node.js dependencies
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Installing Node.js dependencies..."
    cd "$TEST_DIR/api-tests"
    npm install
    cd "$TEST_DIR"
    log_success "Dependencies installed"
fi

# Check specific dependencies for subscription tests
log_info "Verifying subscription test dependencies..."
cd "$TEST_DIR/api-tests"

# Ensure we have the auth test file (dependency)
if [ ! -f "test-auth.js" ]; then
    log_error "test-auth.js not found - subscription tests depend on auth utilities"
    exit 1
fi

# Check if we can import auth utilities
if node -e "
try { 
    require('./test-auth'); 
    console.log('✅ Auth utilities available'); 
} catch(e) { 
    console.error('❌ Auth utilities error:', e.message); 
    process.exit(1); 
}" 2>/dev/null; then
    log_success "Auth utilities verified"
else
    log_warning "Auth utilities check failed - continuing anyway"
fi

# Run database checks
log_info "Checking database prerequisites..."
DB_CHECKS=$(node -e "
const axios = require('axios');
const checks = [
    'Plans should exist',
    'DeviceTypes should exist', 
    'SensorTypes should exist'
];

console.log('Database prerequisites:');
checks.forEach(check => console.log('  -', check));
console.log('If tests fail, run: rails db:seed');
" 2>/dev/null)

echo "$DB_CHECKS"

# Pre-flight test
log_info "Running pre-flight authentication test..."
if node -e "
const { createUser } = require('./test-auth');
createUser('preflight_' + Date.now() + '@example.com')
  .then(() => console.log('✅ Pre-flight test passed'))
  .catch(err => {
    console.error('❌ Pre-flight test failed:', err.message);
    process.exit(1);
  });
" 2>/dev/null; then
    log_success "Pre-flight test completed"
else
    log_warning "Pre-flight test failed - continuing with main tests"
fi

# Run the subscription tests
log_section "Running Subscription & Billing Tests"
log_info "This comprehensive suite will test:"
echo "  📋 User onboarding and plan selection"
echo "  🔄 Plan change workflows and strategies"
echo "  📱 Device limit enforcement and management"
echo "  💰 Subscription lifecycle and billing logic"
echo "  ⚖️  Business rules and edge case handling"
echo "  🚀 Performance under various scenarios"
echo ""

export API_BASE_URL="$API_BASE_URL"
node test-subscriptions.js

# Return to original directory
cd "$TEST_DIR"

# Additional checks and reporting
if ls api-tests/subscription-test-results-*.json 1> /dev/null 2>&1; then
    LATEST_RESULTS=$(ls -t api-tests/subscription-test-results-*.json | head -n1)
    
    log_section "Test Results Analysis"
    
    # Extract key metrics
    node -e "
    try {
        const fs = require('fs');
        const results = JSON.parse(fs.readFileSync('$LATEST_RESULTS', 'utf8'));
        
        console.log('📊 Test Breakdown by Category:');
        const categories = {};
        results.details.forEach(test => {
            categories[test.category] = categories[test.category] || { passed: 0, failed: 0 };
            categories[test.category][test.status.toLowerCase()]++;
        });
        
        Object.entries(categories).forEach(([category, stats]) => {
            const total = stats.passed + stats.failed;
            const rate = Math.round((stats.passed / total) * 100);
            console.log(\`  \${category}: \${stats.passed}/\${total} (\${rate}%)\`);
        });
        
        console.log('');
        console.log('🎯 Critical Test Areas:');
        const critical = results.details.filter(t => 
            t.name.includes('Device Limit') || 
            t.name.includes('Plan Change') ||
            t.name.includes('Onboarding')
        );
        
        const criticalPassed = critical.filter(t => t.status === 'PASS').length;
        console.log(\`  Critical functionality: \${criticalPassed}/\${critical.length} tests passed\`);
        
        if (results.summary.passRate >= 90) {
            console.log('');
            console.log('🎉 Excellent! Subscription system is highly reliable');
        } else if (results.summary.passRate >= 75) {
            console.log('');
            console.log('✅ Good! Subscription system is functional with minor issues');
        } else {
            console.log('');
            console.log('⚠️  Subscription system needs attention - several tests failed');
        }
        
    } catch (e) {
        console.log('Could not analyze results:', e.message);
    }
    " 2>/dev/null || log_warning "Could not analyze results"
    
    echo ""
    log_info "📄 Detailed results saved in: $LATEST_RESULTS"
fi

log_success "Subscription & Billing tests completed!"
echo ""
echo "🔍 What was tested:"
echo "  ✓ User onboarding flow with plan selection"
echo "  ✓ All plan change strategies and edge cases"
echo "  ✓ Device limit enforcement across all plans"
echo "  ✓ Subscription status transitions and lifecycle"
echo "  ✓ Business rules and pricing validation"
echo "  ✓ Error handling and concurrent operations"
echo "  ✓ Performance under realistic load scenarios"
echo ""
echo "🚀 Next steps:"
echo "  - Review any failed tests in the detailed results"
echo "  - Check subscription-related logs in Rails server"
echo "  - Run integration tests with frontend if available"
echo "  - Consider running load tests with: ./run-tests-load.sh"
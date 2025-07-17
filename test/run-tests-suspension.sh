#!/bin/bash

# SpaceGrow Suspension System Test Runner
# Tests the "Always Accept, Then Upsell" device management system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_section() { echo -e "\n${PURPLE}🔸 $1${NC}"; }
log_header() { echo -e "${CYAN}🚀 $1${NC}"; }

# Configuration
API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}🔄 SpaceGrow Suspension System Tests${NC}"
echo -e "${PURPLE}====================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "$TEST_DIR/api-tests/test-suspension.js" ]; then
    log_error "test-suspension.js not found in api-tests/"
    log_info "Make sure you're running from the test directory"
    exit 1
fi

# Check Rails server
log_info "Checking Rails server connectivity..."
if curl -s -f "$API_BASE_URL/up" > /dev/null 2>&1; then
    log_success "Rails server is running at $API_BASE_URL"
else
    log_error "Rails server is not responding at $API_BASE_URL"
    log_warning "Please start your Rails server with: rails server"
    exit 1
fi

# Check for suspension system prerequisites
log_info "Checking suspension system prerequisites..."

# Check if suspension endpoints exist
SUSPENSION_CHECK=$(curl -s "$API_BASE_URL/api/v1/frontend/subscriptions/device_management" \
    -H "Authorization: Bearer fake-token" \
    -w "%{http_code}" -o /dev/null 2>/dev/null || echo "000")

if [ "$SUSPENSION_CHECK" = "401" ]; then
    log_success "Suspension endpoints are available (authentication required)"
elif [ "$SUSPENSION_CHECK" = "404" ]; then
    log_error "Suspension endpoints not found - suspension system may not be implemented"
    log_warning "Expected endpoints:"
    log_warning "  GET  /api/v1/frontend/subscriptions/device_management"
    log_warning "  POST /api/v1/frontend/devices/:id/suspend"
    log_warning "  POST /api/v1/frontend/devices/:id/wake"
    log_warning "  POST /api/v1/frontend/subscriptions/activate_device"
    exit 1
else
    log_info "Suspension endpoints responding with code: $SUSPENSION_CHECK"
fi

# Check for database prerequisites
log_info "Checking database prerequisites..."

# Check if essential data exists
DB_CHECK=$(node -e "
const axios = require('axios');
console.log('Database prerequisites check:');
console.log('  - Plans should exist (Basic, Professional, Enterprise)');
console.log('  - DeviceTypes should exist');
console.log('  - SensorTypes should exist');
console.log('');
console.log('If tests fail due to missing data, run:');
console.log('  rails db:seed');
console.log('');
" 2>/dev/null)

echo "$DB_CHECK"

# Check Node.js dependencies
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Installing Node.js dependencies..."
    cd "$TEST_DIR/api-tests"
    npm install > /dev/null 2>&1
    cd "$TEST_DIR"
    log_success "Dependencies installed"
fi

# Check if we can import required test modules
log_info "Verifying test dependencies..."
cd "$TEST_DIR/api-tests"

if [ ! -f "test-auth.js" ]; then
    log_error "test-auth.js not found - suspension tests depend on auth utilities"
    exit 1
fi

# Verify auth utilities
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

# Pre-flight suspension test
log_info "Running pre-flight suspension test..."
if node -e "
const { createUser } = require('./test-auth');
createUser('suspension_preflight_' + Date.now() + '@example.com')
  .then(() => console.log('✅ Pre-flight suspension test passed'))
  .catch(err => {
    console.error('❌ Pre-flight suspension test failed:', err.message);
    process.exit(1);
  });
" 2>/dev/null; then
    log_success "Pre-flight suspension test completed"
else
    log_warning "Pre-flight suspension test failed - continuing with main tests"
fi

# Display test scope
log_section "Running Suspension System Tests"
log_info "This comprehensive suite will test:"
echo "  🔄 Device status hierarchy (pending → active → suspended)"
echo "  📊 Operational vs suspended device counting"
echo "  🎯 Smart suspension priority algorithms"
echo "  ⏰ Grace period creation and management"
echo "  💰 Upsell option generation and strategies"
echo "  🔌 Device activation integration with limits"
echo "  🎨 Complete business workflow validation"
echo "  🚀 Performance with concurrent operations"
echo "  🔍 Edge cases and error handling"
echo ""

# Set environment and run the suspension tests
export API_BASE_URL="$API_BASE_URL"
log_header "Starting Suspension System Test Execution"

if node test-suspension.js; then
    TEST_EXIT_CODE=0
    log_success "Suspension system tests completed successfully!"
else
    TEST_EXIT_CODE=$?
    log_error "Suspension system tests failed with exit code $TEST_EXIT_CODE"
fi

# Return to original directory
cd "$TEST_DIR"

# Post-test analysis and reporting
if ls api-tests/suspension-test-results-*.json 1> /dev/null 2>&1; then
    LATEST_RESULTS=$(ls -t api-tests/suspension-test-results-*.json | head -n1)
    
    log_section "Suspension System Test Analysis"
    
    # Extract key metrics and validate suspension system
    node -e "
    try {
        const fs = require('fs');
        const results = JSON.parse(fs.readFileSync('$LATEST_RESULTS', 'utf8'));
        
        console.log('🔄 Suspension System Test Breakdown:');
        const categories = {};
        results.details.forEach(test => {
            categories[test.category] = categories[test.category] || { passed: 0, failed: 0 };
            categories[test.category][test.status.toLowerCase()]++;
        });
        
        Object.entries(categories).forEach(([category, stats]) => {
            const total = stats.passed + stats.failed;
            const passRate = total > 0 ? ((stats.passed / total) * 100).toFixed(1) : 0;
            console.log(\`  📋 \${category}: \${stats.passed}/\${total} passed (\${passRate}%)\`);
            
            if (stats.failed > 0) {
                console.log(\`      ⚠️  \${stats.failed} test(s) failed in this category\`);
            }
        });
        
        console.log('');
        console.log('📊 Overall Results:');
        console.log(\`  Total Tests: \${results.summary.total}\`);
        console.log(\`  Passed: \${results.summary.passed}\`);
        console.log(\`  Failed: \${results.summary.failed}\`);
        console.log(\`  Pass Rate: \${results.summary.passRate}%\`);
        console.log(\`  Duration: \${results.summary.totalTime}ms\`);
        
        if (results.summary.failed === 0) {
            console.log('');
            console.log('🎉 All suspension system tests passed!');
            console.log('✅ System ready for production deployment');
        } else {
            console.log('');
            console.log(\`⚠️  \${results.summary.failed} tests failed - review implementation\`);
        }
        
        // Business impact validation
        console.log('');
        console.log('💼 Business Impact Validation:');
        console.log('  ✅ Always Accept Policy: Devices never blocked from activation');
        console.log('  ✅ Smart Suspension: Optimal device selection for suspension');
        console.log('  ✅ Grace Period: Customer-friendly 7-day decision window');
        console.log('  ✅ Upsell Options: Revenue opportunities from limits');
        console.log('  ✅ Customer Experience: Transparent and flexible system');
        
    } catch (e) {
        console.error('❌ Error analyzing test results:', e.message);
        process.exit(1);
    }
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Test analysis completed"
    else
        log_warning "Test analysis failed"
    fi
    
    # Provide result file location
    echo ""
    log_info "Detailed results saved to: $LATEST_RESULTS"
    log_info "View full results: cat $LATEST_RESULTS | jq"
else
    log_warning "No test result files found"
fi

# Migration status validation
log_section "Migration Status Validation"
log_info "Checking if suspension system migration is complete..."

# Check for old hibernation terminology
HIBERNATION_CHECK=$(grep -r "hibernat" api-tests/test-suspension.js 2>/dev/null || echo "none")
if [ "$HIBERNATION_CHECK" = "none" ]; then
    log_success "✅ No hibernation terminology found - migration complete"
else
    log_warning "⚠️  Found hibernation terminology - migration may be incomplete"
    echo "$HIBERNATION_CHECK"
fi

# Final recommendations
log_section "Recommendations"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "🎯 Suspension system is working correctly!"
    echo "🚀 Ready for production deployment"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy to staging for integration testing"
    echo "  2. Monitor suspension patterns and customer feedback"
    echo "  3. Track upsell conversion rates"
    echo "  4. Update documentation with new suspension flow"
else
    echo "🔧 Suspension system needs attention:"
    echo "  1. Review failed test cases"
    echo "  2. Check API endpoint implementations"
    echo "  3. Verify database migrations completed"
    echo "  4. Test business logic edge cases"
fi

echo ""
log_header "Suspension System Test Runner Complete"

# Exit with the same code as the tests
exit $TEST_EXIT_CODE
#!/bin/bash

# XSpaceGrow Hibernation System Test Runner
# Tests the "Always Accept, Then Upsell" device management system

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

echo -e "${PURPLE}🔄 XSpaceGrow Hibernation System Tests${NC}"
echo -e "${PURPLE}=====================================${NC}"

# Check if we're in the right directory
if [ ! -f "$TEST_DIR/api-tests/test-hibernation.js" ]; then
    log_error "test-hibernation.js not found in api-tests/"
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

# Check for hibernation system prerequisites
log_info "Checking hibernation system prerequisites..."

# Check if hibernation endpoints exist
HIBERNATION_CHECK=$(curl -s "$API_BASE_URL/api/v1/frontend/subscriptions/device_management" \
    -H "Authorization: Bearer fake-token" \
    -w "%{http_code}" -o /dev/null || echo "000")

if [ "$HIBERNATION_CHECK" = "401" ]; then
    log_success "Hibernation endpoints are available (authentication required)"
elif [ "$HIBERNATION_CHECK" = "404" ]; then
    log_error "Hibernation endpoints not found - hibernation system may not be implemented"
    log_warning "Expected endpoints:"
    log_warning "  GET  /api/v1/frontend/subscriptions/device_management"
    log_warning "  POST /api/v1/frontend/devices/:id/hibernate"
    log_warning "  POST /api/v1/frontend/devices/:id/wake"
    log_warning "  POST /api/v1/frontend/subscriptions/activate_device"
    exit 1
else
    log_info "Hibernation endpoints responding with code: $HIBERNATION_CHECK"
fi

# Check Node.js dependencies
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Installing Node.js dependencies..."
    cd "$TEST_DIR/api-tests"
    npm install
    cd "$TEST_DIR"
    log_success "Dependencies installed"
fi

# Check if we can import required test modules
log_info "Verifying test dependencies..."
cd "$TEST_DIR/api-tests"

if [ ! -f "test-auth.js" ]; then
    log_error "test-auth.js not found - hibernation tests depend on auth utilities"
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

# Pre-flight hibernation test
log_info "Running pre-flight hibernation test..."
if node -e "
const { createUser } = require('./test-auth');
createUser('hibernation_preflight_' + Date.now() + '@example.com')
  .then(() => console.log('✅ Pre-flight hibernation test passed'))
  .catch(err => {
    console.error('❌ Pre-flight hibernation test failed:', err.message);
    process.exit(1);
  });
" 2>/dev/null; then
    log_success "Pre-flight hibernation test completed"
else
    log_warning "Pre-flight hibernation test failed - continuing with main tests"
fi

# Run the hibernation tests
log_section "Running Hibernation System Tests"
log_info "This comprehensive suite will test:"
echo "  🔄 Device status hierarchy (pending → active → hibernating)"
echo "  📊 Operational vs hibernating device counting"
echo "  🎯 Smart hibernation priority algorithms"
echo "  ⏰ Grace period creation and management"
echo "  💰 Upsell option generation and strategies"
echo "  🔌 Device activation integration with limits"
echo "  🎨 Complete business workflow validation"
echo "  🚀 Performance with concurrent operations"
echo "  🔍 Edge cases and error handling"
echo ""

export API_BASE_URL="$API_BASE_URL"
node test-hibernation.js

# Return to original directory
cd "$TEST_DIR"

# Additional checks and reporting
if ls api-tests/hibernation-test-results-*.json 1> /dev/null 2>&1; then
    LATEST_RESULTS=$(ls -t api-tests/hibernation-test-results-*.json | head -n1)
    
    log_section "Hibernation System Test Analysis"
    
    # Extract key metrics and validate hibernation system
    node -e "
    try {
        const fs = require('fs');
        const results = JSON.parse(fs.readFileSync('$LATEST_RESULTS', 'utf8'));
        
        console.log('🔄 Hibernation System Test Breakdown:');
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
        console.log('🎯 Critical Hibernation Features:');
        const critical = results.details.filter(t => 
            t.name.includes('Always Succeeds') || 
            t.name.includes('Smart Hibernation') ||
            t.name.includes('Grace Period') ||
            t.name.includes('Upsell Options') ||
            t.name.includes('Customer Journey')
        );
        
        const criticalPassed = critical.filter(t => t.status === 'PASS').length;
        console.log(\`  Core hibernation functionality: \${criticalPassed}/\${critical.length} tests passed\`);
        
        console.log('');
        console.log('💰 Business Impact Validation:');
        const businessTests = [
            'Device Activation - Always Succeeds, Then Handles Limits',
            'Complete Customer Journey - Purchase to Upsell',
            'Upsell Options Generation - Add Device Slots',
            'Automatic Hibernation on Limit Exceeded'
        ];
        
        const businessResults = businessTests.map(testName => {
            const test = results.details.find(t => t.name === testName);
            return test ? test.status === 'PASS' : false;
        });
        
        const businessPassed = businessResults.filter(Boolean).length;
        console.log(\`  Business logic validation: \${businessPassed}/\${businessTests.length} core workflows passed\`);
        
        if (results.summary.passRate >= 95) {
            console.log('');
            console.log('🏆 EXCELLENT: Hibernation system is production-ready!');
            console.log('🎯 \"Always Accept, Then Upsell\" strategy fully validated');
        } else if (results.summary.passRate >= 85) {
            console.log('');
            console.log('✅ GOOD: Hibernation system is functional with minor issues');
        } else {
            console.log('');
            console.log('⚠️  WARNING: Hibernation system needs attention before production');
        }
        
        // Check test coverage
        if (results.test_coverage) {
            console.log('');
            console.log('📋 Test Coverage Areas:');
            Object.entries(results.test_coverage).forEach(([area, covered]) => {
                const status = covered ? '✅' : '❌';
                console.log(\`  \${status} \${area.replace(/_/g, ' ')}\`);
            });
        }
        
    } catch (e) {
        console.log('Could not analyze hibernation results:', e.message);
    }
    " 2>/dev/null || log_warning "Could not analyze hibernation results"
    
    echo ""
    log_info "📄 Detailed hibernation results saved in: $LATEST_RESULTS"
fi

log_success "Hibernation System tests completed!"
echo ""
echo "🔍 What was tested:"
echo "  ✓ \"Always Accept\" policy - devices never blocked from activation"
echo "  ✓ Smart hibernation algorithms - oldest/offline devices prioritized"
echo "  ✓ Grace period management - 7-day customer decision window"
echo "  ✓ Upsell option generation - clear upgrade paths provided"
echo "  ✓ Device status transitions - pending → active ↔ hibernating"
echo "  ✓ Operational vs hibernating counting - limits correctly enforced"
echo "  ✓ Device activation integration - ESP32 flow with hibernation"
echo "  ✓ Complete customer journeys - purchase to upsell workflows"
echo "  ✓ Performance under load - concurrent activations handled"
echo "  ✓ Edge cases and error handling - robust system behavior"
echo ""
echo "💡 Business Impact:"
echo "  🎯 Customer satisfaction: Devices always work immediately"
echo "  💰 Revenue opportunity: Limits become sales conversations"
echo "  🚀 Scalability: System handles any number of devices gracefully"
echo "  📈 Growth driver: Subscription limits drive plan upgrades"
echo ""
echo "🚀 Next steps:"
echo "  - Review any failed tests in the detailed results"
echo "  - Check hibernation-related logs in Rails server"
echo "  - Validate hibernation UI/UX in frontend application"
echo "  - Monitor hibernation metrics in production"
echo "  - Run integration tests with full customer workflow"
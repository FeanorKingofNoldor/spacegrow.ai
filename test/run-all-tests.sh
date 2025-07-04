#!/bin/bash

# XSpaceGrow Enhanced Master Test Runner
# Runs all test suites including the hibernation system tests

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
log_section() { echo -e "${PURPLE}🔸 $1${NC}"; }
log_header() { echo -e "${CYAN}🚀 $1${NC}"; }

# Configuration
API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${CYAN}🚀 XSpaceGrow Complete Test Suite (Enhanced)${NC}"
echo -e "${CYAN}============================================${NC}"
echo "Timestamp: $(date)"
echo "API URL: $API_BASE_URL"
echo ""

# Initialize tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
SUITE_RESULTS=()

# Function to run a test suite
run_test_suite() {
    local suite_name="$1"
    local script_name="$2"
    local description="$3"
    
    log_section "Running $suite_name"
    log_info "$description"
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    if [ -f "$TEST_DIR/$script_name" ]; then
        local start_time=$(date +%s)
        
        if bash "$TEST_DIR/$script_name"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            PASSED_SUITES=$((PASSED_SUITES + 1))
            log_success "$suite_name completed successfully (${duration}s)"
            SUITE_RESULTS+=("✅ $suite_name (${duration}s)")
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            FAILED_SUITES=$((FAILED_SUITES + 1))
            log_error "$suite_name failed (${duration}s)"
            SUITE_RESULTS+=("❌ $suite_name (${duration}s)")
        fi
    else
        log_warning "$script_name not found, skipping $suite_name"
        SUITE_RESULTS+=("⚠️  $suite_name (skipped - script not found)")
    fi
    
    echo ""
}

# Check Rails server first
log_info "Checking Rails server status..."
if curl -s -f "$API_BASE_URL/up" > /dev/null 2>&1; then
    log_success "Rails server is running at $API_BASE_URL"
else
    log_error "Rails server is not responding at $API_BASE_URL"
    log_warning "Please start your Rails server with: rails server"
    exit 1
fi

# Check database and seed status
log_info "Checking database and seed data..."
DB_STATUS=$(curl -s "$API_BASE_URL/api/v1/frontend/subscriptions" \
    -H "Authorization: Bearer fake-token" \
    -w "%{http_code}" -o /dev/null 2>/dev/null || echo "000")

if [ "$DB_STATUS" = "401" ]; then
    log_success "Database and seed data appear to be ready"
elif [ "$DB_STATUS" = "500" ]; then
    log_warning "Database error detected - you may need to run: rails db:create db:migrate db:seed"
else
    log_info "Database status check returned: $DB_STATUS"
fi

# Setup test environment
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Setting up test environment..."
    cd "$TEST_DIR/api-tests"
    
    # Initialize package.json if it doesn't exist
    if [ ! -f "package.json" ]; then
        npm init -y > /dev/null 2>&1
    fi
    
    # Install all required dependencies
    npm install axios chalk ws > /dev/null 2>&1
    cd "$TEST_DIR"
    log_success "Test environment ready"
else
    log_info "Test environment already configured"
fi

echo ""
log_header "Starting Enhanced Test Suite Execution"
echo ""

# ===== THIS IS WHERE THE CODE BLOCK GOES =====
# Run all test suites in logical order
run_test_suite "Authentication & Authorization" "run-tests-auth.sh" \
    "Tests JWT tokens, user roles, permissions, and security features"

run_test_suite "Device Management" "run-tests-devices.sh" \
    "Tests device CRUD, sensor data, status calculations, and device limits"

run_test_suite "Subscription & Billing" "run-tests-subscriptions.sh" \
    "Tests subscription lifecycle, plan changes, device limits, and billing logic"

run_test_suite "Hibernation System" "run-tests-hibernation.sh" \
    "Tests \"Always Accept, Then Upsell\" device hibernation and smart limit management"

run_test_suite "WebSocket Communication" "run-tests-websocket.sh" \
    "Tests ActionCable connections, real-time updates, and command sending"

run_test_suite "Load & Performance" "run-tests-load.sh" \
    "Tests system performance under load with concurrent users and connections"
# ===== END OF CODE BLOCK =====

# Generate comprehensive report
log_section "Generating Enhanced Test Report"

cd "$TEST_DIR/api-tests"

# Create enhanced master report
cat > "enhanced-test-report-${TIMESTAMP}.json" << EOF
{
  "metadata": {
    "timestamp": "$(date -Iseconds)",
    "api_url": "$API_BASE_URL",
    "test_environment": {
      "rails_env": "${RAILS_ENV:-development}",
      "node_version": "$(node --version 2>/dev/null || echo 'unknown')",
      "platform": "$(uname -s)",
      "hostname": "$(hostname)"
    }
  },
  "suite_summary": {
    "total_suites": $TOTAL_SUITES,
    "passed_suites": $PASSED_SUITES,
    "failed_suites": $FAILED_SUITES,
    "success_rate": $(echo "scale=1; $PASSED_SUITES * 100 / $TOTAL_SUITES" | bc -l 2>/dev/null || echo "0")
  },
  "suite_results": [],
  "individual_test_summary": {
    "total_tests": 0,
    "total_passed": 0,
    "total_failed": 0,
    "overall_pass_rate": 0
  },
  "detailed_results": []
}
EOF

# Aggregate individual test results with enhanced analysis
if command -v node >/dev/null 2>&1; then
    node -e "
    const fs = require('fs');
    const path = require('path');
    
    // Read master report
    const masterReport = JSON.parse(fs.readFileSync('enhanced-test-report-${TIMESTAMP}.json'));
    
    // Find all individual test result files
    const files = fs.readdirSync('.').filter(f => 
        f.includes('test-results-') && f.endsWith('.json') && !f.includes('master-') && !f.includes('enhanced-')
    );
    
    let totalTests = 0;
    let totalPassed = 0;
    let totalFailed = 0;
    const categoryBreakdown = {};
    
    console.log('📊 Processing individual test results...');
    
    files.forEach(file => {
        try {
            const result = JSON.parse(fs.readFileSync(file));
            const testsInFile = result.summary.total || 0;
            const passedInFile = result.summary.passed || 0;
            const failedInFile = result.summary.failed || 0;
            
            totalTests += testsInFile;
            totalPassed += passedInFile;
            totalFailed += failedInFile;
            
            // Determine test category from filename
            let category = 'unknown';
            if (file.includes('auth')) category = 'authentication';
            else if (file.includes('device')) category = 'device_management';
            else if (file.includes('subscription')) category = 'subscription_billing';
            else if (file.includes('hibernation')) category = 'hibernation_system';
            else if (file.includes('websocket')) category = 'websocket_communication';
            else if (file.includes('load')) category = 'load_performance';
            
            categoryBreakdown[category] = {
                tests: testsInFile,
                passed: passedInFile,
                failed: failedInFile,
                pass_rate: testsInFile > 0 ? ((passedInFile / testsInFile) * 100).toFixed(1) : 0,
                file: file
            };
            
            masterReport.suite_results.push({
                category: category,
                file: file,
                ...result.summary
            });
            
            // Add detailed test results
            if (result.details) {
                masterReport.detailed_results.push({
                    category: category,
                    tests: result.details
                });
            }
            
            console.log(\`  ✓ \${category}: \${passedInFile}/\${testsInFile} tests passed\`);
            
        } catch (e) {
            console.error('  ❌ Error reading', file, ':', e.message);
        }
    });
    
    // Update totals
    masterReport.individual_test_summary.total_tests = totalTests;
    masterReport.individual_test_summary.total_passed = totalPassed;
    masterReport.individual_test_summary.total_failed = totalFailed;
    masterReport.individual_test_summary.overall_pass_rate = totalTests > 0 ? 
        ((totalPassed / totalTests) * 100).toFixed(1) : 0;
    masterReport.individual_test_summary.category_breakdown = categoryBreakdown;
    
    // Save updated report
    fs.writeFileSync('enhanced-test-report-${TIMESTAMP}.json', 
        JSON.stringify(masterReport, null, 2));
    
    console.log('');
    console.log('🎯 ENHANCED TEST SUMMARY');
    console.log('========================');
    console.log(\`Test Suites: \${masterReport.suite_summary.total_suites}\`);
    console.log(\`Passed Suites: \${masterReport.suite_summary.passed_suites}\`);
    console.log(\`Failed Suites: \${masterReport.suite_summary.failed_suites}\`);
    console.log(\`Suite Success Rate: \${masterReport.suite_summary.success_rate}%\`);
    console.log('');
    console.log(\`Total Individual Tests: \${totalTests}\`);
    console.log(\`Passed Tests: \${totalPassed}\`);
    console.log(\`Failed Tests: \${totalFailed}\`);
    console.log(\`Overall Pass Rate: \${masterReport.individual_test_summary.overall_pass_rate}%\`);
    console.log('');
    console.log('📋 Category Breakdown:');
    Object.entries(categoryBreakdown).forEach(([category, stats]) => {
        const status = stats.pass_rate >= 80 ? '✅' : stats.pass_rate >= 60 ? '⚠️ ' : '❌';
        console.log(\`  \${status} \${category}: \${stats.passed}/\${stats.tests} (\${stats.pass_rate}%)\`);
    });
    console.log('');
    
    // Quality assessment
    const overallRate = parseFloat(masterReport.individual_test_summary.overall_pass_rate);
    if (overallRate >= 95) {
        console.log('🏆 EXCELLENT: Your XSpaceGrow API is production-ready!');
    } else if (overallRate >= 85) {
        console.log('🎉 GREAT: Your API is in excellent condition with minor issues');
    } else if (overallRate >= 75) {
        console.log('✅ GOOD: Your API is functional but could use some improvements');
    } else if (overallRate >= 60) {
        console.log('⚠️  NEEDS WORK: Several areas need attention before production');
    } else {
        console.log('❌ CRITICAL: Significant issues detected - review failed tests');
    }
    
    console.log('');
    console.log(\`📄 Enhanced report: enhanced-test-report-${TIMESTAMP}.json\`);
    
    // Return appropriate exit code for script
    process.exit(masterReport.suite_summary.failed_suites);
    "
fi

cd "$TEST_DIR"

# Enhanced final summary with actionable insights
echo ""
log_section "Test Execution Summary"

echo "📊 Suite Results:"
for result in "${SUITE_RESULTS[@]}"; do
    echo "  $result"
done

echo ""
echo "🔍 Key Areas Tested:"
echo "  🔐 Authentication & Authorization (JWT, roles, permissions)"
echo "  🔧 Device Management (CRUD, sensors, status, limits)"
echo "  💳 Subscription & Billing (plans, changes, limits, lifecycle)"
echo "  🔄 Hibernation System (always accept, smart limits, upsell)"
echo "  🔌 WebSocket Communication (ActionCable, real-time updates)"
echo "  🚀 Load & Performance (concurrent users, scalability)"

echo ""
echo "📁 All test reports saved in api-tests/ directory:"
echo "  📄 Individual results: *-test-results-*.json"
echo "  📊 Enhanced summary: enhanced-test-report-${TIMESTAMP}.json"

echo ""
if [ $FAILED_SUITES -eq 0 ]; then
    log_success "🎉 ALL TEST SUITES PASSED!"
    echo "🚀 Your XSpaceGrow API is ready for production!"
    echo ""
    echo "Next steps:"
    echo "  ✓ Review the enhanced test report for detailed insights"
    echo "  ✓ Monitor your application in staging environment"
    echo "  ✓ Set up continuous integration with these tests"
    echo "  ✓ Consider setting up monitoring and alerting"
else
    log_warning "⚠️  $FAILED_SUITES out of $TOTAL_SUITES test suites failed"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review individual test reports for specific failures"
    echo "  2. Check Rails server logs for backend errors"
    echo "  3. Verify database migrations and seed data"
    echo "  4. Re-run failed test suites individually for debugging"
    echo "  5. Fix issues and re-run this complete test suite"
fi

echo ""
echo "🔗 Quick re-run commands:"
echo "  ./run-tests-auth.sh           # Authentication tests"
echo "  ./run-tests-devices.sh        # Device management tests"
echo "  ./run-tests-subscriptions.sh  # Subscription & billing tests"
echo "  ./run-tests-hibernation.sh    # Hibernation system tests"
echo "  ./run-tests-websocket.sh      # WebSocket communication tests"
echo "  ./run-tests-load.sh           # Load & performance tests"

# Exit with appropriate code
exit $FAILED_SUITES
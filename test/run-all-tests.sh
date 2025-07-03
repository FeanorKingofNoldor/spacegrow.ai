#!/bin/bash

# XSpaceGrow Master Test Runner
# Runs all test suites and generates comprehensive report

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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🚀 XSpaceGrow Complete Test Suite"
echo "================================="
echo "Timestamp: $(date)"
echo "API URL: $API_BASE_URL"
echo ""

# Initialize tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Function to run a test suite
run_test_suite() {
    local suite_name="$1"
    local script_name="$2"
    
    log_section "Running $suite_name Tests"
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    if [ -f "$TEST_DIR/$script_name" ]; then
        if bash "$TEST_DIR/$script_name"; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            log_success "$suite_name tests completed successfully"
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            log_error "$suite_name tests failed"
        fi
    else
        log_warning "$script_name not found, skipping $suite_name tests"
    fi
    
    echo ""
}

# Check Rails server first
log_info "Checking Rails server..."
if curl -s -f "$API_BASE_URL/up" > /dev/null 2>&1; then
    log_success "Rails server is running at $API_BASE_URL"
else
    log_error "Rails server is not responding at $API_BASE_URL"
    log_warning "Please start your Rails server with: rails server"
    exit 1
fi

# Setup if needed
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Installing dependencies..."
    cd "$TEST_DIR/api-tests"
    npm install
    cd "$TEST_DIR"
fi

echo ""
log_section "Starting Test Suite Execution"

# Run all test suites
run_test_suite "Authentication & Authorization" "run-tests-auth.sh"
run_test_suite "Device Management" "run-tests-devices.sh"
run_test_suite "WebSocket Communication" "run-tests-websocket.sh"
run_test_suite "Load & Performance" "run-tests-load.sh"

# Generate comprehensive report
log_section "Generating Comprehensive Report"

cd "$TEST_DIR/api-tests"

# Create master report
cat > "master-test-report-${TIMESTAMP}.json" << EOF
{
  "summary": {
    "timestamp": "$(date -Iseconds)",
    "total_suites": $TOTAL_SUITES,
    "passed_suites": $PASSED_SUITES,
    "failed_suites": $FAILED_SUITES,
    "success_rate": $(echo "scale=1; $PASSED_SUITES * 100 / $TOTAL_SUITES" | bc -l 2>/dev/null || echo "0"),
    "api_url": "$API_BASE_URL"
  },
  "suite_results": []
}
EOF

# Aggregate individual test results
if command -v node >/dev/null 2>&1; then
    node -e "
    const fs = require('fs');
    
    // Read master report
    const masterReport = JSON.parse(fs.readFileSync('master-test-report-${TIMESTAMP}.json'));
    
    // Find all individual test result files
    const files = fs.readdirSync('.').filter(f => 
        f.includes('test-results-') && f.endsWith('.json') && !f.includes('master-')
    );
    
    let totalTests = 0;
    let totalPassed = 0;
    let totalFailed = 0;
    
    files.forEach(file => {
        try {
            const result = JSON.parse(fs.readFileSync(file));
            totalTests += result.summary.total || 0;
            totalPassed += result.summary.passed || 0;
            totalFailed += result.summary.failed || 0;
            
            masterReport.suite_results.push({
                file: file,
                ...result.summary
            });
        } catch (e) {
            console.error('Error reading', file, e.message);
        }
    });
    
    // Update totals
    masterReport.summary.total_tests = totalTests;
    masterReport.summary.total_passed = totalPassed;
    masterReport.summary.total_failed = totalFailed;
    masterReport.summary.overall_pass_rate = totalTests > 0 ? 
        ((totalPassed / totalTests) * 100).toFixed(1) : 0;
    
    // Save updated report
    fs.writeFileSync('master-test-report-${TIMESTAMP}.json', 
        JSON.stringify(masterReport, null, 2));
    
    // Print summary
    console.log('');
    console.log('🎯 MASTER TEST SUMMARY');
    console.log('=====================');
    console.log(\`Test Suites: \${masterReport.summary.total_suites}\`);
    console.log(\`Passed Suites: \${masterReport.summary.passed_suites}\`);
    console.log(\`Failed Suites: \${masterReport.summary.failed_suites}\`);
    console.log(\`Suite Success Rate: \${masterReport.summary.success_rate}%\`);
    console.log('');
    console.log(\`Total Individual Tests: \${totalTests}\`);
    console.log(\`Passed Tests: \${totalPassed}\`);
    console.log(\`Failed Tests: \${totalFailed}\`);
    console.log(\`Overall Pass Rate: \${masterReport.summary.overall_pass_rate}%\`);
    console.log('');
    console.log(\`📄 Detailed report: master-test-report-${TIMESTAMP}.json\`);
    "
fi

cd "$TEST_DIR"

# Final summary
echo ""
if [ $FAILED_SUITES -eq 0 ]; then
    log_success "🎉 ALL TEST SUITES PASSED!"
    echo "Your XSpaceGrow API is working excellently!"
else
    log_warning "⚠️  Some test suites failed"
    echo "Check individual test reports for details"
fi

echo ""
echo "📊 Results Summary:"
echo "  - Total Suites: $TOTAL_SUITES"
echo "  - Passed: $PASSED_SUITES"
echo "  - Failed: $FAILED_SUITES"
echo ""
echo "🗂️  All reports saved in api-tests/ directory"

# Exit with appropriate code
exit $FAILED_SUITES
#!/bin/bash

# SpaceGrow Enhanced Test Suite Runner
# Comprehensive testing orchestration with detailed reporting and validation
# Updated for hibernation → suspension migration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_section() { echo -e "\n${PURPLE}🔸 $1${NC}"; }
log_header() { echo -e "\n${CYAN}🚀 $1${NC}"; }

# Configuration
API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Test tracking variables
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                SpaceGrow Enhanced Test Suite                ║${NC}"
echo -e "${CYAN}║              Comprehensive API Validation                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to run a test suite with enhanced reporting
run_test_suite() {
    local suite_name="$1"
    local script_name="$2"
    local description="$3"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    log_header "Running: $suite_name"
    log_info "$description"
    echo ""
    
    local start_time=$(date +%s)
    
    if [ -f "$TEST_DIR/$script_name" ]; then
        if "$TEST_DIR/$script_name"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            PASSED_SUITES=$((PASSED_SUITES + 1))
            log_success "$suite_name completed successfully (${duration}s)"
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            FAILED_SUITES=$((FAILED_SUITES + 1))
            log_error "$suite_name failed (${duration}s)"
        fi
    else
        log_error "Test script not found: $script_name"
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
    
    echo ""
}

# System prerequisites check
log_section "System Prerequisites Check"

# Check if we're in the right directory
if [ ! -d "$TEST_DIR/api-tests" ]; then
    log_error "api-tests directory not found"
    log_info "Make sure you're running from the correct directory"
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

# Check for migration completion
log_info "Checking hibernation → suspension migration status..."

# Look for old hibernation files
OLD_FILES=("run-tests-hibernation.sh" "test-hibernation.js")
FOUND_OLD_FILES=()

for file in "${OLD_FILES[@]}"; do
    if [ -f "$TEST_DIR/$file" ]; then
        FOUND_OLD_FILES+=("$file")
    fi
done

if [ ${#FOUND_OLD_FILES[@]} -gt 0 ]; then
    log_warning "Found old hibernation files: ${FOUND_OLD_FILES[*]}"
    log_warning "Migration may be incomplete - review these files"
else
    log_success "Migration to suspension system complete"
fi

# Check for new suspension files
if [ -f "$TEST_DIR/run-tests-suspension.sh" ] && [ -f "$TEST_DIR/api-tests/test-suspension.js" ]; then
    log_success "Suspension system test files present"
else
    log_warning "Suspension system test files missing"
fi

# Environment setup
log_section "Environment Setup and Validation"

# Set up Node.js test environment
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

# Run all test suites in logical order with enhanced descriptions
run_test_suite "Authentication & Authorization" "run-tests-auth.sh" \
    "Tests JWT tokens, user roles, permissions, and security features"

run_test_suite "Device Management" "run-tests-devices.sh" \
    "Tests device CRUD, status system (pending/active/suspended/disabled), and ESP32 integration"

run_test_suite "Subscription & Billing" "run-tests-subscriptions.sh" \
    "Tests subscription lifecycle, plan changes, device limits, and billing logic"

run_test_suite "Suspension System" "run-tests-suspension.sh" \
    "Tests \"Always Accept, Then Upsell\" device suspension and smart limit management"

run_test_suite "WebSocket Communication" "run-tests-websocket.sh" \
    "Tests ActionCable connections, real-time updates, and command sending"

run_test_suite "Load & Performance" "run-tests-load.sh" \
    "Tests system performance under load with concurrent users and connections"

# Generate comprehensive report
log_section "Generating Enhanced Test Report"

cd "$TEST_DIR/api-tests"

# Create enhanced master report
cat > "enhanced-test-report-${TIMESTAMP}.json" << EOF
{
  "metadata": {
    "timestamp": "$(date -Iseconds)",
    "api_url": "$API_BASE_URL",
    "migration_status": {
      "hibernation_to_suspension": "completed",
      "old_files_found": $([ ${#FOUND_OLD_FILES[@]} -gt 0 ] && echo "true" || echo "false"),
      "suspension_tests_available": $([ -f "test-suspension.js" ] && echo "true" || echo "false")
    },
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
            else if (file.includes('suspension')) category = 'suspension_system'; // Updated category
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
    
    // Write updated master report
    fs.writeFileSync('enhanced-test-report-${TIMESTAMP}.json', JSON.stringify(masterReport, null, 2));
    
    console.log('');
    console.log('📈 Test Results Aggregation:');
    console.log(\`   Total Individual Tests: \${totalTests}\`);
    console.log(\`   Total Passed: \${totalPassed}\`);
    console.log(\`   Total Failed: \${totalFailed}\`);
    console.log(\`   Overall Pass Rate: \${masterReport.individual_test_summary.overall_pass_rate}%\`);
    
    console.log('');
    console.log('📋 Category Breakdown:');
    Object.entries(categoryBreakdown).forEach(([category, stats]) => {
        console.log(\`   \${category}: \${stats.passed}/\${stats.tests} (\${stats.pass_rate}%)\`);
    });
    
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Test results aggregated successfully"
    else
        log_warning "Test result aggregation failed"
    fi
else
    log_warning "Node.js not available - skipping advanced report generation"
fi

# Return to original directory
cd "$TEST_DIR"

# Final validation and reporting
log_section "Final System Validation"

# Calculate overall success rate
if [ $TOTAL_SUITES -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=1; $PASSED_SUITES * 100 / $TOTAL_SUITES" | bc -l 2>/dev/null || echo "0")
else
    SUCCESS_RATE="0"
fi

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    FINAL TEST REPORT                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Test Suite Summary:${NC}"
echo -e "   Total Suites: $TOTAL_SUITES"
echo -e "   Passed: ${GREEN}$PASSED_SUITES${NC}"
echo -e "   Failed: ${RED}$FAILED_SUITES${NC}"
echo -e "   Success Rate: ${SUCCESS_RATE}%"
echo ""

# Migration validation summary
echo -e "${BLUE}🔄 Migration Status:${NC}"
if [ ${#FOUND_OLD_FILES[@]} -eq 0 ]; then
    echo -e "   ✅ Hibernation → Suspension migration: ${GREEN}COMPLETE${NC}"
else
    echo -e "   ⚠️  Hibernation → Suspension migration: ${YELLOW}REVIEW NEEDED${NC}"
    echo -e "       Old files found: ${FOUND_OLD_FILES[*]}"
fi

if [ -f "api-tests/test-suspension.js" ]; then
    echo -e "   ✅ Suspension system tests: ${GREEN}AVAILABLE${NC}"
else
    echo -e "   ❌ Suspension system tests: ${RED}MISSING${NC}"
fi

echo ""

# System readiness assessment
echo -e "${BLUE}🚀 System Readiness:${NC}"

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "   ✅ All test suites passed"
    echo -e "   ✅ API system fully validated"
    echo -e "   ✅ Ready for production deployment"
    echo ""
    echo -e "${GREEN}🎉 SpaceGrow API System: FULLY VALIDATED!${NC}"
    echo -e "${GREEN}🚀 All systems operational and ready for deployment${NC}"
else
    echo -e "   ⚠️  $FAILED_SUITES test suite(s) failed"
    echo -e "   🔧 Review failed test results"
    echo -e "   📋 Address issues before deployment"
    echo ""
    echo -e "${YELLOW}⚠️  System needs attention before deployment${NC}"
fi

echo ""

# Provide actionable next steps
echo -e "${BLUE}📋 Next Steps:${NC}"

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "   1. 🚢 Deploy to staging environment"
    echo -e "   2. 📈 Monitor system performance"
    echo -e "   3. 👥 Conduct user acceptance testing"
    echo -e "   4. 📚 Update documentation"
else
    echo -e "   1. 🔍 Review failed test results:"
    echo -e "      ls -la api-tests/*-test-results-*.json"
    echo -e "   2. 🛠️  Fix identified issues"
    echo -e "   3. 🔄 Re-run failed test suites"
    echo -e "   4. ✅ Validate fixes before deployment"
fi

echo ""

# Report file locations
echo -e "${BLUE}📄 Reports Available:${NC}"
if [ -f "api-tests/enhanced-test-report-${TIMESTAMP}.json" ]; then
    echo -e "   📊 Enhanced Report: api-tests/enhanced-test-report-${TIMESTAMP}.json"
fi

# List recent individual reports
RECENT_REPORTS=$(find api-tests -name "*-test-results-*.json" -mmin -60 2>/dev/null | head -5)
if [ -n "$RECENT_REPORTS" ]; then
    echo -e "   📋 Individual Reports:"
    echo "$RECENT_REPORTS" | while read -r report; do
        echo -e "      - $report"
    done
fi

echo ""

# Cleanup suggestions
if [ $FAILED_SUITES -eq 0 ] && [ ${#FOUND_OLD_FILES[@]} -gt 0 ]; then
    echo -e "${BLUE}🧹 Cleanup Suggestions:${NC}"
    echo -e "   Consider removing old hibernation files:"
    for file in "${FOUND_OLD_FILES[@]}"; do
        echo -e "      rm $file"
    done
    echo ""
fi

# Final status message
log_header "Enhanced Test Suite Execution Complete"

# Exit with appropriate code
if [ $FAILED_SUITES -eq 0 ]; then
    exit 0
else
    exit 1
fi
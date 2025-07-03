#!/bin/bash

# XSpaceGrow Authentication & Authorization Test Runner
# Tests JWT tokens, user roles, permissions, and security

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Configuration
API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔐 XSpaceGrow Authentication Tests"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "$TEST_DIR/api-tests/test-auth.js" ]; then
    log_error "test-auth.js not found in api-tests/"
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

# Check Node.js dependencies
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Installing Node.js dependencies..."
    cd "$TEST_DIR/api-tests"
    npm install
    cd "$TEST_DIR"
    log_success "Dependencies installed"
fi

# Run the auth tests
log_info "Running Authentication & Authorization tests..."
cd "$TEST_DIR/api-tests"

export API_BASE_URL="$API_BASE_URL"
node test-auth.js

# Return to original directory
cd "$TEST_DIR"

log_success "Authentication tests completed!"
echo ""
echo "📊 Check the detailed results in api-tests/auth-test-results-*.json"
echo "🚀 Next: Run Device tests with ./run-tests-devices.sh"
#!/bin/bash

# SpaceGrow WebSocket Communication Test Runner
# Tests ActionCable connections, real-time updates, command sending, and WebSocket performance

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
WS_URL=${WS_URL:-"ws://localhost:3000/cable"}
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔌 SpaceGrow WebSocket Communication Tests"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "$TEST_DIR/api-tests/test-websocket.js" ]; then
    log_error "test-websocket.js not found in api-tests/"
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

# Check WebSocket endpoint
log_info "Checking WebSocket endpoint..."
if curl -s -f "$API_BASE_URL/cable" > /dev/null 2>&1; then
    log_success "ActionCable endpoint is available at $API_BASE_URL/cable"
else
    log_warning "ActionCable endpoint check inconclusive (this might be normal)"
fi

# Check Node.js dependencies
if [ ! -d "$TEST_DIR/api-tests/node_modules" ]; then
    log_info "Installing Node.js dependencies..."
    cd "$TEST_DIR/api-tests"
    npm install
    cd "$TEST_DIR"
    log_success "Dependencies installed"
fi

# Check if WebSocket module is available
log_info "Checking WebSocket dependencies..."
cd "$TEST_DIR/api-tests"
if node -e "require('ws'); console.log('WebSocket module available')" 2>/dev/null; then
    log_success "WebSocket dependencies are ready"
else
    log_warning "WebSocket module not found, installing..."
    npm install ws
    log_success "WebSocket module installed"
fi

# Run the WebSocket tests
log_info "Running WebSocket Communication tests..."
log_warning "Note: Some tests may take longer due to WebSocket timeouts and real-time waiting"

export API_BASE_URL="$API_BASE_URL"
export WS_URL="$WS_URL"
node test-websocket.js

# Return to original directory
cd "$TEST_DIR"

log_success "WebSocket Communication tests completed!"
echo ""
echo "📊 Check the detailed results in api-tests/websocket-test-results-*.json"
echo ""
echo "🔍 WebSocket Test Notes:"
echo "  - Connection tests verify ActionCable setup"
echo "  - Real-time tests check message broadcasting"
echo "  - Command tests verify device control via WebSocket"
echo "  - Performance tests measure connection speed and throughput"
echo ""
echo "🚀 Next: Run Load tests with ./run-tests-load.sh"
#!/bin/bash

# run-tests-load.sh - XSpaceGrow Enhanced Load Testing Suite
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
BASE_URL="${BASE_URL:-http://localhost:3000}"
WS_URL="${WS_URL:-ws://localhost:3000/cable}"
RESULTS_DIR="api-tests"
TIMESTAMP=$(date +%s%3N)

echo -e "${PURPLE}🔥 XSpaceGrow Enhanced Load Testing Suite${NC}"
echo -e "${PURPLE}===========================================${NC}"

# Export load testing environment variable for Rails to pick up
export LOAD_TESTING=true
export RAILS_ENV="${RAILS_ENV:-development}"

echo -e "${CYAN}ℹ  Environment: LOAD_TESTING=${LOAD_TESTING}${NC}"
echo -e "${CYAN}ℹ  Rails Environment: ${RAILS_ENV}${NC}"

# Function to check if Rails server is running
check_server() {
    echo -e "${CYAN}ℹ  Checking Rails server...${NC}"
    if curl -s -f "$BASE_URL/up" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Rails server is running at $BASE_URL${NC}"
        return 0
    else
        return 1
    fi
}

# Function to start Rails server with load testing environment
start_server() {
    echo -e "${YELLOW}ℹ  Starting Rails server with load testing configuration...${NC}"
    
    # Kill any existing Rails processes
    pkill -f "rails server" || true
    pkill -f "puma" || true
    sleep 2
    
    # Start Rails server in background with load testing environment
    cd ..
    LOAD_TESTING=true RAILS_ENV=development rails server -p 3000 > log/load_test_server.log 2>&1 &
    SERVER_PID=$!
    cd api-tests
    
    echo -e "${CYAN}ℹ  Rails server starting (PID: $SERVER_PID)...${NC}"
    
    # Wait for server to start
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if check_server; then
            echo -e "${GREEN}✅ Rails server started successfully${NC}"
            return 0
        fi
        
        sleep 1
        attempts=$((attempts + 1))
        echo -ne "${YELLOW}⏳ Waiting for server... ($attempts/$max_attempts)\r${NC}"
    done
    
    echo -e "\n${RED}❌ Rails server failed to start within $max_attempts seconds${NC}"
    echo -e "${YELLOW}ℹ  Check log/load_test_server.log for errors${NC}"
    return 1
}

# Function to stop the Rails server
stop_server() {
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${CYAN}ℹ  Stopping Rails server (PID: $SERVER_PID)...${NC}"
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        echo -e "${GREEN}✅ Rails server stopped${NC}"
    fi
}

# Trap to ensure server cleanup on exit
trap stop_server EXIT

# Check if server is already running or start it
if ! check_server; then
    echo -e "${YELLOW}⚠  Rails server not running, starting it with load testing configuration...${NC}"
    
    if ! start_server; then
        echo -e "${RED}❌ Failed to start Rails server${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠  Rails server is running but may not have load testing configuration${NC}"
    echo -e "${YELLOW}ℹ  Consider restarting with: LOAD_TESTING=true rails server${NC}"
fi

# Check dependencies
echo -e "${CYAN}ℹ  Checking load testing dependencies...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found${NC}"
    exit 1
fi

cd api-tests

if [ ! -f package.json ]; then
    echo -e "${YELLOW}ℹ  Initializing test environment...${NC}"
    npm init -y > /dev/null 2>&1
fi

# Install dependencies
echo -e "${CYAN}ℹ  Installing/updating dependencies...${NC}"
npm install --silent axios ws > /dev/null 2>&1

echo -e "${GREEN}✅ Load testing dependencies ready${NC}"

# Check Redis connection (important for rate limiting)
echo -e "${CYAN}ℹ  Checking Redis connection...${NC}"
if command -v redis-cli &> /dev/null; then
    if redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Redis is running${NC}"
    else
        echo -e "${YELLOW}⚠  Redis not responding - rate limiting may not work properly${NC}"
    fi
else
    echo -e "${YELLOW}⚠  Redis CLI not found - cannot verify Redis connection${NC}"
fi

# Create test environment setup
echo -e "${CYAN}ℹ  Setting up test environment...${NC}"

# Verify environment variables are passed correctly
node -e "
console.log('🔧 Environment check:');
console.log('  LOAD_TESTING:', process.env.LOAD_TESTING);
console.log('  BASE_URL:', process.env.BASE_URL || 'http://localhost:3000');
console.log('  WS_URL:', process.env.WS_URL || 'ws://localhost:3000/cable');
"

echo -e "${GREEN}✅ Test environment ready${NC}"
echo -e "${CYAN}ℹ  Running Enhanced Load Testing suite...${NC}"
echo -e "${YELLOW}⚠  Note: This will stress your system - monitor resource usage${NC}"
echo -e "${YELLOW}⚠  Rate limiting is disabled during load testing${NC}"

# Run the enhanced load tests
echo -e "${PURPLE}🚀 Starting load tests...${NC}"
LOAD_TESTING=true BASE_URL="$BASE_URL" WS_URL="$WS_URL" node test-load.js

# Check test results
if ls load-test-results-*.json 1> /dev/null 2>&1; then
    LATEST_RESULTS=$(ls -t load-test-results-*.json | head -n1)
    
    # Extract pass rate from results
    PASS_RATE=$(node -e "
        try {
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('$LATEST_RESULTS', 'utf8'));
            console.log(results.summary.passRate || 0);
        } catch (e) {
            console.log(0);
        }
    " 2>/dev/null || echo "0")
    
    echo ""
    echo -e "${PURPLE}📊 Load Test Summary${NC}"
    echo -e "${PURPLE}===================${NC}"
    
    # Ensure PASS_RATE is numeric for comparison
    if [[ "$PASS_RATE" =~ ^[0-9]+$ ]]; then
        if [ "$PASS_RATE" -ge 80 ]; then
            echo -e "${GREEN}✅ Load tests PASSED with ${PASS_RATE}% success rate${NC}"
            echo -e "${GREEN}🚀 System is ready for production load!${NC}"
        elif [ "$PASS_RATE" -ge 60 ]; then
            echo -e "${YELLOW}⚠  Load tests PARTIAL with ${PASS_RATE}% success rate${NC}"
            echo -e "${YELLOW}ℹ  System can handle some load but may need optimization${NC}"
        else
            echo -e "${RED}❌ Load tests FAILED with ${PASS_RATE}% success rate${NC}"
            echo -e "${RED}⚠  System may not be ready for production load${NC}"
        fi
    else
        echo -e "${YELLOW}⚠  Could not determine pass rate from results${NC}"
    fi
    
    echo -e "${BLUE}📄 Detailed results: $LATEST_RESULTS${NC}"
else
    echo -e "${RED}❌ No test results file found${NC}"
fi

echo ""
echo -e "${CYAN}🔍 Load Test Notes:${NC}"
echo -e "${CYAN}  - API tests measure concurrent user capacity${NC}"
echo -e "${CYAN}  - WebSocket tests check real-time scalability${NC}"
echo -e "${CYAN}  - Rate limiting is disabled during testing${NC}"
echo -e "${CYAN}  - Test data is automatically cleaned up${NC}"
echo -e "${CYAN}  - Check Rails logs for server-side performance metrics${NC}"

echo ""
echo -e "${GREEN}✅ Enhanced load testing completed!${NC}"

# Offer to restart server in normal mode
echo ""
read -p "Restart Rails server in normal mode? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}ℹ  Restarting Rails server in normal mode...${NC}"
    stop_server
    cd ..
    rails server -p 3000 > log/development.log 2>&1 &
    echo -e "${GREEN}✅ Rails server restarted in normal mode${NC}"
    trap - EXIT # Remove the trap since we want the server to keep running
fi
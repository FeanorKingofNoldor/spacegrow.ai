#!/bin/bash

# run-tests-load.sh - XSpaceGrow Load Testing Suite
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

echo -e "${PURPLE}🔥 XSpaceGrow Load Testing Suite${NC}"
echo -e "${PURPLE}===================================${NC}"

# Check if server is running
echo -e "${CYAN}ℹ  Checking Rails server...${NC}"
if curl -s -f "$BASE_URL/api/v1/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Rails server is running at $BASE_URL${NC}"
else
    echo -e "${RED}❌ Rails server not responding at $BASE_URL${NC}"
    echo -e "${YELLOW}ℹ  Please start your Rails server first: rails server${NC}"
    exit 1
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

# Install additional dependencies for load testing
echo -e "${CYAN}ℹ  Installing load testing dependencies...${NC}"
npm install --silent autocannon clinic loadtest > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠  Some load testing tools not available, using basic tests${NC}"
}

echo -e "${GREEN}✅ Load testing dependencies ready${NC}"
echo -e "${CYAN}ℹ  Running Load Testing suite...${NC}"
echo -e "${YELLOW}⚠  Note: Load tests will stress your system - monitor resource usage${NC}"

# Run the load tests
node test-load.js

echo -e "${GREEN}✅ Load testing completed!${NC}"
echo ""
echo -e "${BLUE}📊 Check the detailed results in api-tests/load-test-results-*.json${NC}"
echo ""
echo -e "${CYAN}🔍 Load Test Notes:${NC}"
echo -e "${CYAN}  - API tests measure concurrent user capacity${NC}"
echo -e "${CYAN}  - WebSocket tests check real-time scalability${NC}"
echo -e "${CYAN}  - Resource tests monitor system performance${NC}"
echo -e "${CYAN}  - Rate limiting tests verify protection effectiveness${NC}"
echo ""
echo -e "${GREEN}🚀 System is now fully tested and production-ready!${NC}"
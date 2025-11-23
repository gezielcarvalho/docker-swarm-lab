#!/bin/bash

# Run unit tests in WSL environment
# These tests run outside of Docker

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "========================================"
echo "Running Unit Tests (WSL Environment)"
echo "========================================"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/app"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Dependencies not installed. Installing...${NC}"
    npm install
fi

echo -e "${YELLOW}Running unit tests...${NC}\n"

# Run tests
npm test

echo -e "\n${GREEN}"
echo "========================================"
echo "Unit Tests Complete!"
echo "========================================"
echo -e "${NC}"

# Show coverage summary
if [ -d "coverage" ]; then
    echo -e "${BLUE}Coverage report available at:${NC}"
    echo "  $PROJECT_ROOT/app/coverage/lcov-report/index.html"
    echo ""
fi

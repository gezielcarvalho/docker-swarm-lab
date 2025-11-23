#!/bin/bash

# Run integration tests in Docker environment
# These tests run inside a Docker container

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "========================================"
echo "Running Integration Tests (Docker)"
echo "========================================"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/app"

# Build test image
echo -e "${YELLOW}Building test Docker image...${NC}"
docker build -t swarm-lab-app:test -f Dockerfile .

# Run tests in container
echo -e "\n${YELLOW}Running integration tests in container...${NC}\n"

if docker run --rm \
    -e NODE_ENV=test \
    swarm-lab-app:test \
    npm run test:integration; then
    
    echo -e "\n${GREEN}"
    echo "========================================"
    echo "Integration Tests Passed!"
    echo "========================================"
    echo -e "${NC}"
    
    # Cleanup test image
    echo -e "${YELLOW}Cleaning up test image...${NC}"
    docker rmi swarm-lab-app:test
    
    exit 0
else
    echo -e "\n${RED}"
    echo "========================================"
    echo "Integration Tests Failed!"
    echo "========================================"
    echo -e "${NC}"
    
    # Cleanup test image
    echo -e "${YELLOW}Cleaning up test image...${NC}"
    docker rmi swarm-lab-app:test
    
    exit 1
fi

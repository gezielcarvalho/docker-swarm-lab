#!/bin/bash

# Initialize QA Docker Swarm Environment
# This script sets up the QA swarm cluster

set -e

echo "========================================="
echo "Initializing QA Swarm Environment"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

echo -e "${YELLOW}Step 1: Verifying Docker Swarm${NC}"
if ! docker info | grep -q "Swarm: active"; then
    echo -e "${YELLOW}Swarm not initialized. Initializing now...${NC}"
    
    # Detect the best IP address to use
    SWARM_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    
    if [ -z "$SWARM_IP" ]; then
        SWARM_IP=$(ip -4 addr show docker0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    fi
    
    if [ -z "$SWARM_IP" ]; then
        SWARM_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | grep -v '^10\.255\.' | head -1)
    fi
    
    if [ -z "$SWARM_IP" ]; then
        SWARM_IP="127.0.0.1"
    fi
    
    echo "Using IP address: $SWARM_IP"
    docker swarm init --advertise-addr "$SWARM_IP"
fi
echo -e "${GREEN}✓ Swarm active${NC}"

echo -e "\n${YELLOW}Step 2: Creating overlay networks for QA${NC}"
docker network create --driver overlay --attachable qa-frontend 2>/dev/null || echo "Network qa-frontend already exists"
docker network create --driver overlay --attachable qa-backend 2>/dev/null || echo "Network qa-backend already exists"
docker network create --driver overlay --attachable qa-monitoring 2>/dev/null || echo "Network qa-monitoring already exists"
echo -e "${GREEN}✓ Networks created${NC}"

echo -e "\n${YELLOW}Step 3: Creating volumes for QA${NC}"
docker volume create portainer_data_qa 2>/dev/null || echo "Volume portainer_data_qa already exists"
echo -e "${GREEN}✓ Volumes created${NC}"

echo -e "\n${GREEN}========================================="
echo "QA Environment Ready!"
echo "=========================================${NC}"
echo ""
echo "Networks:"
echo "  - qa-frontend (overlay)"
echo "  - qa-backend (overlay)"
echo "  - qa-monitoring (overlay)"
echo ""
echo "Volumes:"
echo "  - portainer_data_qa"
echo ""
echo "Next steps:"
echo "  1. Deploy Portainer: docker stack deploy -c infrastructure/portainer/stack.qa.yml portainer-qa"
echo "  2. Deploy Application: docker stack deploy -c stacks/app.qa.yml app-qa"
echo ""

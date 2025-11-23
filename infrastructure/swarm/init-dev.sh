#!/bin/bash

# Initialize DEV Docker Swarm Environment
# This script sets up the DEV swarm cluster

set -e

echo "========================================="
echo "Initializing DEV Swarm Environment"
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

echo -e "${YELLOW}Step 1: Initializing Docker Swarm (if not already initialized)${NC}"
if ! docker info | grep -q "Swarm: active"; then
    # Detect the best IP address to use
    # Prefer eth0, then docker0, then first available non-loopback interface
    SWARM_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    
    if [ -z "$SWARM_IP" ]; then
        SWARM_IP=$(ip -4 addr show docker0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    fi
    
    if [ -z "$SWARM_IP" ]; then
        # Get first non-loopback IP
        SWARM_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | grep -v '^10\.255\.' | head -1)
    fi
    
    if [ -z "$SWARM_IP" ]; then
        # Fallback to localhost
        SWARM_IP="127.0.0.1"
    fi
    
    echo "Using IP address: $SWARM_IP"
    docker swarm init --advertise-addr "$SWARM_IP"
    echo -e "${GREEN}✓ Swarm initialized${NC}"
else
    echo -e "${GREEN}✓ Swarm already active${NC}"
fi

echo -e "\n${YELLOW}Step 2: Creating overlay networks for DEV${NC}"
docker network create --driver overlay --attachable dev-frontend 2>/dev/null || echo "Network dev-frontend already exists"
docker network create --driver overlay --attachable dev-backend 2>/dev/null || echo "Network dev-backend already exists"
docker network create --driver overlay --attachable dev-monitoring 2>/dev/null || echo "Network dev-monitoring already exists"
echo -e "${GREEN}✓ Networks created${NC}"

echo -e "\n${YELLOW}Step 3: Creating volumes for DEV${NC}"
docker volume create portainer_data_dev 2>/dev/null || echo "Volume portainer_data_dev already exists"
echo -e "${GREEN}✓ Volumes created${NC}"

echo -e "\n${GREEN}========================================="
echo "DEV Environment Ready!"
echo "=========================================${NC}"
echo ""
echo "Networks:"
echo "  - dev-frontend (overlay)"
echo "  - dev-backend (overlay)"
echo "  - dev-monitoring (overlay)"
echo ""
echo "Volumes:"
echo "  - portainer_data_dev"
echo ""
echo "Next steps:"
echo "  1. Deploy Portainer: docker stack deploy -c infrastructure/portainer/stack.dev.yml portainer-dev"
echo "  2. Deploy Application: docker stack deploy -c stacks/app.dev.yml app-dev"
echo ""

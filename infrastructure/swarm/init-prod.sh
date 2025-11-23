#!/bin/bash

# Initialize PROD Docker Swarm Environment
# This script sets up the PROD swarm cluster

set -e

echo "========================================="
echo "Initializing PROD Swarm Environment"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo -e "\n${RED}========================================="
echo "WARNING: PRODUCTION Environment"
echo "=========================================${NC}"
echo "You are setting up a PRODUCTION environment."
echo "Ensure you have proper backups and monitoring in place."
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo -e "\n${YELLOW}Step 2: Creating overlay networks for PROD${NC}"
docker network create --driver overlay --attachable prod-frontend 2>/dev/null || echo "Network prod-frontend already exists"
docker network create --driver overlay --attachable prod-backend 2>/dev/null || echo "Network prod-backend already exists"
docker network create --driver overlay --attachable prod-monitoring 2>/dev/null || echo "Network prod-monitoring already exists"
echo -e "${GREEN}✓ Networks created${NC}"

echo -e "\n${YELLOW}Step 3: Creating volumes for PROD${NC}"
docker volume create portainer_data_prod 2>/dev/null || echo "Volume portainer_data_prod already exists"
echo -e "${GREEN}✓ Volumes created${NC}"

echo -e "\n${GREEN}========================================="
echo "PROD Environment Ready!"
echo "=========================================${NC}"
echo ""
echo "Networks:"
echo "  - prod-frontend (overlay)"
echo "  - prod-backend (overlay)"
echo "  - prod-monitoring (overlay)"
echo ""
echo "Volumes:"
echo "  - portainer_data_prod"
echo ""
echo "Next steps:"
echo "  1. Deploy Portainer: docker stack deploy -c infrastructure/portainer/stack.prod.yml portainer-prod"
echo "  2. Deploy Application: docker stack deploy -c stacks/app.prod.yml app-prod"
echo ""
echo -e "${RED}Remember: This is PRODUCTION. Monitor carefully!${NC}"
echo ""

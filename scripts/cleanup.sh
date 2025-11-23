#!/bin/bash

# Cleanup script - removes all Docker Swarm lab resources
# WARNING: This will stop and remove all services, networks, and volumes

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                   ⚠️  WARNING: CLEANUP OPERATION  ⚠️              ║
║                                                                   ║
║   This will remove:                                               ║
║   - All deployed stacks (app-dev, app-qa, app-prod)               ║
║   - Portainer instances                                           ║
║   - Jenkins                                                       ║
║   - Docker Registry                                               ║
║   - All networks (dev, qa, prod)                                  ║
║   - All volumes (optional)                                        ║
║                                                                   ║
║   This action CANNOT be undone!                                   ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup aborted."
    exit 0
fi

echo -e "\n${YELLOW}Starting cleanup...${NC}\n"

# Remove application stacks
echo -e "${YELLOW}Removing application stacks...${NC}"
docker stack rm app-dev 2>/dev/null || echo "app-dev not found"
docker stack rm app-qa 2>/dev/null || echo "app-qa not found"
docker stack rm app-prod 2>/dev/null || echo "app-prod not found"

# Remove Portainer stacks
echo -e "\n${YELLOW}Removing Portainer stacks...${NC}"
docker stack rm portainer-dev 2>/dev/null || echo "portainer-dev not found"
docker stack rm portainer-qa 2>/dev/null || echo "portainer-qa not found"
docker stack rm portainer-prod 2>/dev/null || echo "portainer-prod not found"

# Remove Jenkins
echo -e "\n${YELLOW}Removing Jenkins...${NC}"
docker stack rm jenkins 2>/dev/null || echo "jenkins not found"

# Remove Registry
echo -e "\n${YELLOW}Removing Registry...${NC}"
docker stack rm registry 2>/dev/null || echo "registry not found"

# Wait for services to stop
echo -e "\n${YELLOW}Waiting for services to stop...${NC}"
sleep 20

# Remove networks
echo -e "\n${YELLOW}Removing networks...${NC}"
docker network rm dev-frontend 2>/dev/null || echo "dev-frontend not found"
docker network rm dev-backend 2>/dev/null || echo "dev-backend not found"
docker network rm dev-monitoring 2>/dev/null || echo "dev-monitoring not found"
docker network rm qa-frontend 2>/dev/null || echo "qa-frontend not found"
docker network rm qa-backend 2>/dev/null || echo "qa-backend not found"
docker network rm qa-monitoring 2>/dev/null || echo "qa-monitoring not found"
docker network rm prod-frontend 2>/dev/null || echo "prod-frontend not found"
docker network rm prod-backend 2>/dev/null || echo "prod-backend not found"
docker network rm prod-monitoring 2>/dev/null || echo "prod-monitoring not found"
docker network rm jenkins-network 2>/dev/null || echo "jenkins-network not found"
docker network rm registry-network 2>/dev/null || echo "registry-network not found"

# Ask about volumes
echo -e "\n${YELLOW}Do you want to remove volumes? This will delete all data!${NC}"
read -p "Remove volumes? (yes/no): " remove_volumes

if [ "$remove_volumes" == "yes" ]; then
    echo -e "\n${YELLOW}Removing volumes...${NC}"
    docker volume rm portainer_data_dev 2>/dev/null || echo "portainer_data_dev not found"
    docker volume rm portainer_data_qa 2>/dev/null || echo "portainer_data_qa not found"
    docker volume rm portainer_data_prod 2>/dev/null || echo "portainer_data_prod not found"
    docker volume rm jenkins_home 2>/dev/null || echo "jenkins_home not found"
    docker volume rm registry_data 2>/dev/null || echo "registry_data not found"
    echo -e "${GREEN}✓ Volumes removed${NC}"
else
    echo "Volumes preserved."
fi

# Ask about leaving swarm
echo -e "\n${YELLOW}Do you want to leave the Docker Swarm?${NC}"
read -p "Leave swarm? (yes/no): " leave_swarm

if [ "$leave_swarm" == "yes" ]; then
    docker swarm leave --force
    echo -e "${GREEN}✓ Left Docker Swarm${NC}"
else
    echo "Swarm mode still active."
fi

# Prune system
echo -e "\n${YELLOW}Do you want to prune unused Docker resources?${NC}"
read -p "Prune system? (yes/no): " prune

if [ "$prune" == "yes" ]; then
    docker system prune -f
    echo -e "${GREEN}✓ System pruned${NC}"
fi

echo -e "\n${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    ✓ Cleanup Complete                             ║
║                                                                   ║
║   To rebuild the environment, run:                                ║
║   ./scripts/init-all.sh                                           ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

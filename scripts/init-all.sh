#!/bin/bash

# Master initialization script for all Docker Swarm environments
# This script sets up DEV, QA, and PROD environments, plus Jenkins and Registry

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   Docker Swarm Lab - Complete Environment Initialization         ║
║                                                                   ║
║   This will set up:                                               ║
║   - Docker Swarm cluster                                          ║
║   - DEV, QA, and PROD environments                                ║
║   - Portainer for each environment                                ║
║   - Jenkins CI/CD server                                          ║
║   - Local Docker Registry                                         ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if Docker is running
echo -e "${YELLOW}Checking Docker...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}\n"

# Step 1: Initialize Swarm environments
echo -e "${YELLOW}========================================"
echo "Step 1: Initializing Swarm Environments"
echo "========================================${NC}"

cd "$PROJECT_ROOT"

echo "Initializing DEV environment..."
bash infrastructure/swarm/init-dev.sh

echo -e "\nInitializing QA environment..."
bash infrastructure/swarm/init-qa.sh

echo -e "\nInitializing PROD environment..."
bash infrastructure/swarm/init-prod.sh

# Step 2: Deploy Docker Registry
echo -e "\n${YELLOW}========================================"
echo "Step 2: Deploying Docker Registry"
echo "========================================${NC}"

docker stack deploy -c infrastructure/registry/stack.yml registry
echo -e "${GREEN}✓ Registry deployed${NC}"

echo "Waiting for registry to be ready..."
sleep 10

# Step 3: Deploy Portainer instances
echo -e "\n${YELLOW}========================================"
echo "Step 3: Deploying Portainer Instances"
echo "========================================${NC}"

echo "Deploying Portainer for DEV..."
docker stack deploy -c infrastructure/portainer/stack.dev.yml portainer-dev

echo "Deploying Portainer for QA..."
docker stack deploy -c infrastructure/portainer/stack.qa.yml portainer-qa

echo "Deploying Portainer for PROD..."
docker stack deploy -c infrastructure/portainer/stack.prod.yml portainer-prod

echo -e "${GREEN}✓ All Portainer instances deployed${NC}"

# Step 4: Build and Deploy Jenkins
echo -e "\n${YELLOW}========================================"
echo "Step 4: Building and Deploying Jenkins"
echo "========================================${NC}"

echo "Building custom Jenkins image..."
cd infrastructure/jenkins
docker build -t docker-swarm-lab-jenkins:latest .
cd "$PROJECT_ROOT"

echo "Deploying Jenkins..."
docker stack deploy -c infrastructure/jenkins/stack.yml jenkins

echo -e "${GREEN}✓ Jenkins deployed${NC}"

# Step 5: Wait for services to start
echo -e "\n${YELLOW}========================================"
echo "Step 5: Waiting for Services to Start"
echo "========================================${NC}"

echo "This may take a few minutes..."
sleep 30

# Step 6: Display status
echo -e "\n${YELLOW}========================================"
echo "Step 6: Checking Service Status"
echo "========================================${NC}"

docker service ls

# Step 7: Display summary
echo -e "\n${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    🎉 Setup Complete! 🎉                          ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Access your services:${NC}\n"
echo -e "  ${YELLOW}Jenkins:${NC}         http://localhost:8080"
echo -e "  ${YELLOW}Registry:${NC}        http://localhost:5000"
echo -e "  ${YELLOW}Portainer DEV:${NC}   http://localhost:9000"
echo -e "  ${YELLOW}Portainer QA:${NC}    http://localhost:9001"
echo -e "  ${YELLOW}Portainer PROD:${NC}  http://localhost:9002"
echo ""
echo -e "${BLUE}Initial Setup Notes:${NC}\n"
echo "  1. Jenkins initial admin password:"
echo "     docker exec \$(docker ps -q -f name=jenkins) cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "  2. Set up Portainer admin accounts at each URL (first time only)"
echo ""
echo "  3. Configure Jenkins:"
echo "     - Create a new Pipeline job"
echo "     - Point to Jenkinsfile in pipelines/Jenkinsfile"
echo "     - Configure Git repository"
echo ""
echo -e "${BLUE}Next Steps:${NC}\n"
echo "  1. Build and push the application image:"
echo "     cd app && docker build -t localhost:5000/swarm-lab-app:1.0.0 ."
echo "     docker push localhost:5000/swarm-lab-app:1.0.0"
echo ""
echo "  2. Deploy to environments:"
echo "     ./scripts/deploy.sh dev"
echo "     ./scripts/deploy.sh qa"
echo "     ./scripts/deploy.sh prod"
echo ""
echo -e "${GREEN}Happy DevOps! 🚀${NC}"
echo ""

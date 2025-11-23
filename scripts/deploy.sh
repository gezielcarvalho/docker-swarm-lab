#!/bin/bash

# Deployment script for specific environments
# Usage: ./deploy.sh [dev|qa|prod] [version]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get arguments
ENV=$1
VERSION=${2:-latest}

# Validate environment
if [ -z "$ENV" ]; then
    echo -e "${RED}Error: Environment not specified${NC}"
    echo "Usage: ./deploy.sh [dev|qa|prod] [version]"
    echo "Example: ./deploy.sh dev 1.0.0"
    exit 1
fi

if [[ ! "$ENV" =~ ^(dev|qa|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment '${ENV}'${NC}"
    echo "Valid environments: dev, qa, prod"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}"
echo "========================================"
echo "Deploying to ${ENV^^} Environment"
echo "========================================"
echo -e "${NC}"

# Check if swarm is active
if ! docker info | grep -q "Swarm: active"; then
    echo -e "${RED}Error: Docker Swarm is not active${NC}"
    echo "Run ./scripts/init-all.sh first"
    exit 1
fi

# Environment-specific settings
case $ENV in
    dev)
        STACK_FILE="$PROJECT_ROOT/stacks/app.dev.yml"
        STACK_NAME="app-dev"
        PORT=3000
        ;;
    qa)
        STACK_FILE="$PROJECT_ROOT/stacks/app.qa.yml"
        STACK_NAME="app-qa"
        PORT=3001
        echo -e "${YELLOW}Warning: Deploying to QA environment${NC}"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted."
            exit 0
        fi
        ;;
    prod)
        STACK_FILE="$PROJECT_ROOT/stacks/app.prod.yml"
        STACK_NAME="app-prod"
        PORT=3002
        echo -e "${RED}"
        echo "========================================"
        echo "WARNING: PRODUCTION DEPLOYMENT"
        echo "========================================"
        echo -e "${NC}"
        read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted."
            exit 0
        fi
        ;;
esac

echo -e "${YELLOW}Environment:${NC} ${ENV^^}"
echo -e "${YELLOW}Version:${NC}     $VERSION"
echo -e "${YELLOW}Stack File:${NC}  $STACK_FILE"
echo -e "${YELLOW}Stack Name:${NC}  $STACK_NAME"
echo ""

# Deploy stack
echo -e "${YELLOW}Deploying stack...${NC}"
VERSION=$VERSION docker stack deploy \
    -c "$STACK_FILE" \
    --with-registry-auth \
    "$STACK_NAME"

echo -e "${GREEN}✓ Stack deployed${NC}\n"

# Wait for service to be ready
echo -e "${YELLOW}Waiting for service to be ready...${NC}"
sleep 10

# Check service status
echo -e "\n${YELLOW}Service Status:${NC}"
docker service ls --filter "label=environment=$ENV"

# Health check
echo -e "\n${YELLOW}Performing health check...${NC}"
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt/$max_attempts..."
    
    if curl -sf "http://localhost:$PORT/health" > /dev/null; then
        echo -e "${GREEN}✓ Health check passed${NC}\n"
        
        # Get app info
        echo -e "${BLUE}Application Info:${NC}"
        curl -s "http://localhost:$PORT/api/info" | json_pp || curl -s "http://localhost:$PORT/api/info"
        echo ""
        
        echo -e "${GREEN}"
        echo "========================================"
        echo "Deployment Successful!"
        echo "========================================"
        echo -e "${NC}"
        echo "Access application at: http://localhost:$PORT"
        echo "View in Portainer:"
        case $ENV in
            dev)  echo "  http://localhost:9000" ;;
            qa)   echo "  http://localhost:9001" ;;
            prod) echo "  http://localhost:9002" ;;
        esac
        echo ""
        exit 0
    fi
    
    attempt=$((attempt + 1))
    sleep 5
done

echo -e "${RED}"
echo "========================================"
echo "Health Check Failed"
echo "========================================"
echo -e "${NC}"
echo "The service was deployed but is not responding to health checks."
echo "Check the logs:"
echo "  docker service logs ${STACK_NAME}_app"
echo ""
exit 1

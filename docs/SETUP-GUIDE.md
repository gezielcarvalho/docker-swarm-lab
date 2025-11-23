# Setup Guide

Complete step-by-step guide to set up the Docker Swarm Lab environment.

## Prerequisites

### Required Software

1. **Docker Desktop** (Windows with WSL2 backend)

   - Version: 24.0 or higher
   - WSL2 integration enabled
   - At least 8GB RAM allocated to Docker
   - At least 50GB disk space

2. **WSL (Windows Subsystem for Linux)**

   - Ubuntu 20.04 or 22.04 recommended
   - Git installed
   - Node.js 20+ installed

3. **Git**
   - For version control

### System Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 16GB minimum, 32GB recommended
- **Disk**: 50GB+ free space
- **OS**: Windows 10/11 with WSL2

## Installation Steps

### Step 1: Clone the Repository

```bash
cd /mnt/c/Users/your-username/projects
git clone <repository-url>
cd docker-swarm-lab
```

### Step 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x infrastructure/swarm/*.sh
```

### Step 3: Verify Docker

```bash
# Check Docker is running
docker --version
docker info

# Verify WSL can access Docker
docker ps
```

### Step 4: Initialize All Environments

Run the master initialization script:

```bash
./scripts/init-all.sh
```

This script will:

- ✅ Initialize Docker Swarm
- ✅ Create networks for DEV, QA, and PROD
- ✅ Deploy Docker Registry
- ✅ Deploy Portainer instances
- ✅ Build and deploy Jenkins

**Expected duration:** 5-10 minutes

### Step 5: Configure Portainer

Access each Portainer instance and create admin accounts:

1. **DEV**: http://localhost:9000

   - Create admin user/password
   - Connect to local Docker environment

2. **QA**: http://localhost:9001

   - Create admin user/password
   - Connect to local Docker environment

3. **PROD**: http://localhost:9002
   - Create admin user/password
   - Connect to local Docker environment

### Step 6: Configure Jenkins

1. **Get initial admin password:**

```bash
docker exec $(docker ps -q -f name=jenkins) cat /var/jenkins_home/secrets/initialAdminPassword
```

2. **Access Jenkins**: http://172.22.226.17:8080/jenkins (replace with your WSL IP)

3. **Complete setup wizard:**

   - Enter admin password
   - Install suggested plugins
   - Create admin user
   - Configure Jenkins URL

4. **Create Pipeline Job:**
   - New Item → Pipeline
   - Name: "Docker Swarm Lab Pipeline"
   - Pipeline script from SCM
   - SCM: Git
   - Repository URL: (your repository)
   - Script Path: pipelines/Jenkinsfile

### Step 7: Build and Push Initial Image

```bash
cd app

# Build image
docker build -t localhost:5000/swarm-lab-app:1.0.0 .

# Tag as latest
docker tag localhost:5000/swarm-lab-app:1.0.0 localhost:5000/swarm-lab-app:latest

# Push to local registry
docker push localhost:5000/swarm-lab-app:1.0.0
docker push localhost:5000/swarm-lab-app:latest
```

### Step 8: Deploy to Environments

Deploy to DEV:

```bash
./scripts/deploy.sh dev 1.0.0
```

Deploy to QA (with approval):

```bash
./scripts/deploy.sh qa 1.0.0
```

Deploy to PROD (with approval):

```bash
./scripts/deploy.sh prod 1.0.0
```

### Step 9: Verify Deployments

Check each environment:

```bash
# DEV
curl http://localhost:3000/health
curl http://localhost:3000/api/info

# QA
curl http://localhost:3001/health
curl http://localhost:3001/api/info

# PROD
curl http://localhost:3002/health
curl http://localhost:3002/api/info
```

View in Portainer:

- DEV: http://localhost:9000
- QA: http://localhost:9001
- PROD: http://localhost:9002

## Development Workflow

### Local Development (WSL)

```bash
cd app

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Run development server
npm run dev

# Run unit tests
npm test

# Or use the script
../scripts/run-tests-wsl.sh
```

### Integration Testing (Docker)

```bash
# From project root
./scripts/run-tests-docker.sh
```

### Code Changes and Deployment

1. **Make code changes** in WSL

2. **Run unit tests:**

   ```bash
   cd app
   npm test
   ```

3. **Run integration tests:**

   ```bash
   cd ..
   ./scripts/run-tests-docker.sh
   ```

4. **Build new version:**

   ```bash
   cd app
   VERSION=1.1.0
   docker build -t localhost:5000/swarm-lab-app:$VERSION .
   docker push localhost:5000/swarm-lab-app:$VERSION
   ```

5. **Deploy via script:**

   ```bash
   cd ..
   ./scripts/deploy.sh dev 1.1.0
   ```

6. **Or trigger Jenkins pipeline:**
   - Commit and push changes
   - Jenkins webhook triggers automatically
   - Or manually trigger in Jenkins UI

## Using Jenkins Pipeline

### Manual Trigger

1. Open Jenkins: http://localhost:8080
2. Select your pipeline job
3. Click "Build Now"
4. Monitor progress in Blue Ocean view

### Automated Trigger (Git Webhook)

Configure webhook in your Git repository:

- Payload URL: http://localhost:8080/github-webhook/
- Content type: application/json
- Events: Push events

### Pipeline Stages

The pipeline will:

1. ✅ Checkout code
2. ✅ Install dependencies
3. ✅ Run linter
4. ✅ Run unit tests
5. ✅ Run integration tests
6. ✅ Build Docker image
7. ✅ Push to registry
8. ✅ Deploy to DEV (automatic)
9. ⏸️ Wait for QA approval
10. ✅ Deploy to QA
11. ⏸️ Wait for PROD approval
12. ✅ Deploy to PROD
13. ✅ Run smoke tests

### Approving Deployments

When pipeline reaches approval stage:

1. Go to Jenkins pipeline view
2. Click "Input requested"
3. Review deployment details
4. Click "Deploy" or "Abort"

## Monitoring and Management

### Portainer

Access Portainer for visual management:

- **Stacks**: View deployed applications
- **Services**: Check service status and replicas
- **Networks**: Inspect network configurations
- **Volumes**: Manage persistent data
- **Logs**: View service logs

### Docker CLI

Useful commands:

```bash
# List all stacks
docker stack ls

# List services in a stack
docker stack services app-dev

# View service logs
docker service logs app-dev_app

# Scale a service
docker service scale app-prod_app=5

# Inspect service
docker service inspect app-dev_app

# Check service tasks
docker service ps app-dev_app
```

### Health Checks

All environments expose health endpoints:

```bash
# DEV
curl http://localhost:3000/health

# QA
curl http://localhost:3001/health

# PROD
curl http://localhost:3002/health
```

## Maintenance

### Updating Jenkins Plugins

```bash
# Access Jenkins container
docker exec -it $(docker ps -q -f name=jenkins) bash

# Update plugins (inside container)
jenkins-plugin-cli --list
```

Or use Jenkins UI: Manage Jenkins → Manage Plugins

### Backing Up Data

```bash
# Backup Jenkins data
docker run --rm -v jenkins_home:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/jenkins-backup.tar.gz /data

# Backup Portainer data
docker run --rm -v portainer_data_dev:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/portainer-dev-backup.tar.gz /data

# Backup Registry data
docker run --rm -v registry_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/registry-backup.tar.gz /data
```

### Restoring from Backup

```bash
# Restore Jenkins
docker run --rm -v jenkins_home:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/jenkins-backup.tar.gz -C /
```

### Cleaning Up Registry

```bash
# Remove old images from registry
docker exec $(docker ps -q -f name=registry) \
  bin/registry garbage-collect /etc/docker/registry/config.yml
```

## Scaling Services

### Scale via CLI

```bash
# Scale DEV (1 replica recommended)
docker service scale app-dev_app=1

# Scale QA (2 replicas recommended)
docker service scale app-qa_app=2

# Scale PROD (3+ replicas)
docker service scale app-prod_app=5
```

### Scale via Portainer

1. Navigate to Services
2. Select service
3. Click "Scale"
4. Set desired replicas
5. Click "Update"

## Troubleshooting Quick Reference

### Services Not Starting

```bash
# Check service status
docker service ls

# View service logs
docker service logs <service-name>

# Inspect service
docker service inspect <service-name>
```

### Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect <network-name>

# Recreate networks
./scripts/cleanup.sh
./scripts/init-all.sh
```

### Registry Issues

```bash
# Check registry logs
docker service logs registry_registry

# Test registry
curl http://localhost:5000/v2/_catalog
```

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Next Steps

Once setup is complete:

1. ✅ Experiment with code changes
2. ✅ Test the CI/CD pipeline
3. ✅ Try scaling services
4. ✅ Practice rollbacks
5. ✅ Explore Portainer features
6. ✅ Monitor resource usage
7. ✅ Implement custom endpoints

## Additional Resources

- [PROJECT-PLAN.md](PROJECT-PLAN.md) - Detailed project overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Jenkins Pipeline Docs](https://www.jenkins.io/doc/book/pipeline/)
- [Portainer Docs](https://docs.portainer.io/)

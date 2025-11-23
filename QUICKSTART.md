# Quick Start Guide

Get up and running with Docker Swarm Lab in under 15 minutes!

## Prerequisites Check

Before starting, ensure you have:

- ✅ Docker Desktop installed and running
- ✅ WSL2 enabled with Ubuntu
- ✅ At least 16GB RAM
- ✅ At least 50GB free disk space
- ✅ Ports available: 3000-3002, 5000, 8080, 9000-9002

## 5-Step Setup

### Step 1: Clone and Navigate

```bash
git clone <your-repo-url>
cd docker-swarm-lab
```

### Step 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x infrastructure/swarm/*.sh
```

### Step 3: Initialize Everything

```bash
./scripts/init-all.sh
```

⏱️ **Wait 5-10 minutes** for all services to start.

### Step 4: Configure Services

**Portainer** (create admin accounts):

- DEV: http://localhost:9000
- QA: http://localhost:9001
- PROD: http://localhost:9002

**Jenkins**:

```bash
# Get admin password
docker exec $(docker ps -q -f name=jenkins) cat /var/jenkins_home/secrets/initialAdminPassword
```

- Open: http://localhost:8080
- Complete setup wizard
- Install suggested plugins

### Step 5: Deploy Application

```bash
# Build and push image
cd app
docker build -t localhost:5000/swarm-lab-app:1.0.0 .
docker push localhost:5000/swarm-lab-app:1.0.0

# Deploy to all environments
cd ..
./scripts/deploy.sh dev 1.0.0
./scripts/deploy.sh qa 1.0.0
./scripts/deploy.sh prod 1.0.0
```

## Verify Deployment

Test each environment:

```bash
# DEV (port 3000)
curl http://localhost:3000/health
curl http://localhost:3000/api/items

# QA (port 3001)
curl http://localhost:3001/health

# PROD (port 3002)
curl http://localhost:3002/health
```

## Access Points

| Service            | URL                   | Purpose          |
| ------------------ | --------------------- | ---------------- |
| **Jenkins**        | http://localhost:8080 | CI/CD Pipeline   |
| **Registry**       | http://localhost:5000 | Docker Images    |
| **Portainer DEV**  | http://localhost:9000 | DEV Management   |
| **Portainer QA**   | http://localhost:9001 | QA Management    |
| **Portainer PROD** | http://localhost:9002 | PROD Management  |
| **App DEV**        | http://localhost:3000 | DEV Application  |
| **App QA**         | http://localhost:3001 | QA Application   |
| **App PROD**       | http://localhost:3002 | PROD Application |

## Test the CI/CD Pipeline

1. **Create a Jenkins pipeline job**:

   - Name: "Docker Swarm Lab Pipeline"
   - Type: Pipeline
   - Script Path: `pipelines/Jenkinsfile`

2. **Run the pipeline**:

   - Click "Build Now"
   - Monitor in Blue Ocean

3. **Approve deployments**:
   - When prompted for QA
   - When prompted for PROD

## Common Commands

```bash
# View all services
docker service ls

# View application logs
docker service logs app-dev_app

# Scale production
docker service scale app-prod_app=5

# Complete cleanup
./scripts/cleanup.sh

# Reinitialize
./scripts/init-all.sh
```

## Next Steps

- 📖 Read the [Full Setup Guide](docs/SETUP-GUIDE.md)
- 🏗️ Explore [Architecture](docs/ARCHITECTURE.md)
- 🔧 Check [Jenkins Setup](docs/JENKINS-SETUP.md)
- 🐛 See [Troubleshooting](docs/TROUBLESHOOTING.md)

## Need Help?

If something goes wrong:

1. Check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. View service logs: `docker service logs <service-name>`
3. Reset everything: `./scripts/cleanup.sh` then `./scripts/init-all.sh`

---

**🎉 You're all set! Happy learning!**

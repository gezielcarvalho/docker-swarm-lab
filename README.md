# Docker Swarm Lab - CI/CD Simulation

A comprehensive simulation environment for Node.js development with Docker Swarm orchestration, Jenkins CI/CD pipelines, and Portainer management across DEV, QA, and PROD environments.

## 🎯 Purpose

This project simulates a complete enterprise development workflow:

- **Development**: VSCode in WSL with unit testing
- **Integration Testing**: Docker-based test environment
- **CI/CD**: Jenkins pipeline automation
- **Orchestration**: Docker Swarm with three environments
- **Management**: Portainer for cluster visualization

## 🏗️ Architecture

```
Developer (WSL) → Git → Jenkins → Docker Registry
                                        ↓
                    ┌───────────────────┼───────────────────┐
                    ↓                   ↓                   ↓
              DEV Swarm            QA Swarm            PROD Swarm
              (Port 3000)          (Port 3001)         (Port 3002)
                    ↓                   ↓                   ↓
            Portainer :9000     Portainer :9001     Portainer :9002
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (with WSL2 backend on Windows)
- Git
- Node.js 20+ (in WSL)
- WSL (Ubuntu recommended)

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd docker-swarm-lab

# Initialize all environments
./scripts/init-all.sh

# Access services
# Jenkins: http://localhost:8080
# Portainer DEV: http://localhost:9000
# Portainer QA: http://localhost:9001
# Portainer PROD: http://localhost:9002
# Registry: http://localhost:5000
```

## 📁 Project Structure

```
docker-swarm-lab/
├── app/                    # Node.js application
│   ├── src/               # Source code
│   ├── tests/             # Unit and integration tests
│   └── Dockerfile         # Container image definition
├── infrastructure/         # Infrastructure as Code
│   ├── jenkins/           # Jenkins configuration
│   ├── portainer/         # Portainer stack files
│   ├── registry/          # Docker registry
│   └── swarm/             # Swarm initialization scripts
├── pipelines/             # Jenkins pipeline definitions
├── stacks/                # Docker stack files per environment
├── scripts/               # Automation scripts
└── docs/                  # Documentation
```

## 🔧 Development Workflow

### 1. Local Development (WSL)

```bash
cd app
npm install
npm run dev
npm test                    # Run unit tests
```

### 2. Integration Testing (Docker)

```bash
./scripts/run-tests-docker.sh
```

### 3. Deploy Pipeline

```bash
# Manual trigger deployment
./scripts/deploy.sh dev     # Deploy to DEV
./scripts/deploy.sh qa      # Deploy to QA (requires approval)
./scripts/deploy.sh prod    # Deploy to PROD (requires approval)
```

### 4. Monitor Deployments

- **Jenkins**: http://localhost:8080 - View pipeline execution
- **Portainer DEV**: http://localhost:9000 - Manage DEV cluster
- **Portainer QA**: http://localhost:9001 - Manage QA cluster
- **Portainer PROD**: http://localhost:9002 - Manage PROD cluster

## 🌍 Environments

| Environment | Purpose                | Port | Replicas | Auto-Deploy        |
| ----------- | ---------------------- | ---- | -------- | ------------------ |
| **DEV**     | Development testing    | 3000 | 1        | ✅ Yes             |
| **QA**      | Pre-production testing | 3001 | 2        | ❌ Manual approval |
| **PROD**    | Production             | 3002 | 3        | ❌ Manual approval |

## 📋 CI/CD Pipeline Stages

1. **Checkout** - Pull code from Git
2. **Build** - npm install and build
3. **Unit Tests** - Run Jest tests in WSL/Jenkins
4. **Integration Tests** - Run Docker-based tests
5. **Docker Build** - Create container image
6. **Push** - Upload to registry
7. **Deploy DEV** - Automatic deployment
8. **Approval Gate** - Manual approval for QA
9. **Deploy QA** - Deploy to QA environment
10. **Approval Gate** - Manual approval for PROD
11. **Deploy PROD** - Deploy to production
12. **Smoke Tests** - Verify deployment

## 🛠️ Available Scripts

```bash
./scripts/init-all.sh          # Initialize all environments
./scripts/deploy.sh [env]      # Deploy to specific environment
./scripts/cleanup.sh           # Clean up all resources
./scripts/run-tests-wsl.sh     # Run unit tests in WSL
./scripts/run-tests-docker.sh  # Run integration tests in Docker
```

## 📚 Documentation

- [Project Plan](docs/PROJECT-PLAN.md) - Detailed project overview and implementation plan
- [Architecture](docs/ARCHITECTURE.md) - System architecture and design decisions
- [Setup Guide](docs/SETUP-GUIDE.md) - Step-by-step setup instructions
- [Jenkins Setup](docs/JENKINS-SETUP.md) - Jenkins configuration and plugin setup
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🔑 Key Features

- ✅ **Three isolated Docker Swarm environments**
- ✅ **Jenkins automated CI/CD pipeline**
- ✅ **Portainer visual management per environment**
- ✅ **Local Docker registry**
- ✅ **Rolling updates with zero downtime**
- ✅ **Manual approval gates for QA/PROD**
- ✅ **Health checks and auto-recovery**
- ✅ **WSL-based development workflow**
- ✅ **Complete automation scripts**

## 🎓 Learning Objectives

This lab helps you learn:

- Docker Swarm orchestration
- Jenkins pipeline development
- Multi-environment deployment strategies
- Container registry management
- Infrastructure as Code
- DevOps best practices
- Rolling update strategies
- High availability configurations

## 🤝 Contributing

This is a learning and demonstration project. Feel free to:

- Add new features
- Improve documentation
- Enhance automation scripts
- Add monitoring/logging capabilities
- Extend to multi-host setups

## 📝 License

MIT License - Feel free to use for learning and experimentation

## 🔗 Resources

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

## 🐛 Troubleshooting

If you encounter issues, check:

1. Docker Desktop is running and WSL2 integration is enabled
2. Ports 3000-3002, 8080, 9000-9002, 5000 are available
3. WSL has access to Docker daemon
4. Consult [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## 🎯 Next Steps

After setup:

1. Explore the Node.js application in `app/`
2. Review the Jenkinsfile in `pipelines/`
3. Examine stack files in `stacks/`
4. Run a complete deployment cycle
5. Monitor in Portainer dashboards
6. Experiment with scaling services

---

**Happy Learning! 🚀**

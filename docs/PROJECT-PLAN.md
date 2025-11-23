# Docker Swarm Lab - Project Plan

## Overview

This project simulates a complete Node.js development and deployment cycle that mirrors real-world enterprise workflows:

- **Development**: VSCode in WSL environment
- **Testing**: Unit tests in WSL, Integration tests in Docker
- **CI/CD**: Jenkins pipeline automation (replacing Azure DevOps)
- **Orchestration**: Docker Swarm with 3 environments (DEV, QA, PROD)
- **Management**: Portainer for cluster visualization and management

## Architecture

```
[Developer Workspace - WSL]
    ↓ (code push)
[Git Repository]
    ↓ (webhook trigger)
[Jenkins Master - Docker Service]
    ↓ (build → test → dockerize)
[Docker Registry]
    ↓ (deploy)
[Docker Swarm Environments]
    ├── DEV Cluster (auto-deploy)
    ├── QA Cluster (manual approval)
    └── PROD Cluster (manual approval)
         ↓ (monitored by)
[Portainer Instances]
    ├── DEV Dashboard (port 9000)
    ├── QA Dashboard (port 9001)
    └── PROD Dashboard (port 9002)
```

## Components

### 1. Sample Node.js Application

**Features:**

- Express.js REST API
- Unit tests (Jest)
- Integration tests (Supertest)
- Health check endpoint
- Environment-aware configuration
- Dockerfile for containerization

**Structure:**

```
app/
├── src/
│   ├── index.js          # Application entry point
│   ├── routes/           # API routes
│   ├── controllers/      # Business logic
│   └── config/           # Configuration
├── tests/
│   ├── unit/             # Unit tests (run in WSL)
│   └── integration/      # Integration tests (run in Docker)
├── package.json
├── Dockerfile
└── .dockerignore
```

### 2. Docker Swarm Infrastructure

**Three Separate Environments:**

#### DEV Environment

- **Purpose**: Continuous deployment from main branch
- **Swarm Manager**: Port 2377
- **Portainer**: Port 9000
- **Application**: Port 3000
- **Auto-deploy**: Yes

#### QA Environment

- **Purpose**: Pre-production testing
- **Swarm Manager**: Port 2378
- **Portainer**: Port 9001
- **Application**: Port 3001
- **Auto-deploy**: Manual approval required

#### PROD Environment

- **Purpose**: Production environment
- **Swarm Manager**: Port 2379
- **Portainer**: Port 9002
- **Application**: Port 3002
- **Auto-deploy**: Manual approval required

**Deployment Strategy:**

- Single Docker host with multiple swarm clusters
- Overlay networks for service isolation
- Rolling updates with health checks
- Service replicas for high availability

### 3. Jenkins CI/CD Pipeline

**Jenkins Master Configuration:**

- **Image**: `jenkins/jenkins:lts`
- **Port**: 8080 (Web UI), 50000 (Agent communication)
- **Volumes**:
  - `/var/jenkins_home` - Persistent configuration
  - `/var/run/docker.sock` - Docker socket for pipeline execution
- **Deployment**: Docker service in swarm

**Required Plugins:**

1. Docker Pipeline
2. Docker Plugin
3. Blue Ocean
4. Pipeline
5. Git Plugin
6. NodeJS Plugin
7. Credentials Binding
8. SSH Agent

**Pipeline Stages:**

```
1. Checkout
   └── Pull code from Git repository

2. Build
   └── npm install
   └── npm run build

3. Unit Tests
   └── npm test (runs in WSL/Jenkins container)

4. Integration Tests
   └── docker-compose up -d
   └── npm run test:integration
   └── docker-compose down

5. Docker Build
   └── docker build -t app:${VERSION}
   └── docker tag app:${VERSION} registry/app:${VERSION}

6. Push to Registry
   └── docker push registry/app:${VERSION}

7. Deploy to DEV
   └── docker stack deploy -c stack.dev.yml app-dev
   └── Automatic deployment

8. Deploy to QA
   └── Manual approval gate
   └── docker stack deploy -c stack.qa.yml app-qa

9. Deploy to PROD
   └── Manual approval gate
   └── docker stack deploy -c stack.prod.yml app-prod
   └── Smoke tests
```

### 4. Portainer Management

**Portainer Configuration:**

- **Image**: `portainer/portainer-ce:latest`
- **Deployment**: One instance per environment
- **Access**:
  - DEV: http://localhost:9000
  - QA: http://localhost:9001
  - PROD: http://localhost:9002

**Features Used:**

- Stack visualization
- Service management
- Log viewing
- Resource monitoring
- Secrets management

### 5. Environment-Specific Configurations

**Docker Compose Stack Files:**

- `stack.dev.yml` - DEV environment configuration
- `stack.qa.yml` - QA environment configuration
- `stack.prod.yml` - PROD environment configuration

**Environment Variables:**

```
# DEV
NODE_ENV=development
LOG_LEVEL=debug
DB_REPLICAS=1

# QA
NODE_ENV=staging
LOG_LEVEL=info
DB_REPLICAS=2

# PROD
NODE_ENV=production
LOG_LEVEL=error
DB_REPLICAS=3
```

**Secrets Management:**

- Docker secrets for sensitive data
- Jenkins credentials for registry access
- Environment-specific secret files

### 6. Docker Registry

**Options:**

- **Option A**: Docker Hub (public/private repositories)
- **Option B**: Local Docker Registry container
- **Option C**: Per-environment registry

**Recommended**: Local registry for simulation

- Port: 5000
- Storage: Named volume
- Access: HTTP (local development)

## Project Structure

```
docker-swarm-lab/
├── docs/
│   ├── PROJECT-PLAN.md           # This file
│   ├── SETUP-GUIDE.md            # Step-by-step setup instructions
│   ├── JENKINS-SETUP.md          # Jenkins configuration guide
│   └── TROUBLESHOOTING.md        # Common issues and solutions
├── app/
│   ├── src/
│   ├── tests/
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
├── infrastructure/
│   ├── jenkins/
│   │   ├── Dockerfile            # Custom Jenkins image
│   │   ├── plugins.txt           # Plugin list
│   │   └── stack.yml             # Jenkins deployment
│   ├── portainer/
│   │   ├── stack.dev.yml
│   │   ├── stack.qa.yml
│   │   └── stack.prod.yml
│   ├── registry/
│   │   └── stack.yml             # Local registry
│   └── swarm/
│       ├── init-dev.sh
│       ├── init-qa.sh
│       └── init-prod.sh
├── pipelines/
│   ├── Jenkinsfile               # Main pipeline
│   └── Jenkinsfile.deploy        # Deployment-only pipeline
├── stacks/
│   ├── app.dev.yml               # DEV stack definition
│   ├── app.qa.yml                # QA stack definition
│   └── app.prod.yml              # PROD stack definition
├── scripts/
│   ├── init-all.sh               # Initialize all environments
│   ├── deploy.sh                 # Deploy to specific environment
│   ├── cleanup.sh                # Cleanup all resources
│   ├── run-tests-wsl.sh          # Run unit tests in WSL
│   └── run-tests-docker.sh       # Run integration tests in Docker
├── .gitignore
└── README.md
```

## Development Workflow

### Day-to-Day Development

1. **Local Development** (in WSL)

   ```bash
   cd app
   npm install
   npm run dev
   ```

2. **Run Unit Tests** (in WSL)

   ```bash
   npm test
   ```

3. **Run Integration Tests** (in Docker)

   ```bash
   ./scripts/run-tests-docker.sh
   ```

4. **Commit and Push**

   ```bash
   git add .
   git commit -m "Feature: Add new endpoint"
   git push origin main
   ```

5. **Jenkins Pipeline Triggers**

   - Webhook triggers build automatically
   - Or manually trigger via Jenkins UI

6. **Monitor Deployment**
   - Jenkins UI: http://localhost:8080
   - Portainer DEV: http://localhost:9000
   - Portainer QA: http://localhost:9001
   - Portainer PROD: http://localhost:9002

### Deployment Process

```
Code Push → Git → Webhook → Jenkins
                                ↓
                           Build & Test
                                ↓
                          Docker Build
                                ↓
                         Push to Registry
                                ↓
                    ┌───────────┴───────────┐
                    ↓                       ↓
              Deploy to DEV          Wait for approval
              (automatic)                   ↓
                    ↓                  Deploy to QA
              Monitor in                    ↓
              Portainer            Wait for approval
                                           ↓
                                    Deploy to PROD
                                           ↓
                                    Monitor in
                                    Portainer
```

## Implementation Phases

### Phase 1: Foundation (Week 1)

- [ ] Create sample Node.js application
- [ ] Add unit tests and integration tests
- [ ] Create Dockerfile
- [ ] Set up Git repository

### Phase 2: Infrastructure (Week 1-2)

- [ ] Initialize Docker Swarm environments (DEV, QA, PROD)
- [ ] Deploy Portainer to each environment
- [ ] Set up local Docker registry
- [ ] Create overlay networks

### Phase 3: Jenkins Setup (Week 2)

- [ ] Deploy Jenkins as Docker service
- [ ] Install required plugins
- [ ] Configure Docker access
- [ ] Set up credentials

### Phase 4: Pipeline Creation (Week 2-3)

- [ ] Create Jenkinsfile
- [ ] Configure build stages
- [ ] Add test stages
- [ ] Implement deployment stages
- [ ] Add approval gates

### Phase 5: Environment Configuration (Week 3)

- [ ] Create stack files for each environment
- [ ] Configure environment variables
- [ ] Set up secrets management
- [ ] Configure service replicas

### Phase 6: Automation (Week 3-4)

- [ ] Create initialization scripts
- [ ] Create deployment scripts
- [ ] Create cleanup scripts
- [ ] Add health checks

### Phase 7: Testing & Documentation (Week 4)

- [ ] End-to-end testing
- [ ] Create setup guide
- [ ] Create troubleshooting guide
- [ ] Create demo scenarios

## Success Criteria

- ✅ Node.js app runs with unit and integration tests
- ✅ Three Docker Swarm environments running independently
- ✅ Portainer managing each environment
- ✅ Jenkins pipeline builds and deploys automatically
- ✅ Manual approval gates work for QA and PROD
- ✅ Rolling updates with zero downtime
- ✅ Complete automation via scripts
- ✅ Documentation covers all scenarios

## Next Steps

1. **Immediate**: Create sample Node.js application
2. **Next**: Set up Docker Swarm infrastructure
3. **Then**: Deploy Jenkins and Portainer
4. **Finally**: Create and test pipelines

## Notes

- This is a simulation environment for learning and testing
- All components run on a single Docker host
- Can be extended to multi-host setups
- Suitable for CI/CD experimentation
- Great for DevOps training

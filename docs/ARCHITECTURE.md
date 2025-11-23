# Architecture Documentation

## System Overview

This Docker Swarm lab simulates a complete enterprise CI/CD pipeline with multiple deployment environments, providing a realistic workflow for Node.js application development and deployment.

## Component Architecture

### Infrastructure Layer

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Host                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Swarm DEV    │  │ Swarm QA     │  │ Swarm PROD   │          │
│  │ Port: 2377   │  │ Port: 2378   │  │ Port: 2379   │          │
│  │              │  │              │  │              │          │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │          │
│  │ │Portainer │ │  │ │Portainer │ │  │ │Portainer │ │          │
│  │ │Port: 9000│ │  │ │Port: 9001│ │  │ │Port: 9002│ │          │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │          │
│  │              │  │              │  │              │          │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │          │
│  │ │   App    │ │  │ │   App    │ │  │ │   App    │ │          │
│  │ │Port: 3000│ │  │ │Port: 3001│ │  │ │Port: 3002│ │          │
│  │ │Replicas:1│ │  │ │Replicas:2│ │  │ │Replicas:3│ │          │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │  Jenkins Master      │  │  Docker Registry     │            │
│  │  Port: 8080, 50000   │  │  Port: 5000          │            │
│  └──────────────────────┘  └──────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### Network Architecture

#### Overlay Networks

Each environment has isolated overlay networks:

```
DEV Environment:
├── dev-frontend (overlay)
├── dev-backend (overlay)
└── dev-monitoring (overlay)

QA Environment:
├── qa-frontend (overlay)
├── qa-backend (overlay)
└── qa-monitoring (overlay)

PROD Environment:
├── prod-frontend (overlay)
├── prod-backend (overlay)
└── prod-monitoring (overlay)

Shared:
└── jenkins-network (overlay)
└── registry-network (overlay)
```

#### Port Mapping Strategy

| Service       | DEV  | QA   | PROD | Purpose       |
| ------------- | ---- | ---- | ---- | ------------- |
| Application   | 3000 | 3001 | 3002 | HTTP API      |
| Portainer     | 9000 | 9001 | 9002 | Management UI |
| Swarm Manager | 2377 | 2378 | 2379 | Orchestration |
| Jenkins       | 8080 | -    | -    | CI/CD UI      |
| Registry      | 5000 | -    | -    | Image Storage |

### Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Node.js Application                       │
├─────────────────────────────────────────────────────────────┤
│  Entry Point (src/index.js)                                 │
│       ↓                                                      │
│  Express Server                                             │
│       ↓                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │ Routes   │  │Middleware│  │  Config  │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
│       ↓              ↓              ↓                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │Controllers│ │ Auth/Log │  │   Env    │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
│       ↓                                                      │
│  ┌──────────┐  ┌──────────┐                                │
│  │ Services │  │   DB     │                                │
│  └──────────┘  └──────────┘                                │
└─────────────────────────────────────────────────────────────┘

Endpoints:
├── GET  /health          # Health check
├── GET  /api/info        # App info
├── GET  /api/items       # List items
├── POST /api/items       # Create item
└── GET  /api/items/:id   # Get item
```

### CI/CD Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Jenkins Pipeline Stages                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  1. Checkout (Git SCM)               │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  2. Build (npm install)              │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  3. Unit Tests (Jest in WSL)         │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  4. Integration Tests (Docker)       │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  5. Docker Build & Tag               │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  6. Push to Registry                 │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  7. Deploy to DEV (auto)             │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  8. Approval Gate (manual)           │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  9. Deploy to QA                     │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  10. Approval Gate (manual)          │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  11. Deploy to PROD                  │
        └──────────────────┬───────────────────┘
                           ↓
        ┌──────────────────────────────────────┐
        │  12. Smoke Tests & Notifications     │
        └──────────────────────────────────────┘
```

### Data Flow

#### Development Flow

```
Developer (WSL) → Git → Jenkins Webhook → Build
                                            ↓
                                    Docker Image Build
                                            ↓
                                    Registry Push
                                            ↓
                                    ┌───────┴───────┐
                                    ↓               ↓
                              Swarm DEV       Swarm QA/PROD
                                    ↓               ↓
                              Rolling Update  Manual Approval
                                    ↓               ↓
                                Portainer     Portainer
```

#### Deployment Flow

```
Stack File → Jenkins → Docker CLI → Swarm Manager
                                         ↓
                                    Scheduler
                                         ↓
                        ┌────────────────┼────────────────┐
                        ↓                ↓                ↓
                   Worker Node 1    Worker Node 2    Worker Node 3
                        ↓                ↓                ↓
                   Service Task     Service Task     Service Task
                   (Container)      (Container)      (Container)
                        ↓                ↓                ↓
                   Health Check     Health Check     Health Check
                        ↓                ↓                ↓
                    Load Balancer (Ingress Network)
                                         ↓
                                    End Users
```

### Storage Architecture

#### Persistent Volumes

```
Docker Volumes:
├── jenkins_home
│   └── /var/jenkins_home (Jenkins config, jobs, builds)
├── portainer_data_dev
│   └── /data (Portainer DEV data)
├── portainer_data_qa
│   └── /data (Portainer QA data)
├── portainer_data_prod
│   └── /data (Portainer PROD data)
└── registry_data
    └── /var/lib/registry (Docker images)
```

#### Volume Backup Strategy

- Jenkins: Backup `/var/jenkins_home` daily
- Portainer: Backup configurations before changes
- Registry: Periodic image pruning and backup

### Security Architecture

#### Access Control

```
┌─────────────────────────────────────────┐
│         Authentication Layer             │
├─────────────────────────────────────────┤
│  Jenkins: User/Password + RBAC          │
│  Portainer: Admin/Team Access            │
│  Docker Registry: Token-based            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Network Security                 │
├─────────────────────────────────────────┤
│  - Overlay networks (encrypted)          │
│  - Network segmentation per env          │
│  - TLS for external access               │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Secrets Management               │
├─────────────────────────────────────────┤
│  - Docker Secrets for credentials        │
│  - Jenkins Credentials Store             │
│  - Environment-specific secrets          │
└─────────────────────────────────────────┘
```

#### Secrets Strategy

- Database credentials → Docker Secrets
- API keys → Environment variables (encrypted)
- Registry credentials → Jenkins Credentials
- TLS certificates → Volume mounts

### Scalability Model

#### Service Scaling

```
DEV Environment:
├── App: 1 replica (development)
└── Purpose: Fast iteration

QA Environment:
├── App: 2 replicas (testing)
└── Purpose: Production-like testing

PROD Environment:
├── App: 3+ replicas (high availability)
└── Purpose: Production workload
```

#### Horizontal Scaling

```bash
# Scale service dynamically
docker service scale app-prod=5

# Auto-scaling (future enhancement)
- CPU threshold: 70%
- Memory threshold: 80%
- Request rate: 1000/min
```

### Monitoring & Logging Architecture

#### Logging Strategy

```
Application Logs → Docker Logging Driver → JSON File
                                              ↓
                                    Centralized Logging
                                    (Future: ELK Stack)
```

#### Monitoring Points

- Jenkins: Build status, duration, success rate
- Portainer: Service health, resource usage
- Docker Swarm: Node status, task distribution
- Application: HTTP metrics, response times

### Deployment Strategies

#### Rolling Update

```
Current: v1.0.0 (3 replicas)
         ↓
Step 1: Stop 1 replica, start v1.1.0
Step 2: Health check passes
Step 3: Stop 2nd replica, start v1.1.0
Step 4: Health check passes
Step 5: Stop 3rd replica, start v1.1.0
         ↓
Complete: v1.1.0 (3 replicas)
```

#### Blue-Green (Future Enhancement)

```
Blue Stack (v1.0.0) ← Traffic
Green Stack (v1.1.0) ← No traffic
         ↓
Test Green Stack
         ↓
Switch Traffic to Green
         ↓
Blue Stack (v1.0.0) ← No traffic (standby)
Green Stack (v1.1.0) ← Traffic
```

### Disaster Recovery

#### Backup Strategy

1. **Jenkins**: Automated backup of `/var/jenkins_home`
2. **Portainer**: Configuration export
3. **Registry**: Image manifest backup
4. **Application**: Database dumps (if applicable)

#### Recovery Procedures

```
1. Infrastructure Failure
   → Re-run init scripts
   → Restore volumes from backup
   → Redeploy services

2. Service Failure
   → Docker Swarm auto-restart
   → Manual intervention if needed
   → Rollback to previous version

3. Data Loss
   → Restore from volume backups
   → Replay transaction logs
   → Verify data integrity
```

### Performance Considerations

#### Resource Allocation

```
Jenkins Master:
├── CPU: 2 cores
├── Memory: 4GB
└── Storage: 20GB

Portainer (per instance):
├── CPU: 0.5 core
├── Memory: 512MB
└── Storage: 1GB

Application (per replica):
├── CPU: 1 core
├── Memory: 512MB
└── Storage: 1GB

Registry:
├── CPU: 1 core
├── Memory: 1GB
└── Storage: 50GB
```

#### Network Performance

- Overlay network encryption overhead: ~5-10%
- Ingress load balancing: Round-robin
- Service mesh: Optional (future enhancement)

## Technology Stack

| Component       | Technology      | Version   |
| --------------- | --------------- | --------- |
| Runtime         | Node.js         | 20 LTS    |
| Framework       | Express.js      | 4.x       |
| Testing         | Jest            | 29.x      |
| Container       | Docker          | 24.x      |
| Orchestration   | Docker Swarm    | Native    |
| CI/CD           | Jenkins         | LTS       |
| Management      | Portainer       | CE Latest |
| Registry        | Docker Registry | 2.x       |
| Version Control | Git             | Latest    |

## Future Enhancements

1. **Service Mesh**: Implement Istio or Linkerd
2. **Monitoring**: Add Prometheus + Grafana
3. **Logging**: Centralized with ELK Stack
4. **Database**: Add PostgreSQL cluster
5. **Caching**: Redis cluster
6. **Message Queue**: RabbitMQ or Kafka
7. **API Gateway**: Kong or Traefik
8. **Secret Management**: HashiCorp Vault
9. **Auto-scaling**: Based on metrics
10. **Multi-host**: Expand to multiple Docker hosts

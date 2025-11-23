# Troubleshooting Guide

Common issues and solutions for the Docker Swarm Lab environment.

## Table of Contents

- [Docker Issues](#docker-issues)
- [Swarm Issues](#swarm-issues)
- [Service Deployment Issues](#service-deployment-issues)
- [Network Issues](#network-issues)
- [Registry Issues](#registry-issues)
- [Jenkins Issues](#jenkins-issues)
- [Portainer Issues](#portainer-issues)
- [Application Issues](#application-issues)
- [Performance Issues](#performance-issues)

---

## Docker Issues

### Docker Desktop Not Running

**Symptom:** `Cannot connect to the Docker daemon`

**Solution:**

```bash
# Windows: Start Docker Desktop from Start Menu
# Verify Docker is running
docker info
```

### WSL2 Integration Not Working

**Symptom:** Docker commands not available in WSL

**Solution:**

1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. Enable integration for your WSL distro
4. Restart WSL terminal

### Insufficient Disk Space

**Symptom:** `no space left on device`

**Solution:**

```bash
# Clean up unused resources
docker system prune -a --volumes

# Increase disk allocation in Docker Desktop
# Settings → Resources → Disk image size
```

### Permission Denied

**Symptom:** `permission denied while trying to connect to the Docker daemon socket`

**Solution:**

```bash
# Add user to docker group (WSL)
sudo usermod -aG docker $USER

# Restart WSL or log out and back in
```

---

## Swarm Issues

### Swarm Not Initialized

**Symptom:** `This node is not a swarm manager`

**Solution:**

```bash
# Initialize swarm
docker swarm init

# Or run initialization script
./scripts/init-all.sh
```

### Cannot Join Swarm

**Symptom:** `Error response from daemon: This node is already part of a swarm`

**Solution:**

```bash
# Leave existing swarm
docker swarm leave --force

# Re-initialize
docker swarm init
```

### Multiple Network Interfaces Error

**Symptom:** `could not choose an IP address to advertise since this system has multiple addresses on different interfaces`

**Solution:**

This is common in WSL2 environments. The initialization scripts now automatically detect the correct IP address, but if you need to manually specify:

```bash
# Leave existing swarm if any
docker swarm leave --force

# Find your IP addresses
ip -4 addr show

# Initialize with specific IP (use eth0 IP, not lo)
docker swarm init --advertise-addr 172.22.226.17

# Or just run the updated initialization script
./infrastructure/swarm/init-dev.sh
```

The scripts will automatically:

1. Try eth0 interface first
2. Fall back to docker0 interface
3. Use first non-loopback IP
4. Default to 127.0.0.1 if nothing else works

### Manager Node Issues

**Symptom:** Services not deploying to manager node

**Solution:**

```bash
# Check node status
docker node ls

# Make current node manager (if needed)
docker node promote <node-id>
```

---

## Service Deployment Issues

### Service Fails to Start

**Symptom:** Service shows 0/N replicas running

**Solution:**

```bash
# Check service logs
docker service logs <service-name>

# Inspect service
docker service inspect <service-name>

# Check task status
docker service ps <service-name> --no-trunc

# Common causes:
# 1. Image not found in registry
# 2. Network not created
# 3. Volume not created
# 4. Port already in use
```

### Image Pull Errors

**Symptom:** `failed to pull image`

**Solution:**

```bash
# Check if registry is running
docker service ls | grep registry

# Verify image exists in registry
curl http://localhost:5000/v2/_catalog

# Push image to registry
docker push localhost:5000/swarm-lab-app:latest

# Check registry authentication
docker stack deploy --with-registry-auth ...
```

### Port Already in Use

**Symptom:** `port is already allocated`

**Solution:**

```bash
# Find process using port
# Windows PowerShell:
netstat -ano | findstr :8080

# Kill process or change port in stack file
```

### Health Check Failures

**Symptom:** Service constantly restarting

**Solution:**

```bash
# Check application logs
docker service logs app-dev_app

# Verify health endpoint works
docker exec <container-id> curl http://localhost:3000/health

# Increase health check timeouts in stack file
healthcheck:
  start_period: 60s  # Increase this
  retries: 5         # Increase this
```

---

## Network Issues

### Network Not Found

**Symptom:** `network <name> not found`

**Solution:**

```bash
# Recreate networks
./infrastructure/swarm/init-dev.sh
./infrastructure/swarm/init-qa.sh
./infrastructure/swarm/init-prod.sh

# Or manually
docker network create --driver overlay --attachable dev-frontend
```

### Cannot Connect Between Services

**Symptom:** Services can't communicate

**Solution:**

```bash
# Verify services are on same network
docker service inspect app-dev_app | grep Networks

# Test connectivity
docker exec <container-id> ping <service-name>

# Ensure network is attachable
docker network inspect dev-backend | grep Attachable
```

### DNS Resolution Issues

**Symptom:** `could not resolve host`

**Solution:**

```bash
# Use service names, not container names
# Correct: http://app-dev_app:3000
# Incorrect: http://container-xyz:3000

# Check Docker DNS
docker exec <container-id> nslookup app-dev_app
```

---

## Registry Issues

### Registry Not Accessible

**Symptom:** `connection refused` when pushing/pulling

**Solution:**

```bash
# Check registry service
docker service ls | grep registry

# Test registry
curl http://localhost:5000/v2/

# Restart registry
docker service update --force registry_registry
```

### TLS/HTTPS Errors

**Symptom:** `server gave HTTP response to HTTPS client`

**Solution:**

```bash
# Add insecure registry to Docker daemon
# Docker Desktop → Settings → Docker Engine
# Add:
{
  "insecure-registries": ["localhost:5000"]
}

# Restart Docker Desktop
```

### Registry Out of Space

**Symptom:** `no space left on device`

**Solution:**

```bash
# Clean up old images
docker exec <registry-container> \
  bin/registry garbage-collect /etc/docker/registry/config.yml

# Prune unused images
docker image prune -a
```

---

## Jenkins Issues

### Cannot Access Jenkins UI

**Symptom:** Jenkins at http://localhost:8080 not loading

**Solution:**

```bash
# Check Jenkins service
docker service ls | grep jenkins

# Check Jenkins logs
docker service logs jenkins_jenkins

# Wait for Jenkins to fully start (can take 2-3 minutes)

# Get Jenkins URL
docker service inspect jenkins_jenkins | grep PublishedPort
```

### Initial Admin Password Not Found

**Symptom:** Can't find admin password

**Solution:**

```bash
# Get password from container
docker exec $(docker ps -q -f name=jenkins) \
  cat /var/jenkins_home/secrets/initialAdminPassword

# If container not found, check service
docker service ps jenkins_jenkins
```

### Plugin Installation Fails

**Symptom:** Jenkins plugins won't install

**Solution:**

```bash
# Rebuild Jenkins image with updated plugins
cd infrastructure/jenkins
docker build -t docker-swarm-lab-jenkins:latest .

# Update Jenkins service
docker service update --force jenkins_jenkins
```

### Pipeline Build Fails

**Symptom:** Jenkins pipeline exits with error

**Solution:**

```bash
# Check Jenkins has Docker access
docker exec <jenkins-container> docker ps

# Verify Docker socket is mounted
docker service inspect jenkins_jenkins | grep Mounts

# Check Jenkins logs
docker service logs jenkins_jenkins

# Common issues:
# 1. Docker socket not mounted
# 2. Node.js not installed in Jenkins
# 3. Registry not accessible
# 4. Stack files not found
```

### Docker Socket Permission Denied

**Symptom:** `permission denied while trying to connect to Docker socket`

**Solution:**

```bash
# Grant Jenkins access to Docker socket
docker exec -u root <jenkins-container> \
  chmod 666 /var/run/docker.sock

# Or add jenkins user to docker group in Dockerfile
```

---

## Portainer Issues

### Cannot Access Portainer

**Symptom:** Portainer UI not loading

**Solution:**

```bash
# Check Portainer service
docker service ls | grep portainer

# Verify correct ports
# DEV: 9000, QA: 9001, PROD: 9002

# Check logs
docker service logs portainer-dev_portainer
```

### Portainer Shows No Endpoints

**Symptom:** No Docker environments visible

**Solution:**

1. First time setup: Create admin account
2. Add local endpoint
3. Select "Docker" as environment type
4. Use `/var/run/docker.sock`

### Portainer Data Lost

**Symptom:** Settings/users disappeared after restart

**Solution:**

```bash
# Check volume exists
docker volume ls | grep portainer

# Verify volume is mounted
docker service inspect portainer-dev_portainer | grep Mounts

# Restore from backup if available
```

---

## Application Issues

### Application Not Responding

**Symptom:** HTTP requests timeout

**Solution:**

```bash
# Check service status
docker service ps app-dev_app

# View application logs
docker service logs app-dev_app

# Test from inside container
docker exec <container-id> curl localhost:3000/health

# Check if port is exposed
docker service inspect app-dev_app | grep PublishedPort
```

### 404 Errors on All Endpoints

**Symptom:** All API calls return 404

**Solution:**

```bash
# Verify application started correctly
docker service logs app-dev_app | grep "listening on"

# Check environment variables
docker service inspect app-dev_app | grep Env

# Test endpoints directly
curl http://localhost:3000/health
curl http://localhost:3000/api/info
```

### Database Connection Errors

**Symptom:** `ECONNREFUSED` or database errors

**Solution:**

```bash
# Check if database service is running (if applicable)
docker service ls

# Verify database connection string
docker service inspect app-dev_app | grep -A 10 Env

# Check network connectivity
docker exec <app-container> ping <db-service-name>
```

### Memory/CPU Issues

**Symptom:** Application slow or crashes

**Solution:**

```bash
# Check resource usage
docker stats

# Increase resource limits in stack file
resources:
  limits:
    memory: 1G
    cpus: '2'

# Update service
docker stack deploy -c stacks/app.dev.yml app-dev
```

---

## Performance Issues

### Slow Service Updates

**Symptom:** Deployments take very long

**Solution:**

```bash
# Reduce update parallelism
update_config:
  parallelism: 2  # Increase this
  delay: 5s       # Reduce this

# Use order: start-first for faster updates
update_config:
  order: start-first
```

### High Memory Usage

**Symptom:** Docker using too much RAM

**Solution:**

```bash
# Check resource usage
docker stats

# Clean up unused containers/images
docker system prune -a

# Reduce service replicas
docker service scale app-prod_app=2

# Increase Docker Desktop memory allocation
# Settings → Resources → Memory
```

### Slow Build Times

**Symptom:** Docker builds take forever

**Solution:**

```bash
# Use BuildKit
export DOCKER_BUILDKIT=1

# Clean build cache
docker builder prune

# Use multi-stage builds (already in Dockerfile)

# Add .dockerignore to exclude unnecessary files
```

---

## General Debugging Commands

### Inspect Everything

```bash
# List all stacks
docker stack ls

# List all services
docker service ls

# List all containers
docker ps -a

# List all networks
docker network ls

# List all volumes
docker volume ls

# List all images
docker images
```

### View Logs

```bash
# Service logs
docker service logs <service-name>

# Follow logs
docker service logs -f <service-name>

# Last 100 lines
docker service logs --tail 100 <service-name>

# With timestamps
docker service logs --timestamps <service-name>
```

### Inspect Resources

```bash
# Inspect service
docker service inspect <service-name>

# Inspect stack
docker stack ps <stack-name>

# Inspect network
docker network inspect <network-name>

# Inspect volume
docker volume inspect <volume-name>
```

### Emergency Procedures

**Complete Reset:**

```bash
# Stop everything
./scripts/cleanup.sh

# Answer "yes" to all prompts

# Reinitialize
./scripts/init-all.sh
```

**Rollback Deployment:**

```bash
# Rollback to previous version
docker service rollback app-prod_app

# Or deploy specific version
VERSION=1.0.0 ./scripts/deploy.sh prod 1.0.0
```

**Force Service Update:**

```bash
# Force recreate service
docker service update --force <service-name>
```

---

## Getting Help

If issues persist:

1. **Check Docker logs:**

   ```bash
   docker service logs <service-name> --tail 200
   ```

2. **Inspect service details:**

   ```bash
   docker service inspect <service-name> --pretty
   ```

3. **Check system resources:**

   ```bash
   docker stats
   ```

4. **Review documentation:**

   - [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
   - [Jenkins Docs](https://www.jenkins.io/doc/)
   - [Portainer Docs](https://docs.portainer.io/)

5. **Complete reset:**
   ```bash
   ./scripts/cleanup.sh
   ./scripts/init-all.sh
   ```

## Common Error Messages

| Error                              | Cause                 | Solution                                |
| ---------------------------------- | --------------------- | --------------------------------------- |
| `no space left on device`          | Disk full             | `docker system prune -a`                |
| `port is already allocated`        | Port in use           | Change port or stop conflicting service |
| `network not found`                | Network missing       | Run init scripts                        |
| `image not found`                  | Not in registry       | Build and push image                    |
| `This node is not a swarm manager` | Swarm not initialized | `docker swarm init`                     |
| `permission denied`                | Docker socket access  | Check user permissions                  |
| `connection refused`               | Service not running   | Check service status                    |

---

**Remember:** Most issues can be resolved by running `./scripts/cleanup.sh` followed by `./scripts/init-all.sh` for a fresh start!

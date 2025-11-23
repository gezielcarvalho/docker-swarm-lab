# Jenkins Setup and Configuration

Complete guide for setting up and configuring Jenkins for the Docker Swarm Lab CI/CD pipeline.

## Initial Setup

### 1. Access Jenkins

After running `./scripts/init-all.sh`, Jenkins will be available at:

- **URL**: http://172.22.226.17:8080/jenkins (replace with your WSL IP)
- **Wait time**: 2-3 minutes for initial startup

> **Note:** Jenkins runs with `--prefix=/jenkins` context path.
> **WSL2 Users:** Replace `172.22.226.17` with your WSL IP from `hostname -I | awk '{print $1}'`

### 2. Get Initial Admin Password

```bash
# Method 1: From container
docker exec $(docker ps -q -f name=jenkins) cat /var/jenkins_home/secrets/initialAdminPassword

# Method 2: From service logs
docker service logs jenkins_jenkins | grep -A 5 "password"
```

Copy the password (40-character alphanumeric string).

### 3. Complete Setup Wizard

1. **Paste the admin password** in the web interface
2. **Select "Install suggested plugins"**
3. Wait for plugin installation (5-10 minutes)
4. **Create Admin User:**
   - Username: `admin`
   - Password: (choose a strong password)
   - Full name: `Admin`
   - Email: `admin@localhost`
5. **Jenkins URL**: Keep default or use `http://172.22.226.17:8080/jenkins`
6. Click "Start using Jenkins"

## Plugin Configuration

### Required Plugins (Already Included)

The custom Jenkins image includes these pre-installed plugins:

- ✅ **Docker Pipeline** - Build and run in Docker containers
- ✅ **Docker Plugin** - Docker integration
- ✅ **Blue Ocean** - Modern pipeline UI
- ✅ **Git Plugin** - Git repository integration
- ✅ **Pipeline** - Pipeline support
- ✅ **Credentials Binding** - Secure credential handling
- ✅ **SSH Agent** - SSH key management
- ✅ **NodeJS Plugin** - Node.js environment
- ✅ **AnsiColor** - Colored console output
- ✅ **Timestamper** - Log timestamps

### Install Additional Plugins (Optional)

1. **Manage Jenkins** → **Manage Plugins**
2. **Available** tab
3. Search and install:
   - **Slack Notification** (for notifications)
   - **Email Extension** (for email alerts)
   - **GitHub Integration** (for webhooks)

## Create Your First Pipeline

### Method 1: Pipeline from SCM (Recommended)

1. **New Item**
2. Enter name: `Docker Swarm Lab Pipeline`
3. Select **Pipeline**
4. Click **OK**

5. **Configure Pipeline:**
   - **Description**: `CI/CD pipeline for Docker Swarm Lab`
   - **Build Triggers**: Check "Poll SCM" (optional)
     - Schedule: `H/5 * * * *` (every 5 minutes)
6. **Pipeline Section:**

   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**:
     ```
     file:///var/jenkins_home/workspace/repo
     # Or your Git repository URL
     ```
   - **Branch**: `*/main` or `*/master`
   - **Script Path**: `pipelines/Jenkinsfile`

7. **Click "Save"**

### Method 2: Direct Pipeline Script

1. **New Item** → **Pipeline**
2. **Pipeline Section:**

   - **Definition**: Pipeline script
   - **Script**: Copy entire content from `pipelines/Jenkinsfile`

3. **Click "Save"**

## Configure Docker Access

Jenkins needs access to Docker daemon to build images and deploy services.

### Verify Docker Access

```bash
# Execute from Jenkins container
docker exec -u jenkins $(docker ps -q -f name=jenkins) docker ps
```

Should show running containers. If error:

### Fix Docker Socket Permissions

```bash
# Get Jenkins container ID
JENKINS_CONTAINER=$(docker ps -q -f name=jenkins)

# Grant access to Docker socket
docker exec -u root $JENKINS_CONTAINER chmod 666 /var/run/docker.sock
```

## Configure Credentials

### Docker Registry Credentials (if using authenticated registry)

1. **Manage Jenkins** → **Manage Credentials**
2. **Jenkins** → **Global credentials** → **Add Credentials**
3. **Kind**: Username with password
4. **Scope**: Global
5. **Username**: (registry username)
6. **Password**: (registry password)
7. **ID**: `docker-registry`
8. **Description**: `Docker Registry Credentials`
9. **Click "OK"**

### Git Credentials (if using private repository)

1. **Add Credentials**
2. **Kind**: SSH Username with private key
3. **ID**: `git-ssh`
4. **Username**: `git`
5. **Private Key**: Enter directly or from file
6. **Passphrase**: (if key is encrypted)

## Configure Node.js

Jenkins needs Node.js for building the application.

### Method 1: Global Tool Configuration (Alternative)

1. **Manage Jenkins** → **Global Tool Configuration**
2. **NodeJS** section
3. **Add NodeJS**
   - **Name**: `NodeJS 20`
   - **Version**: Select 20.x
   - **Global npm packages**: Leave empty
4. **Click "Save"**

### Method 2: Use Pre-installed Node.js (Current Setup)

Node.js is already installed in the custom Jenkins image. Verify:

```bash
docker exec $(docker ps -q -f name=jenkins) node --version
docker exec $(docker ps -q -f name=jenkins) npm --version
```

## Run Your First Build

### Manual Trigger

1. Go to your pipeline job
2. Click **"Build Now"**
3. Monitor progress in **Build History**
4. Click on build number → **Console Output**

### Expected Build Flow

```
✓ Checkout
✓ Install Dependencies
✓ Lint
✓ Unit Tests
✓ Integration Tests
✓ Build Docker Image
✓ Push to Registry
✓ Deploy to DEV
✓ Verify DEV Deployment
⏸ Approve QA Deployment (manual)
✓ Deploy to QA
✓ Verify QA Deployment
⏸ Approve PROD Deployment (manual)
✓ Deploy to PROD
✓ Verify PROD Deployment
✓ Smoke Tests
```

### Approve Deployments

When pipeline reaches approval stage:

1. **Blue notification** appears: "Input requested"
2. Click **"Input requested"** link
3. Review deployment information
4. Click **"Deploy"** to proceed or **"Abort"** to cancel

## Blue Ocean Interface

For better visualization:

1. Click **"Open Blue Ocean"** (left sidebar)
2. Select your pipeline
3. View visual pipeline flow
4. Monitor stages in real-time
5. See detailed logs per stage

## Environment Variables

Set global environment variables for all builds:

1. **Manage Jenkins** → **Configure System**
2. **Global properties** → **Environment variables**
3. Add variables:

| Name              | Value            | Description      |
| ----------------- | ---------------- | ---------------- |
| `DOCKER_REGISTRY` | `localhost:5000` | Registry URL     |
| `NODE_ENV`        | `production`     | Node environment |

4. **Click "Save"**

## Pipeline Configuration

### Modify Jenkinsfile

The Jenkinsfile is located at `pipelines/Jenkinsfile`. Key sections:

#### Environment Variables

```groovy
environment {
    REGISTRY = 'localhost:5000'
    IMAGE_NAME = 'swarm-lab-app'
    VERSION = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
}
```

#### Approval Timeouts

```groovy
timeout(time: 24, unit: 'HOURS') {
    input message: 'Deploy to QA?'
}
```

Adjust timeout as needed.

#### Deployment Commands

```groovy
sh """
    VERSION=${VERSION} docker stack deploy \
        -c stacks/app.dev.yml \
        --with-registry-auth \
        app-dev
"""
```

## Webhook Configuration (Optional)

### GitHub Webhook

1. **Repository Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `http://localhost:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Select "Just the push event"
5. **Active**: Check
6. **Add webhook**

### GitLab Webhook

1. **Repository Settings** → **Webhooks**
2. **URL**: `http://localhost:8080/project/YOUR_JOB_NAME`
3. **Trigger**: Push events
4. **Add webhook**

### Local Git Hook (Development)

For local testing without external Git:

```bash
# In your repository
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
curl -X POST http://localhost:8080/job/Docker%20Swarm%20Lab%20Pipeline/build
EOF

chmod +x .git/hooks/post-commit
```

## Monitoring and Logs

### Build History

- View all builds: Main page → Build History
- Access specific build: Click build number
- Console output: Build page → Console Output
- Pipeline visualization: Build page → Pipeline Steps

### Service Logs

Check deployment status:

```bash
# DEV
docker service logs app-dev_app

# QA
docker service logs app-qa_app

# PROD
docker service logs app-prod_app
```

### Jenkins Logs

```bash
# View Jenkins service logs
docker service logs jenkins_jenkins

# Follow logs
docker service logs -f jenkins_jenkins
```

## Backup Jenkins Configuration

### Manual Backup

```bash
# Backup Jenkins home directory
docker run --rm \
    -v jenkins_home:/data \
    -v $(pwd):/backup \
    ubuntu tar czf /backup/jenkins-backup-$(date +%Y%m%d).tar.gz /data
```

### Automated Backup (Optional)

Create a backup job in Jenkins:

1. **New Item** → **Freestyle project**
2. **Name**: `Jenkins Backup`
3. **Build Triggers**: Build periodically
   - Schedule: `H 2 * * *` (daily at 2 AM)
4. **Build** → **Execute shell**:
   ```bash
   tar -czf /var/jenkins_home/backups/jenkins-$(date +%Y%m%d).tar.gz \
       /var/jenkins_home/jobs \
       /var/jenkins_home/users \
       /var/jenkins_home/credentials.xml
   ```

## Performance Tuning

### Increase Memory

Edit `infrastructure/jenkins/stack.yml`:

```yaml
resources:
  limits:
    memory: 8G # Increase from 4G
  reservations:
    memory: 4G # Increase from 2G
```

Redeploy:

```bash
docker stack deploy -c infrastructure/jenkins/stack.yml jenkins
```

### Cleanup Old Builds

1. **Manage Jenkins** → **Configure System**
2. For each job: **Discard old builds**
   - Days to keep: 30
   - Max # of builds: 20

## Troubleshooting

### Jenkins Won't Start

```bash
# Check service status
docker service ps jenkins_jenkins

# View logs
docker service logs jenkins_jenkins

# Common issues:
# 1. Insufficient memory
# 2. Port 8080 in use
# 3. Volume mount issues
```

### Builds Failing

```bash
# Check Docker access
docker exec $(docker ps -q -f name=jenkins) docker ps

# Verify Node.js
docker exec $(docker ps -q -f name=jenkins) node --version

# Check workspace
docker exec $(docker ps -q -f name=jenkins) ls -la /var/jenkins_home/workspace
```

### Pipeline Hangs at Approval

- Check Blue Ocean interface
- Click "Input requested"
- Approve or abort manually

### Cannot Push to Registry

```bash
# Verify registry is running
docker service ls | grep registry

# Test registry
curl http://localhost:5000/v2/_catalog

# Check registry in Jenkinsfile
# Must use: localhost:5000 (or registry service name)
```

## Advanced Configuration

### Parallel Builds

Modify Jenkinsfile to run tests in parallel:

```groovy
stage('Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'npm test'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'npm run test:integration'
            }
        }
    }
}
```

### Email Notifications

Install Email Extension plugin, then add to Jenkinsfile:

```groovy
post {
    success {
        emailext (
            subject: "SUCCESS: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: "Build succeeded: ${env.BUILD_URL}",
            to: "team@example.com"
        )
    }
    failure {
        emailext (
            subject: "FAILED: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: "Build failed: ${env.BUILD_URL}",
            to: "team@example.com"
        )
    }
}
```

### Slack Notifications

Install Slack Notification plugin, configure, then add:

```groovy
post {
    always {
        slackSend (
            color: currentBuild.result == 'SUCCESS' ? 'good' : 'danger',
            message: "${env.JOB_NAME} - ${env.BUILD_NUMBER} ${currentBuild.result}"
        )
    }
}
```

## Security Best Practices

1. **Change default admin password** immediately
2. **Enable security**: Manage Jenkins → Configure Global Security
3. **Use Matrix-based security** for fine-grained permissions
4. **Enable CSRF Protection** (enabled by default)
5. **Use credentials** for all sensitive data
6. **Keep plugins updated**: Manage Jenkins → Manage Plugins → Updates
7. **Regular backups** of Jenkins home

## Next Steps

✅ Jenkins is now configured!

Try:

1. Run a manual build
2. Make a code change and commit
3. Watch the pipeline execute
4. Approve QA deployment
5. Approve PROD deployment
6. View results in Portainer

For more help, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

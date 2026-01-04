# DevOps CI/CD Project - Spring Boot Application Deployment

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![SonarQube](https://img.shields.io/badge/code%20quality-sonarqube-blue)]()
[![Jenkins](https://img.shields.io/badge/CI%2FCD-jenkins-red)]()
[![AWS](https://img.shields.io/badge/cloud-AWS-orange)]()

A complete end-to-end DevOps CI/CD pipeline project that demonstrates automated building, testing, deployment, and rollback of a Spring Boot application to AWS EC2 using Jenkins, SonarQube, Nexus, Terraform, and Ansible.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Pipeline Stages](#pipeline-stages)
- [Infrastructure Setup](#infrastructure-setup)
- [Configuration Management](#configuration-management)
- [Deployment](#deployment)
- [Rollback Mechanism](#rollback-mechanism)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

This project implements a complete CI/CD pipeline for a Spring Boot web application with the following capabilities:

- **Automated Build & Test**: Maven-based build with SonarQube code quality checks
- **Artifact Management**: Version-controlled artifacts stored in Nexus Repository
- **Infrastructure as Code**: AWS infrastructure provisioned using Terraform
- **Configuration Management**: Ansible playbooks for server configuration
- **Automated Deployment**: Zero-downtime deployment to AWS EC2
- **Health Monitoring**: Automated health checks post-deployment
- **Automatic Rollback**: Reverts to previous version on deployment failure
- **Quality Gates**: Enforced code quality standards via SonarQube

---

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   GitHub    │────▶│   Jenkins    │────▶│  SonarQube  │
│ Source Code │     │   Pipeline   │     │Quality Gate │
└─────────────┘     └──────┬───────┘     └─────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    Maven     │
                    │    Build     │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    Nexus     │
                    │  Repository  │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   AWS EC2    │
                    │  Deployment  │
                    └──────────────┘
```

### Deployment Flow

1. **Code Commit** → Push to Git repository
2. **CI Trigger** → Jenkins detects changes
3. **Build** → Maven compiles and packages JAR
4. **Quality Check** → SonarQube analysis + Quality Gate
5. **Artifact Store** → Push to Nexus Repository
6. **Deploy** → Pull artifact and deploy to AWS EC2
7. **Health Check** → Verify deployment success
8. **Rollback** → Auto-revert on failure

---

## 🛠️ Technologies Used

### CI/CD Pipeline
- **Jenkins** - Continuous Integration/Deployment orchestration
- **Git** - Version control (bare repository)
- **Maven** - Build automation and dependency management

### Code Quality & Artifact Management
- **SonarQube** - Static code analysis and quality gates
- **Nexus Repository** - Artifact storage and versioning

### Infrastructure & Configuration
- **Terraform** - Infrastructure as Code for AWS provisioning
- **Ansible** - Configuration management and automation
- **AWS EC2** - Cloud compute for application hosting
- **AWS VPC** - Network isolation and security

### Application Stack
- **Spring Boot 3.2.0** - Java application framework
- **Thymeleaf** - Server-side templating
- **Spring Boot Actuator** - Health monitoring endpoints
- **Java 17** - Runtime environment

---

## 📁 Project Structure

```
Devops_project_1/
├── config/                          # Configuration management
│   ├── frontend-play/              # Ansible playbooks
│   │   ├── frontend/               # Frontend role
│   │   │   ├── tasks/             # Ansible tasks
│   │   │   ├── handlers/          # Service handlers
│   │   │   ├── templates/         # Jinja2 templates
│   │   │   └── vars/              # Variables
│   │   └── frontend.yaml          # Main playbook
│   └── inventory.ini               # Ansible inventory
│
├── infra/                          # Infrastructure as Code
│   ├── provider.tf                # AWS provider configuration
│   ├── vpc.tf                     # VPC, Subnets, IGW setup
│   ├── instances.tf               # EC2 instance definitions
│   ├── variables.tf               # Terraform variables
│   └── outputs.tf                 # Output values
│
├── src/                            # Application source code
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/demo/
│   │   │       └── DemoApplication.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── templates/
│   │           └── index.html
│   └── test/
│
├── sonarqubesetup/                # SonarQube setup
│   └── docker-compose.yml
│
├── JenkinsFile                    # Jenkins pipeline definition
├── pom.xml                        # Maven project configuration
├── setup_nexus.sh                 # Nexus setup script
└── README.md                      # This file
```

---

## ✅ Prerequisites

### Local Machine Requirements
- Ubuntu 20.04+ / Linux
- Git 2.x+
- Java 17+
- Maven 3.8+
- Docker & Docker Compose
- Terraform 1.0+
- Ansible 2.9+

### Cloud Requirements
- AWS Account with appropriate permissions
- AWS CLI configured
- SSH key pair for EC2 access

### Tools Setup
- Jenkins server running
- SonarQube instance (Docker)
- Nexus Repository Manager

---

## 🚀 Setup Instructions

### 1. Repository Setup (Bare Repository Workflow)

This project uses a **bare Git repository** as the central repository, which Jenkins clones from. This approach simulates a real-world scenario where Jenkins pulls from a central Git server.

#### Step 1: Create Bare Git Repository (Central Repo)
```bash
# Create bare repository directory
mkdir -p /home/ayush/project_repos
cd /home/ayush/project_repos

# Initialize bare repository (acts as your "GitHub" server)
git init --bare Devops_project_1.git

# This creates a central repository that:
# - Has no working directory
# - Only contains Git metadata
# - Acts as the source of truth for Jenkins
```

#### Step 2: Set Up Your Working Repository
```bash
# Navigate to your source code directory
cd /home/ayush/demo-app

# Initialize git (if not already done)
git init

# Add the bare repository as remote origin
git remote add origin /home/ayush/project_repos/Devops_project_1.git

# Create and checkout dev branch
git checkout -b dev

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Complete CI/CD setup"

# Push to bare repository
git push -u origin dev
```

#### Step 3: Development Workflow

```bash
# Make changes to your code
vim src/main/java/com/example/demo/DemoApplication.java

# Stage changes
git add .

# Commit with meaningful message
git commit -m "Feature: Add new endpoint"

# Push to bare repository (triggers Jenkins)
git push origin dev
```

#### How Jenkins Uses the Bare Repository

Jenkins pipeline **clones directly from the bare repository**:

```groovy
stage('Git Clone') {
    steps {
        echo "The workspace is: $workspace"
        sh "rm -rf $repo_name"
        sh "git clone $repo_url"  // Clones from bare repo
    }
}

stage('Git checkout'){
    steps{
        dir("${repo_name}"){
            sh "git checkout dev"  // Switches to dev branch
        }
    }
}
```

**Key Points:**
- Jenkins workspace is cleaned before each build
- Fresh clone ensures clean build environment
- No local changes interfere with CI/CD process
- Mimics pulling from remote Git server (GitHub/GitLab)

### 2. SonarQube Setup

```bash
# Navigate to setup directory
cd ~/demo-app/sonarqubesetup

# Start SonarQube using Docker Compose
docker-compose up -d

# Verify SonarQube is running
curl http://localhost:9000

# Default credentials:
# Username: admin
# Password: admin123 (change on first login)
```

#### Configure SonarQube
1. Login to SonarQube: `http://localhost:9000`
2. Generate token: My Account → Security → Generate Token
3. Configure webhook:
   - Administration → Configuration → Webhooks
   - Name: `Jenkins`
   - URL: `http://YOUR_MACHINE_IP:8080/sonarqube-webhook/`

### 3. Nexus Repository Setup

```bash
# Run Nexus setup script
cd ~/demo-app
chmod +x setup_nexus.sh
./setup_nexus.sh

# Or manually with Docker:
docker run -d -p 8082:8081 --name nexus sonatype/nexus3

# Get initial admin password
docker exec nexus cat /nexus-data/admin.password

# Access Nexus: http://localhost:8082
```

#### Configure Nexus
1. Login with initial password
2. Set new password: `admin`
3. Create Maven hosted repository: `maven-releases`

### 4. Infrastructure Provisioning with Terraform

```bash
# Navigate to infrastructure directory
cd ~/demo-app/infra

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply infrastructure
terraform apply -auto-approve

# Note the output EC2 public IP
terraform output instance_public_ip
```

**Terraform creates:**
- VPC with CIDR 10.0.0.0/16
- Public subnet
- Internet Gateway
- Route tables
- Security groups (ports 22, 8081, 80)
- EC2 instance (t2.micro)

### 5. Configure Ansible

Update `config/inventory.ini`:
```ini
[webservers]
aws-server ansible_host=YOUR_EC2_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/path/to/your-key.pem
```

Test connection:
```bash
cd ~/demo-app/config
ansible -i inventory.ini webservers -m ping
```

### 6. Jenkins Configuration

#### Install Required Plugins
- Git Plugin
- Maven Integration
- SonarQube Scanner
- Pipeline
- SSH Agent

#### Configure Global Tools
**Manage Jenkins → Global Tool Configuration**

1. **Maven**
   - Name: `Maven`
   - Install automatically: ✅
   - Version: 3.9.x

2. **JDK**
   - Name: `JDK17`
   - JAVA_HOME: `/usr/lib/jvm/java-17-openjdk-amd64`

#### Add Credentials

**Manage Jenkins → Manage Credentials → (global) → Add Credentials**

1. **SonarQube Token**
   - Kind: `Secret text`
   - Secret: `your_sonar_token`
   - ID: `sonar-token`

2. **Nexus Credentials**
   - Kind: `Username with password`
   - Username: `admin`
   - Password: `admin`
   - ID: `nexus-credentials`

3. **AWS SSH Key**
   - Kind: `SSH Username with private key`
   - Username: `ubuntu`
   - Private Key: Paste your AWS PEM key
   - ID: `aws-ssh-key`

#### Configure SonarQube Server
**Manage Jenkins → Configure System → SonarQube servers**
- Name: `SonarQube-Local`
- Server URL: `http://localhost:9000`
- Server authentication token: Select `sonar-token`

#### Create Jenkins Pipeline Job

1. **New Item** → **Pipeline** → Name: `Devops-Project-Pipeline`
2. **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `/home/ayush/project_repos/Devops_project_1.git`
   - Branches to build: `*/dev`
   - Script Path: `JenkinsFile`
3. **Save**

### 7. SSH Key Setup for Deployment

```bash
# On Jenkins server, generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096

# Copy public key to AWS EC2
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@YOUR_EC2_IP

# Or manually:
cat ~/.ssh/id_rsa.pub | ssh ubuntu@YOUR_EC2_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Test connection
ssh ubuntu@YOUR_EC2_IP
```

### 8. Maven Settings Configuration

Create/Update `~/.m2/settings.xml`:
```xml
<settings>
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>admin</password>
    </server>
  </servers>
  
  <profiles>
    <profile>
      <id>sonar</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <properties>
        <sonar.host.url>http://localhost:9000</sonar.host.url>
        <sonar.login>YOUR_SONAR_TOKEN</sonar.login>
      </properties>
    </profile>
  </profiles>
</settings>
```

---

## 🔄 Pipeline Stages (Detailed Explanation)

### Stage 1: Git Clone
**Purpose**: Clean workspace and fetch latest code from bare repository

```groovy
stage('Git Clone') {
    steps {
        echo "The workspace is: $workspace"
        sh "rm -rf $repo_name"              // Remove old code
        sh "git clone $repo_url"            // Clone from bare repo
    }
}
```

**What Happens:**
- Jenkins workspace: `/var/lib/jenkins/workspace/Devops-Project-Pipeline/`
- Removes any existing `Devops_project_1` directory
- Clones fresh copy from `/home/ayush/project_repos/Devops_project_1.git`
- Ensures clean build environment without local modifications

**Variables Used:**
- `workspace`: Jenkins workspace path
- `repo_name`: `Devops_project_1`
- `repo_url`: `/home/ayush/project_repos/Devops_project_1.git`

---

### Stage 2: Git Checkout
**Purpose**: Switch to development branch

```groovy
stage('Git checkout'){
    steps{
        dir("${repo_name}"){
            sh "git checkout dev"
        }
    }
}
```

**What Happens:**
- Enters cloned repository directory
- Switches to `dev` branch
- All subsequent builds happen from `dev` branch code
- Allows separate branches for development/staging/production

**Why Separate Clone and Checkout?**
- Clone stage gets the repository
- Checkout stage ensures correct branch
- Clear separation of concerns in pipeline

---

### Stage 3: SonarQube Analysis
**Purpose**: Static code analysis and quality assessment

```groovy
stage('SonarQube Analysis') {
    steps {
        script {
            dir("$repo_name"){
                withSonarQubeEnv('SonarQube-Local') {
                    sh '''
                        mvn sonar:sonar \
                          -Dsonar.projectKey=demo-app \
                          -Dsonar.projectName=DemoApp
                    '''
                }
            }
        }
    }
}
```

**What Happens:**
- Enters repository directory with `pom.xml`
- `withSonarQubeEnv` injects SonarQube credentials automatically
- Runs Maven SonarQube plugin
- Analyzes: Java files, XML, security issues
- Sends report to SonarQube server

**Checks Performed:**
- Code coverage
- Bugs and vulnerabilities
- Code smells and maintainability
- Security hotspots
- Duplicate code

---

### Stage 4: Quality Gate
**Purpose**: Enforce code quality standards before deployment

```groovy
stage('Quality Gate') {
    steps {
        script {
            timeout(time: 150, unit: 'SECONDS') {
                def qg = waitForQualityGate()
                if (qg.status != 'OK') {
                    error "❌ Quality Gate failed: ${qg.status}"
                }
            }
        }
    }
}
```

**What Happens:**
- Waits for SonarQube to process analysis (max 150 seconds)
- SonarQube webhook sends result back to Jenkins
- Checks quality gate status (OK/ERROR/WARN)
- **Pipeline fails if quality gate fails** - prevents bad code deployment
- Ensures only quality code reaches production

**Quality Gate Conditions** (default):
- Coverage on new code ≥ 80%
- New bugs = 0
- New vulnerabilities = 0
- Security rating = A

---

### Stage 5: Maven Clean & Package
**Purpose**: Compile and package application as JAR

```groovy
stage('Maven clean'){
    steps{
        dir("${repo_name}"){
            sh "mvn clean package -Drevision=1.0.${build_version}"
        }
    }
}
```

**What Happens:**
- `clean`: Removes `target/` directory
- `package`: Compiles code and creates JAR
- `-Drevision=1.0.${build_version}`: Dynamic versioning based on Jenkins build number
- Build #1 → `demo-app-1.0.1.jar`
- Build #5 → `demo-app-1.0.5.jar`

**Output:**
- JAR file: `target/demo-app-1.0.X.jar`
- Compiled classes: `target/classes/`
- Dependencies included (Spring Boot fat JAR)

---

### Stage 6: Push to Artifact Repository
**Purpose**: Store versioned artifact in Nexus

```groovy
stage('Push to artifact'){
    steps{
        dir("${repo_name}"){
            sh "mvn deploy -DskipTests -Drevision=1.0.${build_version}"
        }
    }
}
```

**What Happens:**
- Uploads JAR to Nexus Repository Manager
- Stores at: `http://localhost:8082/repository/maven-releases/com/example/demo-app/1.0.X/`
- Creates permanent version record
- `-DskipTests`: Skips tests (already run during package)

**Why Nexus?**
- Artifact versioning and history
- Reliable artifact storage
- Can deploy any previous version
- Acts as single source of truth for deployments

---

### Stage 7: Pull Artifact
**Purpose**: Download specific version from Nexus for deployment

```groovy
stage('Pull the artifact'){
    steps{
        sh "curl -u ${NEXUS_USER}:${NEXUS_PASSWORD} \
            -O ${NEXUS_URL}/1.0.${build_version}/demo-app-1.0.${build_version}.jar"
    }
}
```

**What Happens:**
- Downloads JAR using curl with Nexus credentials
- `-O`: Saves with original filename
- Downloads to Jenkins workspace root
- Ready for transfer to deployment server

**URL Structure:**
```
http://localhost:8082/repository/maven-releases/
  com/example/demo-app/
    1.0.5/
      demo-app-1.0.5.jar
```

---

### Stage 8: Push to Server
**Purpose**: Transfer artifact to AWS EC2 deployment server

```groovy
stage('push to server'){
    steps{
        sh "scp demo-app-1.0.${build_version}.jar ${server_username}@${server_ip}:${deploy_path}"
    }
}
```

**What Happens:**
- Uses SCP (Secure Copy) over SSH
- Copies JAR from Jenkins to EC2
- Target: `/home/ubuntu/deployables/demo-app-1.0.X.jar`
- Requires SSH key authentication (passwordless)

**Prerequisites:**
- SSH key added to EC2: `~/.ssh/authorized_keys`
- Security group allows port 22
- Network connectivity between Jenkins and EC2

---

### Stage 9: Take Backup & Stop Service
**Purpose**: Backup current version and stop running application

```groovy
stage('Take Backup and stop service'){
    steps{
        script{
            sh """
                ssh ${server_username}@${server_ip} <<'EOF'
                files=\$(shopt -s nullglob dotglob; echo app/*)
                if (( \${#files} ))
                then
                    echo "contains files"
                    mkdir -p backup
                    mv app/* backup/              # Backup current JAR
                    pkill -f java || true         # Stop application
                    echo "Moved and killed the process"
                else 
                    echo "empty (first deployment)"
                fi
EOF
            """
        }
    }
}
```

**What Happens:**
- SSH into EC2 server
- Checks if `app/` directory has files
- **If files exist:**
  - Creates `backup/` directory if needed
  - Moves current JAR to backup: `backup/demo-app-1.0.4.jar`
  - Kills running Java process with `pkill`
- **If empty:** First deployment, no backup needed

**Why This Matters:**
- **Critical for rollback!** Without backup, can't revert
- Safely stops current version before deploying new one
- Prevents port conflicts

---

### Stage 10: Deployment
**Purpose**: Deploy new version and start application

```groovy
stage('Deploymnet'){
    steps{
        script{
            sh """
            ssh ${server_username}@${server_ip} <<'EOF'
            export FE_PORT=8081
            cp ${deploy_path}/demo-app-1.0.${build_version}.jar app/
            nohup java -jar app/demo-app-1.0.${build_version}.jar >> app/app.out 2>&1 < /dev/null &
            echo "Started jar in nohup mode,going for sleep for 150s"
            sleep 150
EOF
            """
        }
    }
}
```

**What Happens:**
1. **Set port**: `export FE_PORT=8081` (Spring Boot reads this)
2. **Copy JAR**: From `deployables/` to `app/`
3. **Start app**: 
   - `nohup`: Runs in background, survives SSH disconnect
   - `java -jar`: Executes Spring Boot application
   - `>> app/app.out`: Redirects output to log file
   - `2>&1`: Redirects errors to same file
   - `< /dev/null`: Prevents stdin blocking
   - `&`: Runs in background
4. **Wait**: 150 seconds for application startup

**Why 150 seconds?**
- Spring Boot takes time to initialize
- Loads dependencies, creates beans
- Starts embedded Tomcat
- Ensures app is fully ready for health check

---

### Stage 11: Health Check & Rollback
**Purpose**: Verify deployment success, rollback if failed

```groovy
stage('Health check and Rollback'){
    steps{
        script{
            sh """
                ssh ${server_username}@${server_ip} <<'EOF'
                status=\$(curl -s -o /dev/null -w '%{http_code}' http://$server_ip:8081/api/health)
                
                if [[ "\$status" == "200" ]]; then
                    echo "Health check passed"
                else
                    echo "Health check failed, going for Rollback"
                    
                    lastversion=\$((${build_version} - 1))
                    pkill -f demo-app || true
                    mv app/demo-app-1.0.${build_version}.jar backup/
                    cp backup/demo-app-1.0.\${lastversion}.jar app/
                    nohup java -jar app/demo-app-1.0.\${lastversion}.jar > app/app.out 2>&1 < /dev/null &
                    
                    echo "Rollback completed to version 1.0.\${lastversion}"
                fi
EOF
            """
        }
    }
}
```

**What Happens:**

**Health Check:**
- Calls endpoint: `http://EC2_IP:8081/api/health`
- `curl -s -o /dev/null -w '%{http_code}'`: Gets only HTTP status code
- Expected: `200` (OK)

**If Health Check Passes (200):**
- Logs success message
- Deployment complete ✅
- Pipeline succeeds

**If Health Check Fails (≠ 200):**
1. **Calculate previous version**: `lastversion = current - 1`
   - Build #5 failed → Rollback to version 1.0.4
2. **Stop failed app**: `pkill -f demo-app`
3. **Archive failed JAR**: Move to backup
4. **Restore previous**: Copy `backup/demo-app-1.0.4.jar` to `app/`
5. **Restart old version**: Launch with nohup
6. **Log rollback**: Reports which version restored

**Health Check Response Example:**
```json
{
  "status": "UP",
  "version": "1.0.5",
  "timestamp": 1704364800000
}
```

**Rollback Scenarios:**
- Application crash during startup
- Port already in use
- Configuration error
- Database connection failure
- Memory issues

---

## 🏗️ Infrastructure Setup

### Terraform Configuration

#### VPC Setup (`vpc.tf`)
```hcl
- VPC: 10.0.0.0/16
- Public Subnet: 10.0.1.0/24
- Internet Gateway
- Route Table with internet access
```

#### EC2 Instance (`instances.tf`)
```hcl
- Instance Type: t2.micro
- AMI: Ubuntu 20.04 LTS
- Security Group:
  - Port 22 (SSH)
  - Port 8081 (Application)
  - Port 80 (HTTP)
- Storage: 20GB gp2
```

#### Variables (`variables.tf`)
- AWS region
- Instance type
- Key pair name
- VPC CIDR blocks

### Terraform Commands

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Plan infrastructure
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# Output specific values
terraform output instance_public_ip
```

---

## ⚙️ Configuration Management

### Ansible Playbooks

#### Frontend Role Structure
```
frontend/
├── tasks/
│   └── main.yml          # Main tasks
├── handlers/
│   └── main.yml          # Service handlers
├── templates/
│   └── app.service.j2    # Systemd template
├── vars/
│   └── main.yml          # Role variables
└── defaults/
    └── main.yml          # Default variables
```

#### Main Playbook (`frontend.yaml`)
```yaml
- hosts: webservers
  become: yes
  roles:
    - frontend
```

#### Running Ansible

```bash
# Test connectivity
ansible -i config/inventory.ini webservers -m ping

# Run playbook
ansible-playbook -i config/inventory.ini config/frontend-play/frontend.yaml

# Dry run
ansible-playbook -i config/inventory.ini config/frontend-play/frontend.yaml --check

# Verbose output
ansible-playbook -i config/inventory.ini config/frontend-play/frontend.yaml -vvv
```

---

## 🚀 Deployment

### Manual Deployment (Testing)

```bash
# Build locally
mvn clean package -Drevision=1.0.1

# Copy to server
scp target/demo-app-1.0.1.jar ubuntu@YOUR_EC2_IP:/home/ubuntu/deployables/

# SSH to server
ssh ubuntu@YOUR_EC2_IP

# Deploy
cd /home/ubuntu
mkdir -p app backup
cp deployables/demo-app-1.0.1.jar app/

# Start application
export FE_PORT=8081
nohup java -jar app/demo-app-1.0.1.jar > app/app.out 2>&1 &

# Check status
curl http://localhost:8081/api/health
```

### Automated Deployment (Jenkins)

1. **Trigger Build**:
   - Push code to `dev` branch
   - Or manually trigger in Jenkins: **Build Now**

2. **Monitor Progress**:
   - Jenkins Console Output
   - SonarQube dashboard: `http://localhost:9000`
   - Nexus repository: `http://localhost:8082`

3. **Verify Deployment**:
   ```bash
   # Check application
   curl http://YOUR_EC2_IP:8081/api/health
   
   # Check version
   curl http://YOUR_EC2_IP:8081/api/version
   
   # Access UI
   http://YOUR_EC2_IP:8081
   ```

---

## 🔙 Rollback Mechanism

### Automatic Rollback

The pipeline automatically rolls back if:
- Health check returns non-200 status
- Application fails to start within timeout
- Critical errors detected

### Rollback Process

1. **Detection**: Health check fails (HTTP status ≠ 200)
2. **Stop Failed**: Kills currently running process
3. **Calculate Version**: `lastversion = current - 1`
4. **Move Failed**: Archives failed JAR to backup
5. **Restore Previous**: Copies `backup/demo-app-1.0.X.jar` to `app/`
6. **Restart**: Launches previous version with nohup
7. **Verify**: Logs rollback completion

### Manual Rollback

```bash
# SSH to server
ssh ubuntu@YOUR_EC2_IP

# Stop current application
pkill -f demo-app

# List available backups
ls -lht backup/

# Copy desired version
cp backup/demo-app-1.0.X.jar app/

# Start application
export FE_PORT=8081
nohup java -jar app/demo-app-1.0.X.jar > app/app.out 2>&1 &

# Verify
curl http://localhost:8081/api/health
```

### Backup Strategy

- **Location**: `/home/ubuntu/backup/`
- **Retention**: All previous versions maintained
- **Naming**: `demo-app-1.0.X.jar`
- **Created**: Before every new deployment

---

## 📊 Monitoring

### Application Health

```bash
# Health endpoint
curl http://YOUR_EC2_IP:8081/api/health

# Response:
{
  "status": "UP",
  "version": "1.0.5",
  "timestamp": 1704364800000
}
```

### Version Information

```bash
curl http://YOUR_EC2_IP:8081/api/version

# Response:
{
  "version": "1.0.5",
  "appName": "Demo Application"
}
```

### Spring Boot Actuator

```bash
# Actuator health
curl http://YOUR_EC2_IP:8081/actuator/health

# Metrics
curl http://YOUR_EC2_IP:8081/actuator/metrics
```

### Application Logs

```bash
# SSH to server
ssh ubuntu@YOUR_EC2_IP

# View logs
tail -f app/app.out

# Search for errors
grep -i error app/app.out

# Check process
ps aux | grep demo-app
```

### Jenkins Monitoring

- **Build History**: Job dashboard
- **Console Output**: Detailed logs
- **Test Results**: If tests configured
- **Artifacts**: Archived JARs

### SonarQube Dashboard

- **Code Quality**: `http://localhost:9000/dashboard?id=demo-app`
- **Issues**: Bugs, vulnerabilities, code smells
- **Coverage**: Code coverage percentage
- **Duplications**: Duplicate code detection

---

## 🔧 Troubleshooting

### Common Issues

#### 1. SonarQube Authentication Failed
```bash
# Check token
mvn sonar:sonar -Dsonar.login=YOUR_TOKEN -Dsonar.host.url=http://localhost:9000 -X

# Regenerate token in SonarQube
# Update settings.xml or pipeline
```

#### 2. Nexus Connection Refused
```bash
# Check Nexus is running
docker ps | grep nexus

# Restart Nexus
docker restart nexus

# Check logs
docker logs nexus
```

#### 3. SSH Connection Failed
```bash
# Test SSH
ssh -v ubuntu@YOUR_EC2_IP

# Check security group
# Ensure port 22 is open in AWS

# Verify key permissions
chmod 600 ~/.ssh/id_rsa
```

#### 4. Health Check Always Fails
```bash
# SSH to server
ssh ubuntu@YOUR_EC2_IP

# Check if app is running
ps aux | grep demo-app

# Check port
netstat -tulpn | grep 8081

# Check logs
tail -100 app/app.out

# Check security group
# Ensure port 8081 is open in AWS
```

#### 5. Application Won't Start
```bash
# Check Java version
java -version

# Check environment variable
echo $FE_PORT

# Run manually to see errors
java -jar app/demo-app-1.0.X.jar

# Check permissions
ls -la app/demo-app-1.0.X.jar
```

#### 6. Quality Gate Fails
```bash
# Check SonarQube dashboard
# Review issues in http://localhost:9000

# View detailed report
# Project → Issues tab

# Fix code and rebuild
```

#### 7. Maven Build Fails
```bash
# Check Maven version
mvn -version

# Clean and rebuild
mvn clean install -X

# Check pom.xml syntax
# Validate dependencies
```

### Debug Commands

```bash
# Jenkins
# View workspace
ls -la /var/lib/jenkins/workspace/Devops-Project-Pipeline/

# Check Jenkins logs
tail -f /var/log/jenkins/jenkins.log

# EC2 Server
# Check disk space
df -h

# Check memory
free -m

# Check running processes
top

# Network connectivity
ping google.com
curl http://localhost:8081

# SonarQube
# Check container
docker logs sonarqube

# Nexus
# Check container
docker logs nexus

# Access logs
docker exec nexus tail -f /nexus-data/log/nexus.log
```

---

## 📝 Environment Variables

### Jenkins Pipeline Variables
```groovy
workspace           # Jenkins workspace path
repo_name          # Repository name: Devops_project_1
repo_url           # Git repository URL
repo_branch        # Branch name: Dev
build_version      # Dynamic: ${BUILD_NUMBER}
NEXUS_USER         # Nexus username: admin
NEXUS_PASSWORD     # Nexus password: admin
NEXUS_URL          # Nexus artifact URL
server_ip          # EC2 public IP
server_username    # EC2 username: ubuntu
deploy_path        # Deployment path on EC2
HEALTH_ENDPOINT    # Health check URL
```

### Application Variables
```properties
# application.properties
server.port=${FE_PORT:8081}
app.version=@project.version@
spring.application.name=demo-app
```

---

## 🎯 Best Practices

1. **Version Control**: Always tag releases in Git
2. **Code Quality**: Fix SonarQube issues before deployment
3. **Backup**: Maintain at least 3 previous versions
4. **Monitoring**: Check logs regularly
5. **Security**: Rotate credentials periodically
6. **Documentation**: Update README for changes
7. **Testing**: Test in staging before production
8. **Rollback**: Always have rollback plan ready

---

## 🔐 Security Considerations

- SSH keys properly secured (chmod 600)
- SonarQube token not exposed in code
- Nexus credentials encrypted in Jenkins
- AWS security groups properly configured
- Regular security updates on EC2
- Secrets management via Jenkins credentials

---

## 📚 Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [Ansible Documentation](https://docs.ansible.com/)

---

## 👥 Contributors

- **Ayush** - DevOps Engineer


**Last Updated**: January 2026  
**Version**: 1.0.0

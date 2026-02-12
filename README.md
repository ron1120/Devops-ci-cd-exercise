# DevOps CI/CD Exercise

> A full end-to-end CI/CD pipeline built with Jenkins, Docker, Terraform, and Ansible — deploying a Flask application to AWS.

---

## 📐 Architecture Overview

![Architecture for project](./images/ci_cd_jenkins.png)

### High-Level Flow

```
Developer → GitHub → Jenkins CI → Docker Hub → Terraform + Ansible → AWS EC2
    │          │          │              │               │               │
  Push      Webhook    Build &        Push           Provision       Deploy &
  Code      Trigger    Test           Image          Infra           Run App
```

---

## 🏗️ Project Structure

```
.
├── app/                          # Flask Application
│   ├── __init__.py               #   App factory (create_app)
│   ├── routes/
│   │   ├── user_routes.py        #   /api/users endpoints
│   │   └── product_routes.py     #   /api/products endpoints
│   └── templates/
│       └── index.html            #   Web UI
│
├── tests/                        # Test Suite
│   ├── unit/                     #   Unit tests (routes, utils)
│   ├── integration/              #   API integration tests
│   ├── e2e/                      #   End-to-end (Selenium)
│   └── performance/              #   Load tests (Locust)
│
├── jenkins/
│   └── Jenkinsfile               # Pipeline definition (CI + CD)
│
├── docker/
│   ├── Dockerfile                # Application container
│   ├── Dockerfile.jenkins        # Custom Jenkins image with DevOps tools
│   ├── plugins.txt               # Jenkins plugins list
│   └── casc/
│       └── jenkins.yaml          # Jenkins Configuration as Code
│
├── infrastructure/
│   ├── terraform/                # Infrastructure as Code
│   │   ├── main.tf               #   AWS provider config
│   │   ├── variables.tf          #   Input variables
│   │   ├── network.tf            #   VPC, Subnet, IGW, SG
│   │   ├── ec2.tf                #   EC2 instance + EIP
│   │   └── outputs.tf            #   IP, DNS, URLs
│   └── ansible/
│       ├── deploy.yml            #   Deployment playbook
│       ├── ansible.cfg           #   Ansible configuration
│       └── inventory.ini         #   Dynamic inventory (generated)
│
├── main.py                       # App entrypoint
├── calc.py                       # Calculator module
├── requirements.txt              # Python dependencies
└── pytest.ini                    # Pytest configuration
```

---

## 🔧 Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Application** | Python 3.11, Flask 2.3 | REST API + Web UI |
| **WSGI Server** | Gunicorn | Production-grade HTTP server |
| **CI/CD Engine** | Jenkins 2.x (LTS) | Pipeline orchestration |
| **Containerization** | Docker, Docker Buildx | App packaging (linux/amd64) |
| **Registry** | Docker Hub | Image storage & distribution |
| **Infrastructure** | Terraform 1.6.6 | AWS resource provisioning |
| **Configuration Mgmt** | Ansible | Application deployment |
| **Cloud** | AWS (us-east-2) | EC2, VPC, EIP |
| **Testing** | pytest, Selenium, Locust | Unit/Integration/E2E/Performance |
| **Security** | Bandit | Static security analysis |
| **Linting** | Flake8, Pylint | Code quality |
| **Notifications** | Email (SMTP), Jira REST API | Build alerts & ticket creation |
| **Version Control** | Git, GitHub | Source code management |

---

## 🚀 CI/CD Pipeline

### Pipeline Stages

```
┌─────────────┐
│  Checkout    │  Clone repo from GitHub
└──────┬──────┘
       ▼
┌─────────────┐
│  Setup Env   │  Create Python venv, install dependencies
└──────┬──────┘
       ▼
┌─────────────┐
│  Lint Code   │  Flake8 + Pylint static analysis
└──────┬──────┘
       ▼
┌─────────────┐
│  Unit Tests  │  pytest + coverage (HTML, XML, terminal)
└──────┬──────┘
       ▼
┌──────────────────┐
│ Integration Tests │  API endpoint testing
└──────┬───────────┘
       ▼
┌─────────────┐
│  E2E Tests   │  Selenium browser tests
└──────┬──────┘
       ▼
┌───────────────┐
│ Security Scan  │  Bandit static security analysis
└──────┬────────┘
       ▼
┌───────────────────┐
│ Performance Tests  │  Locust load testing (production only)
└──────┬────────────┘
       ▼
┌──────────────────┐
│ Create Version    │  CalVer tag: YYYY.MM.DD.HHMMSS
│ Tag               │  (main/develop branches only)
└──────┬───────────┘
       ▼
┌──────────────────┐
│ Build Docker      │  docker buildx --platform linux/amd64
│ Image             │
└──────┬───────────┘
       ▼
┌──────────────────┐
│ Push Docker       │  Push to Docker Hub (ronsss/devops-testing-app)
│ Image             │
└──────┬───────────┘
       ▼
┌──────────────────────────────────────┐
│         Deploy to Staging            │
│  ┌────────────────────────────────┐  │
│  │ Terraform Init & Plan          │  │
│  │ Terraform Apply                │  │
│  │ Ansible Deploy                 │  │
│  │ Smoke Test                     │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Branch-Based Behavior

| Branch | Tests | Docker Build | Deploy | Performance |
|--------|-------|-------------|--------|-------------|
| `main` | ✅ All | ✅ Build & Push | ✅ Staging | ❌ Skip |
| `develop` | ✅ All | ✅ Build & Push | ✅ Staging | ❌ Skip |
| `production` | ✅ All | ✅ Build & Push | ✅ Staging | ✅ Run |
| Feature branches | ✅ All | ❌ Skip | ❌ Skip | ❌ Skip |

### Post-Build Actions

| Condition | Email | Jira Ticket | Priority |
|-----------|-------|-------------|----------|
| **Success** | ✅ Build summary | ❌ | — |
| **Unstable** (test failures) | ✅ With failure details | ✅ Task in KAN project | Medium |
| **Failure** (pipeline error) | ✅ With failed stage | ✅ Task in KAN project | High |

---

## ☁️ AWS Infrastructure

### Resources Provisioned by Terraform

```
AWS Region: us-east-2 (Ohio)
│
├── VPC (10.0.0.0/16)
│   ├── Public Subnet (10.0.1.0/24) — AZ: us-east-2c
│   ├── Internet Gateway
│   ├── Route Table (0.0.0.0/0 → IGW)
│   └── Security Group
│       ├── Inbound: SSH (22), HTTP (80), App (5000)
│       └── Outbound: All traffic
│
├── EC2 Instance
│   ├── AMI: Amazon Linux 2023
│   ├── Type: t3.micro
│   ├── Disk: 30 GB gp3 (encrypted)
│   ├── Key: aws_key (ed25519)
│   └── User Data: Docker + Python3 installed
│
└── Elastic IP
    └── Static public IP for the instance
```

### Ansible Deployment Flow

```
1. Wait for EC2 user_data to complete
2. Ensure Docker daemon is running
3. Login to Docker Hub
4. Pull application image
5. Stop & remove old container
6. Start new container (port 5000, restart: always)
7. Wait for health check (/health → 200 OK)
```

---

## 🐳 Docker

### Application Image (`docker/Dockerfile`)

- **Base**: `python:3.11-slim`
- **Server**: Gunicorn (2 workers)
- **Port**: 5000
- **Health Check**: `curl http://localhost:5000/health`
- **Platform**: Built for `linux/amd64` (for AWS EC2 compatibility)

### Jenkins Image (`docker/Dockerfile.jenkins`)

Custom Jenkins image pre-loaded with:
- Python 3 + venv
- Docker CLI
- Terraform 1.6.6
- AWS CLI v2
- Ansible + boto3
- Jenkins plugins (via `plugins.txt`)
- Jenkins Configuration as Code (JCasC)

### Running Jenkins Locally

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-devops:latest
```

---

## 🔑 Jenkins Credentials

| ID | Type | Purpose |
|----|------|---------|
| `RonGitUser` | Username/Password | GitHub PAT |
| `RonDockerUser` | Username/Password | Docker Hub |
| `aws-credentials` | AWS Credentials | IAM Access Key + Secret |
| `StagingSSHKey` | SSH Private Key | EC2 SSH access (ec2-user) |
| `JIRA_API_TOKEN` | Secret Text | Jira REST API authentication |

---

## 🧪 Testing

### Test Types

| Type | Location | Framework | Purpose |
|------|----------|-----------|---------|
| **Unit** | `tests/unit/` | pytest + pytest-cov | Route handlers, utilities |
| **Integration** | `tests/integration/` | pytest + requests | Full API endpoint testing |
| **E2E** | `tests/e2e/` | Selenium + pytest | Browser-based UI tests |
| **Performance** | `tests/performance/` | Locust | Load & stress testing |

### Running Tests Locally

```bash
# Create virtual environment
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/unit/ -v --cov=app --cov-report=html:htmlcov

# Run specific test suite
pytest tests/integration/ -v
pytest tests/e2e/ -v
```

---

## 📧 Notifications

### Email (SMTP)

- **Provider**: Gmail SMTP (`smtp.gmail.com:465`, SSL)
- **Recipient**: Configured in Jenkinsfile
- **Content**: HTML formatted with build number, branch, duration, status, and links

### Jira Integration

- **Instance**: `ron1120.atlassian.net`
- **Project**: KAN
- **Issue Type**: Task
- **Trigger**: Pipeline unstable (Medium) or failure (High)
- **Content**: Job name, build number, branch, build URL

---

## 🚦 Quick Start

### 1. Run the App Locally

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python main.py
# App available at http://localhost:5000
```

### 2. Run with Docker

```bash
docker build -t devops-testing-app -f docker/Dockerfile .
docker run -p 5000:5000 devops-testing-app
# App available at http://localhost:5000
```

### 3. API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Web UI (HTML page) |
| GET | `/health` | Health check |
| GET | `/api/users/` | List all users |
| GET | `/api/users/<id>` | Get user by ID |
| POST | `/api/users/` | Create a user |
| GET | `/api/products/` | List all products |
| GET | `/api/products/<id>` | Get product by ID |
| POST | `/api/products/` | Create a product |
| PUT | `/api/products/<id>` | Update a product |
# 🏗️ LocalStore Platform - Infrastructure

Infrastructure and deployment repository for the LocalStore Platform. Hosts Terraform configurations for AWS deployment, Docker Compose for local development, and CI/CD pipeline configurations.

**Spec Version:** v1.1-specs  
**Repository:** `infra`  
**Status:** 🟡 In Progress

---

## 📋 Overview

This repository contains:

- **Terraform configurations** for AWS infrastructure (VPC, EC2, RDS, etc.)
- **Docker Compose** files for local development and production
- **CI/CD pipelines** using GitHub Actions
- **Kubernetes manifests** (future scaling path)

### Tech Stack

- **IaC:** Terraform 1.5+
- **Container Runtime:** Docker 24+, Docker Compose 2.20+
- **Cloud Provider:** AWS (ap-southeast-1 - Singapore region)
- **CI/CD:** GitHub Actions
- **DNS/CDN:** CloudFlare (optional)

### Target Architecture

```plaintext
MVP ($20/month):
┌─────────────────────────────────────────┐
│           AWS EC2 (t2.small)            │
│  ┌─────────────────────────────────┐    │
│  │        Docker Compose           │    │
│  │  ┌─────────┐  ┌─────────┐      │    │
│  │  │ NestJS  │  │ Python  │      │    │
│  │  │  API    │  │   AI    │      │    │
│  │  └────┬────┘  └────┬────┘      │    │
│  │       │            │           │    │
│  │  ┌────┴────────────┴────┐      │    │
│  │  │     PostgreSQL       │      │    │
│  │  │       + Redis        │      │    │
│  │  └──────────────────────┘      │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```plaintext
infra/
├── .github/
│   ├── workflows/           # CI/CD pipelines
│   │   ├── terraform-plan.yml
│   │   ├── terraform-apply.yml
│   │   └── docker-build.yml
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── copilot-instructions.md
│
├── terraform/
│   ├── environments/
│   │   ├── dev/             # Development environment
│   │   ├── staging/         # Staging environment
│   │   └── prod/            # Production environment
│   ├── modules/
│   │   ├── vpc/             # VPC, subnets, security groups
│   │   ├── ec2/             # EC2 instances
│   │   ├── rds/             # RDS PostgreSQL (future)
│   │   └── s3/              # S3 buckets
│   └── shared/              # Shared variables and outputs
│
├── docker/
│   ├── compose/
│   │   ├── docker-compose.yml        # Local dev
│   │   ├── docker-compose.prod.yml   # Production
│   │   └── docker-compose.test.yml   # Testing
│   ├── nginx/               # Nginx reverse proxy configs
│   └── scripts/             # Helper scripts
│
├── k8s/                     # Kubernetes manifests (future)
│   ├── base/
│   └── overlays/
│
├── scripts/
│   ├── deploy.sh            # Deployment script
│   ├── backup-db.sh         # Database backup
│   └── ssl-renew.sh         # SSL certificate renewal
│
├── docs/
│   ├── DEPLOYMENT.md        # Deployment guide
│   ├── SECURITY.md          # Security configuration
│   └── MONITORING.md        # Monitoring setup
│
├── .env.example             # Environment template
├── SPEC_LINKS.md            # Links to specifications
├── GIT_WORKFLOW.md          # Git workflow guide
└── README.md                # This file
```

---

## 🚀 Quick Start

### Prerequisites

```bash
# Check required tools
terraform --version    # Need 1.5+
docker --version       # Need 24+
docker compose version # Need 2.20+
aws --version          # Need 2.0+
```

### Local Development

```bash
# Clone repository
git clone https://github.com/localstore-platform/infra.git
cd infra

# Copy environment template
cp .env.example .env
# Edit .env with your settings

# Start local development environment
cd docker/compose
docker compose up -d

# Verify services are running
docker compose ps
```

### AWS Deployment (MVP)

```bash
# Configure AWS credentials
aws configure

# Initialize Terraform
cd terraform/environments/prod
terraform init

# Preview changes
terraform plan -out=plan.tfplan

# Apply changes
terraform apply plan.tfplan
```

---

## 🔧 Configuration

### Environment Variables

See [.env.example](.env.example) for all required environment variables.

Key variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `ap-southeast-1` |
| `EC2_INSTANCE_TYPE` | EC2 instance size | `t2.small` |
| `DOMAIN_NAME` | Primary domain | `quanly.ai` |
| `DB_PASSWORD` | Database password | (secret) |

### Infrastructure Costs (Estimated)

| Component | Monthly Cost |
|-----------|--------------|
| EC2 t2.small | ~$15 |
| EBS Storage (20GB) | ~$2 |
| Data Transfer | ~$3 |
| **Total MVP** | **~$20/month** |

---

## 📊 Monitoring

### CloudWatch Metrics

- CPU utilization
- Memory usage
- Disk I/O
- Network traffic

### Alerts (Production)

- CPU > 80% for 5 minutes
- Memory > 85%
- Disk usage > 90%
- API response time > 2s

---

## 🔐 Security

### Security Groups

| Port | Service | Source |
|------|---------|--------|
| 22 | SSH | Admin IPs only |
| 80 | HTTP | 0.0.0.0/0 |
| 443 | HTTPS | 0.0.0.0/0 |
| 5432 | PostgreSQL | VPC only |
| 6379 | Redis | VPC only |

### Best Practices

- ✅ Never commit secrets to repository
- ✅ Use AWS Secrets Manager or Parameter Store
- ✅ Enable VPC flow logs
- ✅ Regular security patching
- ✅ SSL/TLS for all external traffic

---

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Security Configuration](docs/SECURITY.md)
- [Monitoring Setup](docs/MONITORING.md)
- [Specification Links](SPEC_LINKS.md)
- [Git Workflow](GIT_WORKFLOW.md)

---

## 🔗 Related Repositories

| Repository | Description | Status |
|------------|-------------|--------|
| [specs](https://github.com/localstore-platform/specs) | Documentation & specifications | ✅ Complete |
| [api](https://github.com/localstore-platform/api) | NestJS backend API | ✅ Sprint 0.5 |
| [menu](https://github.com/localstore-platform/menu) | Next.js public menu website | 🟡 In Progress |
| [contracts](https://github.com/localstore-platform/contracts) | TypeScript shared types | ✅ v0.1.0 |
| [dashboard](https://github.com/localstore-platform/dashboard) | Next.js owner dashboard | 🟡 Docs Only |
| [mobile](https://github.com/localstore-platform/mobile) | Flutter mobile app | 🟡 Docs Only |

---

## 👥 Team & Ownership

**CODEOWNERS:** @localstore-platform/infra-team

For infrastructure support or questions:

- Create an issue in this repository
- Tag `@localstore-platform/infra-team` in PRs
- Reference relevant spec sections in [SPEC_LINKS.md](SPEC_LINKS.md)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

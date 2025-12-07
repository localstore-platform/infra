# Current Work - Infrastructure Repository

**Sprint:** 0.5 - Menu Demo  
**Last Updated:** 2025-12-07  
**Branch:** `main`

---

## 📋 Stories for This Sprint

| ID | Story | Status | Notes |
|----|-------|--------|-------|
| INFRA-1 | Initialize repository structure | ✅ Done | Terraform, Docker, CI/CD |
| INFRA-2 | Set up Terraform workspaces | ✅ Done | dev workspace created, plan verified |
| INFRA-3 | Docker Compose for local dev | ✅ Done | PostgreSQL 17, Redis 8 |
| INFRA-4 | Docker build workflow (ECR) | ✅ Done | Switched from GHCR to ECR |
| INFRA-5 | Deploy API to AWS | ✅ Done | Dev env deployed with ECR auth |
| INFRA-6 | Add migration & seed to deployment | ✅ Done | PR #2 merged |

---

## 🎯 Current Focus

**All Sprint 0.5 stories complete!**

Dev environment fully deployed and operational:

- EC2: `i-070d4ef3f7f5ac26a` (t2.micro, Amazon Linux 2023)
- Public IP: `54.254.209.58`
- Domain: `api-dev.localstore-platform.com` (CloudFlare DNS + SSL)

Services running:

- API: <https://api-dev.localstore-platform.com/api/v1/health>
- PostgreSQL: `54.254.209.58:5432`
- Redis: `54.254.209.58:6379`
- Nginx: HTTPS reverse proxy with CloudFlare Origin Certificate

Sample data seeded:

- Tenant: "Phở Hà Nội 24"
- Menu: 5 categories, 13 items
- Test: <https://api-dev.localstore-platform.com/api/v1/menu/550e8400-e29b-41d4-a716-446655440000>

---

## 🔧 Infrastructure Status

### AWS Resources

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| S3 (state) | ✅ | ✅ | ✅ |
| DynamoDB (locks) | ✅ | ✅ | ✅ |
| VPC | ✅ | 🔴 | 🔴 |
| EC2 + IAM Profile | ✅ | 🔴 | 🔴 |
| SSH Key | ✅ | 🔴 | 🔴 |
| ECR Repository | ✅ | - | - |
| CloudFlare DNS | ✅ | 🔴 | 🔴 |

### Container Registry (AWS ECR)

- Region: ap-southeast-1
- Account: 767828741221
- Repository: `localstore/api`
- EC2 has IAM instance profile for ECR access

### Docker Images

| Image | Status |
|-------|--------|
| `767828741221.dkr.ecr.ap-southeast-1.amazonaws.com/localstore/api:latest` | ✅ Deployed |

---

## 🚀 Deployment Pipeline

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy.sh` | Main deployment script |
| `scripts/remote-deploy.sh` | ECR login, pull, migrations, start services |
| `scripts/seed.sh` | Seed sample data (dev only) |

### Commands

```bash
# Deploy to dev
make deploy-app

# Full deployment flow:
# 1. Copy files to EC2 (compose, nginx, SSL, .env)
# 2. Run remote-deploy.sh → ECR login, pull, migrations, start
# 3. Run seed.sh (dev only) → Wait for health, seed data
```

### Migration & Seed Commands

| Command | Purpose |
|---------|---------|
| `pnpm run migration:run:prod` | Run migrations (compiled JS) |
| `pnpm run seed:compiled` | Seed database (compiled JS) |

---

## 📝 Notes

### Recently Completed

1. ✅ Added migration step to deployment pipeline
2. ✅ Added seed step for dev environment
3. ✅ Refactored scripts to avoid heredoc issues
4. ✅ Full deployment from scratch verified working
5. ✅ Menu API returns seeded Vietnamese restaurant data

### Merged PRs

- PR #1: Initial infrastructure setup (ECR, CloudFlare, EC2)
- PR #2: Add migration and seed steps to deployment

---

## 🔗 Spec References

- [Backend Setup Guide - AWS Section](https://github.com/localstore-platform/specs/blob/v1.1-specs/architecture/backend-setup-guide.md#L2250-L2700)
- [System Diagram](https://github.com/localstore-platform/specs/blob/v1.1-specs/architecture/system-diagram.md)

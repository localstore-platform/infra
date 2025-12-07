# Current Work - Infrastructure Repository

**Sprint:** 0.5 - Menu Demo  
**Last Updated:** 2025-12-07  
**Branch:** `feat/init-repo`

---

## 📋 Stories for This Sprint

| ID | Story | Status | Notes |
|----|-------|--------|-------|
| INFRA-1 | Initialize repository structure | ✅ Done | Terraform, Docker, CI/CD |
| INFRA-2 | Set up Terraform workspaces | ✅ Done | dev workspace created, plan verified |
| INFRA-3 | Docker Compose for local dev | ✅ Done | PostgreSQL 17, Redis 8 |
| INFRA-4 | Docker build workflow (ECR) | ✅ Done | Switched from GHCR to ECR |
| INFRA-5 | Deploy API to AWS | ✅ Done | Dev env deployed with ECR auth |

---

## 🎯 Current Focus

**All Sprint 0.5 stories complete!**

Dev environment deployed:

- VPC: `vpc-038d8dabcd1c7a03d`
- EC2: `i-070d4ef3f7f5ac26a` (t2.micro, Amazon Linux 2023)
- Public IP: `13.212.103.150`
- SSH: `ssh -i ~/.ssh/localstore-dev.pem ec2-user@13.212.103.150`

Services running:

- PostgreSQL: `13.212.103.150:5432`
- Redis: `13.212.103.150:6379`

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

### Container Registry

Using **AWS ECR** instead of GHCR:

- Region: ap-southeast-1
- Account: 767828741221
- EC2 has IAM instance profile for ECR access

### Docker Images (ECR)

| Image | Status |
|-------|--------|
| 767828741221.dkr.ecr.ap-southeast-1.amazonaws.com/localstore-platform/api | 🔴 Not built yet |
| 767828741221.dkr.ecr.ap-southeast-1.amazonaws.com/localstore-platform/ai | 🔴 Not built yet |

---

## 📝 Notes

### Completed Today

1. Switched from GHCR to ECR for container registry
2. Added IAM role with ECR access for EC2
3. Updated docker-build workflow to create/use ECR repos
4. Deployed PostgreSQL 17 and Redis 8 to dev EC2
5. Both services healthy and accepting connections

### Next Steps

1. Merge PR #1 to main
2. API team runs docker-build workflow to push images to ECR
3. Update docker-compose.prod.yml with ECR images
4. Deploy full stack (API + DB + Redis)

---

## 🔗 Spec References

- [Backend Setup Guide - AWS Section](https://github.com/localstore-platform/specs/blob/v1.1-specs/architecture/backend-setup-guide.md#L2250-L2700)
- [System Diagram](https://github.com/localstore-platform/specs/blob/v1.1-specs/architecture/system-diagram.md)

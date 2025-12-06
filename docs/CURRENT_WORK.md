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
| INFRA-3 | Docker Compose for local dev | ✅ Done | PostgreSQL 17, Redis 8, API image |
| INFRA-4 | Docker build workflow | ✅ Done | GHCR push working |
| INFRA-5 | Deploy API to AWS | 🔴 Not Started | Blocked on SSH key creation |

---

## 🎯 Current Focus

**Story INFRA-2: Terraform Workspaces** - ✅ Completed

Refactored from folder-based environments to workspace-based:
- Created unified `main.tf` using `terraform.workspace`
- Added `tfvars/` directory for environment-specific values
- Created dev workspace and verified plan (7 resources)
- AWS provider updated to 6.25.0

---

## 🔧 Infrastructure Status

### AWS Resources

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| S3 (state) | ✅ | ✅ | ✅ |
| DynamoDB (locks) | ✅ | ✅ | ✅ |
| VPC | 🔴 | 🔴 | 🔴 |
| EC2 | 🔴 | 🔴 | 🔴 |
| SSH Key | 🔴 | 🔴 | 🔴 |

### Docker Images

| Image | Latest Tag | Version Tag |
|-------|------------|-------------|
| ghcr.io/localstore-platform/api | ✅ latest | ✅ v1.0.0 |
| ghcr.io/localstore-platform/ai | 🔴 | 🔴 |

---

## 📝 Notes

### Blockers

- **SSH Key**: Need to create `localstore-dev` key pair in AWS before applying terraform

### Next Steps

1. Create SSH key pair: `aws ec2 create-key-pair --key-name localstore-dev`
2. Apply terraform: `terraform apply "dev.tfplan"`
3. Deploy API container to EC2
4. Post production API URL to unblock menu Vercel deployment

---

## 🔗 Spec References

- [Backend Setup Guide - AWS Section](https://github.com/localstore-platform/specs/blob/v1.1-specs/architecture/backend-setup-guide.md#L2250-L2700)
- [System Diagram](https://github.com/localstore-platform/specs/blob/v1.1-specs/architecture/system-diagram.md)

---

## 📊 Terraform Plan Summary (Dev)

```
Plan: 7 to add, 0 to change, 0 to destroy

Resources:
- module.vpc.aws_vpc.main
- module.vpc.aws_internet_gateway.main
- module.vpc.aws_subnet.public
- module.vpc.aws_route_table.public
- module.vpc.aws_route_table_association.public
- module.ec2.aws_security_group.api
- module.ec2.aws_instance.app
```

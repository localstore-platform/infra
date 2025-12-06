# Specification Links

This document maps infrastructure implementation to the LocalStore Platform specifications.

**Spec Repository:** <https://github.com/localstore-platform/specs>  
**Spec Version:** v1.1-specs  
**Last Updated:** December 2025

---

## 📚 Primary References

### Architecture Documents

| Document | Path | Relevance |
|----------|------|-----------|
| Backend Setup Guide | [architecture/backend-setup-guide.md](https://github.com/localstore-platform/specs/blob/main/architecture/backend-setup-guide.md) | **Primary** - Deployment section, Docker Compose configs |
| System Diagram | [architecture/system-diagram.md](https://github.com/localstore-platform/specs/blob/main/architecture/system-diagram.md) | Overall architecture and component relationships |
| Hybrid Architecture Decision | [architecture/decision-hybrid-architecture.md](https://github.com/localstore-platform/specs/blob/main/architecture/decision-hybrid-architecture.md) | Technical decisions for NestJS + Python hybrid |
| Database Schema | [architecture/database-schema.md](https://github.com/localstore-platform/specs/blob/main/architecture/database-schema.md) | PostgreSQL schema, RLS policies |

### Implementation Guides

| Document | Path | Relevance |
|----------|------|-----------|
| Impl README Template | [documentation/impl-readme-infra.md](https://github.com/localstore-platform/specs/blob/main/documentation/impl-readme-infra.md) | README structure for this repo |
| CODEOWNERS Examples | [documentation/codeowners-examples.md](https://github.com/localstore-platform/specs/blob/main/documentation/codeowners-examples.md) | Team ownership patterns |
| PR Template (Infra) | [documentation/pr-template-infra.md](https://github.com/localstore-platform/specs/blob/main/documentation/pr-template-infra.md) | Pull request template |

### Operational Documents

| Document | Path | Relevance |
|----------|------|-----------|
| Monitoring Runbook | [documentation/monitoring-runbook.md](https://github.com/localstore-platform/specs/blob/main/documentation/monitoring-runbook.md) | CloudWatch, alerts, dashboards |
| Launch Readiness | [documentation/LAUNCH-READINESS.md](https://github.com/localstore-platform/specs/blob/main/documentation/LAUNCH-READINESS.md) | Pre-deployment checklist |

---

## 🎯 Key Spec Sections

### AWS Infrastructure (backend-setup-guide.md)

| Section | Lines | Component | Status |
|---------|-------|-----------|--------|
| AWS VPC Setup | 2250-2350 | VPC, subnets, routing | 🔴 Not Started |
| EC2 Instance | 2400-2500 | t2.small MVP server | 🔴 Not Started |
| Security Groups | 2350-2400 | Ports: 80, 443, 22, 5432, 6379 | 🔴 Not Started |
| Docker Compose Prod | 2500-2600 | Production compose config | 🔴 Not Started |
| SSL Certificate | 2600-2650 | Let's Encrypt auto-renewal | 🔴 Not Started |
| Domain Configuration | 2650-2700 | CloudFlare DNS setup | 🔴 Not Started |

### Docker Compose (backend-setup-guide.md)

| Section | Lines | Component | Status |
|---------|-------|-----------|--------|
| Dev Docker Compose | 200-400 | PostgreSQL + Redis + API | 🔴 Not Started |
| PostgreSQL Init | 300-450 | RLS functions, multi-tenant | 🔴 Not Started |
| Redis Config | 450-550 | Cache configuration | 🔴 Not Started |

### Monitoring (monitoring-runbook.md)

| Section | Component | Status |
|---------|-----------|--------|
| CloudWatch Metrics | CPU, memory, disk alerts | 🔴 Not Started |
| Log Aggregation | CloudWatch Logs | 🔴 Not Started |
| Dashboards | Grafana or CloudWatch | 🔴 Not Started |

---

## 🔄 Cross-Repository Dependencies

```plaintext
specs (documentation)
   │
   ├── infra (this repo)
   │   ├── Terraform → deploys → EC2, VPC, S3
   │   ├── Docker Compose → runs → api, menu containers
   │   └── CI/CD → builds → all repos
   │
   ├── api (NestJS backend)
   │   └── Dockerfile → built by → infra CI
   │
   ├── menu (Next.js website)
   │   └── Deployed to → Vercel or infra
   │
   └── contracts (TypeScript types)
       └── NPM package → used by → api, menu
```

---

## 📋 Implementation Checklist

### Phase 1: Local Development (Current)

- [x] Repository initialized
- [ ] Docker Compose for local dev
- [ ] Environment variable template
- [ ] Development documentation

### Phase 2: AWS MVP Deployment

- [ ] Terraform VPC module
- [ ] Terraform EC2 module
- [ ] Security groups configuration
- [ ] Docker Compose production
- [ ] SSL certificate (Let's Encrypt)
- [ ] Domain configuration

### Phase 3: CI/CD Automation

- [ ] GitHub Actions workflows
- [ ] Terraform plan on PR
- [ ] Terraform apply on merge
- [ ] Docker image builds
- [ ] Deployment automation

### Phase 4: Monitoring & Observability

- [ ] CloudWatch metrics
- [ ] Alert configuration
- [ ] Log aggregation
- [ ] Dashboard setup

---

## 🏷️ Version Compatibility

| Infra Version | Spec Version | Notes |
|---------------|--------------|-------|
| v0.1.0 (planned) | v1.1-specs | Initial AWS MVP deployment |

---

## 📝 Notes

- **Cost Target:** ~$20/month for MVP (<100 users)
- **Region:** ap-southeast-1 (Singapore) - closest to Vietnam
- **Strategy:** Demo-first approach, deploy after localhost validation
- **Scale Path:** EC2 → ECS/EKS when traffic exceeds single server

---

## 🔗 Quick Links

- [Specs Repository](https://github.com/localstore-platform/specs)
- [Backend Setup Guide](https://github.com/localstore-platform/specs/blob/main/architecture/backend-setup-guide.md)
- [Implementation Progress](https://github.com/localstore-platform/specs/blob/main/IMPLEMENTATION_PROGRESS.md)
- [Spec Changelog](https://github.com/localstore-platform/specs/blob/main/SPEC_CHANGELOG.md)

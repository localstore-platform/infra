# Deployment Guide

This guide covers deploying the LocalStore Platform to AWS.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform 1.5+ installed
- Docker and Docker Compose installed
- SSH key pair created in AWS

## MVP Deployment Overview

The MVP deployment consists of a single EC2 instance running all services via Docker Compose.

```diagram
Internet
    │
    ▼
┌─────────────────┐
│   CloudFlare    │ (DNS + CDN)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ EC2 (t2.small)  │
│  ┌───────────┐  │
│  │   Nginx   │  │ (SSL termination)
│  └─────┬─────┘  │
│        │        │
│  ┌─────┴─────┐  │
│  │ API + AI  │  │ (Docker Compose)
│  └─────┬─────┘  │
│        │        │
│  ┌─────┴─────┐  │
│  │PostgreSQL │  │
│  │  + Redis  │  │
│  └───────────┘  │
└─────────────────┘
```

## Deployment Steps

### 1. Configure Terraform Backend

First, create an S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket for state
aws s3 mb s3://localstore-terraform-state --region ap-southeast-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket localstore-terraform-state \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
    --table-name localstore-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-southeast-1
```

### 2. Configure Environment

```bash
cd terraform/environments/prod

# Copy example tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

Required values:

- `key_name`: Your SSH key pair name
- `admin_ip`: Your IP address for SSH access (CIDR format)
- `domain_name`: Your domain (e.g., quanly.ai)

### 3. Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan -var-file="terraform.tfvars" -out=plan.tfplan

# Apply (after reviewing plan)
terraform apply plan.tfplan
```

### 4. Configure DNS

After Terraform creates the EC2 instance:

1. Get the public IP from Terraform output
2. Create A record in CloudFlare pointing to the IP
3. Enable CloudFlare proxy (orange cloud) for DDoS protection

### 5. Deploy Application

SSH into the EC2 instance and deploy:

```bash
# SSH to instance
ssh -i ~/.ssh/localstore-key.pem ec2-user@YOUR_IP

# Clone infra repo
cd /opt/localstore
git clone https://github.com/localstore-platform/infra.git
cd infra/docker/compose

# Copy and configure environment
cp ../../.env.example .env
vim .env  # Update with production values

# Start services
docker compose -f docker-compose.prod.yml up -d

# Verify services
docker compose -f docker-compose.prod.yml ps
```

## Post-Deployment Checklist

- [ ] All services healthy (`docker compose ps`)
- [ ] API health check responds (`curl https://YOUR_DOMAIN/health`)
- [ ] Database accessible from API
- [ ] Redis accessible from API
- [ ] CloudFlare proxy enabled (orange cloud)
- [ ] CloudWatch metrics appearing
- [ ] Alerts configured

## Monitoring

### CloudWatch Dashboard

Access CloudWatch in the AWS Console to view:

- CPU utilization
- Memory usage
- Disk I/O
- Network traffic

### Application Logs

```bash
# View all logs
docker compose logs -f

# View specific service
docker compose logs -f api

# View last 100 lines
docker compose logs --tail=100 api
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs api

# Check resource usage
docker stats

# Restart service
docker compose restart api
```

### Database Connection Issues

```bash
# Check PostgreSQL logs
docker compose logs postgres

# Connect to database
docker compose exec postgres psql -U localstore
```

## Rollback Procedure

### Application Rollback

```bash
# Pull previous image version
docker pull localstore/api:v1.0.0

# Update docker-compose.prod.yml with previous version
# Or use environment variable
API_VERSION=v1.0.0 docker compose -f docker-compose.prod.yml up -d api
```

### Infrastructure Rollback

```bash
# View Terraform state history
terraform state list

# Import previous state if needed
terraform import aws_instance.app i-previous-id

# Or revert to previous Terraform code and apply
git checkout HEAD~1 -- terraform/
terraform apply
```

## Cost Optimization

- Use Reserved Instances for production (up to 40% savings)
- Consider Spot Instances for non-critical workloads
- Enable CloudFront for static assets to reduce EC2 load
- Review CloudWatch metrics to right-size instances

## Related Documents

- [SPEC_LINKS.md](../SPEC_LINKS.md) - Specification references
- [SECURITY.md](SECURITY.md) - Security configuration
- [MONITORING.md](MONITORING.md) - Monitoring setup

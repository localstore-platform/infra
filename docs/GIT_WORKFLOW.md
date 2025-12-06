# Git Workflow Guide

This document describes the Git workflow for the LocalStore Platform infrastructure repository.

## Branch Strategy

### Main Branches

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready code | Protected, requires PR |
| `develop` | Integration branch | Protected, requires PR |

### Feature Branches

```plaintext
feature/{ticket-id}-{description}
bugfix/{ticket-id}-{description}
hotfix/{ticket-id}-{description}
```

**Examples:**

- `feature/INFRA-001-vpc-setup`
- `bugfix/INFRA-002-security-group-fix`
- `hotfix/INFRA-003-ssl-renewal`

## Workflow

### 1. Starting New Work

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/INFRA-001-vpc-setup
```

### 2. Making Changes

```bash
# Make changes to Terraform, Docker, etc.

# Check Terraform format
cd terraform/environments/dev
terraform fmt -recursive
terraform validate

# Stage and commit
git add .
git commit -m "feat(vpc): add VPC and subnet configuration"
```

### 3. Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```plaintext
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature (Terraform module, Docker config)
- `fix`: Bug fix
- `docs`: Documentation only
- `chore`: Maintenance (dependencies, scripts)
- `refactor`: Code change that neither fixes nor adds
- `ci`: CI/CD changes

**Scopes:**

- `vpc`, `ec2`, `rds`, `s3` - Terraform modules
- `docker`, `nginx` - Docker configurations
- `ci`, `github` - CI/CD workflows
- `docs` - Documentation

**Examples:**

```plaintext
feat(ec2): add production EC2 instance configuration
fix(nginx): correct SSL certificate path
docs(readme): update deployment instructions
ci(terraform): add plan output to PR comments
```

### 4. Pushing Changes

```bash
# Push feature branch
git push origin feature/INFRA-001-vpc-setup
```

### 5. Creating Pull Request

1. Open PR on GitHub
2. Fill in the PR template (see [PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md))
3. Attach Terraform plan output
4. Request review from `@localstore-platform/infra-team`

### 6. Code Review

Reviewers should check:

- [ ] Terraform plan output is attached
- [ ] No secrets in code
- [ ] Resources properly tagged
- [ ] Cost impact noted
- [ ] Rollback plan documented

### 7. Merging

After approval:

1. Squash and merge (preferred)
2. Delete feature branch
3. Monitor deployment

## Terraform-Specific Workflow

### Before Every PR

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Generate plan
terraform plan -out=plan.tfplan

# Review plan
terraform show plan.tfplan
```

### State Management

- **Remote state:** Always use S3 backend with DynamoDB locking
- **Never commit:** `.tfstate`, `.tfstate.backup` files
- **State locking:** Required for all environments

### Environment Promotion

```plaintext
dev → staging → prod
```

1. Test changes in `dev` environment first
2. Create PR to `develop` branch
3. Deploy to `staging` for testing
4. Create PR from `develop` to `main`
5. Deploy to `prod` after approval

## Protected Branch Rules

### main branch

- Require PR before merging
- Require at least 1 approval
- Require status checks (terraform validate, fmt)
- No force pushes

### develop branch

- Require PR before merging
- Require at least 1 approval

## Emergency Procedures

### Hotfix Process

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/INFRA-999-urgent-fix

# Make minimal fix
# ... changes ...

# Push and create PR directly to main
git push origin hotfix/INFRA-999-urgent-fix
```

### Rollback

```bash
# Terraform rollback
cd terraform/environments/prod
terraform apply -target=module.affected_module -var "version=previous"

# Or full rollback using state
terraform state list
terraform import ... (if needed)
```

## Useful Commands

```bash
# Check what Terraform will change
terraform plan -detailed-exitcode

# Apply only specific resource
terraform apply -target=aws_instance.app

# Show current state
terraform state list
terraform state show aws_instance.app

# Import existing resource
terraform import aws_instance.app i-1234567890abcdef0
```

## Related Documents

- [SPEC_LINKS.md](SPEC_LINKS.md) - Specification references
- [.github/copilot-instructions.md](.github/copilot-instructions.md) - Coding guidelines
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment guide

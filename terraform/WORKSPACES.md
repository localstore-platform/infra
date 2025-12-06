# Terraform Workspaces Guide

This project uses **Terraform Workspaces** to manage multiple environments (dev, staging, prod) from a single configuration.

## Why Workspaces?

| Approach | Pros | Cons |
|----------|------|------|
| **Separate folders** (old) | Complete isolation | Duplicated code, drift risk |
| **Workspaces** (current) | DRY, consistent | Shared state backend |

## Quick Start

```bash
cd terraform

# Initialize Terraform
terraform init

# Create workspaces (one-time)
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Select workspace
terraform workspace select dev

# Plan with environment-specific vars
terraform plan -var-file="tfvars/dev.tfvars"

# Apply
terraform apply -var-file="tfvars/dev.tfvars"
```

## Workspace Commands

```bash
# List workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Switch workspace
terraform workspace select <name>

# Delete workspace (must switch away first)
terraform workspace delete <name>
```

## Directory Structure

```text
terraform/
├── main.tf              # Main configuration (uses terraform.workspace)
├── variables.tf         # Variable declarations
├── outputs.tf           # Output definitions
├── tfvars/
│   ├── dev.tfvars       # Dev environment values
│   ├── staging.tfvars   # Staging environment values
│   └── prod.tfvars      # Production environment values
└── modules/
    ├── vpc/             # VPC module
    ├── ec2/             # EC2 module
    ├── rds/             # RDS module (future)
    └── s3/              # S3 module (future)
```

## Environment Configuration

The `main.tf` includes environment-specific defaults:

```hcl
locals {
  env_config = {
    dev = {
      instance_type = "t2.micro"
      create_eip    = false
    }
    staging = {
      instance_type = "t2.small"
      create_eip    = true
    }
    prod = {
      instance_type = "t2.small"
      create_eip    = true
    }
  }
}
```

These can be overridden via tfvars files.

## State Management

Each workspace has its own state file in S3:

```
s3://localstore-terraform-state/
├── env:/dev/terraform.tfstate
├── env:/staging/terraform.tfstate
└── env:/prod/terraform.tfstate
```

## CI/CD Integration

```yaml
# Example GitHub Actions
- name: Select Workspace
  run: terraform workspace select ${{ env.ENVIRONMENT }}

- name: Plan
  run: terraform plan -var-file="tfvars/${{ env.ENVIRONMENT }}.tfvars"
```

## Best Practices

1. **Always verify workspace** before applying:
   ```bash
   terraform workspace show
   ```

2. **Use tfvars files** for environment-specific values

3. **Never use `default` workspace** for real environments

4. **Lock sensitive vars** via environment variables:
   ```bash
   export TF_VAR_db_password="secure_password"
   ```

5. **Review plan output** before applying, especially in prod

## Migrating from Folder-Based Environments

If you previously used separate folders:

1. Create the new workspace
2. Import existing resources:
   ```bash
   terraform workspace select prod
   terraform import module.vpc.aws_vpc.main vpc-xxxxx
   terraform import module.ec2.aws_instance.app i-xxxxx
   ```
3. Verify with `terraform plan`
4. Remove old state files after confirming

## Troubleshooting

### "Workspace does not exist"
```bash
terraform workspace new <name>
```

### Wrong workspace applied
Always check before apply:
```bash
terraform workspace show
echo "Applying to: $(terraform workspace show)"
```

### State conflicts
Use DynamoDB locking (already configured in backend).

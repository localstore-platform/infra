# EC2 Module

Creates EC2 instance for LocalStore Platform MVP deployment.

## Resources Created

- EC2 instance (t2.small by default)
- Security groups for HTTP, HTTPS, SSH
- Elastic IP (optional)

## Usage

```hcl
module "ec2" {
  source = "../../modules/ec2"

  environment   = "prod"
  instance_type = "t2.small"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_id
  key_name      = "localstore-prod-key"
  admin_ip      = "YOUR_IP/32"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment name | string | required |
| instance_type | EC2 instance type | string | "t2.small" |
| vpc_id | VPC ID | string | required |
| subnet_id | Subnet ID | string | required |
| key_name | SSH key pair name | string | required |
| admin_ip | Admin IP for SSH (CIDR) | string | required |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| public_ip | EC2 public IP address |

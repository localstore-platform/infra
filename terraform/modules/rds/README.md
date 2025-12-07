# RDS Module (Planned)

This module will create RDS PostgreSQL instances for production scaling.

## Resources (To Be Created)

- RDS PostgreSQL instance
- DB subnet group
- Security group
- Parameter group
- Option group

## Usage (Future)

```hcl
module "rds" {
  source = "../../modules/rds"
  
  environment     = "prod"
  instance_class  = "db.t3.micro"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  db_name         = "localstore"
  db_username     = "localstore"
}
```

## Notes

For MVP, we use PostgreSQL in Docker Compose on EC2.
RDS will be implemented when scaling beyond single server.

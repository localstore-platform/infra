# S3 Module (Planned)

This module will create S3 buckets for assets and backups.

## Resources (To Be Created)

- S3 bucket for static assets
- S3 bucket for database backups
- Bucket policies
- Lifecycle rules
- CloudFront distribution (optional)

## Usage (Future)

```hcl
module "s3" {
  source = "../../modules/s3"
  
  environment  = "prod"
  bucket_name  = "localstore-assets"
}
```

## Notes

For MVP, assets are served directly from the API.
S3 + CloudFront will be implemented for production scaling.

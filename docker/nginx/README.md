# Nginx Configuration

This directory contains Nginx reverse proxy configurations for production deployment.

## Domains

CloudFlare free SSL covers `*.localstore-platform.com` (single-level wildcards only).
Multi-level subdomains like `api.dev.example.com` require paid Advanced Certificate Manager.

| Environment | API Domain                            |
| ----------- | ------------------------------------- |
| dev         | `api-dev.localstore-platform.com`     |
| staging     | `api-staging.localstore-platform.com` |
| prod        | `api.localstore-platform.com`         |

## Files

- `nginx.conf` - Main Nginx configuration
- `conf.d/api.conf` - API server configuration (CloudFlare proxy mode)

## CloudFlare Proxy Mode

When CloudFlare proxy is enabled (orange cloud icon), you get **FREE**:

| Feature       | Description                                      |
| ------------- | ------------------------------------------------ |
| SSL/TLS       | Auto-provisioned certificates                    |
| DDoS Protection | Layer 3/4/7 DDoS mitigation                    |
| WAF           | Web Application Firewall (basic rules)           |
| CDN           | Edge caching for static assets                   |
| Hidden Origin | EC2 IP not exposed publicly                      |

### Architecture

```plaintext
User ──HTTPS──> CloudFlare Edge ──HTTP──> EC2 (nginx port 80) ──> API
                (SSL termination)         (no SSL config needed)
```

### CloudFlare SSL Mode

Set to "Flexible" in CloudFlare dashboard:

- **Flexible**: CloudFlare → Origin via HTTP (recommended for this setup)

---

## Terraform CloudFlare Integration

DNS records are managed automatically by Terraform:

```hcl
# In terraform/main.tf
module "cloudflare_dns" {
  source      = "./modules/cloudflare-dns"
  environment = local.environment
  origin_ip   = module.ec2.public_ip
  proxied     = true  # Enable CloudFlare proxy
}
```

### Required Environment Variable

```bash
export CLOUDFLARE_API_TOKEN="your-api-token-here"
```

Create token at: <https://dash.cloudflare.com/profile/api-tokens>

- Permissions: Zone:DNS:Edit
- Zone Resources: Include → localstore-platform.com

---

## Deployment Sequence

1. **Set CloudFlare API token**:

   ```bash
   export CLOUDFLARE_API_TOKEN="your-token"
   ```

2. **Deploy infrastructure** (creates EC2 + DNS record):

   ```bash
   make deploy-infra ENV=dev
   ```

3. **Start services**:

   ```bash
   make deploy-app ENV=dev
   ```

4. **Verify**:

   ```bash
   curl -I https://api-dev.localstore-platform.com/health
   ```

No SSL certificate management needed! CloudFlare handles everything.

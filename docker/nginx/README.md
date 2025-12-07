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
- `conf.d/api.conf` - API server configuration with HTTPS

## CloudFlare Full (Strict) Mode

We use CloudFlare's **Full (Strict)** SSL mode with Origin Certificates for end-to-end encryption.

### Architecture

```plaintext
User ──HTTPS──> CloudFlare Edge ──HTTPS──> EC2 (nginx port 443) ──> API
                (edge cert)        (origin cert)
```

### SSL Modes Comparison

| Mode | Browser → CF | CF → Origin | Security |
|------|-------------|-------------|----------|
| Flexible | HTTPS | HTTP | Low ❌ |
| Full | HTTPS | HTTPS (any cert) | Medium |
| **Full (Strict)** | HTTPS | HTTPS (valid cert) | **High ✅** |

---

## CloudFlare Origin Certificate Setup

### Step 1: Generate Origin Certificate

1. Go to CloudFlare Dashboard → `localstore-platform.com`
2. Click **SSL/TLS** → **Origin Server**
3. Click **Create Certificate**
4. Options:
   - Let CloudFlare generate a private key
   - Hostnames: `*.localstore-platform.com`, `localstore-platform.com`
   - Validity: 15 years (recommended)
5. Copy the **Origin Certificate** (PEM format)
6. Copy the **Private Key** (PEM format)

### Step 2: Save Certificates Locally

```bash
# Create ssl directory (gitignored)
mkdir -p ssl

# Paste the certificate
cat > ssl/origin.pem << 'EOF'
-----BEGIN CERTIFICATE-----
<paste certificate here>
-----END CERTIFICATE-----
EOF

# Paste the private key
cat > ssl/origin-key.pem << 'EOF'
-----BEGIN PRIVATE KEY-----
<paste private key here>
-----END PRIVATE KEY-----
EOF

# Secure the files
chmod 600 ssl/origin-key.pem
```

### Step 3: Set CloudFlare SSL Mode

1. CloudFlare Dashboard → SSL/TLS → Overview
2. Set encryption mode to **Full (Strict)**

### Step 4: Deploy

```bash
make deploy-app ENV=dev
```

The deploy script will automatically copy SSL certificates to EC2.

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

2. **Generate and save Origin Certificate** (see above)

3. **Set CloudFlare SSL mode to "Full (Strict)"**

4. **Deploy infrastructure** (creates EC2 + DNS record):

   ```bash
   make deploy-infra ENV=dev
   ```

5. **Deploy application** (copies SSL certs + starts containers):

   ```bash
   make deploy-app ENV=dev
   ```

6. **Verify**:

   ```bash
   curl -I https://api-dev.localstore-platform.com/api/v1/health
   ```

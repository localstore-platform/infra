# CloudFlare DNS Module
# Manages DNS records for LocalStore Platform
#
# Prerequisites:
#   - CLOUDFLARE_API_TOKEN environment variable set
#   - Token needs Zone:DNS:Edit permissions
#
# CloudFlare proxy mode (orange cloud) provides:
#   - Free SSL/TLS certificates
#   - DDoS protection
#   - WAF (Web Application Firewall)
#   - CDN caching

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# Get the zone ID for the domain
data "cloudflare_zone" "main" {
  filter = {
    name = var.domain
  }
}

# API subdomain record
# CloudFlare free SSL covers *.localstore-platform.com (single-level only)
# So we use: api-dev, api-staging, api (not api.dev, api.staging)
#
# dev:     api-dev.localstore-platform.com
# staging: api-staging.localstore-platform.com
# prod:    api.localstore-platform.com
resource "cloudflare_dns_record" "api" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = var.environment == "prod" ? "api" : "api-${var.environment}"
  content = var.origin_ip
  type    = "A"
  ttl     = 1 # Auto TTL when proxied
  proxied = var.proxied

  comment = "LocalStore API - ${var.environment} environment"
}

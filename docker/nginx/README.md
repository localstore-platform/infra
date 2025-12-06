# Nginx Configuration

This directory contains Nginx reverse proxy configurations for production deployment.

## Files

- `nginx.conf` - Main Nginx configuration
- `conf.d/` - Site-specific configurations

## Features

- SSL/TLS termination (Let's Encrypt)
- Reverse proxy to API services
- Gzip compression
- Security headers
- Rate limiting

## SSL Certificate Setup

```bash
# Install Certbot
sudo apt-get install certbot

# Generate certificate
sudo certbot certonly --webroot -w /var/www/certbot -d yourdomain.com

# Auto-renewal is handled by cron
```

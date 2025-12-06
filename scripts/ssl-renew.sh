#!/bin/bash
# LocalStore Platform - SSL Certificate Renewal Script
# Usage: ./ssl-renew.sh

set -e

echo "=== SSL Certificate Renewal ==="

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo yum install -y certbot
fi

# Renew certificates
echo "Renewing SSL certificates..."
sudo certbot renew --quiet

# Check certificate status
echo ""
echo "Certificate status:"
sudo certbot certificates

# Reload Nginx if Docker is running
if docker ps | grep -q "localstore-nginx"; then
    echo ""
    echo "Reloading Nginx..."
    docker exec localstore-nginx nginx -s reload
    echo "Nginx reloaded successfully."
fi

echo ""
echo "=== SSL Renewal Complete ==="

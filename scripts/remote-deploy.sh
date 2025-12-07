#!/bin/bash
# =============================================================================
# Remote Deployment Script
# =============================================================================
# This script runs on the EC2 instance to deploy the application.
# It is copied and executed by deploy.sh to avoid heredoc issues.
# =============================================================================

set -e

COMPOSE_DIR="/opt/localstore"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
ECR_REGISTRY="${ECR_REGISTRY:-767828741221.dkr.ecr.ap-southeast-1.amazonaws.com}"

cd "$COMPOSE_DIR"

echo "=== Remote Deployment Script ==="
echo "Working directory: $(pwd)"

# ECR Login
echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$ECR_REGISTRY" 2>/dev/null || \
    echo "Warning: ECR login failed. Will use local/public images only."

# Update .env with ECR_REGISTRY if not set
if ! grep -q "^ECR_REGISTRY=" .env 2>/dev/null; then
    echo "ECR_REGISTRY=$ECR_REGISTRY" >> .env
fi

# Pull latest images
echo "Pulling latest images..."
docker compose pull || echo "Some images may not be available yet"

# Run database migrations BEFORE starting the API
echo "Running database migrations..."
docker compose run --rm api pnpm run migration:run:prod || {
    echo "ERROR: Database migrations failed!"
    exit 1
}
echo "✓ Migrations completed successfully."

# Start all services
echo "Starting services..."
docker compose up -d

# Show running containers
echo "Running containers:"
docker compose ps

echo "=== Remote Deployment Complete ==="

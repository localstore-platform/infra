#!/bin/bash
# =============================================================================
# Database Seed Script
# =============================================================================
# Seeds the database with sample data for development environment.
# This script runs on the EC2 instance after deployment.
#
# NOTE: Requires API repo to provide a compiled seed command (seed:compiled)
#       that works without ts-node. See Slack #agent-events for details.
# =============================================================================

set -e

COMPOSE_DIR="/opt/localstore"
MAX_RETRIES=30
RETRY_INTERVAL=2

cd "$COMPOSE_DIR"

echo "=== Database Seed Script ==="

# Wait for API to be ready
echo "Waiting for API to be ready..."
for i in $(seq 1 $MAX_RETRIES); do
    if docker compose exec -T api wget --no-verbose --tries=1 --spider http://localhost:8080/api/v1/health 2>/dev/null; then
        echo "API is ready!"
        
        # Run seed command
        echo "Running database seed..."
        if docker compose exec -T api pnpm run seed; then
            echo "✓ Database seeding completed successfully."
        else
            echo "⚠ Warning: Database seeding failed. This may be okay if data already exists."
        fi
        
        exit 0
    fi
    
    echo "Attempt $i/$MAX_RETRIES: API not ready yet, waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "✗ Error: API did not become ready after $MAX_RETRIES attempts. Skipping seed."
exit 1

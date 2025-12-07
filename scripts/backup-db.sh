#!/bin/bash
# LocalStore Platform - Database Backup Script
# Usage: ./backup-db.sh [backup_name]

set -e

BACKUP_NAME=${1:-"backup-$(date +%Y%m%d-%H%M%S)"}
BACKUP_DIR="/opt/localstore/backups"
S3_BUCKET=${S3_BACKUP_BUCKET:-"localstore-prod-backups"}

echo "=== LocalStore Database Backup ==="
echo "Backup Name: $BACKUP_NAME"
echo "=================================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Get database credentials from environment
DB_CONTAINER="localstore-postgres"
DB_NAME=${DB_NAME:-"localstore"}
DB_USER=${DB_USER:-"localstore"}

# Create backup
echo "Creating database backup..."
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -f "/tmp/$BACKUP_NAME.dump"

# Copy backup from container
docker cp "$DB_CONTAINER:/tmp/$BACKUP_NAME.dump" "$BACKUP_DIR/$BACKUP_NAME.dump"

# Compress backup
echo "Compressing backup..."
gzip "$BACKUP_DIR/$BACKUP_NAME.dump"

# Upload to S3 (optional)
if command -v aws &> /dev/null && [ -n "$S3_BACKUP_BUCKET" ]; then
    echo "Uploading to S3..."
    aws s3 cp "$BACKUP_DIR/$BACKUP_NAME.dump.gz" "s3://$S3_BUCKET/$BACKUP_NAME.dump.gz"
    echo "Backup uploaded to s3://$S3_BUCKET/$BACKUP_NAME.dump.gz"
fi

# Cleanup old local backups (keep last 7)
echo "Cleaning up old backups..."
ls -t "$BACKUP_DIR"/*.dump.gz 2>/dev/null | tail -n +8 | xargs -r rm

echo ""
echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME.dump.gz"
echo "Size: $(du -h "$BACKUP_DIR/$BACKUP_NAME.dump.gz" | cut -f1)"

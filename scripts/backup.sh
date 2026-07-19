#!/bin/bash
# MyCosmetics Production Backup Script
# Runs: daily via cron (0 2 * * *) and before every deployment
# Retention: 7 daily, 4 weekly, 12 monthly

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/backups
DAILY_DIR=$BACKUP_DIR/daily
WEEKLY_DIR=$BACKUP_DIR/weekly
MONTHLY_DIR=$BACKUP_DIR/monthly

mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR"

FILENAME="mycosmetics_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting backup: $FILENAME"

# Full database dump (compressed)
PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --no-password \
  --format=custom \
  --compress=9 \
  --lock-wait-timeout=30s \
  | gzip > "$DAILY_DIR/$FILENAME"

# Verify backup integrity
if gzip -t "$DAILY_DIR/$FILENAME"; then
  echo "[$(date)] Backup verified OK: $DAILY_DIR/$FILENAME"
else
  echo "[$(date)] ERROR: Backup verification FAILED" >&2
  exit 1
fi

# Weekly backup (every Sunday)
DOW=$(date +%u)
if [ "$DOW" -eq 7 ]; then
  cp "$DAILY_DIR/$FILENAME" "$WEEKLY_DIR/$FILENAME"
  echo "[$(date)] Weekly backup saved"
fi

# Monthly backup (1st of month)
DOM=$(date +%d)
if [ "$DOM" -eq 1 ]; then
  cp "$DAILY_DIR/$FILENAME" "$MONTHLY_DIR/$FILENAME"
  echo "[$(date)] Monthly backup saved"
fi

# Retention cleanup
find "$DAILY_DIR"  -name "*.sql.gz" -mtime +7   -delete
find "$WEEKLY_DIR" -name "*.sql.gz" -mtime +28  -delete
find "$MONTHLY_DIR" -name "*.sql.gz" -mtime +365 -delete

echo "[$(date)] Backup complete. Size: $(du -sh "$DAILY_DIR/$FILENAME" | cut -f1)"

# Optional: upload to S3/GCS
# aws s3 cp "$DAILY_DIR/$FILENAME" "s3://${BACKUP_BUCKET}/database/$FILENAME"

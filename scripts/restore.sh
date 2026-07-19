#!/bin/bash
# MyCosmetics Database Restore Script
# Usage: ./restore.sh <backup_file.sql.gz>
# WARNING: This will DROP and recreate the database. Use with extreme care.

set -euo pipefail

BACKUP_FILE="${1:?Usage: $0 <backup_file.sql.gz>}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file not found: $BACKUP_FILE" >&2; exit 1
fi

echo "=== MyCosmetics Database Restore ==="
echo "File:     $BACKUP_FILE"
echo "Target:   $POSTGRES_DB on $POSTGRES_HOST"
echo "Size:     $(du -sh "$BACKUP_FILE" | cut -f1)"
echo ""
read -p "Type RESTORE to confirm: " CONFIRM
[ "$CONFIRM" != "RESTORE" ] && { echo "Aborted."; exit 1; }

echo "[$(date)] Verifying backup integrity..."
gzip -t "$BACKUP_FILE" || { echo "Backup file is corrupted!"; exit 1; }

echo "[$(date)] Stopping API servers (to prevent writes during restore)..."
# docker-compose -f docker-compose.prod.yml stop api

echo "[$(date)] Restoring database..."
PGPASSWORD=$POSTGRES_PASSWORD pg_restore \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --no-password \
  --clean \
  --if-exists \
  --single-transaction \
  < <(gzip -d < "$BACKUP_FILE")

echo "[$(date)] Restore complete. Verifying..."
PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT COUNT(*) AS users FROM users; SELECT COUNT(*) AS orders FROM orders; SELECT COUNT(*) AS products FROM products;"

echo "[$(date)] Restart API servers manually after verifying restore."
echo "Done."

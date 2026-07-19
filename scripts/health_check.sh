#!/bin/bash
# MyCosmetics Health Check Script
# Run via cron every 5 minutes: */5 * * * * /opt/mycosmetics/scripts/health_check.sh

set -euo pipefail

API_URL="${API_URL:-https://api.mycosmetics.app}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
LOG_FILE=/var/log/mycosmetics/health.log

mkdir -p "$(dirname "$LOG_FILE")"

check() {
  local name="$1" url="$2"
  local status
  status=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$url") || status="TIMEOUT"
  if [ "$status" = "200" ]; then
    echo "[$(date)] OK  $name ($status)"
  else
    echo "[$(date)] ERR $name ($status)" | tee -a "$LOG_FILE"
    if [ -n "$SLACK_WEBHOOK" ]; then
      curl -s -X POST "$SLACK_WEBHOOK" \
        -H 'Content-type: application/json' \
        -d "{\"text\":\"⚠️ Health check FAILED: $name returned $status\"}"
    fi
    exit 1
  fi
}

check "API Health"    "$API_URL/health"
check "API Insights"  "${API_URL%:*}:8081/health" 2>/dev/null || echo "[$(date)] INFO insights unreachable (non-critical)"

echo "[$(date)] All health checks passed"

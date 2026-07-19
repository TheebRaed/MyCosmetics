# MyCosmetics Platform — Maintenance Guide

## Daily Tasks (Automated)
- Database backup runs at 02:00 UTC → `/backups/daily/`
- Health check runs every 5 minutes → alerts Slack on failure
- Redis TTL expiry cleans stale cache entries automatically

## Weekly Tasks
- Review Grafana dashboard for anomalies
- Check slow query log: `SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20`
- Review audit log for suspicious admin actions
- Verify weekly backup was created: `ls -la /backups/weekly/`

## Monthly Tasks
- Test disaster recovery: restore from backup in staging
- Rotate API keys (Stripe, cloud storage)
- Review and purge rate_limit_events older than 30 days:
  ```sql
  DELETE FROM rate_limit_events WHERE "createdAt" < NOW() - INTERVAL '30 days';
  ```
- Refresh recommendation analytics views manually if needed

## Slow Query Detection
Configure PostgreSQL to log slow queries (>500ms):
```sql
ALTER SYSTEM SET log_min_duration_statement = 500;
SELECT pg_reload_conf();
```
View slow queries:
```sql
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC LIMIT 20;
```

## Database Maintenance
```sql
-- Vacuum and analyze all tables (run monthly)
VACUUM ANALYZE;

-- Check table sizes
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes ORDER BY idx_scan ASC;
```

## Redis Maintenance
```bash
# Check memory usage
redis-cli -a $REDIS_PASSWORD INFO memory

# Clear expired keys manually
redis-cli -a $REDIS_PASSWORD DEBUG SLEEP 0

# Check key count
redis-cli -a $REDIS_PASSWORD DBSIZE
```

## Certificate Renewal
SSL certificates auto-renew via certbot cron. To manually renew:
```bash
certbot renew --force-renewal
docker-compose -f /opt/mycosmetics/docker-compose.prod.yml restart nginx
```

## Scaling Guidelines

### When to scale horizontally
- API CPU > 70% sustained for 5+ minutes
- API response time p95 > 500ms
- Database connections > 80% of max_connections

### How to scale
```bash
# Add API replicas (Nginx least_conn handles load balancing)
docker-compose -f docker-compose.prod.yml up -d --scale api=3
```

### Database optimization order
1. Add missing indexes (check pg_stat_user_indexes)
2. Enable pg_stat_statements and identify slow queries
3. Add Redis caching for identified hot paths
4. Consider read replicas for analytics queries
5. Partition large tables (tryon_events, recommendation_events)

## Emergency Procedures

### API not responding
```bash
# 1. Check container status
docker-compose -f docker-compose.prod.yml ps

# 2. View recent logs
docker-compose -f docker-compose.prod.yml logs --tail=100 api

# 3. Restart API
docker-compose -f docker-compose.prod.yml restart api

# 4. If still failing, check database
docker-compose -f docker-compose.prod.yml exec postgres pg_isready
```

### Database out of disk space
```bash
# 1. Check disk usage
df -h && du -sh /var/lib/docker/volumes/*/

# 2. Clear old backups (keep last 7 days)
find /backups/daily -name "*.sql.gz" -mtime +7 -delete

# 3. Vacuum tables
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U mycosmetics -c "VACUUM FULL ANALYZE;"
```

### Suspected security breach
```bash
# 1. Immediately revoke all user sessions
docker-compose -f docker-compose.prod.yml exec redis \
  redis-cli -a $REDIS_PASSWORD FLUSHDB

# 2. Review audit logs
SELECT * FROM audit_logs ORDER BY "createdAt" DESC LIMIT 100;

# 3. Block suspicious IPs in Nginx
# Add to nginx.conf: deny <suspicious_ip>;

# 4. Rotate all secrets in .env.prod and redeploy
```

# MyCosmetics Production Launch Checklist

## Infrastructure ✅

- [ ] Server provisioned (4 CPU / 8GB RAM / 100GB SSD)
- [ ] DNS configured: api.mycosmetics.app → server IP
- [ ] SSL certificates obtained (Let's Encrypt or commercial)
- [ ] Nginx TLS configuration verified (A+ on SSL Labs)
- [ ] Docker + Docker Compose installed
- [ ] All services healthy: `docker-compose ps`
- [ ] Database migrations applied (all 7 migrations)
- [ ] Redis maxmemory + eviction policy configured
- [ ] Automated daily backups running
- [ ] Backup restore tested successfully
- [ ] Health check cron running
- [ ] SSL auto-renewal configured

## Security ✅

- [ ] `.env.prod` not in version control
- [ ] All default passwords changed
- [ ] Postgres not exposed to internet (only internal Docker network)
- [ ] Redis not exposed to internet
- [ ] Nginx rate limiting active (test: `ab -n 100 -c 10 /auth/login`)
- [ ] HTTPS redirect working (HTTP → HTTPS 301)
- [ ] Security headers present: `curl -I https://api.mycosmetics.app/health`
- [ ] HSTS enabled (check Strict-Transport-Security header)
- [ ] Stripe webhook secret configured
- [ ] Session secret is 64+ random bytes

## Payments ✅

- [ ] Stripe account in live mode
- [ ] Live API keys configured (not test keys)
- [ ] Webhook endpoint registered in Stripe dashboard
- [ ] Webhook events configured: payment_intent.succeeded, payment_intent.payment_failed, charge.refunded
- [ ] Test payment end-to-end with real card
- [ ] COD orders tested end-to-end
- [ ] Refund workflow tested

## App Release ✅

- [ ] Android keystore created and backed up securely
- [ ] App signed with release keystore
- [ ] Google Play Console app created
- [ ] AAB uploaded and tested in internal testing
- [ ] iOS signing certificates + provisioning profiles configured
- [ ] iOS IPA uploaded to App Store Connect
- [ ] App Store review submitted
- [ ] Privacy Policy URL configured in both stores
- [ ] App permissions explained in store listing

## BeautyTech ✅

- [ ] ML Kit models loaded correctly on device
- [ ] Camera permissions granted on first launch
- [ ] Skin analysis tested on 5+ different skin tones
- [ ] Virtual Try-On rendering at 30fps on mid-range device
- [ ] Recommendation engine returns results within 3 seconds
- [ ] Saved looks image upload working (real URLs, not local://)
- [ ] Share functionality tested on iOS and Android

## Admin Dashboard ✅

- [ ] Admin user created with correct role
- [ ] All RBAC roles tested (admin, staff, inventoryManager, customerSupport, marketingManager)
- [ ] Dashboard KPIs loading correctly
- [ ] Charts rendering (line, bar, pie)
- [ ] Order status workflow tested
- [ ] Stock adjustment with audit log verified
- [ ] Notification create + send tested
- [ ] Audit log recording admin actions

## Monitoring ✅

- [ ] Grafana dashboard accessible
- [ ] Prometheus scraping all targets
- [ ] Slack webhook configured for alerts
- [ ] Error alerting tested
- [ ] Slow query detection active (Postgres log_min_duration_statement = 500ms)

## Performance ✅

- [ ] API response time < 200ms for catalog endpoints (p95)
- [ ] API response time < 500ms for recommendation generation
- [ ] Database connection pool configured correctly
- [ ] Redis cache hit rate > 60% for product listings
- [ ] Flutter app starts < 3 seconds cold start
- [ ] Image loading uses CDN-optimised URLs

## Legal & Compliance ✅

- [ ] Privacy Policy published (GDPR + local regulations)
- [ ] Terms of Service published
- [ ] Cookie policy (web dashboard)
- [ ] Data retention policy documented
- [ ] User data deletion workflow tested
- [ ] Payment card data: NEVER stored locally (Stripe handles all card data)

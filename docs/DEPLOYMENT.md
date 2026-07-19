# MyCosmetics — Production Deployment Guide

## Prerequisites

- Ubuntu 22.04 LTS server (min 4 CPU, 8GB RAM, 100GB SSD)
- Docker 24.x + Docker Compose v2
- Domain name with DNS pointing to server IP
- SSL certificates (Let's Encrypt via Certbot)
- GitHub repository access

---

## Step 1 — Server Preparation

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy

# Install Certbot
apt install -y certbot
certbot certonly --standalone -d api.mycosmetics.app

# Create app directory
mkdir -p /opt/mycosmetics/nginx/certs
mkdir -p /opt/mycosmetics/backups/{daily,weekly,monthly}
mkdir -p /opt/mycosmetics/scripts

# Link SSL certs
ln -s /etc/letsencrypt/live/api.mycosmetics.app/fullchain.pem /opt/mycosmetics/nginx/certs/
ln -s /etc/letsencrypt/live/api.mycosmetics.app/privkey.pem  /opt/mycosmetics/nginx/certs/
```

## Step 2 — Clone & Configure

```bash
cd /opt/mycosmetics
git clone https://github.com/yourorg/mycosmetics.git .

# Copy and configure environment
cp .env.example .env.prod
nano .env.prod  # Fill in all real values

# Set permissions
chmod 600 .env.prod
chmod +x scripts/*.sh
```

## Step 3 — First Deploy

```bash
cd /opt/mycosmetics

# Start services
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec api \
  ./bin/server --mode=production --apply-migrations

# Verify
docker-compose -f docker-compose.prod.yml ps
curl https://api.mycosmetics.app/health
```

## Step 4 — Automated Backups

```bash
# Daily backup cron (runs at 2am)
echo "0 2 * * * deploy /opt/mycosmetics/scripts/backup.sh >> /var/log/mycosmetics/backup.log 2>&1" \
  | crontab -

# Health check cron (every 5 minutes)
echo "*/5 * * * * deploy /opt/mycosmetics/scripts/health_check.sh" \
  | crontab -

# SSL renewal (twice daily)
echo "0 0,12 * * * root certbot renew --quiet && docker-compose -f /opt/mycosmetics/docker-compose.prod.yml restart nginx" \
  | crontab -
```

## Step 5 — SSL Renewal Automation

```bash
# Test renewal
certbot renew --dry-run
```

---

## Rolling Deployment (Zero Downtime)

```bash
# 1. Pull new image
docker-compose -f docker-compose.prod.yml pull api

# 2. Backup database
./scripts/backup.sh

# 3. Start new replica alongside old
docker-compose -f docker-compose.prod.yml up -d --no-deps --scale api=2 api

# 4. Wait for health check
sleep 15 && curl -f https://api.mycosmetics.app/health

# 5. Apply migrations (if any)
docker-compose -f docker-compose.prod.yml exec api ./bin/server --mode=production --apply-migrations

# 6. Scale back to normal
docker-compose -f docker-compose.prod.yml up -d --no-deps --scale api=1 api
```

## Rollback Procedure

```bash
# Option A: Roll back to previous image tag
docker-compose -f docker-compose.prod.yml up -d --no-deps api

# Option B: Database point-in-time restore
./scripts/restore.sh /backups/daily/mycosmetics_YYYYMMDD_HHMMSS.sql.gz
```

---

## Environment Variables Reference

See `.env.example` for complete list with descriptions.
Required secrets (never commit):
- `POSTGRES_PASSWORD` — min 32 random chars
- `REDIS_PASSWORD` — min 32 random chars
- `SERVERPOD_SESSION_SECRET` — 64+ bytes base64
- `STRIPE_SECRET_KEY` — from Stripe dashboard
- `STRIPE_WEBHOOK_SECRET` — from Stripe webhook config

# MyCosmetics Platform — System Architecture

## Overview

MyCosmetics is a full-stack BeautyTech e-commerce platform consisting of:

| Component | Technology | Purpose |
|---|---|---|
| Customer App | Flutter 3.22 (iOS + Android) | End-user shopping + BeautyTech |
| Admin Dashboard | Flutter 3.22 (Web / Tablet) | Business management |
| API Server | Serverpod 2.x (Dart) | REST API + WebSocket |
| Database | PostgreSQL 16 | Primary data store |
| Session Store | Redis 7 | Auth tokens + caching |
| Reverse Proxy | Nginx 1.25 | TLS + rate limiting |
| Storage | AWS S3 / GCS | Images + saved looks |

## System Architecture Diagram

```
                    ┌─────────────────────────────────────┐
                    │           Load Balancer              │
                    │         (Nginx / Cloudflare)         │
                    └──────────┬────────────────┬──────────┘
                               │                │
                    ┌──────────▼──┐    ┌────────▼─────────┐
                    │ Flutter App  │    │  Admin Dashboard  │
                    │ (iOS/Android)│    │    (Flutter Web)  │
                    └──────────┬──┘    └────────┬──────────┘
                               │                │
                    ┌──────────▼────────────────▼──────────┐
                    │          Nginx (TLS Termination)       │
                    │     Rate Limiting + Security Headers   │
                    └──────────────┬────────────────────────┘
                                   │
                    ┌──────────────▼────────────────────────┐
                    │    Serverpod API (Dart)  ×2 replicas   │
                    │    Port 8080 (API) | 8081 (Insights)   │
                    └────┬──────────────────────────┬───────┘
                         │                          │
            ┌────────────▼─────────┐   ┌───────────▼────────┐
            │   PostgreSQL 16       │   │    Redis 7          │
            │   Primary data store  │   │    Session tokens   │
            │   + Analytics views   │   │    Response cache   │
            └───────────────────────┘   └────────────────────┘
```

## Authentication Flow

```
Client → POST /auth/login → Serverpod
  ↓ Validate credentials (bcrypt)
  ↓ Generate UUID token
  ↓ Store: Redis SET session:{token} {userId} EX 604800
  ↓ Return: {token, user}

Subsequent requests:
  Client → Authorization: Bearer {token} → Serverpod
  ↓ Extract token from header
  ↓ Redis GET session:{token} → userId
  ↓ Optional: DB lookup for role/status
  ↓ Process request
```

## BeautyTech Pipeline

```
Camera Frame → ML Kit Face Detection (on-device)
  ↓ Face bounding box + landmarks
  ↓ SkinToneAnalyser.analyse()
  ↓ PaletteGenerator → dominant colour
  ↓ Brightness (ITU-R 601) + Undertone (RGB warmth ratio)
  ↓ Uniformity (colour variance) + Confidence (head angle)
  ↓ POST /beautyTech/saveSkinAnalysis
  ↓ SkinProfile upserted + SkinAnalysisResult created (atomic)
  ↓ POST /beautyTech/generateRecommendations
  ↓ RecommendationEngine v2.0 (5-factor scoring)
  ↓ Results → Flutter RecommendationsScreen
  ↓ User taps "Try On" → VirtualTryOnScreen
  ↓ MakeupOverlayPainter (CustomPainter) renders in real-time
```

## Database Schema Summary

### Core Tables (Phases 0-3)
- `users` — accounts with RBAC role
- `addresses` — shipping addresses
- `skin_profiles` — beauty profile data
- `password_reset_tokens` — secure reset flow
- `categories`, `brands` — catalog taxonomy
- `products`, `product_variants`, `product_images` — catalog
- `carts`, `cart_items` — shopping cart
- `coupons` — discount codes
- `orders`, `order_items`, `order_status_history` — order lifecycle
- `reviews` — verified-purchase reviews
- `wishlist_items` — saved products

### BeautyTech Tables (Phases 5-6)
- `shade_recommendations` — AI shade picks with 5-factor scores
- `saved_looks` — captured Try-On sessions
- `tryon_events` — analytics per shade application
- `skin_analysis_results` — per-scan analysis record
- `recommendation_history` — per-session generation audit
- `recommendation_events` — acceptance/conversion tracking

### Admin Tables (Phase 7)
- `audit_logs` — INSERT-only admin action log (Postgres RLS)
- `stock_adjustments` — inventory change history
- `admin_notifications` — push campaign records

### Production Tables (Phase 8)
- `payments` — multi-provider payment records
- `payment_audit_logs` — INSERT-only payment event log (RLS)
- `refund_requests` — customer refund workflow
- `shipping_zones`, `shipping_methods`, `shipments` — delivery
- `webhook_events` — idempotent webhook processing
- `revenue_daily` — pre-aggregated revenue for dashboard
- `rate_limit_events` — per-IP rate limit tracking

## Security Architecture

| Layer | Control | Implementation |
|---|---|---|
| Transport | TLS 1.2/1.3 only | Nginx SSL configuration |
| Authentication | Bearer token in header | Redis UUID sessions |
| Authorization | RBAC permission matrix | AuthGuard.requirePermission() |
| Rate Limiting | Per-IP per-endpoint | Nginx limit_req_zone |
| Audit | Immutable append-only | Postgres RLS INSERT-only |
| Secrets | Environment variables | Docker secrets / Vault |
| Logging | Sanitised | SecureLogging utility |
| Payments | Webhook signature | Stripe-Signature header |
| Uploads | Size + type validation | Nginx client_max_body_size |

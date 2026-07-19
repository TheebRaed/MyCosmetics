-- Migration: 00000000000006-production
-- Phase 8: Production Payment System + Shipping + Security Hardening

-- ── Payments ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "payments" (
  "id"              bigserial PRIMARY KEY,
  "orderId"         bigint NOT NULL REFERENCES "orders"("id") ON DELETE RESTRICT,
  "provider"        text NOT NULL,
  "method"          text NOT NULL,
  "status"          text NOT NULL DEFAULT 'pending',
  "amount"          double precision NOT NULL,
  "currency"        text NOT NULL DEFAULT 'USD',
  "providerRefId"   text,
  "providerStatus"  text,
  "failureReason"   text,
  "idempotencyKey"  text NOT NULL,
  "paidAt"          timestamp without time zone,
  "refundedAt"      timestamp without time zone,
  "refundedAmount"  double precision,
  "metadata"        text,
  "createdAt"       timestamp without time zone NOT NULL,
  "updatedAt"       timestamp without time zone NOT NULL,
  CONSTRAINT "payment_status_check" CHECK ("status" IN ('pending','authorised','captured','failed','refunded','partialRefund','cancelled')),
  CONSTRAINT "payment_provider_check" CHECK ("provider" IN ('stripe','cod','future')),
  CONSTRAINT "payment_amount_positive" CHECK ("amount" > 0)
);
CREATE UNIQUE INDEX IF NOT EXISTS "payment_order_idx"        ON "payments" ("orderId");
CREATE INDEX        IF NOT EXISTS "payment_provider_ref_idx" ON "payments" ("providerRefId") WHERE "providerRefId" IS NOT NULL;
CREATE INDEX        IF NOT EXISTS "payment_status_idx"       ON "payments" ("status");
CREATE UNIQUE INDEX IF NOT EXISTS "payment_idempotency_idx"  ON "payments" ("idempotencyKey");

-- ── Payment Audit Logs (immutable) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "payment_audit_logs" (
  "id"              bigserial PRIMARY KEY,
  "paymentId"       bigint NOT NULL REFERENCES "payments"("id") ON DELETE RESTRICT,
  "eventType"       text NOT NULL,
  "previousStatus"  text,
  "newStatus"       text NOT NULL,
  "actorId"         bigint,
  "source"          text NOT NULL DEFAULT 'system',
  "providerPayload" text,
  "createdAt"       timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "payment_audit_payment_idx" ON "payment_audit_logs" ("paymentId");
CREATE INDEX IF NOT EXISTS "payment_audit_created_idx" ON "payment_audit_logs" ("createdAt" DESC);

-- RLS: payment audit logs are INSERT-only
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='payment_audit_logs' AND policyname='payment_audit_insert_only') THEN
    ALTER TABLE "payment_audit_logs" ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "payment_audit_insert_only" ON "payment_audit_logs" FOR INSERT WITH CHECK (true);
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END; $$;

-- ── Refund Requests ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "refund_requests" (
  "id"          bigserial PRIMARY KEY,
  "orderId"     bigint NOT NULL REFERENCES "orders"("id") ON DELETE RESTRICT,
  "userId"      bigint NOT NULL REFERENCES "users"("id") ON DELETE RESTRICT,
  "paymentId"   bigint NOT NULL REFERENCES "payments"("id") ON DELETE RESTRICT,
  "reason"      text NOT NULL,
  "amount"      double precision NOT NULL,
  "status"      text NOT NULL DEFAULT 'pending',
  "adminNote"   text,
  "resolvedBy"  bigint REFERENCES "users"("id"),
  "resolvedAt"  timestamp without time zone,
  "createdAt"   timestamp without time zone NOT NULL,
  CONSTRAINT "refund_status_check" CHECK ("status" IN ('pending','approved','rejected','processed')),
  CONSTRAINT "refund_amount_positive" CHECK ("amount" > 0)
);
CREATE INDEX IF NOT EXISTS "refund_order_idx"  ON "refund_requests" ("orderId");
CREATE INDEX IF NOT EXISTS "refund_user_idx"   ON "refund_requests" ("userId");
CREATE INDEX IF NOT EXISTS "refund_status_idx" ON "refund_requests" ("status");

-- ── Order paymentStatus column ──────────────────────────────────────────────
ALTER TABLE "orders"
  ADD COLUMN IF NOT EXISTS "paymentStatus"  text NOT NULL DEFAULT 'unpaid',
  ADD COLUMN IF NOT EXISTS "paymentId"      bigint,
  ADD COLUMN IF NOT EXISTS "trackingNumber" text;

-- ── Shipping ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "shipping_zones" (
  "id"        bigserial PRIMARY KEY,
  "name"      text NOT NULL,
  "countries" text NOT NULL,
  "isActive"  boolean NOT NULL DEFAULT true,
  "createdAt" timestamp without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS "shipping_methods" (
  "id"            bigserial PRIMARY KEY,
  "zoneId"        bigint NOT NULL REFERENCES "shipping_zones"("id") ON DELETE CASCADE,
  "name"          text NOT NULL,
  "description"   text,
  "baseFee"       double precision NOT NULL DEFAULT 0,
  "freeAbove"     double precision,
  "estimatedDays" integer NOT NULL DEFAULT 3,
  "isActive"      boolean NOT NULL DEFAULT true,
  "sortOrder"     integer NOT NULL DEFAULT 0,
  "createdAt"     timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "shipping_method_zone_idx" ON "shipping_methods" ("zoneId");

CREATE TABLE IF NOT EXISTS "shipments" (
  "id"               bigserial PRIMARY KEY,
  "orderId"          bigint NOT NULL REFERENCES "orders"("id") ON DELETE RESTRICT,
  "methodId"         bigint NOT NULL REFERENCES "shipping_methods"("id") ON DELETE RESTRICT,
  "status"           text NOT NULL DEFAULT 'pending',
  "trackingNumber"   text,
  "courierName"      text,
  "courierUrl"       text,
  "shippingFee"      double precision NOT NULL DEFAULT 0,
  "estimatedDelivery" timestamp without time zone,
  "actualDelivery"   timestamp without time zone,
  "notes"            text,
  "createdAt"        timestamp without time zone NOT NULL,
  "updatedAt"        timestamp without time zone NOT NULL,
  CONSTRAINT "shipment_status_check" CHECK ("status" IN ('pending','readyToShip','pickedUp','inTransit','outForDelivery','delivered','failed','returned'))
);
CREATE UNIQUE INDEX IF NOT EXISTS "shipment_order_idx"    ON "shipments" ("orderId");
CREATE INDEX        IF NOT EXISTS "shipment_tracking_idx" ON "shipments" ("trackingNumber") WHERE "trackingNumber" IS NOT NULL;
CREATE INDEX        IF NOT EXISTS "shipment_status_idx"   ON "shipments" ("status");

-- ── Revenue aggregation table (performance) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS "revenue_daily" (
  "date"              date PRIMARY KEY,
  "grossRevenue"      double precision NOT NULL DEFAULT 0,
  "discountAmount"    double precision NOT NULL DEFAULT 0,
  "netRevenue"        double precision NOT NULL DEFAULT 0,
  "refundedAmount"    double precision NOT NULL DEFAULT 0,
  "orderCount"        integer NOT NULL DEFAULT 0,
  "codOrderCount"     integer NOT NULL DEFAULT 0,
  "stripeOrderCount"  integer NOT NULL DEFAULT 0,
  "updatedAt"         timestamp without time zone NOT NULL
);

-- ── Security: per-IP rate limit tracking ────────────────────────────────────
CREATE TABLE IF NOT EXISTS "rate_limit_events" (
  "id"         bigserial PRIMARY KEY,
  "ipAddress"  text NOT NULL,
  "endpoint"   text NOT NULL,
  "createdAt"  timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "rate_limit_ip_endpoint_idx" ON "rate_limit_events" ("ipAddress", "endpoint", "createdAt" DESC);
-- Auto-cleanup: rows older than 1 hour are irrelevant
CREATE INDEX IF NOT EXISTS "rate_limit_created_idx" ON "rate_limit_events" ("createdAt");

-- ── Webhook events (idempotent processing) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS "webhook_events" (
  "id"              bigserial PRIMARY KEY,
  "provider"        text NOT NULL,
  "eventId"         text NOT NULL,
  "eventType"       text NOT NULL,
  "payload"         text NOT NULL,
  "processedAt"     timestamp without time zone,
  "error"           text,
  "createdAt"       timestamp without time zone NOT NULL,
  CONSTRAINT "webhook_provider_event_unique" UNIQUE ("provider", "eventId")
);
CREATE INDEX IF NOT EXISTS "webhook_event_idx"     ON "webhook_events" ("provider", "eventType");
CREATE INDEX IF NOT EXISTS "webhook_processed_idx" ON "webhook_events" ("processedAt") WHERE "processedAt" IS NULL;

-- ── Default shipping zone (Jordan / GCC for launch) ─────────────────────────
INSERT INTO "shipping_zones" ("name", "countries", "isActive", "createdAt")
VALUES ('Middle East', 'JO,SA,AE,KW,QA,BH,OM,EG', true, NOW())
ON CONFLICT DO NOTHING;

INSERT INTO "shipping_methods" ("zoneId", "name", "baseFee", "freeAbove", "estimatedDays", "isActive", "sortOrder", "createdAt")
SELECT z."id", 'Standard Delivery', 5.00, 50.00, 5, true, 1, NOW() FROM "shipping_zones" z WHERE z."name"='Middle East' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO "shipping_methods" ("zoneId", "name", "baseFee", "freeAbove", "estimatedDays", "isActive", "sortOrder", "createdAt")
SELECT z."id", 'Express Delivery', 12.00, 100.00, 2, true, 2, NOW() FROM "shipping_zones" z WHERE z."name"='Middle East' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO "shipping_methods" ("zoneId", "name", "baseFee", "freeAbove", "estimatedDays", "isActive", "sortOrder", "createdAt")
SELECT z."id", 'Cash on Delivery', 3.00, NULL, 7, true, 3, NOW() FROM "shipping_zones" z WHERE z."name"='Middle East' LIMIT 1
ON CONFLICT DO NOTHING;

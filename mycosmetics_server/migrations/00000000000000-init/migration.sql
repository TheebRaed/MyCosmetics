-- Migration: 00000000000000-init.sql
-- Reconstructed: this file previously contained stray Dart source
-- (a PasswordService class, relocated to lib/src/utils/password_service.dart).
-- Real SQL rebuilt from FK references across every later migration/model:
-- users (referenced by skin_profiles, password_reset_tokens, addresses,
-- wishlist_items, carts, orders, reviews, audit_logs, etc.) and addresses
-- (referenced by orders.addressId). NOTE: categories is intentionally NOT
-- created here -- it is already correctly created in
-- 00000000000001-catalog/migration.sql (reconstructed from the SQL that had
-- been misfiled into catalog_dto.spy.yaml), alongside brands/products which
-- reference it. Creating it twice would collide with that migration.

CREATE TABLE "users" (
  "id" bigserial PRIMARY KEY,
  "email" text NOT NULL,
  "passwordHash" text NOT NULL,
  "fullName" text NOT NULL,
  "role" text NOT NULL DEFAULT 'customer',
  "avatarUrl" text,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL,
  "deletedAt" timestamp without time zone
);
-- Partial unique index: soft-deleted users must not permanently squat an
-- email address (same reasoning later reused for products_slug_idx).
CREATE UNIQUE INDEX "users_email_idx" ON "users" ("email") WHERE "deletedAt" IS NULL;

CREATE TABLE "addresses" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "fullName" text NOT NULL,
  "phone" text NOT NULL,
  "line1" text NOT NULL,
  "line2" text,
  "city" text NOT NULL,
  "state" text,
  "postalCode" text,
  "country" text NOT NULL,
  "isDefault" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE INDEX "addresses_user_idx" ON "addresses" ("userId");

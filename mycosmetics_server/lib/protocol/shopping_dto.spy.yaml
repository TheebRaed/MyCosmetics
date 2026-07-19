-- Migration: 00000000000002-shopping.sql
-- Models: Cart, CartItem, WishlistItem, Coupon, Order, OrderItem,
-- OrderStatusHistory, Review

CREATE TABLE "carts" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "appliedCouponId" bigint REFERENCES "coupons"("id") ON DELETE SET NULL,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE UNIQUE INDEX "carts_user_idx" ON "carts" ("userId");

CREATE TABLE "cart_items" (
  "id" bigserial PRIMARY KEY,
  "cartId" bigint NOT NULL REFERENCES "carts"("id") ON DELETE CASCADE,
  "variantId" bigint NOT NULL REFERENCES "product_variants"("id") ON DELETE CASCADE,
  "quantity" integer NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE INDEX "cart_items_cart_idx" ON "cart_items" ("cartId");
CREATE UNIQUE INDEX "cart_items_cart_variant_idx" ON "cart_items" ("cartId", "variantId");

CREATE TABLE "wishlist_items" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "productId" bigint NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
  "createdAt" timestamp without time zone NOT NULL
);
CREATE INDEX "wishlist_items_user_idx" ON "wishlist_items" ("userId");
CREATE UNIQUE INDEX "wishlist_items_user_product_idx" ON "wishlist_items" ("userId", "productId");

CREATE TABLE "coupons" (
  "id" bigserial PRIMARY KEY,
  "code" text NOT NULL,
  "type" text NOT NULL,
  "value" double precision NOT NULL,
  "minSpend" double precision NOT NULL DEFAULT 0,
  "maxDiscount" double precision,
  "usageLimit" integer,
  "usedCount" integer NOT NULL DEFAULT 0,
  "expiresAt" timestamp without time zone,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE UNIQUE INDEX "coupons_code_idx" ON "coupons" ("code");

CREATE TABLE "orders" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE RESTRICT,
  "addressId" bigint NOT NULL REFERENCES "addresses"("id") ON DELETE RESTRICT,
  "couponId" bigint REFERENCES "coupons"("id") ON DELETE SET NULL,
  "status" text NOT NULL DEFAULT 'pending',
  "subtotal" double precision NOT NULL,
  "discountAmount" double precision NOT NULL DEFAULT 0,
  "total" double precision NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE INDEX "orders_user_idx" ON "orders" ("userId");
CREATE INDEX "orders_status_idx" ON "orders" ("status");
-- Supports "list my orders, newest first" without a filesort.
CREATE INDEX "orders_user_created_idx" ON "orders" ("userId", "createdAt" DESC);

CREATE TABLE "order_items" (
  "id" bigserial PRIMARY KEY,
  "orderId" bigint NOT NULL REFERENCES "orders"("id") ON DELETE CASCADE,
  "variantId" bigint NOT NULL REFERENCES "product_variants"("id") ON DELETE RESTRICT,
  "productNameSnapshot" text NOT NULL,
  "shadeNameSnapshot" text,
  "unitPrice" double precision NOT NULL,
  "quantity" integer NOT NULL,
  "lineTotal" double precision NOT NULL
);
CREATE INDEX "order_items_order_idx" ON "order_items" ("orderId");
-- Supports the "has this user purchased this variant" check used by
-- review eligibility and reorder features.
CREATE INDEX "order_items_variant_idx" ON "order_items" ("variantId");

CREATE TABLE "order_status_history" (
  "id" bigserial PRIMARY KEY,
  "orderId" bigint NOT NULL REFERENCES "orders"("id") ON DELETE CASCADE,
  "status" text NOT NULL,
  "note" text,
  "createdAt" timestamp without time zone NOT NULL
);
CREATE INDEX "order_status_history_order_idx" ON "order_status_history" ("orderId");

CREATE TABLE "reviews" (
  "id" bigserial PRIMARY KEY,
  "productId" bigint NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "orderItemId" bigint NOT NULL REFERENCES "order_items"("id") ON DELETE CASCADE,
  "rating" integer NOT NULL,
  "comment" text,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL,
  CONSTRAINT "reviews_rating_range" CHECK ("rating" >= 1 AND "rating" <= 5)
);
CREATE INDEX "reviews_product_idx" ON "reviews" ("productId");
CREATE UNIQUE INDEX "reviews_user_orderitem_idx" ON "reviews" ("userId", "orderItemId");

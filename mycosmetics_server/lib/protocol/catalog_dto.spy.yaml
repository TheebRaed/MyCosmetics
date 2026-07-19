-- Migration: 00000000000001-catalog.sql
-- Generated from protocol models: Category, Brand, Product, ProductVariant, ProductImage

CREATE TABLE "categories" (
  "id" bigserial PRIMARY KEY,
  "parentId" bigint REFERENCES "categories"("id") ON DELETE RESTRICT,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "imageUrl" text,
  "sortOrder" integer NOT NULL DEFAULT 0,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE UNIQUE INDEX "categories_slug_idx" ON "categories" ("slug");
CREATE INDEX "categories_parent_idx" ON "categories" ("parentId");

CREATE TABLE "brands" (
  "id" bigserial PRIMARY KEY,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "logoUrl" text,
  "description" text,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE UNIQUE INDEX "brands_slug_idx" ON "brands" ("slug");

CREATE TABLE "products" (
  "id" bigserial PRIMARY KEY,
  "categoryId" bigint NOT NULL REFERENCES "categories"("id") ON DELETE RESTRICT,
  "brandId" bigint NOT NULL REFERENCES "brands"("id") ON DELETE RESTRICT,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "description" text NOT NULL,
  "basePrice" double precision NOT NULL,
  "ratingAvg" double precision NOT NULL DEFAULT 0,
  "ratingCount" integer NOT NULL DEFAULT 0,
  "isFeatured" boolean NOT NULL DEFAULT false,
  "isBestSeller" boolean NOT NULL DEFAULT false,
  "isNewArrival" boolean NOT NULL DEFAULT false,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL,
  "deletedAt" timestamp without time zone
);
-- Partial unique index: slug only needs to be unique among non-deleted
-- products, mirroring the same reasoning as users_email_idx in Phase 1
-- (soft-deleted rows must not permanently squat a slug).
CREATE UNIQUE INDEX "products_slug_idx" ON "products" ("slug") WHERE "deletedAt" IS NULL;
CREATE INDEX "products_category_idx" ON "products" ("categoryId");
CREATE INDEX "products_brand_idx" ON "products" ("brandId");
-- Supports filter+sort+pagination queries (active products, newest first / by rating).
CREATE INDEX "products_active_created_idx" ON "products" ("isActive", "createdAt") WHERE "deletedAt" IS NULL;
CREATE INDEX "products_active_rating_idx" ON "products" ("isActive", "ratingAvg") WHERE "deletedAt" IS NULL;
CREATE INDEX "products_active_price_idx" ON "products" ("isActive", "basePrice") WHERE "deletedAt" IS NULL;
-- Full-text search over name + description.
ALTER TABLE "products" ADD COLUMN "searchVector" tsvector
  GENERATED ALWAYS AS (to_tsvector('english', coalesce("name", '') || ' ' || coalesce("description", ''))) STORED;
CREATE INDEX "products_search_idx" ON "products" USING GIN ("searchVector");

CREATE TABLE "product_variants" (
  "id" bigserial PRIMARY KEY,
  "productId" bigint NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
  "shadeName" text,
  "hexColor" text,
  "size" text,
  "sku" text NOT NULL,
  "price" double precision NOT NULL,
  "stockQty" integer NOT NULL DEFAULT 0,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE UNIQUE INDEX "product_variants_sku_idx" ON "product_variants" ("sku");
CREATE INDEX "product_variants_product_idx" ON "product_variants" ("productId");

CREATE TABLE "product_images" (
  "id" bigserial PRIMARY KEY,
  "productId" bigint NOT NULL REFERENCES "products"("id") ON DELETE CASCADE,
  "variantId" bigint REFERENCES "product_variants"("id") ON DELETE CASCADE,
  "url" text NOT NULL,
  "sortOrder" integer NOT NULL DEFAULT 0,
  "createdAt" timestamp without time zone NOT NULL
);
CREATE INDEX "product_images_product_idx" ON "product_images" ("productId");
CREATE INDEX "product_images_variant_idx" ON "product_images" ("variantId");

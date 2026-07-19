-- Migration: 00000000000003-beautytech
ALTER TABLE "skin_profiles"
  ADD COLUMN IF NOT EXISTS "brightness" double precision,
  ADD COLUMN IF NOT EXISTS "favoriteCategories" text,
  ADD COLUMN IF NOT EXISTS "preferredShades" text;

CREATE TABLE IF NOT EXISTS "shade_recommendations" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "skinProfileId" bigint NOT NULL REFERENCES "skin_profiles"("id") ON DELETE CASCADE,
  "productVariantId" bigint NOT NULL REFERENCES "product_variants"("id") ON DELETE CASCADE,
  "category" text NOT NULL,
  "confidenceScore" double precision NOT NULL,
  "reason" text NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  CONSTRAINT "shade_rec_confidence_range" CHECK ("confidenceScore" >= 0 AND "confidenceScore" <= 1)
);
CREATE INDEX IF NOT EXISTS "shade_rec_user_idx"    ON "shade_recommendations" ("userId");
CREATE INDEX IF NOT EXISTS "shade_rec_profile_idx" ON "shade_recommendations" ("skinProfileId");

CREATE TABLE IF NOT EXISTS "saved_looks" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "name" text NOT NULL,
  "imageUrl" text NOT NULL,
  "appliedVariantIds" text NOT NULL DEFAULT '',
  "isFavorite" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "saved_looks_user_idx" ON "saved_looks" ("userId");

CREATE TABLE IF NOT EXISTS "tryon_events" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "productVariantId" bigint NOT NULL REFERENCES "product_variants"("id") ON DELETE CASCADE,
  "productCategory" text NOT NULL,
  "sessionId" text NOT NULL,
  "createdAt" timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "tryon_events_user_idx"     ON "tryon_events" ("userId");
CREATE INDEX IF NOT EXISTS "tryon_events_variant_idx"  ON "tryon_events" ("productVariantId");
CREATE INDEX IF NOT EXISTS "tryon_events_session_idx"  ON "tryon_events" ("sessionId");
CREATE INDEX IF NOT EXISTS "tryon_events_created_idx"  ON "tryon_events" ("createdAt");

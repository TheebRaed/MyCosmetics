-- Migration: 00000000000004-ai-intelligence (Phase 6)
ALTER TABLE "skin_profiles"
  ADD COLUMN IF NOT EXISTS "favoriteShades" text,
  ADD COLUMN IF NOT EXISTS "preferredBrands" text,
  ADD COLUMN IF NOT EXISTS "purchaseHistorySignals" text;

ALTER TABLE "shade_recommendations"
  ADD COLUMN IF NOT EXISTS "historyId"           bigint,
  ADD COLUMN IF NOT EXISTS "scoreSkinTone"       double precision,
  ADD COLUMN IF NOT EXISTS "scoreUndertone"      double precision,
  ADD COLUMN IF NOT EXISTS "scorePopularity"     double precision,
  ADD COLUMN IF NOT EXISTS "scoreUserPreference" double precision,
  ADD COLUMN IF NOT EXISTS "scoreTryOnActivity"  double precision;

CREATE TABLE IF NOT EXISTS "skin_analysis_results" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "skinProfileId" bigint REFERENCES "skin_profiles"("id") ON DELETE SET NULL,
  "skinToneHex" text NOT NULL,
  "brightness" double precision NOT NULL,
  "undertone" text NOT NULL,
  "uniformityScore" double precision NOT NULL DEFAULT 0,
  "confidenceScore" double precision NOT NULL,
  "analyzedAt" timestamp without time zone NOT NULL,
  "deviceModel" text,
  "createdAt" timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "skin_analysis_user_idx" ON "skin_analysis_results" ("userId");

CREATE TABLE IF NOT EXISTS "recommendation_history" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "skinProfileId" bigint NOT NULL REFERENCES "skin_profiles"("id") ON DELETE RESTRICT,
  "skinAnalysisResultId" bigint REFERENCES "skin_analysis_results"("id") ON DELETE SET NULL,
  "engineVersion" text NOT NULL DEFAULT '2.0',
  "totalGenerated" integer NOT NULL DEFAULT 0,
  "categoryFilter" text,
  "triggeredBy" text NOT NULL DEFAULT 'user',
  "createdAt" timestamp without time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "rec_history_user_idx" ON "recommendation_history" ("userId");

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name='shade_rec_history_fk' AND table_name='shade_recommendations') THEN
    ALTER TABLE "shade_recommendations" ADD CONSTRAINT "shade_rec_history_fk" FOREIGN KEY ("historyId") REFERENCES "recommendation_history"("id") ON DELETE SET NULL;
  END IF;
END; $$;

CREATE TABLE IF NOT EXISTS "recommendation_events" (
  "id" bigserial PRIMARY KEY,
  "userId" bigint NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "recommendationId" bigint NOT NULL REFERENCES "shade_recommendations"("id") ON DELETE CASCADE,
  "eventType" text NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  CONSTRAINT "rec_event_type_check" CHECK ("eventType" IN ('viewed','triedOn','addedToCart','purchased','dismissed'))
);
CREATE INDEX IF NOT EXISTS "rec_event_user_idx" ON "recommendation_events" ("userId");
CREATE INDEX IF NOT EXISTS "rec_event_rec_idx"  ON "recommendation_events" ("recommendationId");

CREATE OR REPLACE VIEW "v_top_recommended_variants" AS
  SELECT sr."productVariantId", pv."shadeName", p."name" AS "productName", pv."hexColor",
         COUNT(*) AS "recommendationCount", AVG(sr."confidenceScore") AS "avgConfidence",
         COUNT(CASE WHEN re."eventType"='purchased' THEN 1 END) AS "purchaseCount"
  FROM "shade_recommendations" sr
  JOIN "product_variants" pv ON pv."id"=sr."productVariantId"
  JOIN "products" p ON p."id"=pv."productId"
  LEFT JOIN "recommendation_events" re ON re."recommendationId"=sr."id"
  GROUP BY sr."productVariantId", pv."shadeName", p."name", pv."hexColor";

CREATE OR REPLACE VIEW "v_undertone_distribution" AS
  SELECT COALESCE("undertone",'unknown') AS "undertone", COUNT(*) AS "count",
         ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(),2) AS "percentage"
  FROM "skin_profiles" GROUP BY "undertone";

CREATE OR REPLACE VIEW "v_recommendation_acceptance" AS
  SELECT sr."category",
         COUNT(DISTINCT sr."id") AS "totalRecommendations",
         COUNT(DISTINCT CASE WHEN re."eventType" IN ('triedOn','addedToCart','purchased') THEN re."recommendationId" END) AS "accepted",
         COUNT(DISTINCT CASE WHEN re."eventType"='purchased' THEN re."recommendationId" END) AS "converted",
         ROUND(COUNT(DISTINCT CASE WHEN re."eventType" IN ('triedOn','addedToCart','purchased') THEN re."recommendationId" END)*100.0/NULLIF(COUNT(DISTINCT sr."id"),0),2) AS "acceptanceRate",
         ROUND(COUNT(DISTINCT CASE WHEN re."eventType"='purchased' THEN re."recommendationId" END)*100.0/NULLIF(COUNT(DISTINCT sr."id"),0),2) AS "conversionRate"
  FROM "shade_recommendations" sr
  LEFT JOIN "recommendation_events" re ON re."recommendationId"=sr."id"
  GROUP BY sr."category";

BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "addresses" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
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

-- Indexes
CREATE INDEX "addresses_user_idx" ON "addresses" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "admin_notifications" (
    "id" bigserial PRIMARY KEY,
    "adminId" bigint NOT NULL,
    "title" text NOT NULL,
    "body" text NOT NULL,
    "audience" text NOT NULL DEFAULT 'allUsers'::text,
    "audienceFilter" text,
    "status" text NOT NULL DEFAULT 'draft'::text,
    "scheduledAt" timestamp without time zone,
    "sentAt" timestamp without time zone,
    "recipientCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "admin_notif_status_idx" ON "admin_notifications" USING btree ("status");
CREATE INDEX "admin_notif_created_idx" ON "admin_notifications" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "audit_logs" (
    "id" bigserial PRIMARY KEY,
    "adminId" bigint NOT NULL,
    "action" text NOT NULL,
    "entity" text NOT NULL,
    "entityId" bigint,
    "oldValue" text,
    "newValue" text,
    "ipAddress" text,
    "userAgent" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "audit_log_admin_idx" ON "audit_logs" USING btree ("adminId");
CREATE INDEX "audit_log_entity_idx" ON "audit_logs" USING btree ("entity", "entityId");
CREATE INDEX "audit_log_created_idx" ON "audit_logs" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
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

-- Indexes
CREATE UNIQUE INDEX "brands_slug_idx" ON "brands" USING btree ("slug");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "cart_items" (
    "id" bigserial PRIMARY KEY,
    "cartId" bigint NOT NULL,
    "variantId" bigint NOT NULL,
    "quantity" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "cart_items_cart_idx" ON "cart_items" USING btree ("cartId");
CREATE UNIQUE INDEX "cart_items_cart_variant_idx" ON "cart_items" USING btree ("cartId", "variantId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "carts" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "appliedCouponId" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "carts_user_idx" ON "carts" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "categories" (
    "id" bigserial PRIMARY KEY,
    "parentId" bigint,
    "name" text NOT NULL,
    "slug" text NOT NULL,
    "imageUrl" text,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "categories_slug_idx" ON "categories" USING btree ("slug");
CREATE INDEX "categories_parent_idx" ON "categories" USING btree ("parentId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "coupons" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "type" text NOT NULL,
    "value" double precision NOT NULL,
    "minSpend" double precision NOT NULL DEFAULT 0,
    "maxDiscount" double precision,
    "usageLimit" bigint,
    "usedCount" bigint NOT NULL DEFAULT 0,
    "expiresAt" timestamp without time zone,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "coupons_code_idx" ON "coupons" USING btree ("code");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "order_items" (
    "id" bigserial PRIMARY KEY,
    "orderId" bigint NOT NULL,
    "variantId" bigint NOT NULL,
    "productNameSnapshot" text NOT NULL,
    "shadeNameSnapshot" text,
    "unitPrice" double precision NOT NULL,
    "quantity" bigint NOT NULL,
    "lineTotal" double precision NOT NULL
);

-- Indexes
CREATE INDEX "order_items_order_idx" ON "order_items" USING btree ("orderId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "order_status_history" (
    "id" bigserial PRIMARY KEY,
    "orderId" bigint NOT NULL,
    "status" text NOT NULL,
    "note" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "order_status_history_order_idx" ON "order_status_history" USING btree ("orderId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "orders" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "addressId" bigint NOT NULL,
    "couponId" bigint,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "paymentStatus" text NOT NULL DEFAULT 'unpaid'::text,
    "paymentId" bigint,
    "trackingNumber" text,
    "subtotal" double precision NOT NULL,
    "discountAmount" double precision NOT NULL DEFAULT 0,
    "total" double precision NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "orders_user_idx" ON "orders" USING btree ("userId");
CREATE INDEX "orders_status_idx" ON "orders" USING btree ("status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "password_reset_tokens" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "tokenHash" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "password_reset_tokens_hash_idx" ON "password_reset_tokens" USING btree ("tokenHash");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "payment_audit_logs" (
    "id" bigserial PRIMARY KEY,
    "paymentId" bigint NOT NULL,
    "eventType" text NOT NULL,
    "previousStatus" text,
    "newStatus" text NOT NULL,
    "actorId" bigint,
    "source" text NOT NULL,
    "providerPayload" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "payment_audit_payment_idx" ON "payment_audit_logs" USING btree ("paymentId");
CREATE INDEX "payment_audit_created_idx" ON "payment_audit_logs" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "payments" (
    "id" bigserial PRIMARY KEY,
    "orderId" bigint NOT NULL,
    "provider" text NOT NULL,
    "method" text NOT NULL,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "amount" double precision NOT NULL,
    "currency" text NOT NULL DEFAULT 'USD'::text,
    "providerRefId" text,
    "providerStatus" text,
    "failureReason" text,
    "idempotencyKey" text NOT NULL,
    "paidAt" timestamp without time zone,
    "refundedAt" timestamp without time zone,
    "refundedAmount" double precision,
    "metadata" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "payment_order_idx" ON "payments" USING btree ("orderId");
CREATE INDEX "payment_provider_ref_idx" ON "payments" USING btree ("providerRefId");
CREATE INDEX "payment_status_idx" ON "payments" USING btree ("status");
CREATE UNIQUE INDEX "payment_idempotency_idx" ON "payments" USING btree ("idempotencyKey");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "product_images" (
    "id" bigserial PRIMARY KEY,
    "productId" bigint NOT NULL,
    "variantId" bigint,
    "url" text NOT NULL,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "product_images_product_idx" ON "product_images" USING btree ("productId");
CREATE INDEX "product_images_variant_idx" ON "product_images" USING btree ("variantId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "product_variants" (
    "id" bigserial PRIMARY KEY,
    "productId" bigint NOT NULL,
    "shadeName" text,
    "hexColor" text,
    "size" text,
    "sku" text NOT NULL,
    "price" double precision NOT NULL,
    "stockQty" bigint NOT NULL DEFAULT 0,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "product_variants_sku_idx" ON "product_variants" USING btree ("sku");
CREATE INDEX "product_variants_product_idx" ON "product_variants" USING btree ("productId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "products" (
    "id" bigserial PRIMARY KEY,
    "categoryId" bigint NOT NULL,
    "brandId" bigint NOT NULL,
    "name" text NOT NULL,
    "slug" text NOT NULL,
    "description" text NOT NULL,
    "basePrice" double precision NOT NULL,
    "ratingAvg" double precision NOT NULL DEFAULT 0,
    "ratingCount" bigint NOT NULL DEFAULT 0,
    "isFeatured" boolean NOT NULL DEFAULT false,
    "isBestSeller" boolean NOT NULL DEFAULT false,
    "isNewArrival" boolean NOT NULL DEFAULT false,
    "isActive" boolean NOT NULL DEFAULT true,
    "tryOnEnabled" boolean NOT NULL DEFAULT true,
    "aiRecommendationEnabled" boolean NOT NULL DEFAULT true,
    "discountPercent" double precision,
    "discountExpiresAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "products_slug_idx" ON "products" USING btree ("slug");
CREATE INDEX "products_category_idx" ON "products" USING btree ("categoryId");
CREATE INDEX "products_brand_idx" ON "products" USING btree ("brandId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "recommendation_events" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "recommendationId" bigint NOT NULL,
    "eventType" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "rec_event_user_idx" ON "recommendation_events" USING btree ("userId");
CREATE INDEX "rec_event_rec_idx" ON "recommendation_events" USING btree ("recommendationId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "recommendation_history" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "skinProfileId" bigint NOT NULL,
    "skinAnalysisResultId" bigint,
    "engineVersion" text NOT NULL,
    "totalGenerated" bigint NOT NULL,
    "categoryFilter" text,
    "triggeredBy" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "rec_history_user_idx" ON "recommendation_history" USING btree ("userId");
CREATE INDEX "rec_history_created_idx" ON "recommendation_history" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "refund_requests" (
    "id" bigserial PRIMARY KEY,
    "orderId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "paymentId" bigint NOT NULL,
    "reason" text NOT NULL,
    "amount" double precision NOT NULL,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "adminNote" text,
    "resolvedBy" bigint,
    "resolvedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "refund_order_idx" ON "refund_requests" USING btree ("orderId");
CREATE INDEX "refund_user_idx" ON "refund_requests" USING btree ("userId");
CREATE INDEX "refund_status_idx" ON "refund_requests" USING btree ("status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "reviews" (
    "id" bigserial PRIMARY KEY,
    "productId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "orderItemId" bigint NOT NULL,
    "rating" bigint NOT NULL,
    "comment" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "reviews_product_idx" ON "reviews" USING btree ("productId");
CREATE UNIQUE INDEX "reviews_user_orderitem_idx" ON "reviews" USING btree ("userId", "orderItemId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "saved_looks" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "name" text NOT NULL,
    "imageUrl" text NOT NULL,
    "appliedVariantIds" text NOT NULL,
    "isFavorite" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "saved_looks_user_idx" ON "saved_looks" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "shade_recommendations" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "skinProfileId" bigint NOT NULL,
    "productVariantId" bigint NOT NULL,
    "historyId" bigint,
    "category" text NOT NULL,
    "confidenceScore" double precision NOT NULL,
    "reason" text NOT NULL,
    "scoreSkinTone" double precision,
    "scoreUndertone" double precision,
    "scorePopularity" double precision,
    "scoreUserPreference" double precision,
    "scoreTryOnActivity" double precision,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "shade_rec_user_idx" ON "shade_recommendations" USING btree ("userId");
CREATE INDEX "shade_rec_profile_idx" ON "shade_recommendations" USING btree ("skinProfileId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "shipments" (
    "id" bigserial PRIMARY KEY,
    "orderId" bigint NOT NULL,
    "methodId" bigint NOT NULL,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "trackingNumber" text,
    "courierName" text,
    "courierUrl" text,
    "shippingFee" double precision NOT NULL,
    "estimatedDelivery" timestamp without time zone,
    "actualDelivery" timestamp without time zone,
    "notes" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "shipment_order_idx" ON "shipments" USING btree ("orderId");
CREATE INDEX "shipment_tracking_idx" ON "shipments" USING btree ("trackingNumber");
CREATE INDEX "shipment_status_idx" ON "shipments" USING btree ("status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "shipping_methods" (
    "id" bigserial PRIMARY KEY,
    "zoneId" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "baseFee" double precision NOT NULL,
    "freeAbove" double precision,
    "estimatedDays" bigint NOT NULL,
    "isActive" boolean NOT NULL DEFAULT true,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "shipping_method_zone_idx" ON "shipping_methods" USING btree ("zoneId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "shipping_zones" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "countries" text NOT NULL,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "shipping_zone_name_idx" ON "shipping_zones" USING btree ("name");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "skin_analysis_results" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "skinProfileId" bigint,
    "skinToneHex" text NOT NULL,
    "brightness" double precision NOT NULL,
    "undertone" text NOT NULL,
    "uniformityScore" double precision NOT NULL,
    "confidenceScore" double precision NOT NULL,
    "analyzedAt" timestamp without time zone NOT NULL,
    "deviceModel" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "skin_analysis_user_idx" ON "skin_analysis_results" USING btree ("userId");
CREATE INDEX "skin_analysis_created_idx" ON "skin_analysis_results" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "skin_profiles" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "skinToneHex" text,
    "undertone" text,
    "concerns" text,
    "scannedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "skin_profiles_user_idx" ON "skin_profiles" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "stock_adjustments" (
    "id" bigserial PRIMARY KEY,
    "variantId" bigint NOT NULL,
    "adminId" bigint NOT NULL,
    "previousQty" bigint NOT NULL,
    "newQty" bigint NOT NULL,
    "delta" bigint NOT NULL,
    "reason" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "stock_adj_variant_idx" ON "stock_adjustments" USING btree ("variantId");
CREATE INDEX "stock_adj_created_idx" ON "stock_adjustments" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tryon_events" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "productVariantId" bigint NOT NULL,
    "productCategory" text NOT NULL,
    "sessionId" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "tryon_events_user_idx" ON "tryon_events" USING btree ("userId");
CREATE INDEX "tryon_events_variant_idx" ON "tryon_events" USING btree ("productVariantId");
CREATE INDEX "tryon_events_session_idx" ON "tryon_events" USING btree ("sessionId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "users" (
    "id" bigserial PRIMARY KEY,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL,
    "fullName" text NOT NULL,
    "role" text NOT NULL,
    "avatarUrl" text,
    "suspendedAt" timestamp without time zone,
    "suspendedReason" text,
    "lastActiveAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "users_email_idx" ON "users" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "wishlist_items" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "productId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "wishlist_items_user_idx" ON "wishlist_items" USING btree ("userId");
CREATE UNIQUE INDEX "wishlist_items_user_product_idx" ON "wishlist_items" USING btree ("userId", "productId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "addresses"
    ADD CONSTRAINT "addresses_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "admin_notifications"
    ADD CONSTRAINT "admin_notifications_fk_0"
    FOREIGN KEY("adminId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "audit_logs"
    ADD CONSTRAINT "audit_logs_fk_0"
    FOREIGN KEY("adminId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "cart_items"
    ADD CONSTRAINT "cart_items_fk_0"
    FOREIGN KEY("cartId")
    REFERENCES "carts"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "cart_items"
    ADD CONSTRAINT "cart_items_fk_1"
    FOREIGN KEY("variantId")
    REFERENCES "product_variants"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "carts"
    ADD CONSTRAINT "carts_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "carts"
    ADD CONSTRAINT "carts_fk_1"
    FOREIGN KEY("appliedCouponId")
    REFERENCES "coupons"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "categories"
    ADD CONSTRAINT "categories_fk_0"
    FOREIGN KEY("parentId")
    REFERENCES "categories"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "order_items"
    ADD CONSTRAINT "order_items_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "order_items"
    ADD CONSTRAINT "order_items_fk_1"
    FOREIGN KEY("variantId")
    REFERENCES "product_variants"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "order_status_history"
    ADD CONSTRAINT "order_status_history_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "orders"
    ADD CONSTRAINT "orders_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "orders"
    ADD CONSTRAINT "orders_fk_1"
    FOREIGN KEY("addressId")
    REFERENCES "addresses"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "orders"
    ADD CONSTRAINT "orders_fk_2"
    FOREIGN KEY("couponId")
    REFERENCES "coupons"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "password_reset_tokens"
    ADD CONSTRAINT "password_reset_tokens_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "payment_audit_logs"
    ADD CONSTRAINT "payment_audit_logs_fk_0"
    FOREIGN KEY("paymentId")
    REFERENCES "payments"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "payments"
    ADD CONSTRAINT "payments_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "product_images"
    ADD CONSTRAINT "product_images_fk_0"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "product_images"
    ADD CONSTRAINT "product_images_fk_1"
    FOREIGN KEY("variantId")
    REFERENCES "product_variants"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "product_variants"
    ADD CONSTRAINT "product_variants_fk_0"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "products"
    ADD CONSTRAINT "products_fk_0"
    FOREIGN KEY("categoryId")
    REFERENCES "categories"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "products"
    ADD CONSTRAINT "products_fk_1"
    FOREIGN KEY("brandId")
    REFERENCES "brands"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "recommendation_events"
    ADD CONSTRAINT "recommendation_events_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "recommendation_events"
    ADD CONSTRAINT "recommendation_events_fk_1"
    FOREIGN KEY("recommendationId")
    REFERENCES "shade_recommendations"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "recommendation_history"
    ADD CONSTRAINT "recommendation_history_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "recommendation_history"
    ADD CONSTRAINT "recommendation_history_fk_1"
    FOREIGN KEY("skinProfileId")
    REFERENCES "skin_profiles"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "recommendation_history"
    ADD CONSTRAINT "recommendation_history_fk_2"
    FOREIGN KEY("skinAnalysisResultId")
    REFERENCES "skin_analysis_results"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "refund_requests"
    ADD CONSTRAINT "refund_requests_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "refund_requests"
    ADD CONSTRAINT "refund_requests_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "refund_requests"
    ADD CONSTRAINT "refund_requests_fk_2"
    FOREIGN KEY("paymentId")
    REFERENCES "payments"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "reviews"
    ADD CONSTRAINT "reviews_fk_0"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "reviews"
    ADD CONSTRAINT "reviews_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "reviews"
    ADD CONSTRAINT "reviews_fk_2"
    FOREIGN KEY("orderItemId")
    REFERENCES "order_items"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "saved_looks"
    ADD CONSTRAINT "saved_looks_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "shade_recommendations"
    ADD CONSTRAINT "shade_recommendations_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "shade_recommendations"
    ADD CONSTRAINT "shade_recommendations_fk_1"
    FOREIGN KEY("skinProfileId")
    REFERENCES "skin_profiles"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "shade_recommendations"
    ADD CONSTRAINT "shade_recommendations_fk_2"
    FOREIGN KEY("productVariantId")
    REFERENCES "product_variants"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "shade_recommendations"
    ADD CONSTRAINT "shade_recommendations_fk_3"
    FOREIGN KEY("historyId")
    REFERENCES "recommendation_history"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "shipments"
    ADD CONSTRAINT "shipments_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "shipments"
    ADD CONSTRAINT "shipments_fk_1"
    FOREIGN KEY("methodId")
    REFERENCES "shipping_methods"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "shipping_methods"
    ADD CONSTRAINT "shipping_methods_fk_0"
    FOREIGN KEY("zoneId")
    REFERENCES "shipping_zones"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "skin_analysis_results"
    ADD CONSTRAINT "skin_analysis_results_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "skin_analysis_results"
    ADD CONSTRAINT "skin_analysis_results_fk_1"
    FOREIGN KEY("skinProfileId")
    REFERENCES "skin_profiles"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "skin_profiles"
    ADD CONSTRAINT "skin_profiles_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "stock_adjustments"
    ADD CONSTRAINT "stock_adjustments_fk_0"
    FOREIGN KEY("variantId")
    REFERENCES "product_variants"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "stock_adjustments"
    ADD CONSTRAINT "stock_adjustments_fk_1"
    FOREIGN KEY("adminId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "tryon_events"
    ADD CONSTRAINT "tryon_events_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "tryon_events"
    ADD CONSTRAINT "tryon_events_fk_1"
    FOREIGN KEY("productVariantId")
    REFERENCES "product_variants"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "wishlist_items"
    ADD CONSTRAINT "wishlist_items_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "wishlist_items"
    ADD CONSTRAINT "wishlist_items_fk_1"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR mycosmetics
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('mycosmetics', '20260722160502480', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260722160502480', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

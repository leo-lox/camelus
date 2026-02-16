BEGIN;

--
-- Class BloomFilterEvent as table bloom_filter_events
--
CREATE TABLE "bloom_filter_events" (
    "id" bigserial PRIMARY KEY,
    "size" bigint NOT NULL,
    "numHashFunctions" bigint NOT NULL,
    "bitArray" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "name" text,
    "description" text
);

-- Indexes
CREATE INDEX "bloom_filter_events_crated_at_idx" ON "bloom_filter_events" USING btree ("createdAt");

--
-- Class BloomFilterProfile as table bloom_filter_profiles
--
CREATE TABLE "bloom_filter_profiles" (
    "id" bigserial PRIMARY KEY,
    "size" bigint NOT NULL,
    "numHashFunctions" bigint NOT NULL,
    "bitArray" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "name" text,
    "description" text
);

-- Indexes
CREATE INDEX "bloom_filter_events_created_at_idx" ON "bloom_filter_profiles" USING btree ("createdAt");

--
-- Class Nip05Data as table nip_05_data
--
CREATE TABLE "nip_05_data" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "domain" text NOT NULL,
    "pubkey" text NOT NULL,
    "relays" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "domain_idx" ON "nip_05_data" USING btree ("domain");
CREATE INDEX "nip_05_crated_at_idx" ON "nip_05_data" USING btree ("createdAt");
CREATE UNIQUE INDEX "name_domain_idx" ON "nip_05_data" USING btree ("name", "domain");

--
-- Class OtsoGeoSubscription as table otso_geo_subscriptions
--
CREATE TABLE "otso_geo_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "pubkey" text NOT NULL,
    "geohash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "otso_geo_subscription_unique_idx" ON "otso_geo_subscriptions" USING btree ("pubkey", "geohash");

--
-- Class OtsoPushSubscription as table otso_push_subscriptions
--
CREATE TABLE "otso_push_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "pubkey" text NOT NULL,
    "relay" text NOT NULL,
    "token" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "otso_push_subscription_unique_idx" ON "otso_push_subscriptions" USING btree ("pubkey", "relay", "token");

--
-- Class PushSubscription as table push_subscriptions
--
CREATE TABLE "push_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "pubkey" text NOT NULL,
    "relay" text NOT NULL,
    "token" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "subscription_unique_idx" ON "push_subscriptions" USING btree ("pubkey", "relay", "token");

--
-- Class ReportsIncoming as table reports_incoming
--
CREATE TABLE "reports_incoming" (
    "id" bigserial PRIMARY KEY,
    "createdAt" timestamp without time zone NOT NULL,
    "report" json NOT NULL,
    "author" text NOT NULL,
    "type" text NOT NULL,
    "processed" boolean NOT NULL
);

--
-- Class ShortLinkInviteData as table short_link_invite_data
--
CREATE TABLE "short_link_invite_data" (
    "id" bigserial PRIMARY KEY,
    "shortLink" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "invitedByNpub" text NOT NULL,
    "listName" text NOT NULL,
    "listNpub" text NOT NULL,
    "usageCount" bigint NOT NULL DEFAULT 0,
    "lastUsed" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "short_link_invite_short_link_idx" ON "short_link_invite_data" USING btree ("shortLink");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
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
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
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
-- Class FutureCallEntry as table serverpod_future_call
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
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
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
-- Class ServerHealthMetric as table serverpod_health_metric
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
-- Class LogEntry as table serverpod_log
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
-- Class MessageLogEntry as table serverpod_message_log
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
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
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
-- Class QueryLogEntry as table serverpod_query_log
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
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
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
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20250706094815209', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250706094815209', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

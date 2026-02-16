BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "otso_external_sync" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "syncedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "otso_external_sync_unique_idx" ON "otso_external_sync" USING btree ("itemId");

--
-- ACTION DROP TABLE
--
DROP TABLE "push_subscriptions" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "push_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "pubKey" text NOT NULL,
    "relay" text NOT NULL,
    "token" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "subscription_unique_idx" ON "push_subscriptions" USING btree ("pubKey", "relay", "token");


--
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20250709102015128', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250709102015128', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "otso_geo_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "pubKey" text NOT NULL,
    "geohash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "otso_geo_subscription_unique_idx" ON "otso_geo_subscriptions" USING btree ("pubKey", "geohash");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "otso_push_subscriptions" (
    "id" bigserial PRIMARY KEY,
    "pubKey" text NOT NULL,
    "relay" text NOT NULL,
    "token" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "otso_push_subscription_unique_idx" ON "otso_push_subscriptions" USING btree ("pubKey", "relay", "token");


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

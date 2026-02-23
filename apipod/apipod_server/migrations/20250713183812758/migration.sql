BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "otso_external_sync" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "otso_external_sync" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "source" text NOT NULL,
    "syncedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "otso_external_sync_unique_idx" ON "otso_external_sync" USING btree ("itemId", "source");


--
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20250713183812758', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250713183812758', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

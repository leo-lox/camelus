BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20250320134010505', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250320134010505', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

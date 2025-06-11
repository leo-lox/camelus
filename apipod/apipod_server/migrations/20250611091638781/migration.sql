BEGIN;

--
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20250611091638781', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250611091638781', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

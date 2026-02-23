BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "reports_incoming" CASCADE;

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
-- ACTION ALTER TABLE
--
ALTER TABLE "serverpod_session_log" ADD COLUMN "userId" text;

--
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20260127093644718', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260127093644718', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;

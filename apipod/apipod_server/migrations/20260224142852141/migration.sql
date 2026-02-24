BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "trends_snapshot" (
    "id" bigserial PRIMARY KEY,
    "createdAt" timestamp without time zone NOT NULL,
    "interval" text NOT NULL,
    "payloadJson" text NOT NULL
);


--
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20260224142852141', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260224142852141', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;

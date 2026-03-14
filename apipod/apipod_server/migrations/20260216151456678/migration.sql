BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "push_subscriptions" ADD COLUMN "kinds" json;
--
-- ACTION ALTER TABLE
--
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");

--
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20260216151456678', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260216151456678', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;

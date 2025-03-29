BEGIN;

--
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR apipod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('apipod', '20250329152226716', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250329152226716', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;

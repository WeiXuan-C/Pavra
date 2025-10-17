-- You can safely remove BEGIN/COMMIT in pgAdmin if desired
BEGIN;

-- =======================================
-- ACTION CREATE TABLES
-- =======================================

CREATE TABLE IF NOT EXISTS "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "serverpod_cloud_storage_path_idx"
    ON "serverpod_cloud_storage" ("storageId", "path");
CREATE INDEX IF NOT EXISTS "serverpod_cloud_storage_expiration"
    ON "serverpod_cloud_storage" ("expiration");


CREATE TABLE IF NOT EXISTS "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "serverpod_cloud_storage_direct_upload_storage_path"
    ON "serverpod_cloud_storage_direct_upload" ("storageId", "path");


CREATE TABLE IF NOT EXISTS "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

CREATE INDEX IF NOT EXISTS "serverpod_future_call_time_idx"
    ON "serverpod_future_call" ("time");
CREATE INDEX IF NOT EXISTS "serverpod_future_call_serverId_idx"
    ON "serverpod_future_call" ("serverId");
CREATE INDEX IF NOT EXISTS "serverpod_future_call_identifier_idx"
    ON "serverpod_future_call" ("identifier");


CREATE TABLE IF NOT EXISTS "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "serverpod_health_connection_info_timestamp_idx"
    ON "serverpod_health_connection_info" ("timestamp", "serverId", "granularity");


CREATE TABLE IF NOT EXISTS "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "serverpod_health_metric_timestamp_idx"
    ON "serverpod_health_metric" ("timestamp", "serverId", "name", "granularity");


CREATE TABLE IF NOT EXISTS "serverpod_log" (
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

CREATE INDEX IF NOT EXISTS "serverpod_log_sessionLogId_idx"
    ON "serverpod_log" ("sessionLogId");


CREATE TABLE IF NOT EXISTS "serverpod_message_log" (
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


CREATE TABLE IF NOT EXISTS "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "serverpod_method_endpoint_method_idx"
    ON "serverpod_method" ("endpoint", "method");


CREATE TABLE IF NOT EXISTS "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

CREATE UNIQUE INDEX IF NOT EXISTS "serverpod_migrations_ids"
    ON "serverpod_migrations" ("module");


CREATE TABLE IF NOT EXISTS "serverpod_query_log" (
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

CREATE INDEX IF NOT EXISTS "serverpod_query_log_sessionLogId_idx"
    ON "serverpod_query_log" ("sessionLogId");


CREATE TABLE IF NOT EXISTS "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);


CREATE TABLE IF NOT EXISTS "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);


CREATE TABLE IF NOT EXISTS "serverpod_session_log" (
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

CREATE INDEX IF NOT EXISTS "serverpod_session_log_serverid_idx"
    ON "serverpod_session_log" ("serverId");
CREATE INDEX IF NOT EXISTS "serverpod_session_log_touched_idx"
    ON "serverpod_session_log" ("touched");
CREATE INDEX IF NOT EXISTS "serverpod_session_log_isopen_idx"
    ON "serverpod_session_log" ("isOpen");


-- =======================================
-- ACTION CREATE FOREIGN KEYS (safe add)
-- =======================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'serverpod_log_fk_0'
    ) THEN
        ALTER TABLE "serverpod_log"
            ADD CONSTRAINT "serverpod_log_fk_0"
            FOREIGN KEY("sessionLogId")
            REFERENCES "serverpod_session_log"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'serverpod_message_log_fk_0'
    ) THEN
        ALTER TABLE "serverpod_message_log"
            ADD CONSTRAINT "serverpod_message_log_fk_0"
            FOREIGN KEY("sessionLogId")
            REFERENCES "serverpod_session_log"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'serverpod_query_log_fk_0'
    ) THEN
        ALTER TABLE "serverpod_query_log"
            ADD CONSTRAINT "serverpod_query_log_fk_0"
            FOREIGN KEY("sessionLogId")
            REFERENCES "serverpod_session_log"("id")
            ON DELETE CASCADE ON UPDATE NO ACTION;
    END IF;
END$$;


-- =======================================
-- MIGRATION VERSION UPDATES
-- =======================================

INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('pavra_server', '20251013093515748', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251013093515748', "timestamp" = now();

INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();

COMMIT;

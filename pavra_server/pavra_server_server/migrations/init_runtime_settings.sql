-- Initialize serverpod_runtime_settings if not exists
INSERT INTO "serverpod_runtime_settings" (
    "id",
    "logSettings",
    "logSettingsOverrides",
    "logServiceCalls",
    "logMalformedCalls"
)
SELECT 
    1,
    '{"0":{"logLevel":"info","logStreamingEnabled":true,"logAllSessions":true}}'::json,
    '{}'::json,
    true,
    true
WHERE NOT EXISTS (
    SELECT 1 FROM "serverpod_runtime_settings" WHERE "id" = 1
);

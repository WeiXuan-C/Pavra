-- =====================================
-- PAVRA DATABASE EXTENSIONS
-- =====================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- 用于密码哈希和加密
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- 用于 UUID 生成
CREATE EXTENSION IF NOT EXISTS pg_net;        -- 用于 HTTP 请求（OneSignal）

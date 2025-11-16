-- =====================================
-- PROFILES TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  email TEXT,
  avatar_url TEXT,
  provider TEXT CHECK (provider IN ('email', 'google', 'github', 'facebook', 'discord', 'otp')),
  provider_user_id TEXT,
  role TEXT CHECK (role IN ('user', 'authority', 'developer')),
  language TEXT,
  theme_mode TEXT,
  reports_count INT DEFAULT 0,
  reputation_score INT DEFAULT 0,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_provider_user UNIQUE (provider, provider_user_id)
);

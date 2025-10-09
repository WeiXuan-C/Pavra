CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  email TEXT NULL,
  avatar_url TEXT,
  provider TEXT CHECK (provider IN ('email', 'google', 'github', 'facebook', 'discord', 'otp')),
  provider_user_id TEXT,
  recovery_code TEXT,
  role TEXT CHECK (role IN ('user', 'authority', 'developer')), -- *User* (reporter) & *Authority* (reviewer)
  language TEXT,
  theme_mode TEXT,
  reports_count INT,
  reputation_score INT, -- (prevent spam)
  notifications_enabled BOOLEAN,
  device_token TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_provider_user UNIQUE (provider, provider_user_id)
);


CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_updated_at ON public.profiles;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();
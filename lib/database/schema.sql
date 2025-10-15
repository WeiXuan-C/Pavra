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
  recovery_code TEXT,
  role TEXT CHECK (role IN ('user', 'authority', 'developer')),  -- reporter / reviewer / dev
  language TEXT,
  theme_mode TEXT,
  reports_count INT DEFAULT 0,
  reputation_score INT DEFAULT 0,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  device_token TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_provider_user UNIQUE (provider, provider_user_id)
);

-- =====================================
-- ACTION LOG TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.action_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,         -- e.g. "CREATE_REPORT", "LOGIN", "SEND_MESSAGE"
  target_id UUID,                    -- optional link to report, comment, etc.
  target_table TEXT,                 -- optional table name
  description TEXT,                  -- e.g. "User submitted report #23"
  metadata JSONB DEFAULT '{}',       -- extra data
  created_at TIMESTAMPTZ DEFAULT now()
);


-- =====================================
-- NOTIFICATIONS TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('success', 'warning', 'alert', 'info')),
  is_read BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  related_action UUID REFERENCES action_log(id) ON DELETE SET NULL,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- =====================================
-- AUTO-UPDATE UPDATED_AT
-- =====================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- PROFILES
DROP TRIGGER IF EXISTS trg_set_updated_at_profiles ON public.profiles;
CREATE TRIGGER trg_set_updated_at_profiles
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- NOTIFICATIONS
DROP TRIGGER IF EXISTS trg_set_updated_at_notifications ON public.notifications;
CREATE TRIGGER trg_set_updated_at_notifications
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =====================================
-- INDEXES FOR FOREIGN KEYS & COMMON QUERIES
-- =====================================

-- PROFILES
-- (No extra FK here since id references auth.users directly as PK)

-- ACTION LOG
CREATE INDEX IF NOT EXISTS idx_action_log_user_id ON public.action_log(user_id);
CREATE INDEX IF NOT EXISTS idx_action_log_created_at ON public.action_log(created_at);
CREATE INDEX IF NOT EXISTS idx_action_log_action_type ON public.action_log(action_type);

-- NOTIFICATIONS
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_related_action ON public.notifications(related_action);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_is_deleted ON public.notifications(is_deleted);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- =====================================
-- OPTIONAL: COMPOSITE INDEXES (for filtering + ordering)
-- =====================================
-- Helps if you often query notifications by user_id and unread status
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications(user_id, is_read, created_at DESC);

-- Helps if you often query action logs by user and date
CREATE INDEX IF NOT EXISTS idx_action_log_user_created
  ON public.action_log(user_id, created_at DESC);
-- =====================================
-- PAVRA DATABASE SCHEMA
-- =====================================
-- 完整的数据库表结构定义
-- 
-- 注意：
-- - 函数和触发器在 functions/ 文件夹
-- - RLS 策略在 policies/ 文件夹
-- - 迁移脚本在 migrations/ 文件夹

-- =====================================
-- EXTENSIONS
-- =====================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- 用于密码哈希和加密
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- 用于 UUID 生成
CREATE EXTENSION IF NOT EXISTS pg_net;        -- 用于 HTTP 请求（OneSignal）

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

-- =====================================
-- ACTION LOG TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.action_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  target_id UUID,
  target_table TEXT,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  is_synced BOOLEAN DEFAULT FALSE
);

-- =====================================
-- NOTIFICATIONS TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (
    type IN (
      'success', 'warning', 'alert', 'info',
      'system', 'user', 'report', 'location_alert',
      'submission_status', 'promotion', 'reminder'
    )
  ),
  related_action UUID REFERENCES action_log(id) ON DELETE SET NULL,
  data JSONB DEFAULT '{}',
  status TEXT DEFAULT 'sent' CHECK (
    status IN ('draft', 'scheduled', 'sent', 'failed')
  ),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  target_type TEXT DEFAULT 'single' CHECK (
    target_type IN ('single', 'all', 'role', 'custom')
  ),
  target_roles TEXT[],
  target_user_ids UUID[],
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- =====================================
-- USER NOTIFICATIONS TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.user_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(notification_id, user_id)
);

-- =====================================
-- REPORT ISSUES TABLE 
-- =====================================
CREATE TABLE IF NOT EXISTS public.report_issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,                                  -- 由AI或用户生成的标题
  description TEXT,                            -- 用户描述，可为空
  issue_type_ids UUID[] DEFAULT '{}',          -- 多选的 issue type ID
  severity TEXT CHECK (
    severity IN ('minor', 'low', 'moderate', 'high', 'critical')
  ) DEFAULT 'moderate',
  address TEXT,                                -- 详细地址
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  status TEXT DEFAULT 'draft' CHECK (
    status IN ('draft', 'submitted', 'reviewed', 'spam', 'discard')
  ),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.issue_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID REFERENCES report_issues(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,                     -- Supabase Storage 路径或公开URL
  photo_type TEXT DEFAULT 'main' CHECK (
    photo_type IN ('main', 'additional', 'reviewed', 'ai_reference')
  ),                                           -- 区分主图、附图、审核图、AI图
  is_primary BOOLEAN DEFAULT FALSE,            -- 是否主图（用户上传的首图）
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.issue_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  icon_url TEXT,                         -- 可选：用于前端展示
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.issue_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id UUID REFERENCES report_issues(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_type TEXT CHECK (vote_type IN ('verify', 'spam')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(issue_id, user_id, vote_type)
);


-- =====================================
-- AUTHORITY REQUESTS TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_number TEXT NOT NULL,
  organization TEXT NOT NULL,
  location TEXT NOT NULL,
  referrer_code TEXT,
  remarks TEXT,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'approved', 'rejected')
  ),
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_comment TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================
-- USER REPUTATION SCORE  TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.reputations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (
    action_type IN ('UPLOAD_ISSUE', 'ISSUE_REVIEWED', 'AUTHORITY_REJECTED', 'ISSUE_SPAM', 'OTHERS')
  ),
  change_amount INT NOT NULL,
  score_before INT NOT NULL CHECK (score_before >= 0 AND score_before <= 100),
  score_after INT NOT NULL CHECK (score_after >= 0 AND score_after <= 100),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================
-- INDEXES
-- =====================================

-- PROFILES
-- (No extra FK here since id references auth.users directly as PK)

-- ACTION LOG
CREATE INDEX IF NOT EXISTS idx_action_log_user_id ON public.action_log(user_id);
CREATE INDEX IF NOT EXISTS idx_action_log_created_at ON public.action_log(created_at);
CREATE INDEX IF NOT EXISTS idx_action_log_action_type ON public.action_log(action_type);
CREATE INDEX IF NOT EXISTS idx_action_log_is_synced ON public.action_log(is_synced) WHERE is_synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_action_log_user_created ON public.action_log(user_id, created_at DESC);

-- NOTIFICATIONS
CREATE INDEX IF NOT EXISTS idx_notifications_target_user_ids ON public.notifications USING GIN(target_user_ids);
CREATE INDEX IF NOT EXISTS idx_notifications_related_action ON public.notifications(related_action);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_at ON public.notifications(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX IF NOT EXISTS idx_notifications_target_type ON public.notifications(target_type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_by ON public.notifications(created_by);
CREATE INDEX IF NOT EXISTS idx_notifications_is_deleted ON public.notifications(is_deleted);

-- USER NOTIFICATIONS
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON public.user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_notification_id ON public.user_notifications(notification_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_unread ON public.user_notifications(user_id, is_read) WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_report_issues_status ON public.report_issues(status);
CREATE INDEX IF NOT EXISTS idx_report_issues_severity ON public.report_issues(severity);
CREATE INDEX IF NOT EXISTS idx_report_issues_created_by ON public.report_issues(created_by);
CREATE INDEX IF NOT EXISTS idx_report_issues_location ON public.report_issues(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_report_issues_issue_type_ids ON public.report_issues USING GIN(issue_type_ids);

-- REQUESTS
CREATE INDEX IF NOT EXISTS idx_requests_user_id ON public.requests(user_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_reviewed_by ON public.requests(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON public.requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_requests_is_deleted ON public.requests(is_deleted);

-- REPUTATIONS
CREATE INDEX IF NOT EXISTS idx_reputations_user_id ON public.reputations(user_id);
CREATE INDEX IF NOT EXISTS idx_reputations_created_at ON public.reputations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reputations_user_created ON public.reputations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reputations_action_type ON public.reputations(action_type);

-- =====================================
-- 说明
-- =====================================
-- 
-- 下一步：
-- 1. 执行 functions/handle_new_user.sql
-- 2. 执行 functions/notification_functions.sql
-- 3. 执行 policies/profiles_policies.sql
-- 4. 执行 policies/action_log_policies.sql
-- 5. 执行 policies/notification_policies.sql

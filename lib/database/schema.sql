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
    action_type IN (
      -- Positive actions (increase reputation)
      'UPLOAD_ISSUE',           -- +1: User submits a report
      'FIRST_REPORTER',         -- +5: First to report in location      
      'DUPLICATE_REPORT',       -- -5: Duplicate of existing report
      'ABUSE_REPORT',           -- -25: System abuse
      'MANUAL_ADJUSTMENT',      -- ±any: Admin manual correction
      'OTHERS'                  -- For future extensions
    )
  ),
  change_amount INT NOT NULL,
  score_before INT NOT NULL CHECK (score_before >= 0 AND score_before <= 100),
  score_after INT NOT NULL CHECK (score_after >= 0 AND score_after <= 100),
  related_issue_id UUID REFERENCES report_issues(id) ON DELETE SET NULL,  -- Link to related report
  notes TEXT,                                                              -- Optional admin notes
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
-- SAVED ROUTES TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.saved_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    from_location_name VARCHAR(255) NOT NULL,
    from_latitude DOUBLE PRECISION NOT NULL,
    from_longitude DOUBLE PRECISION NOT NULL,
    from_address TEXT,
    to_location_name VARCHAR(255) NOT NULL,
    to_latitude DOUBLE PRECISION NOT NULL,
    to_longitude DOUBLE PRECISION NOT NULL,
    to_address TEXT,
    distance_km DOUBLE PRECISION,
    is_monitoring BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT false
);

-- =====================================
-- SAVED LOCATIONS TABLE
-- =====================================
CREATE TABLE IF NOT EXISTS public.saved_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    icon VARCHAR(50) DEFAULT 'place',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT false,
    UNIQUE(user_id, label)
);

-- =====================================
-- INDEXES (continued)
-- =====================================

-- SAVED ROUTES
CREATE INDEX IF NOT EXISTS idx_saved_routes_user_id ON public.saved_routes(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_routes_is_monitoring ON public.saved_routes(is_monitoring);
CREATE INDEX IF NOT EXISTS idx_saved_routes_deleted ON public.saved_routes(is_deleted);

-- SAVED LOCATIONS
CREATE INDEX IF NOT EXISTS idx_saved_locations_user_id ON public.saved_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_locations_deleted ON public.saved_locations(is_deleted);

-- =====================================
-- FUNCTIONS
-- =====================================

-- Function to update updated_at timestamp (with security settings)
CREATE OR REPLACE FUNCTION update_saved_routes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

-- =====================================
-- TRIGGERS
-- =====================================

-- Trigger for saved_routes updated_at
CREATE TRIGGER trigger_update_saved_routes_updated_at
    BEFORE UPDATE ON public.saved_routes
    FOR EACH ROW
    EXECUTE FUNCTION update_saved_routes_updated_at();

-- Trigger for saved_locations updated_at
CREATE TRIGGER trigger_update_saved_locations_updated_at
    BEFORE UPDATE ON public.saved_locations
    FOR EACH ROW
    EXECUTE FUNCTION update_saved_routes_updated_at();

-- =====================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================

-- Enable RLS on saved_routes
ALTER TABLE public.saved_routes ENABLE ROW LEVEL SECURITY;

-- Enable RLS on saved_locations
ALTER TABLE public.saved_locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for saved_routes (Optimized for performance)
-- Using (select auth.uid()) instead of auth.uid() prevents re-evaluation for each row
CREATE POLICY "saved_routes_select_policy"
    ON public.saved_routes
    FOR SELECT
    USING ((select auth.uid()) = user_id);

CREATE POLICY "saved_routes_insert_policy"
    ON public.saved_routes
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_routes_update_policy"
    ON public.saved_routes
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_routes_delete_policy"
    ON public.saved_routes
    FOR DELETE
    USING ((select auth.uid()) = user_id);

-- RLS Policies for saved_locations (Optimized for performance)
CREATE POLICY "saved_locations_select_policy"
    ON public.saved_locations
    FOR SELECT
    USING ((select auth.uid()) = user_id);

CREATE POLICY "saved_locations_insert_policy"
    ON public.saved_locations
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_locations_update_policy"
    ON public.saved_locations
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_locations_delete_policy"
    ON public.saved_locations
    FOR DELETE
    USING ((select auth.uid()) = user_id);

-- =====================================
-- PERMISSIONS
-- =====================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_routes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_locations TO authenticated;

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
--
-- 新增表：
-- - saved_routes: 用户保存的常用路线
-- - saved_locations: 用户保存的常用地点（家、公司等）
--
-- 安全优化：
-- - RLS 策略使用 (select auth.uid()) 提升性能
-- - 函数使用 SECURITY DEFINER 和固定 search_path 防止安全漏洞

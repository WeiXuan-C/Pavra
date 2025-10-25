-- =====================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Notification System
-- =====================================

-- =====================================
-- NOTIFICATIONS TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "notifications_select_developer" ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_authority_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_user" ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_all" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own_draft" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_service_all" ON public.notifications;
DROP POLICY IF EXISTS "Service role can manage notifications" ON public.notifications;
DROP POLICY IF EXISTS "View notifications" ON public.notifications;
DROP POLICY IF EXISTS "Insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Update notification read status" ON public.notifications;

-- 1. SELECT Policy (合并为单个策略以优化性能)

-- Developer 可以查看所有通知
-- Authority 可以查看自己创建的通知
-- 用户可以查看发送给自己的通知
CREATE POLICY "notifications_select_all" ON public.notifications
  FOR SELECT
  USING (
    -- Developer 可以查看所有
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) AND role = 'developer'
    )
    -- Authority 可以查看自己创建的
    OR (
      EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid()) AND role = 'authority'
      )
      AND created_by = (SELECT auth.uid())
    )
    -- 用户可以查看发送给自己的
    OR EXISTS (
      SELECT 1 FROM public.user_notifications
      WHERE notification_id = notifications.id
        AND user_id = (SELECT auth.uid())
        AND is_deleted = FALSE
    )
  );

-- 2. INSERT Policy

-- Developer 和 Authority 可以创建通知
CREATE POLICY "notifications_insert_admin" ON public.notifications
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) 
        AND role IN ('developer', 'authority')
    )
  );

-- 3. UPDATE Policy

-- 只有创建者可以更新自己的通知（仅 draft 状态）
CREATE POLICY "notifications_update_own_draft" ON public.notifications
  FOR UPDATE
  USING (
    created_by = (SELECT auth.uid())
    AND status = 'draft'
  )
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND status = 'draft'
  );

-- 4. DELETE Policy

-- 只有创建者可以删除自己的通知（仅 draft/scheduled 状态）
CREATE POLICY "notifications_delete_own" ON public.notifications
  FOR DELETE
  USING (
    created_by = (SELECT auth.uid())
    AND status IN ('draft', 'scheduled')
  );

-- 5. Service Role Policy

-- Service role 可以完全管理 notifications
CREATE POLICY "notifications_service_all" ON public.notifications
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- USER NOTIFICATIONS TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.user_notifications ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "user_notifications_select_own" ON public.user_notifications;
DROP POLICY IF EXISTS "user_notifications_select_developer" ON public.user_notifications;
DROP POLICY IF EXISTS "user_notifications_select_all" ON public.user_notifications;
DROP POLICY IF EXISTS "user_notifications_insert_system" ON public.user_notifications;
DROP POLICY IF EXISTS "user_notifications_update_own" ON public.user_notifications;
DROP POLICY IF EXISTS "user_notifications_delete_own" ON public.user_notifications;
DROP POLICY IF EXISTS "user_notifications_service_all" ON public.user_notifications;

-- 1. SELECT Policy (合并为单个策略以优化性能)

-- 用户可以查看自己的，Developer 可以查看所有
CREATE POLICY "user_notifications_select_all" ON public.user_notifications
  FOR SELECT
  USING (
    user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) AND role = 'developer'
    )
  );

-- 2. INSERT Policy

-- 触发器自动插入，允许系统插入
CREATE POLICY "user_notifications_insert_system" ON public.user_notifications
  FOR INSERT
  WITH CHECK (true);

-- 3. UPDATE Policy

-- 用户可以更新自己的 user_notifications（标记已读、软删除等）
CREATE POLICY "user_notifications_update_own" ON public.user_notifications
  FOR UPDATE
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- 4. DELETE Policy

-- 用户可以删除自己的 user_notifications（硬删除，一般不用）
CREATE POLICY "user_notifications_delete_own" ON public.user_notifications
  FOR DELETE
  USING (user_id = (SELECT auth.uid()));

-- 5. Service Role Policy

-- Service role 可以完全管理 user_notifications
CREATE POLICY "user_notifications_service_all" ON public.user_notifications
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- POLICY 说明
-- =====================================

COMMENT ON POLICY "notifications_select_all" ON public.notifications IS 
  'Developer 可以查看所有通知，Authority 可以查看自己创建的，用户可以查看发送给自己的';

COMMENT ON POLICY "notifications_insert_admin" ON public.notifications IS 
  'Developer 和 Authority 可以创建通知';

COMMENT ON POLICY "notifications_update_own_draft" ON public.notifications IS 
  '只有创建者可以更新自己的 draft 状态通知';

COMMENT ON POLICY "notifications_delete_own" ON public.notifications IS 
  '只有创建者可以删除自己的 draft/scheduled 状态通知';

COMMENT ON POLICY "notifications_service_all" ON public.notifications IS 
  'Service role 可以完全管理 notifications';

COMMENT ON POLICY "user_notifications_select_all" ON public.user_notifications IS 
  '用户可以查看自己的通知状态，Developer 可以查看所有';

COMMENT ON POLICY "user_notifications_insert_system" ON public.user_notifications IS 
  '允许触发器自动插入记录';

COMMENT ON POLICY "user_notifications_update_own" ON public.user_notifications IS 
  '用户可以更新自己的通知状态（已读、删除等）';

COMMENT ON POLICY "user_notifications_delete_own" ON public.user_notifications IS 
  '用户可以硬删除自己的通知记录（一般使用软删除）';

COMMENT ON POLICY "user_notifications_service_all" ON public.user_notifications IS 
  'Service role 可以完全管理 user_notifications';

-- =====================================
-- ACTION LOG TABLE POLICIES
-- =====================================

ALTER TABLE public.action_log ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies
DROP POLICY IF EXISTS "action_log_select_own" ON public.action_log;
DROP POLICY IF EXISTS "action_log_select_developer" ON public.action_log;
DROP POLICY IF EXISTS "action_log_select_all" ON public.action_log;
DROP POLICY IF EXISTS "action_log_insert_own" ON public.action_log;
DROP POLICY IF EXISTS "action_log_service_all" ON public.action_log;
DROP POLICY IF EXISTS "Service role can manage logs" ON public.action_log;
DROP POLICY IF EXISTS "View action logs" ON public.action_log;
DROP POLICY IF EXISTS "Insert own action logs" ON public.action_log;

-- 1. SELECT Policy (合并为单个策略以优化性能)

-- 用户可以查看自己的 logs，Developer 可以查看所有 logs
CREATE POLICY "action_log_select_all" ON public.action_log
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = (SELECT auth.uid()) AND role = 'developer'
    )
  );

-- 2. INSERT Policy

-- 用户可以插入自己的 action logs
CREATE POLICY "action_log_insert_own" ON public.action_log
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- 3. Service Role Policy

-- Service role 可以完全管理 action logs
CREATE POLICY "action_log_service_all" ON public.action_log
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- POLICY 说明
-- =====================================

COMMENT ON POLICY "action_log_select_all" ON public.action_log IS 
  '用户可以查看自己的 logs，Developer 可以查看所有 logs';

COMMENT ON POLICY "action_log_insert_own" ON public.action_log IS 
  '用户可以插入自己的 action logs';

COMMENT ON POLICY "action_log_service_all" ON public.action_log IS 
  'Service role 可以完全管理 action logs';

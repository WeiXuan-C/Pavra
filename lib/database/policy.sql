-- =====================================
-- PROFILES TABLE
-- =====================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.profiles;

-- Allow authenticated users to view all profiles
-- (Required for notification system, user selection, etc.)
CREATE POLICY "Authenticated users can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow service role to insert profiles
CREATE POLICY "Service role can insert profiles"
  ON public.profiles
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Allow authenticated users to insert their own profile (fallback)
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

-- Allow authenticated users to update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- Allow authenticated users to delete their own profile
CREATE POLICY "Users can delete own profile"
  ON public.profiles
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = id);

-- =====================================
-- ACTION LOG TABLE
-- =====================================
ALTER TABLE public.action_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage logs" ON public.action_log;
DROP POLICY IF EXISTS "View action logs" ON public.action_log;
DROP POLICY IF EXISTS "Insert own action logs" ON public.action_log;

-- SELECT: Users can view own logs, authority/developer can view all logs
CREATE POLICY "View action logs"
  ON public.action_log
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND LOWER(role) IN ('authority', 'developer')
    )
  );

-- INSERT: Users can only insert their own logs
CREATE POLICY "Insert own action logs"
  ON public.action_log
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Allow service role (backend) to manage logs
CREATE POLICY "Service role can manage logs"
  ON public.action_log
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================
-- NOTIFICATIONS TABLE
-- =====================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage notifications" ON public.notifications;
DROP POLICY IF EXISTS "View notifications" ON public.notifications;
DROP POLICY IF EXISTS "Insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Update notification read status" ON public.notifications;

-- SELECT: Developers can see ALL notifications (created by anyone)
-- Authority and Users can only see notifications sent to them (via target_user_ids)
CREATE POLICY "View notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (
    -- Developer can see ALL notifications (not just their own)
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND LOWER(role) = 'developer'
    )
    OR
    -- Authority and User can see notifications where they are in target_user_ids (uuid array)
    (
      target_user_ids IS NOT NULL 
      AND (SELECT auth.uid()) = ANY(target_user_ids)
    )
    OR
    -- Legacy: User can see notifications sent directly to them
    (SELECT auth.uid()) = user_id
  );

-- INSERT: Only developers/authorities can create notifications
CREATE POLICY "Insert notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND LOWER(role) IN ('authority', 'developer')
    )
  );

-- UPDATE: Users can only update is_read/is_deleted for notifications sent to them
-- Developers can update ALL notifications
CREATE POLICY "Update notification read status"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (
    -- Developer can update ALL notifications
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND LOWER(role) = 'developer'
    )
    OR
    -- Authority and User can update notifications sent to them (is_read, is_deleted only)
    (
      target_user_ids IS NOT NULL 
      AND (SELECT auth.uid()) = ANY(target_user_ids)
    )
    OR
    -- Legacy: User can update notifications sent directly to them
    (SELECT auth.uid()) = user_id
  )
  WITH CHECK (
    -- Developer can update ALL notifications
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND LOWER(role) = 'developer'
    )
    OR
    -- Authority and User can update notifications sent to them
    (
      target_user_ids IS NOT NULL 
      AND (SELECT auth.uid()) = ANY(target_user_ids)
    )
    OR
    -- Legacy: User can update notifications sent directly to them
    (SELECT auth.uid()) = user_id
  );

-- Allow service role to fully manage notifications (for backend system)
CREATE POLICY "Service role can manage notifications"
  ON public.notifications
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
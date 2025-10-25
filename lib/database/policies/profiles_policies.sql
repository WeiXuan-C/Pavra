-- =====================================
-- PROFILES TABLE POLICIES
-- =====================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_service" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.profiles;

-- 1. SELECT Policy
-- 所有认证用户可以查看所有 profiles（用于显示用户名、选择用户等）
CREATE POLICY "profiles_select_all" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- 2. INSERT Policies
-- Service role 可以插入 profiles（用于触发器）
CREATE POLICY "profiles_insert_service" ON public.profiles
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- 用户可以插入自己的 profile（fallback）
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

-- 3. UPDATE Policy
-- 用户只能更新自己的 profile
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- 4. DELETE Policy
-- 用户可以删除自己的 profile
CREATE POLICY "profiles_delete_own" ON public.profiles
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = id);

-- =====================================
-- POLICY 说明
-- =====================================

COMMENT ON POLICY "profiles_select_all" ON public.profiles IS 
  '所有认证用户可以查看所有 profiles';

COMMENT ON POLICY "profiles_insert_service" ON public.profiles IS 
  'Service role 可以插入 profiles（用于触发器）';

COMMENT ON POLICY "profiles_insert_own" ON public.profiles IS 
  '用户可以插入自己的 profile';

COMMENT ON POLICY "profiles_update_own" ON public.profiles IS 
  '用户只能更新自己的 profile';

COMMENT ON POLICY "profiles_delete_own" ON public.profiles IS 
  '用户可以删除自己的 profile';

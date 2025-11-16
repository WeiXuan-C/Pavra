-- =====================================
-- USER ALERT PREFERENCES RLS POLICIES
-- =====================================
ALTER TABLE public.user_alert_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only view their own alert preferences
CREATE POLICY "user_alert_preferences_select_policy"
  ON public.user_alert_preferences
  FOR SELECT
  USING ((select auth.uid()) = user_id);

-- Users can only insert their own alert preferences
CREATE POLICY "user_alert_preferences_insert_policy"
  ON public.user_alert_preferences
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

-- Users can only update their own alert preferences
CREATE POLICY "user_alert_preferences_update_policy"
  ON public.user_alert_preferences
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Users can only delete their own alert preferences
CREATE POLICY "user_alert_preferences_delete_policy"
  ON public.user_alert_preferences
  FOR DELETE
  USING ((select auth.uid()) = user_id);

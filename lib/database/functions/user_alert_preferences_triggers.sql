-- =====================================
-- USER ALERT PREFERENCES TRIGGERS
-- =====================================

-- Function to create default alert preferences for new users
CREATE OR REPLACE FUNCTION create_default_alert_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_alert_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

-- Trigger to create default preferences when a new profile is created
DROP TRIGGER IF EXISTS trigger_create_default_alert_preferences ON public.profiles;
CREATE TRIGGER trigger_create_default_alert_preferences
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_default_alert_preferences();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_alert_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trigger_update_alert_preferences_updated_at ON public.user_alert_preferences;
CREATE TRIGGER trigger_update_alert_preferences_updated_at
  BEFORE UPDATE ON public.user_alert_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_alert_preferences_updated_at();
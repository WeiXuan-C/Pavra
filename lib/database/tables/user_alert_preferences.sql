-- =====================================
-- USER ALERT PREFERENCES TABLE
-- =====================================
-- Stores user preferences for safety alerts including
-- enabled alert types and monitoring radius

CREATE TABLE IF NOT EXISTS public.user_alert_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Alert radius in miles (default 5 miles based on UI)
  alert_radius_miles DOUBLE PRECISION DEFAULT 5.0 CHECK (alert_radius_miles >= 1.0 AND alert_radius_miles <= 10.0),
  
  -- Alert type toggles
  road_damage_enabled BOOLEAN DEFAULT TRUE,
  construction_zones_enabled BOOLEAN DEFAULT TRUE,
  weather_hazards_enabled BOOLEAN DEFAULT TRUE,
  traffic_incidents_enabled BOOLEAN DEFAULT TRUE,
  
  -- Notification behavior settings
  sound_enabled BOOLEAN DEFAULT TRUE,
  vibration_enabled BOOLEAN DEFAULT FALSE,
  do_not_disturb_respect BOOLEAN DEFAULT FALSE,
  
  -- Quiet hours (stored as time without timezone)
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one preference record per user
  UNIQUE(user_id)
);
-- =====================================
-- GET NEARBY USERS FUNCTION
-- =====================================
-- Returns user IDs who have location alerts enabled and notifications enabled
-- 
-- NOTE: This is a simplified implementation that returns users based on their
-- alert preferences. Geographic filtering by actual user location would require
-- adding location tracking to the profiles table. For now, this returns all
-- users who have location alerts enabled and would want to be notified about
-- issues in any location within their configured alert radius.
--
-- Future enhancement: Add user location tracking and implement true geographic
-- filtering using Haversine formula or PostGIS spatial queries.

CREATE OR REPLACE FUNCTION public.get_nearby_users(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (id UUID)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.id
  FROM public.profiles p
  LEFT JOIN public.user_alert_preferences uap ON p.id = uap.user_id
  WHERE 
    -- User has notifications enabled globally
    p.notifications_enabled = true
    -- Check if any location-based alert type is enabled
    -- If no preferences exist, default to enabled (all alert types on by default)
    AND (
      uap.id IS NULL -- No preferences set, use defaults (all enabled)
      OR uap.road_damage_enabled = true
      OR uap.construction_zones_enabled = true
      OR uap.weather_hazards_enabled = true
      OR uap.traffic_incidents_enabled = true
    )
    -- User's configured alert radius is sufficient (convert km to miles for comparison)
    -- Default alert radius is 5 miles if not set
    AND COALESCE(uap.alert_radius_miles, 5.0) >= (radius_km * 0.621371)
    -- Don't notify the current user (report creator)
    AND p.id != COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)
    -- Exclude deleted users (soft delete check via auth.users if implemented)
    -- For now, we rely on CASCADE DELETE from auth.users
    ;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION public.get_nearby_users IS 'Returns user IDs who have location alerts and notifications enabled. Currently returns users based on alert preferences. Geographic filtering by user location to be implemented when location tracking is added.';

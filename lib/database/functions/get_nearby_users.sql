-- =====================================
-- GET NEARBY USERS FUNCTION
-- =====================================
-- Returns user IDs who are within the specified radius of a location
-- and have location tracking and notifications enabled
-- 
-- Uses Haversine formula for accurate distance calculation
-- Filters for users with recent location updates (within 30 minutes)

-- Drop existing function first (required when changing return type)
DROP FUNCTION IF EXISTS public.get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION public.get_nearby_users(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (id UUID, distance_km DOUBLE PRECISION)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS '
  SELECT 
    p.id,
    (
      6371 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(lat)) * 
          cos(radians(p.current_latitude)) * 
          cos(radians(p.current_longitude) - radians(lng)) + 
          sin(radians(lat)) * 
          sin(radians(p.current_latitude))
        ))
      )
    ) AS distance_km
  FROM public.profiles p
  LEFT JOIN public.user_alert_preferences uap ON p.id = uap.user_id
  WHERE 
    p.location_tracking_enabled = true
    AND p.current_latitude IS NOT NULL
    AND p.current_longitude IS NOT NULL
    AND p.location_updated_at > NOW() - INTERVAL ''30 minutes''
    AND p.notifications_enabled = true
    AND (
      uap.id IS NULL
      OR uap.road_damage_enabled = true
      OR uap.construction_zones_enabled = true
      OR uap.weather_hazards_enabled = true
      OR uap.traffic_incidents_enabled = true
    )
    AND p.id != COALESCE(auth.uid(), ''00000000-0000-0000-0000-000000000000''::UUID)
    AND (
      6371 * acos(
        LEAST(1.0, GREATEST(-1.0,
          cos(radians(lat)) * 
          cos(radians(p.current_latitude)) * 
          cos(radians(p.current_longitude) - radians(lng)) + 
          sin(radians(lat)) * 
          sin(radians(p.current_latitude))
        ))
      )
    ) <= radius_km
  ORDER BY distance_km ASC
';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION public.get_nearby_users IS 'Returns user IDs within specified radius who have location tracking and notifications enabled. Uses Haversine formula for distance calculation and filters for recent location updates (within 30 minutes).';

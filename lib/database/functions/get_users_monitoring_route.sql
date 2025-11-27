-- =====================================
-- GET USERS MONITORING ROUTE FUNCTION
-- =====================================
-- Returns user IDs who are monitoring routes that pass within a buffer distance
-- of a given location (where a report was submitted)
--
-- This function uses the Haversine formula to calculate distances between
-- the report location and route waypoints. When PostGIS is available, this
-- can be upgraded to use ST_DWithin for more efficient spatial queries.

CREATE OR REPLACE FUNCTION public.get_users_monitoring_route(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  buffer_km DOUBLE PRECISION DEFAULT 0.5
)
RETURNS TABLE (user_id UUID)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  buffer_meters DOUBLE PRECISION;
BEGIN
  -- Convert km to meters for distance calculation
  buffer_meters := buffer_km * 1000;
  
  RETURN QUERY
  SELECT DISTINCT sr.user_id
  FROM public.saved_routes sr
  WHERE 
    -- Route monitoring is enabled
    sr.is_monitoring = true
    -- Route is not deleted
    AND sr.is_deleted = false
    -- Route passes within buffer distance of the location
    -- Check if any waypoint is within buffer using Haversine formula
    AND EXISTS (
      SELECT 1
      FROM public.route_waypoints rw
      WHERE rw.route_id = sr.id
      -- Haversine formula for distance calculation
      -- Returns distance in meters
      AND (
        6371000 * acos(
          LEAST(1.0, GREATEST(-1.0,
            cos(radians(lat)) * cos(radians(rw.latitude)) * 
            cos(radians(rw.longitude) - radians(lng)) + 
            sin(radians(lat)) * sin(radians(rw.latitude))
          ))
        )
      ) <= buffer_meters
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_users_monitoring_route(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- Add function comment
COMMENT ON FUNCTION public.get_users_monitoring_route IS 'Returns user IDs who are monitoring routes that pass within the specified buffer distance of a location. Uses Haversine formula for distance calculation.';


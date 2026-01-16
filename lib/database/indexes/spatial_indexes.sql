-- =====================================
-- SPATIAL INDEXES
-- =====================================
-- Indexes to optimize spatial queries for route waypoints
-- and location-based notifications

-- ROUTE WAYPOINTS SPATIAL INDEX
-- Composite index on latitude and longitude for efficient spatial queries
-- This supports the Haversine distance calculations in get_users_monitoring_route
CREATE INDEX IF NOT EXISTS idx_route_waypoints_location 
ON public.route_waypoints(latitude, longitude);

-- Additional index on route_id for efficient JOIN operations
-- This is already covered by the foreign key, but explicit index improves performance
CREATE INDEX IF NOT EXISTS idx_route_waypoints_route_id 
ON public.route_waypoints(route_id);

-- Composite index for route_id and waypoint_order for ordered retrieval
CREATE INDEX IF NOT EXISTS idx_route_waypoints_route_order 
ON public.route_waypoints(route_id, waypoint_order);

-- Note: If PostGIS extension is enabled in the future, consider upgrading to:
-- CREATE INDEX idx_route_waypoints_location_gist 
-- ON public.route_waypoints USING GIST(ST_MakePoint(longitude, latitude));

-- PROFILES LOCATION SPATIAL INDEX
-- Composite index on latitude and longitude for efficient proximity queries
-- This supports location tracking and nearby user searches
-- Partial index only includes users with location tracking enabled
CREATE INDEX IF NOT EXISTS idx_profiles_location 
ON public.profiles (current_latitude, current_longitude)
WHERE current_latitude IS NOT NULL 
  AND current_longitude IS NOT NULL
  AND location_tracking_enabled = TRUE;

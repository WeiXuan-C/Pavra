-- =====================================
-- ROUTE WAYPOINTS TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.route_waypoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES public.saved_routes(id) ON DELETE CASCADE,
    waypoint_order INT NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(route_id, waypoint_order)
);

-- Enable RLS
ALTER TABLE public.route_waypoints ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_waypoints TO authenticated;

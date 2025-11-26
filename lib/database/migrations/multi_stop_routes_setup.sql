-- =====================================
-- MULTI-STOP ROUTES FEATURE SETUP
-- =====================================
-- This migration sets up the database schema for multi-stop route planning
-- including the route_waypoints table and travel_mode column

-- Step 1: Add travel_mode column to saved_routes table
ALTER TABLE public.saved_routes 
ADD COLUMN IF NOT EXISTS travel_mode VARCHAR(20) DEFAULT 'driving';

-- Update existing records to have default travel mode
UPDATE public.saved_routes 
SET travel_mode = 'driving' 
WHERE travel_mode IS NULL;

-- Step 2: Create route_waypoints table
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

-- Step 3: Enable RLS on route_waypoints
ALTER TABLE public.route_waypoints ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_waypoints TO authenticated;

-- Step 5: Create RLS policies for route_waypoints
-- Users can only access waypoints for routes they own

CREATE POLICY "route_waypoints_select_policy"
    ON public.route_waypoints
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.saved_routes
            WHERE saved_routes.id = route_waypoints.route_id
            AND saved_routes.user_id = (select auth.uid())
        )
    );

CREATE POLICY "route_waypoints_insert_policy"
    ON public.route_waypoints
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.saved_routes
            WHERE saved_routes.id = route_waypoints.route_id
            AND saved_routes.user_id = (select auth.uid())
        )
    );

CREATE POLICY "route_waypoints_update_policy"
    ON public.route_waypoints
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.saved_routes
            WHERE saved_routes.id = route_waypoints.route_id
            AND saved_routes.user_id = (select auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.saved_routes
            WHERE saved_routes.id = route_waypoints.route_id
            AND saved_routes.user_id = (select auth.uid())
        )
    );

CREATE POLICY "route_waypoints_delete_policy"
    ON public.route_waypoints
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.saved_routes
            WHERE saved_routes.id = route_waypoints.route_id
            AND saved_routes.user_id = (select auth.uid())
        )
    );

-- Step 6: Create index on route_id for better query performance
CREATE INDEX IF NOT EXISTS idx_route_waypoints_route_id 
ON public.route_waypoints(route_id);

-- Step 7: Create index on waypoint_order for better ordering performance
CREATE INDEX IF NOT EXISTS idx_route_waypoints_order 
ON public.route_waypoints(route_id, waypoint_order);

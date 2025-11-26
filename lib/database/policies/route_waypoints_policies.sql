-- =====================================
-- ROUTE WAYPOINTS RLS POLICIES
-- =====================================

-- RLS Policies for route_waypoints
-- Users can only access waypoints for routes they own
-- Using (select auth.uid()) instead of auth.uid() prevents re-evaluation for each row

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

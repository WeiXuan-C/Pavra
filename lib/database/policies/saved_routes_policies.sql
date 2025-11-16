-- =====================================
-- SAVED ROUTES RLS POLICIES
-- =====================================

-- RLS Policies for saved_routes (Optimized for performance)
-- Using (select auth.uid()) instead of auth.uid() prevents re-evaluation for each row
CREATE POLICY "saved_routes_select_policy"
    ON public.saved_routes
    FOR SELECT
    USING ((select auth.uid()) = user_id);

CREATE POLICY "saved_routes_insert_policy"
    ON public.saved_routes
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_routes_update_policy"
    ON public.saved_routes
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_routes_delete_policy"
    ON public.saved_routes
    FOR DELETE
    USING ((select auth.uid()) = user_id);

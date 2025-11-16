-- =====================================
-- SAVED LOCATIONS RLS POLICIES
-- =====================================

-- RLS Policies for saved_locations (Optimized for performance)
CREATE POLICY "saved_locations_select_policy"
    ON public.saved_locations
    FOR SELECT
    USING ((select auth.uid()) = user_id);

CREATE POLICY "saved_locations_insert_policy"
    ON public.saved_locations
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_locations_update_policy"
    ON public.saved_locations
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "saved_locations_delete_policy"
    ON public.saved_locations
    FOR DELETE
    USING ((select auth.uid()) = user_id);

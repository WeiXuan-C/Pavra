-- =====================================
-- SAVED ROUTES & LOCATIONS TRIGGERS
-- =====================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_saved_routes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp;

-- Trigger for saved_routes updated_at
CREATE TRIGGER trigger_update_saved_routes_updated_at
    BEFORE UPDATE ON public.saved_routes
    FOR EACH ROW
    EXECUTE FUNCTION update_saved_routes_updated_at();

-- Trigger for saved_locations updated_at
CREATE TRIGGER trigger_update_saved_locations_updated_at
    BEFORE UPDATE ON public.saved_locations
    FOR EACH ROW
    EXECUTE FUNCTION update_saved_routes_updated_at();

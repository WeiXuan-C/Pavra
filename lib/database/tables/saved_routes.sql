-- =====================================
-- SAVED ROUTES TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.saved_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    from_location_name VARCHAR(255) NOT NULL,
    from_latitude DOUBLE PRECISION NOT NULL,
    from_longitude DOUBLE PRECISION NOT NULL,
    from_address TEXT,
    to_location_name VARCHAR(255) NOT NULL,
    to_latitude DOUBLE PRECISION NOT NULL,
    to_longitude DOUBLE PRECISION NOT NULL,
    to_address TEXT,
    distance_km DOUBLE PRECISION,
    is_monitoring BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT false
);

-- Enable RLS
ALTER TABLE public.saved_routes ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_routes TO authenticated;

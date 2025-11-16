-- =====================================
-- SAVED LOCATIONS TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.saved_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    icon VARCHAR(50) DEFAULT 'place',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT false,
    UNIQUE(user_id, label)
);

-- Enable RLS
ALTER TABLE public.saved_locations ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_locations TO authenticated;

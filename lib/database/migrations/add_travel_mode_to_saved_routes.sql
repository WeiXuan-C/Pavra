-- =====================================
-- MIGRATION: Add travel_mode to saved_routes
-- =====================================

-- Add travel_mode column to saved_routes table
ALTER TABLE public.saved_routes 
ADD COLUMN IF NOT EXISTS travel_mode VARCHAR(20) DEFAULT 'driving';

-- Update existing records to have default travel mode
UPDATE public.saved_routes 
SET travel_mode = 'driving' 
WHERE travel_mode IS NULL;

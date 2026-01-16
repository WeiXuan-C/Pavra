# Location Tracking Migration

## Overview
This migration adds location tracking capabilities to the Pavra application, enabling real-time proximity-based notifications for road safety issues.

## Migration File
`20241203_location_tracking.sql`

## Changes Included

### 1. Database Schema Changes
Adds four new columns to the `profiles` table:
- `current_latitude` (DOUBLE PRECISION) - User's current latitude
- `current_longitude` (DOUBLE PRECISION) - User's current longitude  
- `location_updated_at` (TIMESTAMPTZ) - Timestamp of last location update
- `location_tracking_enabled` (BOOLEAN, default FALSE) - Whether user has enabled location tracking

### 2. Spatial Index
Creates a partial index `idx_profiles_location` on latitude/longitude columns for efficient proximity queries. The index only includes users with:
- Non-null coordinates
- Location tracking enabled

### 3. Updated get_nearby_users Function
The function now:
- Uses Haversine formula for accurate distance calculation
- Filters for users with `location_tracking_enabled = TRUE`
- Filters for users with non-null coordinates
- Filters for users with location data updated within last 30 minutes
- Returns results with calculated distance in kilometers
- Orders results by distance ascending

## How to Apply

### Option 1: Supabase CLI (Recommended)
```bash
supabase db push
```

### Option 2: Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy the contents of `20241203_location_tracking.sql`
4. Paste and execute

### Option 3: Direct SQL
Connect to your database and run:
```bash
psql -h <your-host> -U postgres -d postgres -f supabase/migrations/20241203_location_tracking.sql
```

## Verification

After applying the migration, verify the changes:

```sql
-- Check new columns exist
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('current_latitude', 'current_longitude', 'location_updated_at', 'location_tracking_enabled');

-- Check index exists
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'profiles' 
AND indexname = 'idx_profiles_location';

-- Test the function
SELECT * FROM get_nearby_users(37.7749, -122.4194, 5.0);
```

## Rollback

If you need to rollback this migration:

```sql
-- Drop the function
DROP FUNCTION IF EXISTS public.get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

-- Drop the index
DROP INDEX IF EXISTS public.idx_profiles_location;

-- Remove columns
ALTER TABLE public.profiles
DROP COLUMN IF EXISTS current_latitude,
DROP COLUMN IF EXISTS current_longitude,
DROP COLUMN IF EXISTS location_updated_at,
DROP COLUMN IF EXISTS location_tracking_enabled;
```

## Next Steps

After applying this migration:
1. Implement LocationTrackingService (Task 2)
2. Extend UserApi with location methods (Task 3)
3. Implement NearbyIssueMonitorService (Task 4)
4. Add UI controls for location tracking (Task 6)

## Requirements Validated

This migration satisfies the following requirements:
- Requirements 1.1-1.5: Database schema for location tracking
- Requirements 2.1-2.8: Nearby users database function with Haversine distance calculation

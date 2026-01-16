# Database Migration Guide - Location Tracking

This guide provides step-by-step instructions for applying and verifying the location tracking database migration.

## Prerequisites

Before applying the migration, ensure you have:

- [ ] Access to your Supabase project
- [ ] Supabase CLI installed (for Option 1) OR access to Supabase Dashboard (for Option 2)
- [ ] Database backup (recommended before any migration)
- [ ] Read access to the migration file: `20241203_location_tracking.sql`

## Migration Overview

**Migration File**: `20241203_location_tracking.sql`  
**Date**: December 3, 2024  
**Purpose**: Add location tracking capabilities for proximity-based notifications

### Changes Summary

1. **Schema Changes**: 4 new columns added to `profiles` table
2. **Index Creation**: Spatial index for efficient proximity queries
3. **Function Update**: Enhanced `get_nearby_users` function with Haversine distance calculation

---

## Step 1: Backup Your Database

**IMPORTANT**: Always backup your database before applying migrations.

### Using Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Database** → **Backups**
3. Click **Create Backup**
4. Wait for backup to complete
5. Note the backup timestamp

### Using Supabase CLI

```bash
# Export current schema
supabase db dump -f backup_before_location_tracking.sql

# Verify backup file was created
ls -lh backup_before_location_tracking.sql
```

---

## Step 2: Apply the Migration

Choose one of the following methods:

### Option 1: Supabase CLI (Recommended)

This is the recommended method as it tracks migration history.

```bash
# Navigate to your project root
cd /path/to/pavra

# Ensure you're logged in to Supabase
supabase login

# Link to your project (if not already linked)
supabase link --project-ref <your-project-ref>

# Apply all pending migrations
supabase db push

# Verify migration was applied
supabase db diff
```

**Expected Output**:
```
Applying migration 20241203_location_tracking.sql...
✓ Migration applied successfully
```

### Option 2: Supabase Dashboard (Manual)

Use this method if you don't have CLI access.

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Open the migration file: `supabase/migrations/20241203_location_tracking.sql`
5. Copy the entire contents
6. Paste into the SQL Editor
7. Click **Run** (or press Ctrl+Enter)
8. Wait for execution to complete

**Expected Output**:
```
Success. No rows returned
```

### Option 3: Direct Database Connection

Use this method if you have direct database access.

```bash
# Using psql
psql -h <your-supabase-host> \
     -U postgres \
     -d postgres \
     -f supabase/migrations/20241203_location_tracking.sql

# You'll be prompted for the database password
```

**Expected Output**:
```
ALTER TABLE
CREATE INDEX
COMMENT
CREATE FUNCTION
COMMENT
```

---

## Step 3: Verify the Migration

After applying the migration, verify that all changes were applied correctly.

### Verification Script

Run the following SQL queries to verify each component:

#### 3.1 Verify Schema Changes

```sql
-- Check that all 4 new columns exist with correct types
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
  AND table_name = 'profiles' 
  AND column_name IN (
    'current_latitude', 
    'current_longitude', 
    'location_updated_at', 
    'location_tracking_enabled'
  )
ORDER BY column_name;
```

**Expected Result** (4 rows):
```
column_name                | data_type         | column_default | is_nullable
---------------------------+-------------------+----------------+-------------
current_latitude           | double precision  | NULL           | YES
current_longitude          | double precision  | NULL           | YES
location_tracking_enabled  | boolean           | false          | YES
location_updated_at        | timestamp with... | NULL           | YES
```

#### 3.2 Verify Spatial Index

```sql
-- Check that the spatial index was created
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
  AND tablename = 'profiles' 
  AND indexname = 'idx_profiles_location';
```

**Expected Result** (1 row):
```
schemaname | tablename | indexname             | indexdef
-----------+-----------+-----------------------+------------------
public     | profiles  | idx_profiles_location | CREATE INDEX...
```

The `indexdef` should contain:
- `(current_latitude, current_longitude)`
- `WHERE current_latitude IS NOT NULL`
- `AND current_longitude IS NOT NULL`
- `AND location_tracking_enabled = true`

#### 3.3 Verify Function Update

```sql
-- Check that the function exists and has correct signature
SELECT 
  routine_name,
  routine_type,
  data_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'get_nearby_users';
```

**Expected Result** (1 row):
```
routine_name      | routine_type | data_type | routine_definition
------------------+--------------+-----------+--------------------
get_nearby_users  | FUNCTION     | USER-...  | BEGIN...
```

#### 3.4 Test Function Execution

```sql
-- Test the function with sample coordinates (San Francisco)
-- This should return 0 rows if no users have location tracking enabled yet
SELECT 
  id,
  distance_km
FROM get_nearby_users(37.7749, -122.4194, 5.0)
LIMIT 5;
```

**Expected Result**:
- If no users have location tracking enabled: `0 rows`
- If users exist with location tracking: List of user IDs with distances

#### 3.5 Verify Column Comments

```sql
-- Check that column comments were added
SELECT 
  column_name,
  col_description(
    (table_schema || '.' || table_name)::regclass::oid,
    ordinal_position
  ) as column_comment
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN (
    'current_latitude',
    'current_longitude',
    'location_updated_at',
    'location_tracking_enabled'
  )
ORDER BY column_name;
```

**Expected Result** (4 rows with comments):
```
column_name                | column_comment
---------------------------+------------------------------------------
current_latitude           | User's current latitude for proximity...
current_longitude          | User's current longitude for proximity...
location_tracking_enabled  | Whether user has enabled location tracking
location_updated_at        | Timestamp of last location update
```

---

## Step 4: Post-Migration Testing

After verification, perform these functional tests:

### Test 1: Insert Test Location Data

```sql
-- Get a test user ID (replace with actual user ID from your database)
SELECT id, username FROM profiles LIMIT 1;

-- Update test user with location data
UPDATE profiles
SET 
  current_latitude = 37.7749,
  current_longitude = -122.4194,
  location_updated_at = NOW(),
  location_tracking_enabled = TRUE
WHERE id = '<test-user-id>';

-- Verify update
SELECT 
  id,
  username,
  current_latitude,
  current_longitude,
  location_updated_at,
  location_tracking_enabled
FROM profiles
WHERE id = '<test-user-id>';
```

### Test 2: Test Nearby Users Query

```sql
-- Query for users near San Francisco (should include test user)
SELECT 
  p.id,
  p.username,
  nu.distance_km,
  p.current_latitude,
  p.current_longitude,
  p.location_updated_at
FROM get_nearby_users(37.7749, -122.4194, 5.0) nu
JOIN profiles p ON p.id = nu.id;
```

**Expected Result**: Should return the test user with distance ~0 km

### Test 3: Test Staleness Filter

```sql
-- Update test user with old location (31 minutes ago)
UPDATE profiles
SET location_updated_at = NOW() - INTERVAL '31 minutes'
WHERE id = '<test-user-id>';

-- Query should NOT return this user (location too old)
SELECT COUNT(*) as stale_user_count
FROM get_nearby_users(37.7749, -122.4194, 5.0) nu
WHERE nu.id = '<test-user-id>';
```

**Expected Result**: `stale_user_count = 0`

### Test 4: Test Distance Calculation

```sql
-- Update test user to a location ~3km away
UPDATE profiles
SET 
  current_latitude = 37.8049,  -- ~3.3 km north
  current_longitude = -122.4194,
  location_updated_at = NOW()
WHERE id = '<test-user-id>';

-- Query with 5km radius (should include user)
SELECT distance_km
FROM get_nearby_users(37.7749, -122.4194, 5.0)
WHERE id = '<test-user-id>';
```

**Expected Result**: `distance_km` should be approximately 3.3

### Test 5: Clean Up Test Data

```sql
-- Reset test user location data
UPDATE profiles
SET 
  current_latitude = NULL,
  current_longitude = NULL,
  location_updated_at = NULL,
  location_tracking_enabled = FALSE
WHERE id = '<test-user-id>';
```

---

## Step 5: Monitor Performance

After migration, monitor query performance:

### Check Index Usage

```sql
-- Check if the spatial index is being used
EXPLAIN ANALYZE
SELECT * FROM get_nearby_users(37.7749, -122.4194, 5.0);
```

Look for `Index Scan using idx_profiles_location` in the query plan.

### Monitor Query Performance

```sql
-- Check average execution time
SELECT 
  query,
  calls,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
WHERE query LIKE '%get_nearby_users%'
ORDER BY mean_exec_time DESC;
```

**Expected Performance**:
- Mean execution time: < 50ms for databases with < 10,000 users
- Mean execution time: < 200ms for databases with < 100,000 users

---

## Troubleshooting

### Issue: Migration Fails with "column already exists"

**Cause**: Migration was partially applied or run multiple times

**Solution**: The migration uses `IF NOT EXISTS` clauses, so it should be safe to re-run. If issues persist:

```sql
-- Check which columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name LIKE '%location%';

-- Manually add missing columns if needed
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS current_latitude DOUBLE PRECISION;
-- ... repeat for other columns
```

### Issue: Function creation fails

**Cause**: Function already exists with different signature

**Solution**: Drop and recreate the function

```sql
-- Drop existing function
DROP FUNCTION IF EXISTS public.get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

-- Re-run the CREATE FUNCTION statement from the migration file
```

### Issue: Index creation fails

**Cause**: Index already exists or conflicting index

**Solution**: Drop and recreate the index

```sql
-- Drop existing index
DROP INDEX IF EXISTS public.idx_profiles_location;

-- Re-run the CREATE INDEX statement from the migration file
```

### Issue: Permission denied errors

**Cause**: Insufficient database permissions

**Solution**: Ensure you're connected as a user with sufficient privileges (e.g., `postgres` user)

```sql
-- Grant necessary permissions
GRANT ALL ON TABLE profiles TO postgres;
GRANT EXECUTE ON FUNCTION get_nearby_users TO postgres;
```

### Issue: Query returns no results

**Cause**: No users have location tracking enabled yet

**Solution**: This is expected behavior. Users must enable location tracking in the app before they appear in nearby user queries.

---

## Rollback Procedure

If you need to rollback this migration:

### Step 1: Create Rollback Script

```sql
-- Save this as rollback_location_tracking.sql

-- Drop the function
DROP FUNCTION IF EXISTS public.get_nearby_users(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

-- Drop the index
DROP INDEX IF EXISTS public.idx_profiles_location;

-- Remove columns (WARNING: This will delete all location data)
ALTER TABLE public.profiles
DROP COLUMN IF EXISTS current_latitude,
DROP COLUMN IF EXISTS current_longitude,
DROP COLUMN IF EXISTS location_updated_at,
DROP COLUMN IF EXISTS location_tracking_enabled;
```

### Step 2: Apply Rollback

```bash
# Using Supabase CLI
supabase db execute -f rollback_location_tracking.sql

# OR using psql
psql -h <host> -U postgres -d postgres -f rollback_location_tracking.sql
```

### Step 3: Verify Rollback

```sql
-- Verify columns are removed
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('current_latitude', 'current_longitude', 'location_updated_at', 'location_tracking_enabled');
```

**Expected Result**: 0 rows

---

## Checklist

Use this checklist to track your migration progress:

- [ ] Database backup created
- [ ] Migration file reviewed
- [ ] Migration applied successfully
- [ ] Schema changes verified (4 columns)
- [ ] Spatial index verified
- [ ] Function update verified
- [ ] Column comments verified
- [ ] Test data inserted
- [ ] Nearby users query tested
- [ ] Staleness filter tested
- [ ] Distance calculation tested
- [ ] Test data cleaned up
- [ ] Performance monitoring enabled
- [ ] Team notified of migration completion

---

## Next Steps

After successfully applying and verifying the migration:

1. ✅ **Deploy Application Code**: Deploy the updated application code that uses the new location tracking features
2. ✅ **Monitor Logs**: Watch application logs for any location tracking errors
3. ✅ **User Communication**: Inform users about the new location tracking feature
4. ✅ **Performance Monitoring**: Monitor database performance and query execution times
5. ✅ **User Adoption**: Track how many users enable location tracking

---

## Support

If you encounter issues during migration:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review Supabase logs in the dashboard
3. Contact the development team
4. Refer to the [Location Tracking API Documentation](../../lib/docs/LOCATION_TRACKING_API.md)

---

**Migration Version**: 1.0  
**Last Updated**: December 2024  
**Maintained By**: Pavra Development Team

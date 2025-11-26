# Database Migrations

This directory contains SQL migration scripts for the Pavra database.

## Available Migrations

### Multi-Stop Routes Setup (`multi_stop_routes_setup.sql`)

This migration sets up the database schema for the multi-stop route planning feature.

**What it does:**
1. Adds `travel_mode` column to `saved_routes` table
2. Creates `route_waypoints` table with foreign key to `saved_routes`
3. Enables Row Level Security (RLS) on `route_waypoints`
4. Creates RLS policies to ensure users can only access their own route waypoints
5. Creates indexes for better query performance

**How to apply:**

#### Using Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy the contents of `multi_stop_routes_setup.sql`
4. Paste and execute the SQL

#### Using Supabase CLI
```bash
supabase db push
```

#### Using psql
```bash
psql -h <your-host> -U <your-user> -d <your-database> -f lib/database/migrations/multi_stop_routes_setup.sql
```

## Migration Order

Migrations should be applied in the following order:
1. `multi_stop_routes_setup.sql` - Multi-stop routes feature

## Rollback

To rollback the multi-stop routes migration:

```sql
-- Drop policies
DROP POLICY IF EXISTS "route_waypoints_select_policy" ON public.route_waypoints;
DROP POLICY IF EXISTS "route_waypoints_insert_policy" ON public.route_waypoints;
DROP POLICY IF EXISTS "route_waypoints_update_policy" ON public.route_waypoints;
DROP POLICY IF EXISTS "route_waypoints_delete_policy" ON public.route_waypoints;

-- Drop indexes
DROP INDEX IF EXISTS idx_route_waypoints_route_id;
DROP INDEX IF EXISTS idx_route_waypoints_order;

-- Drop table
DROP TABLE IF EXISTS public.route_waypoints;

-- Remove travel_mode column
ALTER TABLE public.saved_routes DROP COLUMN IF EXISTS travel_mode;
```

## Notes

- Always backup your database before applying migrations
- Test migrations in a development environment first
- RLS policies ensure data security by restricting access to user's own data
- Indexes improve query performance for route waypoint lookups

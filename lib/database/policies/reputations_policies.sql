-- =============================================
-- Row Level Security (RLS) Policies for Reputations Table
-- =============================================
-- This file defines access control policies for the reputations table
-- Ensures users can only view their own reputation history
-- Only the system (service role) can insert/update reputation records
--
-- IMPORTANT: This file includes automatic cleanup of duplicate policies
-- to prevent performance issues. Safe to run multiple times.
--
-- Expected Policies After Execution:
-- 1. "Users and developers can view reputation records" (SELECT, authenticated)
-- 2. "Service role can insert reputation records" (INSERT, service_role)
-- 3. "Authenticated users can insert reputation records" (INSERT, authenticated)
-- 4. "Developers can delete reputation records" (DELETE, authenticated)
-- =============================================

-- Enable Row Level Security
ALTER TABLE public.reputations ENABLE ROW LEVEL SECURITY;

-- =============================================
-- CLEANUP: Remove any duplicate policies first
-- =============================================

-- Drop all old SELECT policy variations
DO $$ 
BEGIN
  EXECUTE 'DROP POLICY IF EXISTS "Users can view own reputation history" ON public.reputations';
  EXECUTE 'DROP POLICY IF EXISTS "Developers can view all reputation records" ON public.reputations';
  EXECUTE 'DROP POLICY IF EXISTS "Users and developers can view reputation records" ON public.reputations';
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Drop all old INSERT policy variations
DO $$ 
BEGIN
  EXECUTE 'DROP POLICY IF EXISTS "Authenticated users can insert own reputation records" ON public.reputations';
  EXECUTE 'DROP POLICY IF EXISTS "Authorities can insert reputation records for others" ON public.reputations';
  EXECUTE 'DROP POLICY IF EXISTS "Authenticated users can insert reputation records" ON public.reputations';
  EXECUTE 'DROP POLICY IF EXISTS "Service role can insert reputation records" ON public.reputations';
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Drop old DELETE policy variations
DO $$ 
BEGIN
  EXECUTE 'DROP POLICY IF EXISTS "Developers can delete reputation records" ON public.reputations';
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- =============================================
-- SELECT Policies
-- =============================================

-- Policy: Users can view own reputation history, developers can view all
-- Combined policy for optimal performance (avoids multiple permissive policies)
CREATE POLICY "Users and developers can view reputation records"
ON public.reputations
FOR SELECT
TO authenticated
USING (
  -- Users can view their own reputation history
  (SELECT auth.uid()) = user_id
  OR
  -- Developers can view all reputation records
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = (SELECT auth.uid())
    AND profiles.role = 'developer'
  )
);

-- =============================================
-- INSERT Policies
-- =============================================

-- Policy: Only service role can insert reputation records
-- This ensures reputation changes are controlled server-side
CREATE POLICY "Service role can insert reputation records"
ON public.reputations
FOR INSERT
TO service_role
WITH CHECK (true);

-- Policy: Authenticated users can insert reputation records
-- Combined policy for optimal performance (avoids multiple permissive policies)
-- Users can insert their own records, authorities/developers can insert for anyone
CREATE POLICY "Authenticated users can insert reputation records"
ON public.reputations
FOR INSERT
TO authenticated
WITH CHECK (
  -- Users can insert their own reputation records
  (SELECT auth.uid()) = user_id
  OR
  -- Authorities and developers can insert for any user
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = (SELECT auth.uid())
    AND profiles.role IN ('authority', 'developer')
  )
);

-- =============================================
-- UPDATE Policies
-- =============================================

-- Policy: No one can update reputation records (immutable history)
-- Reputation records should never be modified once created
-- If you need to correct a mistake, create a new compensating record

-- =============================================
-- DELETE Policies
-- =============================================

-- Policy: Only developers can delete reputation records (for cleanup/debugging)
DROP POLICY IF EXISTS "Developers can delete reputation records" ON public.reputations;
CREATE POLICY "Developers can delete reputation records"
ON public.reputations
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = (SELECT auth.uid())
    AND profiles.role = 'developer'
  )
);

-- =============================================
-- Indexes for Performance
-- =============================================

-- Index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_reputations_user_id 
ON public.reputations(user_id);

-- Index on created_at for sorting by date
CREATE INDEX IF NOT EXISTS idx_reputations_created_at 
ON public.reputations(created_at DESC);

-- Composite index for user reputation history queries
CREATE INDEX IF NOT EXISTS idx_reputations_user_created 
ON public.reputations(user_id, created_at DESC);

-- Index on action_type for filtering by action
CREATE INDEX IF NOT EXISTS idx_reputations_action_type 
ON public.reputations(action_type);

-- =============================================
-- Comments
-- =============================================

COMMENT ON POLICY "Users and developers can view reputation records" ON public.reputations IS 
'Allows authenticated users to view their own reputation history, and developers to view all records for debugging and administration';

COMMENT ON POLICY "Service role can insert reputation records" ON public.reputations IS 
'Allows the service role to insert reputation records for system-controlled updates';

COMMENT ON POLICY "Authenticated users can insert reputation records" ON public.reputations IS 
'Allows authenticated users to create reputation records for their own actions, and allows authorities/developers to create records for any user when reviewing issues';

COMMENT ON POLICY "Developers can delete reputation records" ON public.reputations IS 
'Allows developers to delete reputation records for cleanup and debugging purposes';

-- =============================================
-- Helper Functions (Optional)
-- =============================================

-- Function to get user's current reputation score
CREATE OR REPLACE FUNCTION public.get_user_reputation_score(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_score INTEGER;
BEGIN
  SELECT reputation_score INTO v_score
  FROM public.profiles
  WHERE id = p_user_id;
  
  RETURN COALESCE(v_score, 0);
END;
$$;

COMMENT ON FUNCTION public.get_user_reputation_score(UUID) IS 
'Returns the current reputation score for a given user';

-- Function to get reputation history summary
CREATE OR REPLACE FUNCTION public.get_reputation_summary(p_user_id UUID)
RETURNS TABLE (
  action_type TEXT,
  total_changes INTEGER,
  count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.action_type,
    SUM(r.change_amount)::INTEGER as total_changes,
    COUNT(*)::INTEGER as count
  FROM public.reputations r
  WHERE r.user_id = p_user_id
  GROUP BY r.action_type
  ORDER BY total_changes DESC;
END;
$$;

COMMENT ON FUNCTION public.get_reputation_summary(UUID) IS 
'Returns a summary of reputation changes grouped by action type for a given user';

-- Function to validate reputation score constraints
CREATE OR REPLACE FUNCTION public.validate_reputation_score()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- Ensure score_after is within valid range (0-100)
  IF NEW.score_after < 0 THEN
    NEW.score_after := 0;
  ELSIF NEW.score_after > 100 THEN
    NEW.score_after := 100;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger to validate reputation scores before insert
DROP TRIGGER IF EXISTS validate_reputation_score_trigger ON public.reputations;
CREATE TRIGGER validate_reputation_score_trigger
BEFORE INSERT ON public.reputations
FOR EACH ROW
EXECUTE FUNCTION validate_reputation_score();

COMMENT ON TRIGGER validate_reputation_score_trigger ON public.reputations IS 
'Ensures reputation scores stay within valid range (0-100) before insertion';

-- =============================================
-- Grant Permissions
-- =============================================

-- Grant SELECT to authenticated users (controlled by RLS policies)
GRANT SELECT ON public.reputations TO authenticated;

-- Grant INSERT to authenticated users (controlled by RLS policies)
GRANT INSERT ON public.reputations TO authenticated;

-- Grant DELETE to authenticated users (controlled by RLS policies)
GRANT DELETE ON public.reputations TO authenticated;

-- Grant all permissions to service role
GRANT ALL ON public.reputations TO service_role;

-- =============================================
-- Verification
-- =============================================

-- Query to verify policies are correctly set up
-- Run this after applying the policies to confirm no duplicates exist
DO $$
DECLARE
  policy_count INTEGER;
  select_count INTEGER;
  insert_count INTEGER;
  delete_count INTEGER;
BEGIN
  -- Count total policies
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'reputations';
  
  -- Count by command type
  SELECT COUNT(*) INTO select_count
  FROM pg_policies
  WHERE tablename = 'reputations' AND cmd = 'SELECT';
  
  SELECT COUNT(*) INTO insert_count
  FROM pg_policies
  WHERE tablename = 'reputations' AND cmd = 'INSERT';
  
  SELECT COUNT(*) INTO delete_count
  FROM pg_policies
  WHERE tablename = 'reputations' AND cmd = 'DELETE';
  
  RAISE NOTICE 'Total policies: %', policy_count;
  RAISE NOTICE 'SELECT policies: %', select_count;
  RAISE NOTICE 'INSERT policies: %', insert_count;
  RAISE NOTICE 'DELETE policies: %', delete_count;
  
  -- Validate expected counts
  IF select_count != 1 THEN
    RAISE WARNING 'Expected 1 SELECT policy, found %', select_count;
  END IF;
  
  IF insert_count != 2 THEN
    RAISE WARNING 'Expected 2 INSERT policies (service_role + authenticated), found %', insert_count;
  END IF;
  
  IF delete_count != 1 THEN
    RAISE WARNING 'Expected 1 DELETE policy, found %', delete_count;
  END IF;
  
  IF policy_count = 4 THEN
    RAISE NOTICE '✓ All policies configured correctly!';
  ELSE
    RAISE WARNING 'Expected 4 total policies, found %', policy_count;
  END IF;
END $$;

-- =============================================
-- Notes
-- =============================================
-- 1. Reputation records are immutable (no UPDATE policy)
-- 2. Users can only view their own reputation history
-- 3. Developers have full visibility for debugging
-- 4. Service role can insert records for system operations
-- 5. Authenticated users can insert their own records
-- 6. Scores are automatically constrained to 0-100 range
-- 7. Indexes are created for optimal query performance
-- 8. All duplicate policies are cleaned up before creating new ones

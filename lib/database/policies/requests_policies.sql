-- =====================================================
-- Requests Table RLS Policies
-- =====================================================
-- This file defines Row Level Security policies for the requests table
-- 
-- Roles:
-- - user: Can create requests and view their own requests
-- - authority: Can view their own requests
-- - developer: Can view all requests and update request status
-- =====================================================

-- Enable RLS
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for all users" ON public.requests;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.requests;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.requests;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.requests;
DROP POLICY IF EXISTS "Users can view their own requests" ON public.requests;
DROP POLICY IF EXISTS "Developers can view all requests" ON public.requests;
DROP POLICY IF EXISTS "Users can create requests" ON public.requests;
DROP POLICY IF EXISTS "Developers can update requests" ON public.requests;
DROP POLICY IF EXISTS "Developers can soft delete requests" ON public.requests;

-- =====================================================
-- SELECT Policies
-- =====================================================

-- Policy 1: Users can view their own requests
CREATE POLICY "Users can view their own requests"
ON public.requests
FOR SELECT
TO authenticated
USING (
  (select auth.uid()) = user_id
  AND is_deleted = false
);

-- Policy 2: Developers can view all requests
CREATE POLICY "Developers can view all requests"
ON public.requests
FOR SELECT
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = (select auth.uid())) = 'developer'
  AND is_deleted = false
);

-- =====================================================
-- INSERT Policies
-- =====================================================

-- Policy 3: Only users (not authority or developer) can create requests
CREATE POLICY "Users can create requests"
ON public.requests
FOR INSERT
TO authenticated
WITH CHECK (
  -- Must be authenticated
  (select auth.uid()) = user_id
  AND
  -- Must have 'user' role
  (SELECT role FROM public.profiles WHERE id = (select auth.uid())) = 'user'
  AND
  -- Cannot have an existing pending request
  NOT EXISTS (
    SELECT 1 FROM public.requests
    WHERE user_id = (select auth.uid())
    AND status = 'pending'
    AND is_deleted = false
  )
);

-- =====================================================
-- UPDATE Policies
-- =====================================================

-- Policy 4: Developers can update request status (approve/reject)
CREATE POLICY "Developers can update requests"
ON public.requests
FOR UPDATE
TO authenticated
USING (
  -- Must be a developer
  (SELECT role FROM public.profiles WHERE id = (select auth.uid())) = 'developer'
  AND is_deleted = false
)
WITH CHECK (
  -- Must be a developer
  (SELECT role FROM public.profiles WHERE id = (select auth.uid())) = 'developer'
  AND is_deleted = false
);

-- =====================================================
-- DELETE Policies
-- =====================================================

-- Policy 5: Developers can soft delete requests
CREATE POLICY "Developers can soft delete requests"
ON public.requests
FOR UPDATE
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = (select auth.uid())) = 'developer'
)
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = (select auth.uid())) = 'developer'
  AND is_deleted = true
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_requests_user_id ON public.requests(user_id);

-- Index on status for filtering
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.requests(status);

-- Index on is_deleted for filtering
CREATE INDEX IF NOT EXISTS idx_requests_is_deleted ON public.requests(is_deleted);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_requests_user_status ON public.requests(user_id, status, is_deleted);

-- Index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON public.requests(created_at DESC);

-- =====================================================
-- Comments
-- =====================================================

COMMENT ON POLICY "Users can view their own requests" ON public.requests IS 
'Allows users to view only their own requests that are not deleted';

COMMENT ON POLICY "Developers can view all requests" ON public.requests IS 
'Allows developers to view all requests for management purposes';

COMMENT ON POLICY "Users can create requests" ON public.requests IS 
'Allows users with role=user to create authority requests. Prevents duplicate pending requests.';

COMMENT ON POLICY "Developers can update requests" ON public.requests IS 
'Allows developers to update request status (approve/reject) and add review comments';

COMMENT ON POLICY "Developers can soft delete requests" ON public.requests IS 
'Allows developers to soft delete requests by setting is_deleted=true';

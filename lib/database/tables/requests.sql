-- =====================================
-- AUTHORITY REQUESTS TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  id_number TEXT NOT NULL,
  organization TEXT NOT NULL,
  location TEXT NOT NULL,
  referrer_code TEXT,
  remarks TEXT,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'approved', 'rejected')
  ),
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_comment TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT FALSE
);

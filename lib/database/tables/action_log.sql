-- =====================================
-- ACTION LOG TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.action_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  target_id UUID,
  target_table TEXT,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  is_synced BOOLEAN DEFAULT FALSE
);

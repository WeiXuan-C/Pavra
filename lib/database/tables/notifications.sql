-- =====================================
-- NOTIFICATIONS TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (
    type IN (
      'success', 'warning', 'alert', 'info',
      'system', 'user', 'report', 'location_alert',
      'submission_status', 'promotion', 'reminder'
    )
  ),
  related_action UUID REFERENCES action_log(id) ON DELETE SET NULL,
  data JSONB DEFAULT '{}',
  status TEXT DEFAULT 'sent' CHECK (
    status IN ('draft', 'scheduled', 'sent', 'failed')
  ),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  target_type TEXT DEFAULT 'single' CHECK (
    target_type IN ('single', 'all', 'role', 'custom')
  ),
  target_roles TEXT[],
  target_user_ids UUID[],
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

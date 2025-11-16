-- =====================================
-- USER REPUTATION SCORE TABLE
-- =====================================

CREATE TABLE IF NOT EXISTS public.reputations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (
    action_type IN (
      'UPLOAD_ISSUE',           -- +1: User submits a report
      'FIRST_REPORTER',         -- +5: First to report in location      
      'DUPLICATE_REPORT',       -- -5: Duplicate of existing report
      'ABUSE_REPORT',           -- -25: System abuse
      'MANUAL_ADJUSTMENT',      -- ±any: Admin manual correction
      'OTHERS'                  -- For future extensions
    )
  ),
  change_amount INT NOT NULL,
  score_before INT NOT NULL CHECK (score_before >= 0 AND score_before <= 100),
  score_after INT NOT NULL CHECK (score_after >= 0 AND score_after <= 100),
  related_issue_id UUID REFERENCES report_issues(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

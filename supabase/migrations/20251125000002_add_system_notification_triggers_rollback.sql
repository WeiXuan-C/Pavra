-- =====================================
-- ROLLBACK: Remove System Notification Triggers
-- =====================================
-- This migration removes the automatic notification triggers
-- Created: 2024-11-25

-- Drop triggers
DROP TRIGGER IF EXISTS trg_notify_nearby_users_on_report ON public.report_issues;
DROP TRIGGER IF EXISTS trg_notify_reporter_on_verification ON public.issue_votes;
DROP TRIGGER IF EXISTS trg_notify_user_on_reputation_change ON public.reputations;
DROP TRIGGER IF EXISTS trg_notify_requester_on_authority_decision ON public.requests;

-- Drop functions
DROP FUNCTION IF EXISTS public.notify_nearby_users_on_report_creation();
DROP FUNCTION IF EXISTS public.notify_reporter_on_verification();
DROP FUNCTION IF EXISTS public.notify_user_on_reputation_change();
DROP FUNCTION IF EXISTS public.notify_requester_on_authority_decision();

-- Verify cleanup
DO $$
BEGIN
  RAISE NOTICE 'System notification triggers and functions removed successfully';
END $$;

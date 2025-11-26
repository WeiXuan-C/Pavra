-- =====================================
-- MIGRATION: Add System Notification Triggers
-- =====================================
-- This migration adds automatic notification triggers for system events
-- Created: 2024-11-25
-- Description: Implements automatic notifications for:
--   - Report creation (nearby users)
--   - Report verification
--   - Reputation changes
--   - Authority request decisions

-- Load the system notification triggers
\i lib/database/functions/system_notification_triggers.sql

-- Verify triggers are created
DO $$
BEGIN
  -- Check if triggers exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_notify_nearby_users_on_report'
  ) THEN
    RAISE EXCEPTION 'Trigger trg_notify_nearby_users_on_report was not created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_notify_reporter_on_verification'
  ) THEN
    RAISE EXCEPTION 'Trigger trg_notify_reporter_on_verification was not created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_notify_user_on_reputation_change'
  ) THEN
    RAISE EXCEPTION 'Trigger trg_notify_user_on_reputation_change was not created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_notify_requester_on_authority_decision'
  ) THEN
    RAISE EXCEPTION 'Trigger trg_notify_requester_on_authority_decision was not created';
  END IF;

  RAISE NOTICE 'All system notification triggers created successfully';
END $$;

-- =====================================
-- ROLLBACK MIGRATION: Remove OneSignal Integration Columns
-- =====================================
-- Description: Rollback script to remove OneSignal columns from notifications table
-- Date: 2025-11-25

-- Drop indexes first
DROP INDEX IF EXISTS public.idx_notifications_onesignal_id;
DROP INDEX IF EXISTS public.idx_notifications_status_created;

-- Remove OneSignal integration columns from notifications table
ALTER TABLE public.notifications
DROP COLUMN IF EXISTS onesignal_notification_id,
DROP COLUMN IF EXISTS sound,
DROP COLUMN IF EXISTS category,
DROP COLUMN IF EXISTS priority,
DROP COLUMN IF EXISTS error_message,
DROP COLUMN IF EXISTS recipients_count,
DROP COLUMN IF EXISTS successful_deliveries,
DROP COLUMN IF EXISTS failed_deliveries;

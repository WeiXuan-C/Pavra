-- =====================================
-- MIGRATION: Add OneSignal Integration Columns
-- =====================================
-- Description: Adds columns to notifications table for OneSignal push notification integration
-- Requirements: 2.1, 10.1, 10.5
-- Date: 2025-11-25

-- Add OneSignal integration columns to notifications table
ALTER TABLE public.notifications
ADD COLUMN IF NOT EXISTS onesignal_notification_id TEXT,
ADD COLUMN IF NOT EXISTS sound TEXT,
ADD COLUMN IF NOT EXISTS category TEXT,
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
ADD COLUMN IF NOT EXISTS error_message TEXT,
ADD COLUMN IF NOT EXISTS recipients_count INTEGER,
ADD COLUMN IF NOT EXISTS successful_deliveries INTEGER,
ADD COLUMN IF NOT EXISTS failed_deliveries INTEGER;

-- Add comments for documentation
COMMENT ON COLUMN public.notifications.onesignal_notification_id IS 'OneSignal notification ID returned after successful send';
COMMENT ON COLUMN public.notifications.sound IS 'Custom sound file name for the notification (e.g., alert.wav, warning.wav)';
COMMENT ON COLUMN public.notifications.category IS 'Android notification channel/category for grouping and priority';
COMMENT ON COLUMN public.notifications.priority IS 'Notification priority level (1-10, default 5)';
COMMENT ON COLUMN public.notifications.error_message IS 'Error message if notification send failed';
COMMENT ON COLUMN public.notifications.recipients_count IS 'Total number of intended recipients';
COMMENT ON COLUMN public.notifications.successful_deliveries IS 'Number of successful deliveries reported by OneSignal';
COMMENT ON COLUMN public.notifications.failed_deliveries IS 'Number of failed deliveries reported by OneSignal';

-- Create index on onesignal_notification_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_notifications_onesignal_id 
ON public.notifications(onesignal_notification_id) 
WHERE onesignal_notification_id IS NOT NULL;

-- Create index on status and created_at for filtering scheduled/sent notifications
CREATE INDEX IF NOT EXISTS idx_notifications_status_created 
ON public.notifications(status, created_at);

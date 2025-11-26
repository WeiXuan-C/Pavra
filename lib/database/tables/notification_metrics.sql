-- =====================================
-- NOTIFICATION METRICS TABLE
-- =====================================
-- Tracks delivery metrics and analytics for notifications
-- Used for monitoring notification performance and user engagement

CREATE TABLE IF NOT EXISTS public.notification_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID REFERENCES notifications(id) ON DELETE CASCADE,
  
  -- Delivery metrics
  send_success_rate DECIMAL(5,2), -- Percentage (0-100)
  average_delivery_time_ms INTEGER, -- Average time from send to delivery in milliseconds
  
  -- User engagement metrics
  open_rate DECIMAL(5,2), -- Percentage of users who opened the notification
  click_rate DECIMAL(5,2), -- Percentage of users who clicked the notification
  dismiss_rate DECIMAL(5,2), -- Percentage of users who dismissed without action
  
  -- Timing metrics
  first_delivery_at TIMESTAMPTZ, -- When first user received the notification
  last_delivery_at TIMESTAMPTZ, -- When last user received the notification
  
  -- Aggregate counts
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_failed INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  total_dismissed INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT valid_rates CHECK (
    send_success_rate >= 0 AND send_success_rate <= 100 AND
    open_rate >= 0 AND open_rate <= 100 AND
    click_rate >= 0 AND click_rate <= 100 AND
    dismiss_rate >= 0 AND dismiss_rate <= 100
  )
);

-- Index for fast lookups by notification_id
CREATE INDEX IF NOT EXISTS idx_notification_metrics_notification_id 
  ON public.notification_metrics(notification_id);

-- Index for time-based queries
CREATE INDEX IF NOT EXISTS idx_notification_metrics_created_at 
  ON public.notification_metrics(created_at DESC);

-- Enable RLS
ALTER TABLE public.notification_metrics ENABLE ROW LEVEL SECURITY;

-- Policy: Developers and admins can view all metrics
CREATE POLICY "Developers and admins can view metrics"
  ON public.notification_metrics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('developer', 'admin')
    )
  );

-- Policy: Only system can insert/update metrics
CREATE POLICY "System can manage metrics"
  ON public.notification_metrics
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notification_metrics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
DROP TRIGGER IF EXISTS trigger_update_notification_metrics_updated_at ON public.notification_metrics;
CREATE TRIGGER trigger_update_notification_metrics_updated_at
  BEFORE UPDATE ON public.notification_metrics
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_metrics_updated_at();

-- Function to calculate and update metrics for a notification
CREATE OR REPLACE FUNCTION calculate_notification_metrics(p_notification_id UUID)
RETURNS void AS $$
DECLARE
  v_total_sent INTEGER;
  v_total_delivered INTEGER;
  v_total_failed INTEGER;
  v_send_success_rate DECIMAL(5,2);
  v_first_delivery TIMESTAMPTZ;
  v_last_delivery TIMESTAMPTZ;
  v_avg_delivery_time INTEGER;
BEGIN
  -- Get notification data
  SELECT 
    COALESCE(recipients_count, 0),
    COALESCE(successful_deliveries, 0),
    COALESCE(failed_deliveries, 0)
  INTO 
    v_total_sent,
    v_total_delivered,
    v_total_failed
  FROM notifications
  WHERE id = p_notification_id;
  
  -- Calculate success rate
  IF v_total_sent > 0 THEN
    v_send_success_rate := (v_total_delivered::DECIMAL / v_total_sent::DECIMAL * 100);
  ELSE
    v_send_success_rate := 0;
  END IF;
  
  -- Get delivery timing from user_notifications
  SELECT 
    MIN(created_at),
    MAX(created_at)
  INTO
    v_first_delivery,
    v_last_delivery
  FROM user_notifications
  WHERE notification_id = p_notification_id;
  
  -- Calculate average delivery time (if we have sent_at timestamp)
  SELECT 
    EXTRACT(EPOCH FROM (AVG(un.created_at - n.sent_at) * 1000))::INTEGER
  INTO
    v_avg_delivery_time
  FROM user_notifications un
  JOIN notifications n ON n.id = un.notification_id
  WHERE un.notification_id = p_notification_id
    AND n.sent_at IS NOT NULL;
  
  -- Insert or update metrics
  INSERT INTO notification_metrics (
    notification_id,
    send_success_rate,
    average_delivery_time_ms,
    first_delivery_at,
    last_delivery_at,
    total_sent,
    total_delivered,
    total_failed
  ) VALUES (
    p_notification_id,
    v_send_success_rate,
    v_avg_delivery_time,
    v_first_delivery,
    v_last_delivery,
    v_total_sent,
    v_total_delivered,
    v_total_failed
  )
  ON CONFLICT (notification_id) 
  DO UPDATE SET
    send_success_rate = EXCLUDED.send_success_rate,
    average_delivery_time_ms = EXCLUDED.average_delivery_time_ms,
    first_delivery_at = EXCLUDED.first_delivery_at,
    last_delivery_at = EXCLUDED.last_delivery_at,
    total_sent = EXCLUDED.total_sent,
    total_delivered = EXCLUDED.total_delivered,
    total_failed = EXCLUDED.total_failed,
    updated_at = now();
END;
$$ LANGUAGE plpgsql;

-- Add unique constraint on notification_id to prevent duplicates
ALTER TABLE public.notification_metrics 
  ADD CONSTRAINT notification_metrics_notification_id_key 
  UNIQUE (notification_id);

-- =====================================
-- AUTOMATIC SYSTEM NOTIFICATION TRIGGERS
-- =====================================
-- This file contains database triggers that automatically create
-- notifications for system events such as report creation,
-- verification, reputation changes, and authority requests.

-- =====================================
-- FUNCTION: notify_nearby_users_on_report_creation
-- =====================================
-- Creates notifications for users within alert radius when a new report is submitted
-- Respects user alert preferences and enabled alert types

CREATE OR REPLACE FUNCTION public.notify_nearby_users_on_report_creation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  nearby_user_ids UUID[];
  notification_id UUID;
  severity_type TEXT;
  notification_title TEXT;
  notification_message TEXT;
BEGIN
  -- Only trigger for submitted reports (not drafts)
  IF NEW.status != 'submitted' OR NEW.latitude IS NULL OR NEW.longitude IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Determine notification type based on severity
  CASE NEW.severity
    WHEN 'critical', 'high' THEN
      severity_type := 'alert';
    WHEN 'moderate' THEN
      severity_type := 'warning';
    ELSE
      severity_type := 'info';
  END CASE;
  
  -- Build notification title and message
  notification_title := 'New Road Issue Nearby';
  notification_message := COALESCE(NEW.title, 'A road issue has been reported near your location');
  
  IF NEW.severity IN ('critical', 'high') THEN
    notification_message := notification_message || ' - ' || UPPER(NEW.severity) || ' severity';
  END IF;
  
  -- Find nearby users within their alert radius
  -- Convert miles to meters for PostGIS distance calculation (1 mile = 1609.34 meters)
  SELECT ARRAY_AGG(DISTINCT uap.user_id) INTO nearby_user_ids
  FROM public.user_alert_preferences uap
  JOIN public.profiles p ON p.id = uap.user_id
  WHERE 
    -- User has notifications enabled
    p.notifications_enabled = TRUE
    -- User is not the report creator
    AND uap.user_id != NEW.created_by
    -- Calculate distance using Haversine formula approximation
    -- This is a simplified calculation; for production, consider using PostGIS
    AND (
      6371000 * acos(
        cos(radians(NEW.latitude)) * 
        cos(radians(COALESCE((SELECT latitude FROM saved_locations WHERE user_id = uap.user_id LIMIT 1), 0))) * 
        cos(radians(COALESCE((SELECT longitude FROM saved_locations WHERE user_id = uap.user_id LIMIT 1), 0)) - radians(NEW.longitude)) + 
        sin(radians(NEW.latitude)) * 
        sin(radians(COALESCE((SELECT latitude FROM saved_locations WHERE user_id = uap.user_id LIMIT 1), 0)))
      )
    ) <= (uap.alert_radius_miles * 1609.34);
  
  -- If no nearby users found, return early
  IF nearby_user_ids IS NULL OR array_length(nearby_user_ids, 1) IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Create notification
  INSERT INTO public.notifications (
    title,
    message,
    type,
    status,
    target_type,
    target_user_ids,
    data,
    sound,
    category,
    priority,
    created_by
  ) VALUES (
    notification_title,
    notification_message,
    'location_alert',
    'sent',
    'custom',
    nearby_user_ids,
    jsonb_build_object(
      'report_id', NEW.id,
      'latitude', NEW.latitude,
      'longitude', NEW.longitude,
      'severity', NEW.severity,
      'address', NEW.address
    ),
    CASE severity_type
      WHEN 'alert' THEN 'alert'
      WHEN 'warning' THEN 'warning'
      ELSE 'default'
    END,
    severity_type,
    CASE severity_type
      WHEN 'alert' THEN 10
      WHEN 'warning' THEN 7
      ELSE 5
    END,
    NEW.created_by
  ) RETURNING id INTO notification_id;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_nearby_users_on_report_creation IS 
'Automatically creates notifications for nearby users when a new report is submitted';

-- =====================================
-- FUNCTION: notify_reporter_on_verification
-- =====================================
-- Creates notification for report creator when their report receives verification votes

CREATE OR REPLACE FUNCTION public.notify_reporter_on_verification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  report_creator_id UUID;
  report_title TEXT;
  verification_count INT;
  notification_id UUID;
BEGIN
  -- Only trigger for verify votes (not spam votes)
  IF NEW.vote_type != 'verify' THEN
    RETURN NEW;
  END IF;
  
  -- Get report creator and title
  SELECT created_by, title INTO report_creator_id, report_title
  FROM public.report_issues
  WHERE id = NEW.issue_id;
  
  -- Don't notify if creator is voting on their own report
  IF report_creator_id = NEW.user_id OR report_creator_id IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Count total verifications for this report
  SELECT COUNT(*) INTO verification_count
  FROM public.issue_votes
  WHERE issue_id = NEW.issue_id AND vote_type = 'verify';
  
  -- Create notification for report creator
  INSERT INTO public.notifications (
    title,
    message,
    type,
    status,
    target_type,
    target_user_ids,
    data,
    sound,
    category,
    priority,
    created_by
  ) VALUES (
    'Report Verified',
    'Your report "' || COALESCE(report_title, 'Untitled') || '" has been verified by another user (' || verification_count || ' total verifications)',
    'success',
    'sent',
    'single',
    ARRAY[report_creator_id],
    jsonb_build_object(
      'report_id', NEW.issue_id,
      'verification_count', verification_count,
      'verified_by', NEW.user_id
    ),
    'success',
    'success',
    5,
    NEW.user_id
  ) RETURNING id INTO notification_id;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_reporter_on_verification IS 
'Automatically creates notification for report creator when their report is verified';

-- =====================================
-- FUNCTION: notify_user_on_reputation_change
-- =====================================
-- Creates notification for user when their reputation score changes

CREATE OR REPLACE FUNCTION public.notify_user_on_reputation_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  notification_id UUID;
  notification_title TEXT;
  notification_message TEXT;
  notification_type TEXT;
  notification_sound TEXT;
BEGIN
  -- Determine notification type based on change amount
  IF NEW.change_amount > 0 THEN
    notification_type := 'success';
    notification_sound := 'success';
    notification_title := 'Reputation Increased';
    notification_message := 'You earned +' || NEW.change_amount || ' reputation points';
  ELSIF NEW.change_amount < 0 THEN
    notification_type := 'warning';
    notification_sound := 'warning';
    notification_title := 'Reputation Decreased';
    notification_message := 'You lost ' || ABS(NEW.change_amount) || ' reputation points';
  ELSE
    -- No change, don't notify
    RETURN NEW;
  END IF;
  
  -- Add action context to message
  CASE NEW.action_type
    WHEN 'UPLOAD_ISSUE' THEN
      notification_message := notification_message || ' for submitting a report';
    WHEN 'FIRST_REPORTER' THEN
      notification_message := notification_message || ' for being the first to report this issue';
    WHEN 'DUPLICATE_REPORT' THEN
      notification_message := notification_message || ' for submitting a duplicate report';
    WHEN 'ABUSE_REPORT' THEN
      notification_message := notification_message || ' due to system abuse';
    WHEN 'MANUAL_ADJUSTMENT' THEN
      notification_message := notification_message || ' (manual adjustment)';
    ELSE
      -- Keep default message
  END CASE;
  
  notification_message := notification_message || '. Your new score is ' || NEW.score_after;
  
  -- Create notification
  INSERT INTO public.notifications (
    title,
    message,
    type,
    status,
    target_type,
    target_user_ids,
    data,
    sound,
    category,
    priority
  ) VALUES (
    notification_title,
    notification_message,
    notification_type,
    'sent',
    'single',
    ARRAY[NEW.user_id],
    jsonb_build_object(
      'reputation_id', NEW.id,
      'action_type', NEW.action_type,
      'change_amount', NEW.change_amount,
      'score_before', NEW.score_before,
      'score_after', NEW.score_after,
      'related_issue_id', NEW.related_issue_id
    ),
    notification_sound,
    notification_type,
    CASE 
      WHEN ABS(NEW.change_amount) >= 10 THEN 7
      ELSE 5
    END,
    NULL
  ) RETURNING id INTO notification_id;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_user_on_reputation_change IS 
'Automatically creates notification when user reputation score changes';

-- =====================================
-- FUNCTION: notify_requester_on_authority_decision
-- =====================================
-- Creates notification for requester when authority request is approved or rejected

CREATE OR REPLACE FUNCTION public.notify_requester_on_authority_decision()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  notification_id UUID;
  notification_title TEXT;
  notification_message TEXT;
  notification_type TEXT;
  notification_sound TEXT;
BEGIN
  -- Only trigger when status changes to approved or rejected
  IF NEW.status NOT IN ('approved', 'rejected') THEN
    RETURN NEW;
  END IF;
  
  -- Don't trigger if status hasn't changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;
  
  -- Build notification based on decision
  IF NEW.status = 'approved' THEN
    notification_type := 'success';
    notification_sound := 'success';
    notification_title := 'Authority Request Approved';
    notification_message := 'Congratulations! Your authority request has been approved. You now have authority privileges.';
  ELSE -- rejected
    notification_type := 'info';
    notification_sound := 'default';
    notification_title := 'Authority Request Update';
    notification_message := 'Your authority request has been reviewed.';
    
    IF NEW.reviewed_comment IS NOT NULL THEN
      notification_message := notification_message || ' Reason: ' || NEW.reviewed_comment;
    END IF;
  END IF;
  
  -- Create notification
  INSERT INTO public.notifications (
    title,
    message,
    type,
    status,
    target_type,
    target_user_ids,
    data,
    sound,
    category,
    priority,
    created_by
  ) VALUES (
    notification_title,
    notification_message,
    notification_type,
    'sent',
    'single',
    ARRAY[NEW.user_id],
    jsonb_build_object(
      'request_id', NEW.id,
      'request_status', NEW.status,
      'reviewed_by', NEW.reviewed_by,
      'reviewed_at', NEW.reviewed_at,
      'reviewed_comment', NEW.reviewed_comment
    ),
    notification_sound,
    notification_type,
    CASE 
      WHEN NEW.status = 'approved' THEN 7
      ELSE 5
    END,
    NEW.reviewed_by
  ) RETURNING id INTO notification_id;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_requester_on_authority_decision IS 
'Automatically creates notification when authority request is approved or rejected';

-- =====================================
-- TRIGGERS: Automatic System Notifications
-- =====================================

-- Trigger: Notify nearby users when report is created
DROP TRIGGER IF EXISTS trg_notify_nearby_users_on_report ON public.report_issues;
CREATE TRIGGER trg_notify_nearby_users_on_report
  AFTER INSERT ON public.report_issues
  FOR EACH ROW
  WHEN (NEW.status = 'submitted' AND NEW.is_deleted = FALSE)
  EXECUTE FUNCTION public.notify_nearby_users_on_report_creation();

-- Trigger: Notify reporter when report is verified
DROP TRIGGER IF EXISTS trg_notify_reporter_on_verification ON public.issue_votes;
CREATE TRIGGER trg_notify_reporter_on_verification
  AFTER INSERT ON public.issue_votes
  FOR EACH ROW
  WHEN (NEW.vote_type = 'verify')
  EXECUTE FUNCTION public.notify_reporter_on_verification();

-- Trigger: Notify user on reputation change
DROP TRIGGER IF EXISTS trg_notify_user_on_reputation_change ON public.reputations;
CREATE TRIGGER trg_notify_user_on_reputation_change
  AFTER INSERT ON public.reputations
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_user_on_reputation_change();

-- Trigger: Notify requester on authority request decision
DROP TRIGGER IF EXISTS trg_notify_requester_on_authority_decision ON public.requests;
CREATE TRIGGER trg_notify_requester_on_authority_decision
  AFTER UPDATE ON public.requests
  FOR EACH ROW
  WHEN (NEW.status IN ('approved', 'rejected') AND OLD.status != NEW.status)
  EXECUTE FUNCTION public.notify_requester_on_authority_decision();


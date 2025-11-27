-- =====================================
-- DATABASE INDEXES
-- =====================================

-- ACTION LOG
CREATE INDEX IF NOT EXISTS idx_action_log_user_id ON public.action_log(user_id);
CREATE INDEX IF NOT EXISTS idx_action_log_created_at ON public.action_log(created_at);
CREATE INDEX IF NOT EXISTS idx_action_log_action_type ON public.action_log(action_type);
CREATE INDEX IF NOT EXISTS idx_action_log_is_synced ON public.action_log(is_synced) WHERE is_synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_action_log_user_created ON public.action_log(user_id, created_at DESC);

-- NOTIFICATIONS
CREATE INDEX IF NOT EXISTS idx_notifications_target_user_ids ON public.notifications USING GIN(target_user_ids);
CREATE INDEX IF NOT EXISTS idx_notifications_related_action ON public.notifications(related_action);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON public.notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_at ON public.notifications(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX IF NOT EXISTS idx_notifications_target_type ON public.notifications(target_type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_by ON public.notifications(created_by);
CREATE INDEX IF NOT EXISTS idx_notifications_is_deleted ON public.notifications(is_deleted);

-- USER NOTIFICATIONS
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON public.user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_notification_id ON public.user_notifications(notification_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_unread ON public.user_notifications(user_id, is_read) WHERE is_deleted = FALSE;

-- REPORT ISSUES
CREATE INDEX IF NOT EXISTS idx_report_issues_status ON public.report_issues(status);
CREATE INDEX IF NOT EXISTS idx_report_issues_severity ON public.report_issues(severity);
CREATE INDEX IF NOT EXISTS idx_report_issues_created_by ON public.report_issues(created_by);
CREATE INDEX IF NOT EXISTS idx_report_issues_location ON public.report_issues(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_report_issues_issue_type_ids ON public.report_issues USING GIN(issue_type_ids);

-- REQUESTS
CREATE INDEX IF NOT EXISTS idx_requests_user_id ON public.requests(user_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_reviewed_by ON public.requests(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON public.requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_requests_is_deleted ON public.requests(is_deleted);

-- REPUTATIONS
CREATE INDEX IF NOT EXISTS idx_reputations_user_id ON public.reputations(user_id);
CREATE INDEX IF NOT EXISTS idx_reputations_created_at ON public.reputations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reputations_user_created ON public.reputations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reputations_action_type ON public.reputations(action_type);

-- SAVED ROUTES
CREATE INDEX IF NOT EXISTS idx_saved_routes_user_id ON public.saved_routes(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_routes_is_monitoring ON public.saved_routes(is_monitoring);
CREATE INDEX IF NOT EXISTS idx_saved_routes_deleted ON public.saved_routes(is_deleted);

-- Composite index for route monitoring queries (optimizes get_users_monitoring_route)
CREATE INDEX IF NOT EXISTS idx_saved_routes_monitoring_deleted 
ON public.saved_routes(is_monitoring, is_deleted) 
WHERE is_monitoring = TRUE AND is_deleted = FALSE;

-- SAVED LOCATIONS
CREATE INDEX IF NOT EXISTS idx_saved_locations_user_id ON public.saved_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_locations_deleted ON public.saved_locations(is_deleted);

-- USER ALERT PREFERENCES
CREATE INDEX IF NOT EXISTS idx_user_alert_preferences_user_id ON public.user_alert_preferences(user_id);

-- Composite indexes for efficient filtering in get_nearby_users function
-- Index for road damage alerts
CREATE INDEX IF NOT EXISTS idx_user_alert_preferences_road_damage 
ON public.user_alert_preferences(user_id, road_damage_enabled) 
WHERE road_damage_enabled = TRUE;

-- Index for construction zone alerts
CREATE INDEX IF NOT EXISTS idx_user_alert_preferences_construction 
ON public.user_alert_preferences(user_id, construction_zones_enabled) 
WHERE construction_zones_enabled = TRUE;

-- Index for weather hazard alerts
CREATE INDEX IF NOT EXISTS idx_user_alert_preferences_weather 
ON public.user_alert_preferences(user_id, weather_hazards_enabled) 
WHERE weather_hazards_enabled = TRUE;

-- Index for traffic incident alerts
CREATE INDEX IF NOT EXISTS idx_user_alert_preferences_traffic 
ON public.user_alert_preferences(user_id, traffic_incidents_enabled) 
WHERE traffic_incidents_enabled = TRUE;

-- Index for alert radius filtering
CREATE INDEX IF NOT EXISTS idx_user_alert_preferences_radius 
ON public.user_alert_preferences(user_id, alert_radius_miles);

-- PROFILES
-- Index for notifications_enabled to optimize get_nearby_users queries
CREATE INDEX IF NOT EXISTS idx_profiles_notifications_enabled 
ON public.profiles(notifications_enabled) 
WHERE notifications_enabled = TRUE;

-- Composite index for notifications_enabled with id for efficient filtering
CREATE INDEX IF NOT EXISTS idx_profiles_notifications_id 
ON public.profiles(id, notifications_enabled);

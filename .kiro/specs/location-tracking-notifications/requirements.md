# Requirements Document

## Introduction

This specification defines the implementation of real-time location tracking and proximity-based notifications for the Pavra road safety application. Currently, the system cannot alert users when they move near severe road issues while GPS is enabled. This feature will implement continuous location tracking, server-side location updates, and automated proximity monitoring to notify users of nearby critical road hazards in real-time.

The solution implements a three-layer architecture:
1. **Location Tracking Layer**: Continuous GPS monitoring with intelligent update throttling
2. **Server Synchronization Layer**: Periodic location updates to the database with distance and time thresholds
3. **Proximity Monitoring Layer**: Background service that checks for nearby critical issues and triggers notifications

## Glossary

- **Location Tracking**: Continuous monitoring of user's GPS position using device location services
- **Location Update Threshold**: Minimum distance (meters) or time (seconds) before updating server with new location
- **Proximity Monitoring**: Background service that periodically checks for critical road issues near user's current location
- **Alert Radius**: The distance (in kilometers) within which users should be notified of critical road issues
- **Location Tracking Service**: Flutter service managing GPS position streams and update throttling
- **Nearby Issue Monitor Service**: Background service that checks for critical issues near user's location
- **Current Location**: User's most recent GPS coordinates stored in the profiles table
- **Location Staleness**: Time elapsed since last location update, used to filter inactive users
- **Distance Filter**: Minimum distance change required to trigger a location update event
- **Critical Issue**: Road issue with severity 'high' or 'critical' requiring immediate user notification
- **Notified Issues Cache**: In-memory set tracking which issues have already notified the user to prevent duplicates
- **Server Update**: Writing user's current location to the profiles table in the database
- **Position Stream**: Continuous stream of GPS position updates from the device
- **Location Permission**: User-granted permission allowing the app to access device GPS

## Requirements

### Requirement 1: Database Schema for Location Tracking

**User Story:** As a system architect, I want to store user locations in the database, so that the system can identify users near road issues and send proximity notifications.

#### Acceptance Criteria

1. WHEN the profiles table is modified THEN the System SHALL add current_latitude column as DOUBLE PRECISION
2. WHEN the profiles table is modified THEN the System SHALL add current_longitude column as DOUBLE PRECISION
3. WHEN the profiles table is modified THEN the System SHALL add location_updated_at column as TIMESTAMPTZ
4. WHEN the profiles table is modified THEN the System SHALL add location_tracking_enabled column as BOOLEAN with default FALSE
5. WHEN spatial queries are needed THEN the System SHALL create a spatial index on location coordinates for efficient proximity searches

### Requirement 2: Nearby Users Database Function

**User Story:** As a developer, I want a database function to find users near a location, so that I can identify who should receive proximity notifications for road issues.

#### Acceptance Criteria

1. WHEN get_nearby_users function is called with latitude, longitude, and radius THEN the System SHALL return user IDs within the specified radius
2. WHEN querying nearby users THEN the System SHALL only include users where location_tracking_enabled is TRUE
3. WHEN querying nearby users THEN the System SHALL only include users where current_latitude and current_longitude are NOT NULL
4. WHEN querying nearby users THEN the System SHALL only include users where location_updated_at is within the last 30 minutes
5. WHEN querying nearby users THEN the System SHALL only include users where notifications_enabled is TRUE
6. WHEN querying nearby users THEN the System SHALL exclude the current authenticated user
7. WHEN querying nearby users THEN the System SHALL calculate distance using the Haversine formula
8. WHEN querying nearby users THEN the System SHALL return results ordered by distance ascending

### Requirement 3: Location Tracking Service

**User Story:** As a user with location tracking enabled, I want the app to continuously monitor my GPS position, so that I can receive timely alerts about nearby road hazards.

#### Acceptance Criteria

1. WHEN startTracking is called THEN the Location Tracking Service SHALL request location permissions if not granted
2. WHEN location permissions are denied THEN the Location Tracking Service SHALL throw an exception with error message
3. WHEN startTracking is called THEN the Location Tracking Service SHALL initialize a position stream with high accuracy
4. WHEN startTracking is called THEN the Location Tracking Service SHALL set distance filter to 50 meters
5. WHEN a new position is received THEN the Location Tracking Service SHALL invoke the onLocationUpdate callback
6. WHEN a new position is received THEN the Location Tracking Service SHALL check if server update thresholds are met
7. WHEN server update thresholds are met THEN the Location Tracking Service SHALL invoke the onServerUpdate callback
8. WHEN stopTracking is called THEN the Location Tracking Service SHALL cancel the position stream subscription
9. WHEN stopTracking is called THEN the Location Tracking Service SHALL set isTracking to FALSE

### Requirement 4: Server Update Thresholds

**User Story:** As a system administrator, I want location updates to be throttled, so that we minimize database writes and reduce server load while maintaining accuracy.

#### Acceptance Criteria

1. WHEN evaluating server update THEN the System SHALL update if this is the first position (no previous update time)
2. WHEN evaluating server update THEN the System SHALL skip update if less than 60 seconds have elapsed since last update
3. WHEN evaluating server update THEN the System SHALL skip update if distance from last position is less than 100 meters
4. WHEN evaluating server update THEN the System SHALL update if both time threshold (60 seconds) and distance threshold (100 meters) are exceeded
5. WHEN server update is performed THEN the System SHALL record the current timestamp as last update time

### Requirement 5: User Location API

**User Story:** As a developer, I want API methods to update user location, so that the server maintains current location data for proximity calculations.

#### Acceptance Criteria

1. WHEN updateCurrentLocation is called THEN the User API SHALL update current_latitude in the profiles table
2. WHEN updateCurrentLocation is called THEN the User API SHALL update current_longitude in the profiles table
3. WHEN updateCurrentLocation is called THEN the User API SHALL update location_updated_at with current timestamp
4. WHEN updateCurrentLocation fails THEN the User API SHALL log the error without throwing exceptions
5. WHEN setLocationTrackingEnabled is called THEN the User API SHALL update location_tracking_enabled in the profiles table

### Requirement 6: Nearby Issue Monitor Service

**User Story:** As a user with location tracking enabled, I want the app to automatically check for critical road issues near me, so that I receive timely safety alerts without manual intervention.

#### Acceptance Criteria

1. WHEN startMonitoring is called THEN the Nearby Issue Monitor Service SHALL start a periodic timer with 2-minute intervals
2. WHEN startMonitoring is called THEN the Nearby Issue Monitor Service SHALL perform an immediate proximity check
3. WHEN the periodic timer triggers THEN the Nearby Issue Monitor Service SHALL check for nearby critical issues
4. WHEN stopMonitoring is called THEN the Nearby Issue Monitor Service SHALL cancel the periodic timer
5. WHEN stopMonitoring is called THEN the Nearby Issue Monitor Service SHALL clear the notified issues cache

### Requirement 7: Proximity Issue Detection

**User Story:** As a user moving through an area, I want to be notified of critical road issues within 5km, so that I can take appropriate safety precautions or choose alternate routes.

#### Acceptance Criteria

1. WHEN checking for nearby issues THEN the System SHALL use the last known position from Location Tracking Service
2. WHEN no position is available THEN the System SHALL log a message and skip the proximity check
3. WHEN position is available THEN the System SHALL search for issues within 5km radius
4. WHEN issues are found THEN the System SHALL filter for severity 'high' or 'critical'
5. WHEN filtering issues THEN the System SHALL exclude issues already in the notified issues cache
6. WHEN no new critical issues are found THEN the System SHALL log a message and complete without notifications
7. WHEN new critical issues are found THEN the System SHALL send notifications for each issue
8. WHEN notification is sent successfully THEN the System SHALL add the issue ID to the notified issues cache

### Requirement 8: Notification Integration

**User Story:** As a user near a critical road issue, I want to receive a push notification with issue details, so that I'm immediately aware of the hazard.

#### Acceptance Criteria

1. WHEN a critical issue is detected nearby THEN the System SHALL call notifyNearbyUsers with report details
2. WHEN calling notifyNearbyUsers THEN the System SHALL include report ID, title, latitude, longitude, and severity
3. WHEN calling notifyNearbyUsers THEN the System SHALL include the current user ID in nearbyUserIds
4. WHEN notification creation fails THEN the System SHALL log the error and continue processing other issues
5. WHEN notification is sent THEN the System SHALL log the issue ID for debugging

### Requirement 9: Application Integration

**User Story:** As a user, I want a simple way to enable or disable location tracking, so that I can control when the app monitors my location and sends proximity alerts.

#### Acceptance Criteria

1. WHEN enableLocationTracking is called THEN the System SHALL update location_tracking_enabled to TRUE in the database
2. WHEN enableLocationTracking is called THEN the System SHALL start the Location Tracking Service
3. WHEN enableLocationTracking is called THEN the System SHALL start the Nearby Issue Monitor Service
4. WHEN disableLocationTracking is called THEN the System SHALL update location_tracking_enabled to FALSE in the database
5. WHEN disableLocationTracking is called THEN the System SHALL stop the Location Tracking Service
6. WHEN disableLocationTracking is called THEN the System SHALL stop the Nearby Issue Monitor Service

### Requirement 10: Error Handling and Resilience

**User Story:** As a developer, I want location tracking failures to be handled gracefully, so that the app remains stable even when GPS or network issues occur.

#### Acceptance Criteria

1. WHEN location permission is denied THEN the System SHALL throw a clear exception message
2. WHEN position stream encounters an error THEN the System SHALL log the error without crashing
3. WHEN server location update fails THEN the System SHALL log the error without disrupting location tracking
4. WHEN nearby issue search fails THEN the System SHALL log the error and continue monitoring
5. WHEN notification creation fails THEN the System SHALL log the error and continue processing other issues

### Requirement 11: Performance and Battery Optimization

**User Story:** As a user, I want location tracking to be battery-efficient, so that I can keep it enabled without significantly draining my device battery.

#### Acceptance Criteria

1. WHEN configuring position stream THEN the System SHALL use a distance filter of 50 meters to reduce update frequency
2. WHEN evaluating server updates THEN the System SHALL enforce minimum 60-second interval between updates
3. WHEN evaluating server updates THEN the System SHALL enforce minimum 100-meter distance change
4. WHEN checking for nearby issues THEN the System SHALL use a 2-minute interval to balance responsiveness and performance
5. WHEN querying nearby users THEN the System SHALL use database spatial indexes for efficient queries

### Requirement 12: Privacy and User Control

**User Story:** As a user, I want control over location tracking, so that I can protect my privacy and only share location when I choose to.

#### Acceptance Criteria

1. WHEN location tracking is disabled THEN the System SHALL NOT update user location to the server
2. WHEN location tracking is disabled THEN the System SHALL NOT perform proximity monitoring
3. WHEN a user disables location tracking THEN the System SHALL stop all location-related background services
4. WHEN location_tracking_enabled is FALSE THEN the System SHALL exclude the user from nearby user queries
5. WHEN location data is older than 30 minutes THEN the System SHALL exclude the user from nearby user queries

### Requirement 13: Notified Issues Cache Management

**User Story:** As a user, I want to avoid receiving duplicate notifications for the same issue, so that I'm not annoyed by repeated alerts.

#### Acceptance Criteria

1. WHEN an issue notification is sent THEN the System SHALL add the issue ID to the notified issues cache
2. WHEN checking for nearby issues THEN the System SHALL exclude issues in the notified issues cache
3. WHEN clearNotifiedCache is called THEN the System SHALL remove all issue IDs from the cache
4. WHEN stopMonitoring is called THEN the System SHALL clear the notified issues cache
5. WHEN the user moves significantly THEN the System SHOULD clear the notified issues cache to allow re-notification

### Requirement 14: Service Initialization

**User Story:** As a developer, I want proper service initialization, so that all dependencies are available before location tracking starts.

#### Acceptance Criteria

1. WHEN Nearby Issue Monitor Service is initialized THEN the System SHALL require a ReportIssueApi instance
2. WHEN Nearby Issue Monitor Service is initialized THEN the System SHALL require a NotificationHelperService instance
3. WHEN startMonitoring is called without initialization THEN the System SHALL throw an exception
4. WHEN services are initialized THEN the System SHALL store references for use during monitoring
5. WHEN Location Tracking Service is instantiated THEN the System SHALL use singleton pattern to ensure single instance

### Requirement 15: Logging and Debugging

**User Story:** As a developer, I want comprehensive logging, so that I can debug location tracking issues and monitor system behavior.

#### Acceptance Criteria

1. WHEN location tracking starts THEN the System SHALL log a message indicating tracking is active
2. WHEN location tracking stops THEN the System SHALL log a message indicating tracking is stopped
3. WHEN server location is updated THEN the System SHALL log the latitude and longitude
4. WHEN proximity check finds critical issues THEN the System SHALL log the count of issues found
5. WHEN proximity check finds no issues THEN the System SHALL log a message indicating no new issues
6. WHEN errors occur THEN the System SHALL log error messages with stack traces
7. WHEN notifications are sent THEN the System SHALL log the issue ID for tracking

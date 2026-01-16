# Implementation Plan

- [x] 1. Database schema migration and functions




- [x] 1.1 Create migration file for profiles table location columns


  - Add current_latitude, current_longitude, location_updated_at, location_tracking_enabled columns
  - Create spatial index on location coordinates
  - Add column comments for documentation
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 1.2 Update get_nearby_users database function


  - Implement Haversine distance calculation
  - Add filtering for location_tracking_enabled, non-null coordinates, recent updates
  - Add filtering for notifications_enabled and alert preferences
  - Exclude current user from results
  - Order results by distance ascending
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [ ]* 1.3 Write unit tests for database schema
  - Test column existence and types
  - Test spatial index existence
  - Test default values
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ]* 1.4 Write property test for get_nearby_users distance accuracy
  - **Property 1: Nearby users distance accuracy**
  - **Validates: Requirements 2.1, 2.7**

- [ ]* 1.5 Write property test for get_nearby_users filtering
  - **Property 2: Nearby users filtering completeness**
  - **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
-

- [x] 2. Implement LocationTrackingService



- [x] 2.1 Create LocationTrackingService with singleton pattern


  - Implement singleton instance
  - Add state management (isTracking, lastPosition, lastUpdateTime)
  - Define configuration constants (distance threshold, time threshold)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 14.5_

- [x] 2.2 Implement startTracking method


  - Check and request location permissions
  - Initialize position stream with high accuracy and 50m distance filter
  - Implement onLocationUpdate callback invocation
  - Implement threshold checking and onServerUpdate callback
  - Add error handling for position stream
  - Add logging for tracking start
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 10.1, 10.2, 15.1_

- [x] 2.3 Implement _shouldUpdateServer threshold logic


  - Return true if no previous update (first position)
  - Check time threshold (60 seconds)
  - Check distance threshold (100 meters)
  - Return true only if both thresholds exceeded
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 11.2, 11.3_

- [x] 2.4 Implement stopTracking method


  - Cancel position stream subscription
  - Set isTracking to false
  - Add logging for tracking stop
  - _Requirements: 3.8, 3.9, 15.2_

- [x] 2.5 Implement getCurrentPosition method


  - Get single position with high accuracy
  - _Requirements: 3.1_

- [ ]* 2.6 Write unit tests for LocationTrackingService
  - Test singleton pattern
  - Test permission handling (denied, granted)
  - Test stream configuration
  - Test start/stop lifecycle
  - Test callback invocation
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.8, 3.9, 14.5_

- [ ]* 2.7 Write property test for position callback invocation
  - **Property 5: Position callback invocation**
  - **Validates: Requirements 3.5**

- [ ]* 2.8 Write property test for threshold checking
  - **Property 6: Threshold checking occurs**
  - **Validates: Requirements 3.6**

- [ ]* 2.9 Write property test for server update on threshold met
  - **Property 7: Server update on threshold met**
  - **Validates: Requirements 3.7, 4.4**

- [ ]* 2.10 Write property test for time threshold enforcement
  - **Property 8: Time threshold enforcement**
  - **Validates: Requirements 4.2, 11.2**

- [ ]* 2.11 Write property test for distance threshold enforcement
  - **Property 9: Distance threshold enforcement**
  - **Validates: Requirements 4.3, 11.3**
-

- [x] 3. Extend UserApi with location methods




- [x] 3.1 Implement updateCurrentLocation method


  - Update current_latitude, current_longitude, location_updated_at in profiles table
  - Add error handling (log but don't throw)
  - Add logging for successful updates
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 10.3, 15.3_

- [x] 3.2 Implement setLocationTrackingEnabled method


  - Update location_tracking_enabled flag in profiles table
  - _Requirements: 5.5_

- [ ]* 3.3 Write unit tests for UserApi location methods
  - Test updateCurrentLocation persistence
  - Test error handling (no exceptions)
  - Test setLocationTrackingEnabled
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ]* 3.4 Write property test for location update persistence
  - **Property 11: Location update persistence**
  - **Validates: Requirements 5.1, 5.2, 5.3**

- [ ]* 3.5 Write property test for location update error resilience
  - **Property 12: Location update error resilience**
  - **Validates: Requirements 5.4, 10.3**
-

- [x] 4. Implement NearbyIssueMonitorService



- [x] 4.1 Create NearbyIssueMonitorService with singleton pattern


  - Implement singleton instance
  - Add state management (isMonitoring, notifiedIssueIds cache)
  - Define configuration constants (check interval, alert radius)
  - Add reference to LocationTrackingService
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 13.1, 13.2, 13.3, 13.4_

- [x] 4.2 Implement initialize method

  - Store ReportIssueApi reference
  - Store NotificationHelperService reference
  - _Requirements: 14.1, 14.2, 14.4_

- [x] 4.3 Implement startMonitoring method

  - Check initialization (throw if not initialized)
  - Create periodic timer with 2-minute interval
  - Perform immediate proximity check
  - Set isMonitoring to true
  - _Requirements: 6.1, 6.2, 14.3_

- [x] 4.4 Implement _checkNearbyIssues method

  - Get last position from LocationTrackingService
  - Handle no position case (log and return)
  - Search for nearby issues within 5km radius
  - Filter for high/critical severity
  - Exclude issues in notified cache
  - Send notifications for each new critical issue
  - Add issue IDs to notified cache
  - Add error handling for search and notification failures
  - Add logging for issue count and notifications sent
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 8.1, 8.2, 8.3, 8.4, 8.5, 10.4, 10.5, 15.4, 15.5, 15.7_

- [x] 4.5 Implement stopMonitoring method

  - Cancel periodic timer
  - Clear notified issues cache
  - Set isMonitoring to false
  - _Requirements: 6.4, 6.5, 13.4_

- [x] 4.6 Implement clearNotifiedCache method

  - Clear all issue IDs from cache
  - _Requirements: 13.3_

- [ ]* 4.7 Write unit tests for NearbyIssueMonitorService
  - Test initialization requirements
  - Test timer configuration
  - Test immediate check on start
  - Test cache management
  - Test error handling
  - _Requirements: 6.1, 6.2, 6.4, 6.5, 13.3, 13.4, 14.1, 14.2, 14.3_

- [ ]* 4.8 Write property test for periodic check execution
  - **Property 14: Periodic check execution**
  - **Validates: Requirements 6.3**

- [ ]* 4.9 Write property test for last position usage
  - **Property 15: Last position usage**
  - **Validates: Requirements 7.1**

- [ ]* 4.10 Write property test for severity filtering
  - **Property 17: Severity filtering**
  - **Validates: Requirements 7.4**

- [ ]* 4.11 Write property test for cache-based deduplication
  - **Property 18: Cache-based deduplication**
  - **Validates: Requirements 7.5, 13.2**
-

- [x] 5. Implement application integration functions



- [x] 5.1 Create enableLocationTracking function


  - Update location_tracking_enabled to TRUE in database
  - Start LocationTrackingService with callbacks
  - Start NearbyIssueMonitorService
  - Add error handling
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 5.2 Create disableLocationTracking function

  - Update location_tracking_enabled to FALSE in database
  - Stop LocationTrackingService
  - Stop NearbyIssueMonitorService
  - Add error handling
  - _Requirements: 9.4, 9.5, 9.6_

- [ ]* 5.3 Write integration tests for enable/disable flow
  - Test enable tracking database update
  - Test enable tracking service start
  - Test disable tracking database update
  - Test disable tracking service stop
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ]* 5.4 Write property test for enable tracking
  - **Property 25: Enable tracking database update**
  - **Property 26: Enable tracking service start**
  - **Validates: Requirements 9.1, 9.2, 9.3**

- [ ]* 5.5 Write property test for disable tracking
  - **Property 27: Disable tracking database update**
  - **Property 28: Disable tracking service stop**
  - **Validates: Requirements 9.4, 9.5, 9.6**

- [x] 6. Add UI controls for location tracking




- [x] 6.1 Add location tracking toggle to settings screen


  - Add switch widget for enabling/disabling tracking
  - Wire up to enableLocationTracking/disableLocationTracking functions
  - Show current tracking status
  - Add permission explanation dialog
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 12.1, 12.2, 12.3_

- [x] 6.2 Add location tracking status indicator


  - Show tracking active/inactive status
  - Show last location update time
  - Show number of nearby issues being monitored
  - _Requirements: 15.1, 15.2, 15.3_

- [ ]* 6.3 Write UI tests for location tracking controls
  - Test toggle switch functionality
  - Test status display
  - Test permission dialog
  - _Requirements: 9.1, 9.4_
-

- [x] 7. Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.
-

- [x] 8. Documentation and deployment




- [x] 8.1 Update API documentation


  - Document LocationTrackingService API
  - Document UserApi location methods
  - Document NearbyIssueMonitorService API
  - Document integration functions
  - _Requirements: All_

- [x] 8.2 Create user guide for location tracking


  - Explain location tracking feature
  - Explain privacy and battery impact
  - Explain how to enable/disable
  - Explain proximity notifications
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 8.3 Run database migration


  - Apply schema changes to profiles table
  - Update get_nearby_users function
  - Verify indexes are created
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 9. Final checkpoint - Ensure all tests pass





  - Ensure all tests pass, ask the user if questions arise.

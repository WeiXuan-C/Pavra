# Implementation Plan

- [x] 1. Create NotificationHelperService





  - [x] 1.1 Create notification helper service file


    - Create lib/core/services/notification_helper_service.dart
    - Implement constructor with NotificationApi dependency
    - Add error handling wrapper for all methods
    - _Requirements: 9.1, 9.3, 13.1, 13.2_

  - [ ]* 1.2 Write property test for error handling
    - **Property 31: Notification creation failures are logged without exceptions**
    - **Validates: Requirements 9.3, 13.1, 13.2**

  - [x] 1.3 Implement report notification methods


    - Add notifyReportSubmitted() method
    - Add notifyNearbyUsers() method
    - Add notifyReportVerified() method
    - Add notifyReportSpam() method
    - Add notifyVoteThreshold() method
    - Configure sound, category, priority for each type
    - _Requirements: 1.1, 1.3, 1.4, 2.1, 2.2, 2.5, 9.2_

  - [ ]* 1.4 Write property tests for report notifications
    - **Property 1: Report submission creates success notification**
    - **Property 3: Nearby users receive location alerts**
    - **Property 4: Nearby alerts contain report details**
    - **Property 5: Report verification creates success notification**
    - **Property 6: Report spam creates warning notification**
    - **Property 7: Vote threshold notifications include count**
    - **Validates: Requirements 1.1, 1.3, 1.4, 2.1, 2.2, 2.5**

  - [x] 1.5 Implement authority request notification methods


    - Add notifyRequestSubmitted() method
    - Add notifyRequestApproved() method
    - Add notifyRequestRejected() method
    - Add notifyAdminsNewRequest() method
    - Configure sound, category, priority for each type
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.2_

  - [ ]* 1.6 Write property tests for authority request notifications
    - **Property 8: Request submission creates confirmation**
    - **Property 9: Request approval creates high-priority notification**
    - **Property 10: Request rejection includes reason**
    - **Property 11: New requests notify admins**
    - **Property 12: Admin notifications include request details**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

  - [x] 1.7 Implement reputation notification methods


    - Add notifyReputationChange() method
    - Add notifyReputationMilestone() method
    - Implement milestone detection logic (25, 50, 75, 100)
    - Add achievement-specific messages and icons
    - Configure sound, category, priority for each type
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 9.2_

  - [ ]* 1.8 Write property tests for reputation notifications
    - **Property 13: Positive reputation change creates success notification**
    - **Property 14: Negative reputation change creates warning notification**
    - **Property 15: Milestone notifications include achievement messages**
    - **Validates: Requirements 4.1, 4.2, 4.4**

  - [ ]* 1.9 Write example tests for reputation milestones
    - **Example 3: Reputation milestone 25**
    - **Example 4: Reputation milestone 50**
    - **Example 5: Reputation milestone 75**
    - **Example 6: Reputation milestone 100**
    - **Validates: Requirements 4.3**

  - [x] 1.10 Implement AI detection notification methods


    - Add notifyCriticalDetection() method
    - Add notifyOfflineQueueProcessed() method
    - Configure maximum priority for critical detections
    - Configure sound, category, priority for each type
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 9.2_

  - [ ]* 1.11 Write property tests for AI detection notifications
    - **Property 16: Critical detections create maximum priority alerts**
    - **Property 17: High severity detections create high priority alerts**
    - **Property 18: Critical detection alerts include detection details**
    - **Property 19: Offline queue processing includes sync count**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.5**

  - [x] 1.12 Implement route notification methods


    - Add notifyMonitoredRouteIssue() method
    - Add notifyRouteSaved() method
    - Add notifyRouteMonitoringEnabled() method
    - Configure sound, category, priority for each type
    - _Requirements: 6.2, 6.3, 6.4, 6.5, 9.2_

  - [ ]* 1.13 Write property tests for route notifications
    - **Property 21: Monitored route users receive alerts**
    - **Property 22: Route monitoring alerts include route information**
    - **Property 23: Route save creates confirmation**
    - **Property 24: Route monitoring enablement creates confirmation**
    - **Validates: Requirements 6.2, 6.3, 6.4, 6.5**

  - [x] 1.14 Implement user onboarding notification methods


    - Add notifyWelcomeNewUser() method
    - Add notifyRoleChanged() method
    - Include onboarding guidance in welcome message
    - Configure sound, category, priority for each type
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 9.2_

  - [ ]* 1.15 Write property tests for user onboarding notifications
    - **Property 25: New user profile creates welcome notification**
    - **Property 26: Role change creates notification with new role**
    - **Validates: Requirements 7.1, 7.2, 7.3, 7.4**

  - [x] 1.16 Implement system notification methods


    - Add notifySystemMaintenance() method
    - Add notifyAppUpdate() method
    - Add notifyImportantAnnouncement() method
    - Configure sound, category, priority for each type
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 9.2_

  - [ ]* 1.17 Write property tests for system notifications
    - **Property 27: App update notifications include version details**
    - **Property 28: Maintenance notifications include time window**
    - **Property 29: System notifications target all users**
    - **Validates: Requirements 8.2, 8.3, 8.4, 8.5**

  - [ ]* 1.18 Write example test for maintenance timing
    - **Example 7: Maintenance notification timing**
    - **Validates: Requirements 8.1**

  - [ ]* 1.19 Write property test for notification configuration
    - **Property 30: Notification methods configure sound, category, and priority**
    - **Validates: Requirements 9.2**

  - [ ]* 1.20 Write property test for data validation
    - **Property 32: Notification data validation occurs before creation**
    - **Validates: Requirements 9.4**
-

- [x] 2. Implement nearby user resolution




  - [x] 2.1 Create database function for nearby users


    - Create lib/database/functions/get_nearby_users.sql
    - Implement spatial query with radius filtering
    - Add filters for location_alerts_enabled, notifications_enabled
    - Exclude current user and deleted accounts
    - Grant execute permissions to authenticated users
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [x] 2.2 Add getNearbyUsers method to UserApi


    - Add getNearbyUsers() method to lib/core/api/user/user_api.dart
    - Call get_nearby_users database function via RPC
    - Handle errors gracefully and return empty list on failure
    - Add logging for errors
    - _Requirements: 10.1, 13.4_

  - [ ]* 2.3 Write property tests for nearby user resolution
    - **Property 33: Nearby users query applies all filters**
    - **Property 34: Nearby users are within specified radius**
    - **Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**

  - [ ]* 2.4 Write property test for empty results
    - **Property 47: Empty nearby users list doesn't cause errors**
    - **Validates: Requirements 1.5**

- [x] 3. Implement route monitoring resolution




  - [x] 3.1 Create database function for monitored routes


    - Create lib/database/functions/get_users_monitoring_route.sql
    - Implement spatial query with buffer distance
    - Add filters for is_monitoring and is_deleted
    - Use PostGIS for spatial calculations
    - Grant execute permissions to authenticated users
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [x] 3.2 Add getUsersMonitoringRoute method to SavedRouteApi


    - Add getUsersMonitoringRoute() method to lib/core/api/saved_route/saved_route_api.dart
    - Call get_users_monitoring_route database function via RPC
    - Handle errors gracefully and return empty list on failure
    - Add logging for errors
    - _Requirements: 11.1, 13.4_

  - [ ]* 3.3 Write property tests for route monitoring resolution
    - **Property 35: Monitored route query applies all filters**
    - **Property 36: Monitored routes are within buffer distance**
    - **Property 37: Monitored route query returns user IDs**
    - **Validates: Requirements 11.1, 11.2, 11.3, 11.4**

  - [ ]* 3.4 Write property test for empty results
    - **Property 51: Empty monitored routes list doesn't cause errors**
    - **Validates: Requirements 11.5**

- [x] 4. Checkpoint - Ensure all tests pass





  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Integrate notifications into ReportIssueApi




- [ ] 5. Integrate notifications into ReportIssueApi
  - [x] 5.1 Add NotificationHelperService dependency to ReportIssueApi


    - Inject NotificationHelperService into constructor
    - Inject UserApi for nearby user queries
    - Inject SavedRouteApi for route monitoring queries
    - _Requirements: 12.1_

  - [x] 5.2 Add notification trigger to submitReport


    - Call notifyReportSubmitted after successful submission
    - Query nearby users with getNearbyUsers
    - Call notifyNearbyUsers if nearby users exist
    - Query monitoring users with getUsersMonitoringRoute
    - Call notifyMonitoredRouteIssue if monitoring users exist
    - Wrap all notification calls in try-catch
    - _Requirements: 1.1, 1.2, 1.3, 6.1, 6.2, 12.1, 13.2_

  - [ ]* 5.3 Write property test for report submission integration
    - **Property 38: Report submission triggers notifications**
    - **Property 2: Report submission queries nearby users**
    - **Property 20: Report submission queries monitored routes**
    - **Validates: Requirements 1.2, 6.1, 12.1**

  - [x] 5.4 Add notification trigger to markAsReviewed


    - Call notifyReportVerified after successful review
    - Wrap notification call in try-catch
    - _Requirements: 2.1, 12.2, 13.2_

  - [ ]* 5.5 Write property test for review integration
    - **Property 39: Report review triggers verification notification**
    - **Validates: Requirements 12.2**

  - [x] 5.6 Add notification trigger to markAsSpam


    - Call notifyReportSpam after marking as spam
    - Include spam comment in notification
    - Wrap notification call in try-catch
    - _Requirements: 2.2, 12.3, 13.2_

  - [ ]* 5.7 Write property test for spam integration
    - **Property 40: Report spam triggers spam notification**
    - **Validates: Requirements 12.3**

  - [x] 5.8 Add notification trigger to vote methods


    - Check vote counts after voteVerify/voteSpam
    - Call notifyVoteThreshold when thresholds reached (5 verified, 3 spam)
    - Wrap notification call in try-catch
    - _Requirements: 2.3, 2.4, 2.5, 13.2_

  - [ ]* 5.9 Write example tests for vote thresholds
    - **Example 1: Verification vote threshold**
    - **Example 2: Spam vote threshold**
    - **Validates: Requirements 2.3, 2.4**
- [x] 6. Integrate notifications into AuthorityRequestApi




- [ ] 6. Integrate notifications into AuthorityRequestApi

  - [x] 6.1 Add NotificationHelperService dependency to AuthorityRequestApi


    - Inject NotificationHelperService into constructor
    - _Requirements: 12.5_

  - [x] 6.2 Add notification trigger to createRequest


    - Call notifyRequestSubmitted after successful creation
    - Call notifyAdminsNewRequest to notify admins
    - Wrap notification calls in try-catch
    - _Requirements: 3.1, 3.4, 13.2_

  - [x] 6.3 Add notification trigger to updateRequestStatus


    - Check new status (approved/rejected)
    - Call notifyRequestApproved if status is approved
    - Call notifyRequestRejected if status is rejected
    - Include rejection comment in notification
    - Wrap notification calls in try-catch
    - _Requirements: 3.2, 3.3, 12.5, 13.2_

  - [ ]* 6.4 Write property test for authority request integration
    - **Property 42: Authority status update triggers notifications**
    - **Validates: Requirements 12.5**
-

- [x] 7. Integrate notifications into ReputationApi




  - [x] 7.1 Add NotificationHelperService dependency to ReputationApi


    - Inject NotificationHelperService into constructor
    - _Requirements: 12.4_

  - [x] 7.2 Add notification trigger to addReputationRecord


    - Skip notification if changeAmount is zero
    - Call notifyReputationChange for non-zero changes
    - Check if milestone reached (25, 50, 75, 100)
    - Call notifyReputationMilestone if milestone reached
    - Wrap notification calls in try-catch
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 12.4, 13.2_

  - [ ]* 7.3 Write property test for reputation integration
    - **Property 41: Reputation change triggers notifications**
    - **Property 48: Zero reputation change skips notification**
    - **Validates: Requirements 4.5, 12.4**
-

- [x] 8. Integrate notifications into AiDetectionApi




  - [x] 8.1 Add NotificationHelperService dependency to AiDetectionApi


    - Inject NotificationHelperService into constructor
    - _Requirements: 5.1, 5.2_

  - [x] 8.2 Add notification trigger to detectRoadDamage


    - Check detection severity after successful detection
    - Call notifyCriticalDetection if severity is 'critical' or 'high'
    - Skip notification for 'moderate' or 'low' severity
    - Wrap notification call in try-catch
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 13.2_

  - [ ]* 8.3 Write property test for detection severity
    - **Property 49: Low severity detections skip notification**
    - **Validates: Requirements 5.4**

  - [x] 8.4 Add notification trigger to DetectionQueueManager


    - Call notifyOfflineQueueProcessed after processing queue
    - Include count of processed detections
    - Wrap notification call in try-catch
    - _Requirements: 5.5, 13.2_
-

- [x] 9. Integrate notifications into SavedRouteApi




  - [x] 9.1 Add NotificationHelperService dependency to SavedRouteApi


    - Inject NotificationHelperService into constructor
    - _Requirements: 6.4, 6.5_

  - [x] 9.2 Add notification trigger to createRoute


    - Call notifyRouteSaved after successful creation
    - Wrap notification call in try-catch
    - _Requirements: 6.4, 13.2_

  - [x] 9.3 Add notification trigger to toggleRouteMonitoring


    - Check if monitoring was enabled (not disabled)
    - Call notifyRouteMonitoringEnabled if enabled
    - Wrap notification call in try-catch
    - _Requirements: 6.5, 13.2_

- [x] 10. Integrate notifications into UserApi




  - [x] 10.1 Add NotificationHelperService dependency to UserApi


    - Inject NotificationHelperService into constructor
    - _Requirements: 7.1, 7.3_

  - [x] 10.2 Add notification trigger to createProfile


    - Call notifyWelcomeNewUser after successful profile creation
    - Wrap notification call in try-catch
    - _Requirements: 7.1, 7.2, 13.2_

  - [x] 10.3 Add notification trigger to updateProfile


    - Check if role changed (new role != old role)
    - Skip notification if role is unchanged
    - Call notifyRoleChanged if role changed
    - Wrap notification call in try-catch
    - _Requirements: 7.3, 7.4, 7.5, 13.2_

  - [ ]* 10.4 Write property test for role change
    - **Property 50: Same role change skips notification**
    - **Validates: Requirements 7.5**
-

- [x] 11. Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Add error handling and logging





  - [x] 12.1 Implement structured logging in NotificationHelperService


    - Use dart:developer log for all errors
    - Include error, stackTrace, and context in logs
    - Add performance logging for slow operations (>500ms)
    - _Requirements: 13.1, 14.5_

  - [ ]* 12.2 Write property tests for error handling
    - **Property 43: Notification failures don't disrupt business logic**
    - **Property 44: OneSignal unavailability is handled gracefully**
    - **Property 45: Database query failures are handled gracefully**
    - **Property 46: Performance warnings are logged for slow operations**
    - **Validates: Requirements 13.2, 13.3, 13.4, 13.5, 14.5**

  - [x] 12.3 Add error handling to user resolution methods


    - Wrap getNearbyUsers in try-catch
    - Return empty list on error
    - Log error with full context
    - _Requirements: 13.4_

  - [x] 12.4 Add error handling to route resolution methods


    - Wrap getUsersMonitoringRoute in try-catch
    - Return empty list on error
    - Log error with full context
    - _Requirements: 13.4_
- [x] 13. Add database indexes for performance




- [ ] 13. Add database indexes for performance

  - [x] 13.1 Create spatial indexes for route waypoints


    - Add GIST index on route_waypoints location
    - Create lib/database/indexes/spatial_indexes.sql
    - _Requirements: 14.1_

  - [x] 13.2 Create indexes for user alert preferences


    - Add index on user_alert_preferences(user_id, location_alerts_enabled)
    - Add index on profiles(notifications_enabled, is_deleted)
    - _Requirements: 14.1_

  - [x] 13.3 Create indexes for route monitoring


    - Add index on saved_routes(is_monitoring, is_deleted)
    - _Requirements: 14.1_

- [ ]* 14. Write integration tests
  - [ ]* 14.1 Write end-to-end test for report submission flow
    - Test report submission → success notification → nearby alerts
    - Verify all notifications created with correct data
    - _Requirements: All report requirements_

  - [ ]* 14.2 Write end-to-end test for authority request flow
    - Test request submission → confirmation → approval → notification
    - Verify admin notifications sent
    - _Requirements: All authority request requirements_

  - [ ]* 14.3 Write end-to-end test for reputation flow
    - Test reputation change → notification → milestone detection
    - Verify milestone notifications at correct thresholds
    - _Requirements: All reputation requirements_
- [x] 15. Update documentation




- [ ] 15. Update documentation

  - [x] 15.1 Document NotificationHelperService API


    - Add JSDoc comments to all public methods
    - Document parameters and return values
    - Add usage examples
    - _Requirements: All_

  - [x] 15.2 Update API documentation


    - Document new methods in UserApi and SavedRouteApi
    - Document database functions
    - Add integration examples
    - _Requirements: All_

  - [x] 15.3 Create notification trigger guide


    - Document all notification trigger points
    - Provide code examples for each integration
    - Document error handling best practices
    - _Requirements: All_

- [ ] 16. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

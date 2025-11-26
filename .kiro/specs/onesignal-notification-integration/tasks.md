# Implementation Plan

- [x] 1. Database schema enhancements





  - Add new columns to notifications table for OneSignal integration
  - Create database migration script
  - Test migration on development database
  - _Requirements: 2.1, 10.1, 10.5_







- [ ] 2. Enhance Flutter OneSignalService
  - [ ] 2.1 Implement enhanced initialization with error handling
    - Update initialize() method with proper error handling
    - Add initialization state tracking
    - Implement retry logic for failed initialization
    - _Requirements: 1.1_


  - [ ]* 2.2 Write property test for initialization
    - **Property 1: Initialization establishes OneSignal connection**
    - **Validates: Requirements 1.1**


  - [ ] 2.3 Implement user ID linking with conflict resolution
    - Update setExternalUserId() to handle 409 conflicts
    - Implement logout-then-login pattern
    - Add proper error handling and logging
    - _Requirements: 1.2_

  - [ ] 2.4 Implement user ID removal on logout
    - Update removeExternalUserId() method

    - Ensure clean logout flow
    - _Requirements: 1.3_

  - [ ]* 2.5 Write property test for login-logout round trip
    - **Property 2: Login-logout round trip clears external user ID**
    - **Validates: Requirements 1.2, 1.3**

  - [ ] 2.6 Implement notification click handler with navigation
    - Update handleNotificationClick() to extract navigation data
    - Implement route navigation logic
    - Add support for different notification types (report, user, etc.)
    - _Requirements: 1.5, 9.1, 9.2, 9.3, 9.4_

  - [ ]* 2.7 Write property test for navigation data extraction
    - **Property 30: Navigation data extraction is correct**

    - **Validates: Requirements 9.1**

  - [ ]* 2.8 Write example tests for specific navigation cases
    - **Example 1: Report detail navigation**
    - **Example 2: User profile navigation**
    - **Example 3: Default navigation**
    - **Validates: Requirements 9.2, 9.3, 9.4**





  - [ ] 2.9 Implement foreground notification handler
    - Update foreground notification display logic
    - Add in-app notification banner support
    - _Requirements: 1.4_

  - [ ]* 2.10 Write property test for notification display
    - **Property 3: Notification display preserves content**
    - **Validates: Requirements 1.4**

- [x] 3. Enhance NotificationAPI for CRUD operations



  - [x] 3.1 Update createNotification() with OneSignal fields

    - Add sound, category, priority parameters
    - Update API call to include new fields
    - Implement immediate send logic for status='sent'

    - _Requirements: 2.1, 2.3, 6.1, 6.2, 6.3, 6.4, 6.5_

  - [ ]* 3.2 Write property test for sent notification delivery
    - **Property 5: Sent notifications trigger immediate delivery**
    - **Validates: Requirements 2.1**

  - [ ]* 3.3 Write property test for draft notification behavior
    - **Property 7: Draft notifications do not trigger delivery**
    - **Validates: Requirements 2.3**

  - [ ]* 3.4 Write property test for notification type mapping
    - **Property 23: Notification type maps to correct configuration**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4**

  - [x] 3.5 Update updateNotification() with status transition logic

    - Implement draft-to-sent transition
    - Implement draft-to-scheduled transition
    - Add validation to prevent updating sent notifications
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [ ]* 3.6 Write property test for draft updates
    - **Property 10: Draft updates do not trigger delivery**
    - **Validates: Requirements 3.1**

  - [ ]* 3.7 Write property test for status transitions
    - **Property 11: Status transition to sent triggers delivery**
    - **Property 12: Status transition to scheduled creates scheduling job**
    - **Validates: Requirements 3.2, 3.3**

  - [ ]* 3.8 Write property test for sent notification immutability
    - **Property 13: Sent notifications are immutable**
    - **Validates: Requirements 3.4**

  - [x] 3.9 Update deleteNotification() with status-based logic


    - Implement soft delete for draft notifications
    - Implement OneSignal cancellation for scheduled notifications
    - Add validation to prevent deleting sent notifications
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 3.10 Write property tests for deletion behavior
    - **Property 15: Draft deletion is soft delete**
    - **Property 16: Scheduled deletion cancels OneSignal notification**
    - **Property 17: Sent notifications cannot be deleted**
    - **Validates: Requirements 4.1, 4.2, 4.3**

  - [x] 3.11 Add filtering support to getUserNotifications()


    - Add type, isRead, startDate, endDate parameters
    - Implement filter logic in query
    - _Requirements: 12.1, 12.3, 12.4, 12.5, 12.6_

  - [ ]* 3.12 Write property test for filtering
    - **Property 39: Filters return only matching notifications**
    - **Validates: Requirements 12.3, 12.4, 12.5, 12.6**
-

- [x] 4. Enhance Serverpod OneSignalService




  - [x] 4.1 Add notification category and sound support


    - Update sendToUser() to include sound and category
    - Update sendToUsers() to include sound and category
    - Update sendToAll() to include sound and category
    - Add priority parameter support
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1_

  - [ ]* 4.2 Write property test for category inclusion
    - **Property 24: Category is included in payload**
    - **Validates: Requirements 6.5**

  - [ ]* 4.3 Write property test for custom sound inclusion
    - **Property 28: Custom sound is included in payload**
    - **Validates: Requirements 8.1**

  - [x] 4.4 Implement data notification support


    - Add sendDataNotification() method for silent notifications
    - Configure payload for background data delivery
    - _Requirements: 7.1_

  - [ ]* 4.5 Write property test for data notifications
    - **Property 25: Data-only notifications are silent**
    - **Validates: Requirements 7.1**

  - [x] 4.6 Implement notification scheduling via OneSignal


    - Add scheduleNotification() method
    - Configure send_after parameter
    - _Requirements: 2.2_

  - [x] 4.7 Implement scheduled notification cancellation


    - Add cancelScheduledNotification() method
    - Handle cancellation errors gracefully
    - _Requirements: 4.2_

  - [x] 4.8 Implement delivery status tracking


    - Add getNotificationStatus() method
    - Add getDeliveryStats() method
    - Parse OneSignal response for recipient counts
    - _Requirements: 10.1, 10.2, 10.5_

  - [ ]* 4.9 Write property tests for status tracking
    - **Property 31: Successful send stores OneSignal ID**
    - **Property 32: Failed send updates status**
    - **Property 35: Delivery statistics are stored**
    - **Validates: Requirements 10.1, 10.2, 10.5**

- [x] 5. Enhance Serverpod NotificationEndpoint




  - [x] 5.1 Update handleNotificationCreated() for enhanced sending


    - Query notification with new OneSignal fields
    - Resolve target users based on target_type
    - Call OneSignalService with sound, category, priority
    - Store OneSignal notification ID in database
    - Update status to 'failed' on error
    - _Requirements: 2.1, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [ ]* 5.2 Write property test for target resolution
    - **Property 8: Target resolution creates correct user notification records**
    - **Validates: Requirements 2.4, 2.5, 2.6, 2.7**

  - [ ]* 5.3 Write property test for user notification record creation
    - **Property 9: Sent notifications have user notification records**
    - **Validates: Requirements 2.8**

  - [x] 5.4 Update scheduleNotificationById() for QStash integration


    - Implement QStash scheduling logic
    - Store QStash job ID for cancellation
    - Handle scheduling errors
    - _Requirements: 2.2_

  - [ ]* 5.5 Write property test for scheduling
    - **Property 6: Scheduled notifications create scheduling jobs**
    - **Validates: Requirements 2.2**

  - [x] 5.6 Implement handleScheduledNotification() webhook


    - Process QStash webhook callback
    - Update notification status from 'scheduled' to 'sent'
    - Trigger database function to create user_notifications
    - Send push notification via OneSignal
    - _Requirements: 10.3_

  - [ ]* 5.7 Write property test for scheduled notification processing
    - **Property 33: Scheduled notification processing updates status**
    - **Validates: Requirements 10.3**

  - [x] 5.8 Add updateNotificationStatus() endpoint


    - Create endpoint for status updates
    - Update notification record with status, OneSignal ID, error message
    - Store delivery statistics
    - _Requirements: 10.1, 10.2, 10.4, 10.5_

  - [ ]* 5.9 Write property test for status queries
    - **Property 34: Status query returns current state**
    - **Validates: Requirements 10.4**
-

- [x] 6. Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement user notification management



  - [x] 7.1 Update markAsRead() to set both fields


    - Update is_read to true
    - Set read_at timestamp
    - _Requirements: 5.1_

  - [ ]* 7.2 Write property test for mark as read
    - **Property 19: Mark as read updates fields correctly**
    - **Validates: Requirements 5.1**

  - [x] 7.3 Update markAllAsRead() with unread count verification


    - Update all unread notifications for user
    - Verify unread count becomes zero
    - _Requirements: 5.2_

  - [ ]* 7.4 Write property test for mark all as read
    - **Property 20: Mark all as read clears unread count**
    - **Validates: Requirements 5.2**

  - [x] 7.5 Update deleteNotificationForUser() for isolation


    - Implement soft delete for user_notification record
    - Ensure other users' records are unaffected
    - _Requirements: 5.3_

  - [ ]* 7.6 Write property test for user deletion isolation
    - **Property 21: User deletion is isolated**
    - **Validates: Requirements 5.3**

  - [x] 7.7 Update getUserNotifications() to filter deleted


    - Add is_deleted=false filter to query
    - Verify no deleted notifications are returned
    - _Requirements: 5.4_

  - [ ]* 7.8 Write property test for deleted notification filtering
    - **Property 22: Deleted notifications are filtered from view**
    - **Validates: Requirements 5.4**

- [-] 8. Implement data notification handling


  - [x] 8.1 Add data notification action handlers



    - Create action handler registry
    - Implement handlers for different action types
    - Add error handling for failed actions
    - _Requirements: 7.3, 7.4_

  - [ ]* 8.2 Write property test for action handler invocation
    - **Property 26: Data notification action handlers are invoked**
    - **Validates: Requirements 7.3**

  - [ ]* 8.3 Write property test for error handling
    - **Property 27: Data notification errors are logged without crashing**
    - **Validates: Requirements 7.4**

- [x] 9. Add notification sounds and categories







  - [x] 9.1 Add sound files to Android resources



    - Create alert.wav, warning.wav, success.wav, default.wav
    - Place in android/app/src/main/res/raw/
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [x] 9.2 Add sound files to iOS resources


    - Create alert.wav, warning.wav, success.wav, default.wav
    - Place in ios/Runner/Resources/
    - Update Info.plist if needed
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ]* 9.3 Write property test for default sound behavior
    - **Property 29: Default sound when no sound specified**
    - **Validates: Requirements 8.4**

  - [x] 9.4 Create Android notification channels


    - Add notification channel creation code to MainActivity
    - Create channels for alert, warning, info, success
    - Set appropriate importance levels
    - _Requirements: 6.5_

- [x] 10. Implement automatic system notifications




  - [x] 10.1 Add notification trigger for report creation


    - Hook into report creation flow
    - Query nearby users within alert radius
    - Create notification with target_user_ids
    - _Requirements: 11.1_

  - [x] 10.2 Add notification trigger for report verification


    - Hook into report verification flow
    - Create notification for report creator
    - _Requirements: 11.2_

  - [x] 10.3 Add notification trigger for reputation changes


    - Hook into reputation update flow
    - Create notification for affected user
    - _Requirements: 11.3_

  - [x] 10.4 Add notification trigger for authority requests


    - Hook into request approval/rejection flow
    - Create notification for requester
    - _Requirements: 11.4_

  - [x] 10.5 Add notification trigger for system maintenance


    - Create admin endpoint for maintenance notifications
    - Send to all users with target_type='all'
    - _Requirements: 11.5_

  - [ ]* 10.6 Write property test for system event notifications
    - **Property 36: System events trigger notifications**
    - **Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5**

- [-] 11. Update UI components


  - [x] 11.1 Update NotificationFormScreen for new fields



    - Add sound selection dropdown
    - Add category selection dropdown
    - Add priority slider
    - Update form validation
    - _Requirements: 2.1, 6.1, 6.2, 6.3, 6.4, 6.5, 8.1_

  - [ ] 11.2 Update NotificationItemWidget for status display
    - Show OneSignal delivery status
    - Display error messages for failed notifications
    - Show recipient count and delivery stats
    - _Requirements: 10.1, 10.2, 10.5_

  - [ ] 11.3 Update NotificationScreen for enhanced filtering
    - Add filter chips for type, status, date range
    - Update filter logic to use new API parameters
    - _Requirements: 12.3, 12.4, 12.5, 12.6_

  - [ ]* 11.4 Write property test for user notification filtering
    - **Property 37: User notifications are correctly filtered**
    - **Validates: Requirements 12.1**

  - [ ]* 11.5 Write property test for all notifications query
    - **Property 38: All notifications query returns complete set**
    - **Validates: Requirements 12.2**

- [x] 12. Implement scheduled notification management

  - [x] 12.1 Add scheduled notification update logic
    - Cancel previous QStash job on update
    - Create new QStash job with updated parameters
    - _Requirements: 3.5_

  - [ ]* 12.2 Write property test for scheduled notification updates
    - **Property 14: Scheduled notification updates cancel previous schedule**
    - **Validates: Requirements 3.5**

  - [x] 12.3 Add hard delete functionality
    - Implement hardDeleteNotification() in API
    - Add cascade delete logic
    - Add admin permission check
    - _Requirements: 4.4_

  - [ ]* 12.4 Write property test for hard delete cascade
    - **Property 18: Hard delete cascades to user notifications**
    - **Validates: Requirements 4.4**

- [x] 13. Add error handling and logging

  - [x] 13.1 Implement comprehensive error handling
    - Add try-catch blocks for all OneSignal API calls
    - Add try-catch blocks for all database operations
    - Add try-catch blocks for all QStash operations
    - Update notification status on errors
    - _Requirements: 10.2_

  - [x] 13.2 Add structured logging
    - Log all notification creation events
    - Log all OneSignal API responses
    - Log all delivery failures
    - Log all user interactions
    - _Requirements: 7.4, 10.2_

  - [x] 13.3 Implement retry logic
    - Add retry logic for failed OneSignal API calls
    - Add exponential backoff
    - Limit retry attempts
    - _Requirements: 10.2_

- [x] 14. Add monitoring and analytics





  - [x] 14.1 Implement delivery metrics tracking




    - Track notification send success rate
    - Track average delivery time
    - Track user engagement metrics
    - Store metrics in database
    - _Requirements: 10.5_

  - [x] 14.2 Add alerting for failures


    - Alert on high failure rates
    - Alert on OneSignal API errors
    - Alert on QStash scheduling failures
    - _Requirements: 10.2_

- [ ] 15. Performance optimizations
  - [ ] 15.1 Add database indexes
    - Add index on user_notifications(user_id, is_deleted, is_read)
    - Add index on notifications(status, created_at)
    - Add index on notifications(onesignal_notification_id)
    - _Requirements: 12.1, 12.3, 12.4, 12.5_

  - [ ] 15.2 Implement batch operations
    - Use batch inserts for user_notifications
    - Send to multiple users in single OneSignal call
    - _Requirements: 2.5, 2.6, 2.7_

  - [ ] 15.3 Add caching
    - Cache unread count
    - Cache user role information
    - Implement local notification cache
    - _Requirements: 5.2, 12.1_

- [x] 16. Security enhancements






  - [x] 16.1 Add permission checks




    - Verify user can create notifications
    - Verify user can only delete own user_notifications
    - Restrict admin operations to authorized roles
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 5.3_

  - [x] 16.2 Add input validation


    - Validate notification data before sending
    - Sanitize user input
    - Limit payload size
    - _Requirements: 2.1, 3.2, 3.3_

  - [x] 16.3 Implement rate limiting


    - Add rate limiting on notification creation
    - Prevent spam
    - Monitor API usage
    - _Requirements: 2.1_
-

- [ ] 17. Documentation and testing

  - [ ]* 17.1 Write integration tests
    - Test end-to-end notification flow
    - Test scheduled notification flow
    - Test multi-user targeting
    - _Requirements: All_

  - [x] 17.2 Update API documentation


    - Document new API endpoints
    - Document new parameters
    - Add usage examples
    - _Requirements: All_

  - [x] 17.3 Create user guide



    - Document notification creation process
    - Document scheduling process
    - Document filtering options
    - _Requirements: All_
- [x] 18. Final checkpoint - Ensure all tests pass




- [ ] 18. Final checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

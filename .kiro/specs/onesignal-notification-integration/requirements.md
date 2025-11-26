# Requirements Document

## Introduction

This specification defines the enhancement of the existing notification system to fully integrate OneSignal push notifications with advanced features including notification categories, custom sounds, data notifications, and comprehensive CRUD operations. The system will support immediate, scheduled, and draft notifications with proper targeting (single user, multiple users, role-based, and broadcast to all users).

## Glossary

- **Notification System**: The application's notification management system consisting of database tables, API endpoints, and UI components
- **OneSignal**: Third-party push notification service provider used for delivering notifications to mobile devices
- **Push Notification**: A message sent to a user's device that appears even when the app is not actively running
- **Data Notification**: A silent notification that delivers data to the app without displaying a visible alert
- **Notification Category**: A classification system for notifications that determines their priority, sound, and visual presentation
- **External User ID**: The application's user ID linked to OneSignal's player ID for targeted notifications
- **Player ID**: OneSignal's unique identifier for a device subscription
- **Notification Sound**: Custom audio file played when a notification is received
- **Scheduled Notification**: A notification configured to be sent at a future time
- **Draft Notification**: A notification saved but not yet sent or scheduled
- **Target Type**: The recipient specification method (single, custom, role, all)
- **Notification Status**: The current state of a notification (draft, scheduled, sent, failed)
- **User Notifications Table**: Database table storing per-user notification delivery records
- **Notifications Table**: Database table storing notification definitions and metadata
- **Soft Delete**: Marking a record as deleted without physically removing it from the database
- **Hard Delete**: Permanently removing a record from the database

## Requirements

### Requirement 1

**User Story:** As a mobile app user, I want to receive push notifications on my device, so that I can stay informed about important events even when the app is closed.

#### Acceptance Criteria

1. WHEN the application initializes THEN the Notification System SHALL register the device with OneSignal and obtain a Player ID
2. WHEN a user logs in THEN the Notification System SHALL link the user's External User ID with their OneSignal Player ID
3. WHEN a user logs out THEN the Notification System SHALL remove the External User ID association from OneSignal
4. WHEN the device receives a push notification THEN the Notification System SHALL display the notification with the specified title and message
5. WHEN a user taps on a push notification THEN the Notification System SHALL open the app and navigate to the relevant screen based on notification data

### Requirement 2

**User Story:** As a developer, I want to create notifications with different delivery options, so that I can send immediate, scheduled, or draft notifications to appropriate users.

#### Acceptance Criteria

1. WHEN a developer creates a notification with status 'sent' THEN the Notification System SHALL immediately send the push notification to target users
2. WHEN a developer creates a notification with status 'scheduled' and a future timestamp THEN the Notification System SHALL schedule the notification for delivery at the specified time
3. WHEN a developer creates a notification with status 'draft' THEN the Notification System SHALL save the notification without sending or scheduling it
4. WHEN a notification is created with target type 'single' THEN the Notification System SHALL send the notification to the specified user ID
5. WHEN a notification is created with target type 'custom' THEN the Notification System SHALL send the notification to all specified user IDs
6. WHEN a notification is created with target type 'role' THEN the Notification System SHALL send the notification to all users with the specified roles
7. WHEN a notification is created with target type 'all' THEN the Notification System SHALL send the notification to all registered users
8. WHEN a notification is sent THEN the Notification System SHALL create corresponding user notification records in the User Notifications Table

### Requirement 3

**User Story:** As a developer, I want to update existing notifications, so that I can modify draft or scheduled notifications before they are sent.

#### Acceptance Criteria

1. WHEN a developer updates a notification with status 'draft' THEN the Notification System SHALL save the changes without sending the notification
2. WHEN a developer updates a notification and changes status from 'draft' to 'sent' THEN the Notification System SHALL immediately send the notification to target users
3. WHEN a developer updates a notification and changes status from 'draft' to 'scheduled' THEN the Notification System SHALL schedule the notification for the specified time
4. WHEN a developer updates a notification with status 'sent' THEN the Notification System SHALL reject the update and return an error
5. WHEN a developer updates a scheduled notification THEN the Notification System SHALL cancel the previous schedule and create a new schedule with updated parameters

### Requirement 4

**User Story:** As a developer, I want to delete notifications, so that I can remove draft or scheduled notifications that are no longer needed.

#### Acceptance Criteria

1. WHEN a developer deletes a notification with status 'draft' THEN the Notification System SHALL perform a soft delete by setting is_deleted to true
2. WHEN a developer deletes a notification with status 'scheduled' THEN the Notification System SHALL cancel the OneSignal scheduled notification and perform a soft delete
3. WHEN a developer attempts to delete a notification with status 'sent' THEN the Notification System SHALL reject the deletion and return an error
4. WHEN a developer performs a hard delete on a notification THEN the Notification System SHALL permanently remove the notification record and all associated user notification records

### Requirement 5

**User Story:** As a user, I want to manage my received notifications, so that I can mark them as read or remove them from my notification list.

#### Acceptance Criteria

1. WHEN a user marks a notification as read THEN the Notification System SHALL update the is_read field to true and set the read_at timestamp in the User Notifications Table
2. WHEN a user marks all notifications as read THEN the Notification System SHALL update all unread notifications for that user to read status
3. WHEN a user deletes a notification THEN the Notification System SHALL perform a soft delete on the user notification record without affecting other users
4. WHEN a user views their notifications THEN the Notification System SHALL display only notifications that are not soft deleted

### Requirement 6

**User Story:** As a developer, I want to send notifications with different categories, so that users receive appropriately prioritized notifications with distinct visual and audio presentations.

#### Acceptance Criteria

1. WHEN a notification is created with type 'alert' THEN the Notification System SHALL send the push notification with high priority and critical alert sound
2. WHEN a notification is created with type 'warning' THEN the Notification System SHALL send the push notification with medium priority and warning sound
3. WHEN a notification is created with type 'info' THEN the Notification System SHALL send the push notification with normal priority and default sound
4. WHEN a notification is created with type 'success' THEN the Notification System SHALL send the push notification with normal priority and success sound
5. WHEN a notification is created with an Android notification category THEN the Notification System SHALL include the category in the push notification payload

### Requirement 7

**User Story:** As a developer, I want to send data notifications, so that the app can receive and process data in the background without displaying a visible notification to the user.

#### Acceptance Criteria

1. WHEN a notification is created with a data payload and no visible content THEN the Notification System SHALL send a silent data notification
2. WHEN the app receives a data notification THEN the Notification System SHALL process the data payload without displaying a notification banner
3. WHEN a data notification contains an action type THEN the Notification System SHALL execute the corresponding action handler
4. WHEN a data notification processing fails THEN the Notification System SHALL log the error without affecting the user experience

### Requirement 8

**User Story:** As a developer, I want to configure custom notification sounds, so that different notification types can have distinct audio alerts.

#### Acceptance Criteria

1. WHEN a notification is created with a custom sound parameter THEN the Notification System SHALL include the sound file name in the push notification payload
2. WHEN the device receives a notification with a custom sound THEN the Notification System SHALL play the specified sound file
3. WHEN a custom sound file does not exist THEN the Notification System SHALL fall back to the default notification sound
4. WHEN a notification is created without a sound parameter THEN the Notification System SHALL use the default notification sound

### Requirement 9

**User Story:** As a developer, I want to handle notification interactions, so that users can navigate to relevant content when they tap on notifications.

#### Acceptance Criteria

1. WHEN a user taps on a notification with navigation data THEN the Notification System SHALL extract the target route from the notification payload
2. WHEN a notification contains a report_id in the data payload THEN the Notification System SHALL navigate to the report detail screen
3. WHEN a notification contains a user_id in the data payload THEN the Notification System SHALL navigate to the user profile screen
4. WHEN a notification contains no navigation data THEN the Notification System SHALL open the app to the home screen
5. WHEN the app is in the foreground and receives a notification THEN the Notification System SHALL display an in-app notification banner

### Requirement 10

**User Story:** As a developer, I want to track notification delivery status, so that I can monitor which notifications were successfully sent and identify delivery failures.

#### Acceptance Criteria

1. WHEN a notification is successfully sent via OneSignal THEN the Notification System SHALL store the OneSignal notification ID in the notification record
2. WHEN a notification send fails THEN the Notification System SHALL update the notification status to 'failed' and log the error message
3. WHEN a scheduled notification is processed THEN the Notification System SHALL update the notification status from 'scheduled' to 'sent' and set the sent_at timestamp
4. WHEN a developer queries notification status THEN the Notification System SHALL return the current status and delivery metadata
5. WHEN OneSignal returns delivery statistics THEN the Notification System SHALL store the recipient count and delivery success rate

### Requirement 11

**User Story:** As a system administrator, I want notifications to be created automatically for system events, so that users are informed about important activities without manual intervention.

#### Acceptance Criteria

1. WHEN a new report issue is created THEN the Notification System SHALL create a notification for nearby users within the alert radius
2. WHEN a user's report is verified THEN the Notification System SHALL create a notification for the report creator
3. WHEN a user's reputation changes THEN the Notification System SHALL create a notification for that user
4. WHEN an authority request is approved or rejected THEN the Notification System SHALL create a notification for the requester
5. WHEN a system maintenance event occurs THEN the Notification System SHALL create a notification for all users

### Requirement 12

**User Story:** As a developer, I want to filter and query notifications, so that I can retrieve specific subsets of notifications based on various criteria.

#### Acceptance Criteria

1. WHEN a user requests their notifications THEN the Notification System SHALL return only notifications targeted to that user
2. WHEN a developer requests all notifications THEN the Notification System SHALL return all notifications from the Notifications Table
3. WHEN filtering by notification type THEN the Notification System SHALL return only notifications matching the specified type
4. WHEN filtering by status THEN the Notification System SHALL return only notifications matching the specified status
5. WHEN filtering by date range THEN the Notification System SHALL return only notifications created within the specified time period
6. WHEN filtering by read status THEN the Notification System SHALL return only read or unread notifications based on the filter

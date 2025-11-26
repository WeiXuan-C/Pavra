# Notification System User Guide

A comprehensive guide for using the Pavra notification system.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Creating Notifications](#creating-notifications)
4. [Scheduling Notifications](#scheduling-notifications)
5. [Managing Notifications](#managing-notifications)
6. [Filtering and Searching](#filtering-and-searching)
7. [Understanding Notification Types](#understanding-notification-types)
8. [Notification Sounds and Categories](#notification-sounds-and-categories)
9. [Targeting Options](#targeting-options)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)
12. [FAQ](#faq)

---

## Introduction

The Pavra notification system allows you to send push notifications to users through OneSignal. You can send notifications immediately, schedule them for later, or save them as drafts.

### Key Features

- ✅ **Immediate delivery** - Send notifications instantly
- 📅 **Scheduled delivery** - Schedule notifications for future delivery
- 📝 **Draft mode** - Save notifications without sending
- 🎯 **Flexible targeting** - Send to specific users, roles, or everyone
- 🔔 **Custom sounds** - Different sounds for different notification types
- 📊 **Delivery tracking** - Monitor delivery status and statistics
- 🔕 **Silent notifications** - Background data delivery without alerts

### Who Can Use This?

| Role | Permissions |
|------|-------------|
| **Developer** | Create, update, delete, schedule, broadcast |
| **Authority** | Create, update, delete, schedule |
| **Admin** | Create, update, delete, schedule, broadcast, hard delete |
| **User** | View own notifications, mark as read, delete own |

---

## Getting Started

### Accessing the Notification Screen

1. Open the Pavra app
2. Tap the **Notifications** icon in the navigation bar
3. You'll see your notification list

### Understanding the Interface

The notification screen shows:

- **Notification list** - All your notifications
- **Unread badge** - Number of unread notifications
- **Filter options** - Filter by type, status, or date
- **Create button** - Create new notifications (if you have permission)

---

## Creating Notifications

### Step 1: Open the Notification Form

1. Navigate to the Notifications screen
2. Tap the **Create** button (+ icon)
3. The notification form will open

### Step 2: Fill in Basic Information

#### Title
- **Required**
- Maximum 100 characters
- Should be clear and concise
- Example: "Road Hazard Alert"

#### Message
- **Required**
- Maximum 500 characters
- Provide detailed information
- Example: "A large pothole has been reported on Main Street near the intersection with Oak Avenue."

#### Type
- **Required**
- Choose from:
  - **Success** ✅ - Positive outcomes (e.g., "Report approved")
  - **Warning** ⚠️ - Cautions (e.g., "Approaching hazard")
  - **Alert** 🚨 - Urgent issues (e.g., "Road closed")
  - **Info** ℹ️ - General information (e.g., "New feature available")
  - **System** ⚙️ - System messages (e.g., "Maintenance scheduled")
  - **User** 👤 - User interactions (e.g., "New comment")
  - **Report** 📝 - Report updates (e.g., "Report verified")
  - **Location Alert** 📍 - Location-based (e.g., "Hazard nearby")
  - **Submission Status** 📋 - Status updates (e.g., "Request approved")
  - **Promotion** 📢 - Announcements (e.g., "New feature")
  - **Reminder** 🔔 - Reminders (e.g., "Update available")

### Step 3: Choose Delivery Method

#### Send Immediately
- Select **Status: Sent**
- Notification will be delivered right away
- Cannot be modified after sending

#### Schedule for Later
- Select **Status: Scheduled**
- Choose date and time
- Can be modified or cancelled before delivery
- Useful for announcements or reminders

#### Save as Draft
- Select **Status: Draft**
- Notification is saved but not sent
- Can be edited and sent later
- Useful for preparing notifications in advance

### Step 4: Select Target Audience

#### Single User
- Send to one specific user
- Enter the user ID
- Use for personal notifications

#### Multiple Users
- Send to a list of specific users
- Enter multiple user IDs
- Use for group notifications

#### Role-Based
- Send to all users with specific roles
- Select roles: Developer, Authority, Admin, User
- Use for role-specific announcements

#### Broadcast to All
- Send to all registered users
- **Requires admin or developer role**
- Use sparingly for important announcements

### Step 5: Configure Sound and Priority

#### Sound
- **Alert** - Critical alerts (loud, attention-grabbing)
- **Warning** - Warnings (moderate volume)
- **Success** - Success messages (pleasant tone)
- **Default** - Standard notification sound

#### Category (Android)
- Determines notification channel
- Affects how the notification is displayed
- Options: alert, warning, info, success

#### Priority
- Scale from 1 (lowest) to 10 (highest)
- Higher priority notifications appear first
- Default: 5 (medium priority)

### Step 6: Add Custom Data (Optional)

Custom data allows you to include additional information for navigation or processing.

**Example:**
```json
{
  "report_id": "abc-123",
  "action": "view_report",
  "latitude": 37.7749,
  "longitude": -122.4194
}
```

### Step 7: Review and Send

1. Review all information
2. Tap **Create Notification**
3. Confirm the action
4. Notification will be sent/scheduled/saved based on status

---

## Scheduling Notifications

### When to Use Scheduling

- **Maintenance announcements** - Notify users before scheduled maintenance
- **Event reminders** - Remind users about upcoming events
- **Time-sensitive alerts** - Send alerts at specific times
- **Batch notifications** - Prepare multiple notifications in advance

### How to Schedule

1. Create a notification as described above
2. Select **Status: Scheduled**
3. Choose the date and time
4. The notification will be automatically sent at the scheduled time

### Managing Scheduled Notifications

#### View Scheduled Notifications
- Filter by **Status: Scheduled**
- See the scheduled time for each notification

#### Reschedule a Notification
1. Open the scheduled notification
2. Tap **Edit**
3. Change the scheduled time
4. Tap **Update**
5. The previous schedule is cancelled and a new one is created

#### Cancel a Scheduled Notification
1. Open the scheduled notification
2. Tap **Delete**
3. Confirm deletion
4. The notification will not be sent

---

## Managing Notifications

### Viewing Your Notifications

#### All Notifications
- Shows all notifications sent to you
- Sorted by most recent first

#### Unread Notifications
- Filter by **Unread** to see only unread notifications
- Unread notifications have a blue dot indicator

#### Read Notifications
- Filter by **Read** to see notifications you've already read

### Marking as Read

#### Single Notification
1. Tap on a notification to open it
2. It will automatically be marked as read

#### Mark All as Read
1. Tap the **More** menu (⋮)
2. Select **Mark All as Read**
3. All unread notifications will be marked as read

### Deleting Notifications

#### Delete for Yourself
1. Swipe left on a notification
2. Tap **Delete**
3. The notification is removed from your list
4. Other users can still see it

#### Delete Permanently (Admin Only)
1. Open the notification
2. Tap **More** menu (⋮)
3. Select **Delete Permanently**
4. Confirm deletion
5. The notification is removed for all users

---

## Filtering and Searching

### Filter by Type

1. Tap the **Filter** button
2. Select notification type(s)
3. Only notifications of selected types will be shown

### Filter by Status

1. Tap the **Filter** button
2. Select status: Draft, Scheduled, Sent, Failed
3. Only notifications with selected status will be shown

### Filter by Date Range

1. Tap the **Filter** button
2. Select **Date Range**
3. Choose start and end dates
4. Only notifications within the date range will be shown

### Filter by Read Status

1. Tap the **Filter** button
2. Select **Read** or **Unread**
3. Only notifications with selected read status will be shown

### Combining Filters

You can combine multiple filters:
- Type + Date Range
- Status + Read Status
- Type + Status + Date Range

### Clearing Filters

1. Tap the **Filter** button
2. Tap **Clear All Filters**
3. All notifications will be shown

---

## Understanding Notification Types

### Success ✅
**When to use:** Positive outcomes, completed actions

**Examples:**
- "Your report has been approved"
- "Account verified successfully"
- "Payment processed"

**Sound:** Success tone  
**Priority:** Medium (5-6)

---

### Warning ⚠️
**When to use:** Cautions, potential issues

**Examples:**
- "Approaching a reported hazard"
- "Low battery - save your work"
- "Unusual activity detected"

**Sound:** Warning tone  
**Priority:** Medium-High (6-7)

---

### Alert 🚨
**When to use:** Urgent issues, critical information

**Examples:**
- "Road closed ahead"
- "Emergency maintenance required"
- "Security alert"

**Sound:** Alert tone (loud)  
**Priority:** High (8-10)

---

### Info ℹ️
**When to use:** General information, updates

**Examples:**
- "New feature available"
- "App updated to version 2.0"
- "Tips for using the app"

**Sound:** Default  
**Priority:** Low-Medium (3-5)

---

### System ⚙️
**When to use:** System messages, maintenance

**Examples:**
- "Scheduled maintenance tonight"
- "System update in progress"
- "Service restored"

**Sound:** Default  
**Priority:** Medium (5-6)

---

### User 👤
**When to use:** User interactions, social

**Examples:**
- "Someone commented on your report"
- "New follower"
- "Message received"

**Sound:** Default  
**Priority:** Medium (4-6)

---

### Report 📝
**When to use:** Report status changes

**Examples:**
- "Your report has been verified"
- "Report status updated"
- "Report resolved"

**Sound:** Success or default  
**Priority:** Medium (5-6)

---

### Location Alert 📍
**When to use:** Location-based notifications

**Examples:**
- "Hazard reported 500m from your location"
- "Entering monitored area"
- "Nearby report needs verification"

**Sound:** Alert or warning  
**Priority:** High (7-8)

---

### Submission Status 📋
**When to use:** Form or request status updates

**Examples:**
- "Authority request approved"
- "Form submitted successfully"
- "Application under review"

**Sound:** Success or default  
**Priority:** Medium (5-6)

---

### Promotion 📢
**When to use:** Announcements, features, promotions

**Examples:**
- "New feature: Dark mode"
- "Join our community event"
- "Special offer available"

**Sound:** Default  
**Priority:** Low-Medium (3-5)

---

### Reminder 🔔
**When to use:** Scheduled reminders

**Examples:**
- "Update your profile"
- "Complete your weekly report"
- "Maintenance in 1 hour"

**Sound:** Default  
**Priority:** Medium (5-6)

---

## Notification Sounds and Categories

### Available Sounds

| Sound | Description | Use Case |
|-------|-------------|----------|
| **alert.wav** | Loud, urgent | Critical alerts, emergencies |
| **warning.wav** | Moderate, attention-grabbing | Warnings, cautions |
| **success.wav** | Pleasant, positive | Success messages, completions |
| **default.wav** | Standard notification | General notifications |

### Android Notification Channels

Android groups notifications into channels. Each channel has its own settings:

| Channel | Importance | Sound | Vibration |
|---------|------------|-------|-----------|
| **alert** | High | alert.wav | Yes |
| **warning** | Default | warning.wav | Yes |
| **info** | Low | default.wav | No |
| **success** | Default | success.wav | No |

Users can customize channel settings in their device settings.

### iOS Notification Categories

iOS uses categories to group similar notifications:

- **ALERT_CATEGORY** - Critical alerts
- **WARNING_CATEGORY** - Warnings
- **INFO_CATEGORY** - Information
- **SUCCESS_CATEGORY** - Success messages

---

## Targeting Options

### Single User

**Use when:**
- Sending personal notifications
- Responding to user actions
- User-specific updates

**Example:**
```
Target Type: Single
User ID: abc-123
```

**Result:** Only user abc-123 receives the notification

---

### Multiple Users (Custom)

**Use when:**
- Sending to a specific group
- Notifying nearby users
- Targeting selected users

**Example:**
```
Target Type: Custom
User IDs: [abc-123, def-456, ghi-789]
```

**Result:** Only the specified users receive the notification

---

### Role-Based

**Use when:**
- Sending to all users with specific roles
- Role-specific announcements
- Permission-based notifications

**Example:**
```
Target Type: Role
Roles: [authority, admin]
```

**Result:** All users with authority or admin role receive the notification

---

### Broadcast to All

**Use when:**
- Important system announcements
- App-wide updates
- Emergency notifications

**Example:**
```
Target Type: All
```

**Result:** All registered users receive the notification

**⚠️ Note:** Requires admin or developer role. Use sparingly.

---

## Best Practices

### 1. Choose the Right Type

Match the notification type to the content:
- Use **Alert** for urgent issues
- Use **Success** for positive outcomes
- Use **Info** for general updates

### 2. Write Clear Titles

- Keep titles under 50 characters
- Make them descriptive
- Use action words

**Good:** "Road Hazard Reported Nearby"  
**Bad:** "Notification"

### 3. Provide Context in Messages

- Explain what happened
- Include relevant details
- Add actionable information

**Good:** "A large pothole has been reported on Main Street near Oak Avenue. Tap to view details and navigate."  
**Bad:** "New report"

### 4. Set Appropriate Priorities

- **High (8-10):** Emergencies, critical alerts
- **Medium (5-7):** Important updates, warnings
- **Low (1-4):** General information, promotions

### 5. Use Scheduling Wisely

- Schedule maintenance notifications in advance
- Avoid sending notifications at night (unless urgent)
- Consider user time zones

### 6. Don't Spam Users

- Limit notification frequency
- Combine related notifications
- Respect user preferences

### 7. Include Navigation Data

Add data payload for easy navigation:
```json
{
  "report_id": "abc-123",
  "action": "view_report"
}
```

### 8. Test Before Broadcasting

- Test with a single user first
- Verify content and formatting
- Check on both iOS and Android

### 9. Monitor Delivery

- Check delivery statistics
- Review failed notifications
- Adjust strategy based on engagement

### 10. Respect User Settings

- Users can disable notifications
- Users can customize sounds
- Don't override user preferences

---

## Troubleshooting

### Notification Not Received

**Possible causes:**
1. User has notifications disabled
2. User is not logged in
3. Network connectivity issues
4. OneSignal service issues

**Solutions:**
1. Ask user to check notification settings
2. Verify user is logged in
3. Check network connection
4. Check OneSignal dashboard for errors

---

### Scheduled Notification Not Sent

**Possible causes:**
1. Notification was cancelled
2. Scheduling service (QStash) error
3. Notification was deleted

**Solutions:**
1. Check notification status in the list
2. Look for error messages
3. Reschedule the notification

---

### Cannot Create Notification

**Possible causes:**
1. Insufficient permissions
2. Validation errors
3. Rate limit exceeded

**Solutions:**
1. Verify you have developer or authority role
2. Check all required fields are filled
3. Wait before creating more notifications

---

### Notification Shows as Failed

**Possible causes:**
1. OneSignal API error
2. Invalid user IDs
3. Network timeout

**Solutions:**
1. Check error message in notification details
2. Verify user IDs are correct
3. Try resending the notification

---

### Cannot Delete Notification

**Possible causes:**
1. Notification already sent
2. Insufficient permissions
3. Not the creator

**Solutions:**
1. Sent notifications cannot be deleted (by design)
2. Only creators can delete their notifications
3. Contact an admin for hard delete

---

## FAQ

### Q: Can I edit a notification after sending?

**A:** No, sent notifications are immutable. You can only edit draft or scheduled notifications.

---

### Q: How do I know if a notification was delivered?

**A:** Check the notification details to see delivery statistics including recipient count, successful deliveries, and failed deliveries.

---

### Q: Can I send notifications to users in specific locations?

**A:** Yes, use the Custom targeting option and provide a list of user IDs for users in the target location. You'll need to query users by location first.

---

### Q: What happens if I delete a scheduled notification?

**A:** The notification is cancelled and will not be sent. The cancellation is immediate.

---

### Q: Can users opt out of notifications?

**A:** Yes, users can disable notifications in their device settings. They can also customize which types of notifications they receive.

---

### Q: How many notifications can I send per hour?

**A:** Regular notifications: 100 per hour. Broadcast to all: 10 per hour. These limits prevent spam and ensure system stability.

---

### Q: Can I send notifications with images?

**A:** Currently, the system supports text notifications with custom data. Image support may be added in future updates.

---

### Q: What's the difference between deleting for myself and permanent delete?

**A:** Deleting for yourself removes the notification from your list only. Permanent delete (admin only) removes it for all users.

---

### Q: Can I schedule recurring notifications?

**A:** Not directly. You'll need to create separate scheduled notifications for each occurrence.

---

### Q: How do I send a notification to nearby users?

**A:** 
1. Query users within a specific radius using location services
2. Get their user IDs
3. Create a notification with Custom targeting
4. Provide the list of user IDs

---

### Q: What happens if OneSignal is down?

**A:** The notification will be marked as failed with an error message. You can retry sending once the service is restored.

---

### Q: Can I see who has read my notification?

**A:** Currently, you can see delivery statistics (how many received) but not individual read status for privacy reasons.

---

### Q: How long are notifications stored?

**A:** Notifications are stored indefinitely unless deleted. Users can delete notifications from their own list at any time.

---

### Q: Can I send notifications from the backend/API?

**A:** Yes, developers can use the Serverpod API to send notifications programmatically. See the [API Documentation](./API_DOCUMENTATION.md) for details.

---

### Q: What's a data notification?

**A:** A data notification is a silent notification that delivers data to the app without showing a visible alert. It's used for background updates and synchronization.

---

## Getting Help

### Support Resources

- **API Documentation** - [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Notification Usage Guide** - [NOTIFICATION_USAGE.md](./NOTIFICATION_USAGE.md)
- **OneSignal Setup** - [ONESIGNAL_SETUP.md](./ONESIGNAL_SETUP.md)

### Contact Support

If you need additional help:
1. Check the documentation above
2. Review the FAQ section
3. Contact your system administrator
4. Submit a support ticket

---

## Appendix

### Notification Lifecycle

```
Draft → Scheduled → Sent
  ↓         ↓         ↓
Delete  Cancel    Delivered
```

### Status Transitions

| From | To | Action |
|------|-----|--------|
| Draft | Sent | Update status to 'sent' |
| Draft | Scheduled | Update status to 'scheduled' |
| Draft | Deleted | Delete notification |
| Scheduled | Sent | Automatic at scheduled time |
| Scheduled | Deleted | Cancel and delete |
| Sent | - | Cannot be modified |

### Keyboard Shortcuts (Desktop)

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + N` | Create new notification |
| `Ctrl/Cmd + F` | Open filter menu |
| `Ctrl/Cmd + R` | Mark all as read |
| `Delete` | Delete selected notification |
| `Enter` | Open selected notification |

---

**Last Updated**: 2024-11-25  
**Version**: 2.0.0  
**Maintainer**: Pavra Team

---

## Quick Reference Card

### Creating a Notification

1. Tap **Create** button
2. Fill in **Title** and **Message**
3. Choose **Type**
4. Select **Status** (Sent/Scheduled/Draft)
5. Choose **Target** audience
6. Configure **Sound** and **Priority**
7. Tap **Create Notification**

### Scheduling a Notification

1. Create notification as above
2. Select **Status: Scheduled**
3. Choose **Date and Time**
4. Tap **Create Notification**

### Managing Notifications

- **Mark as read:** Tap notification
- **Mark all as read:** Menu → Mark All as Read
- **Delete:** Swipe left → Delete
- **Filter:** Tap Filter button
- **Search:** Use search bar

### Notification Types Quick Reference

| Icon | Type | Use For |
|------|------|---------|
| ✅ | Success | Positive outcomes |
| ⚠️ | Warning | Cautions |
| 🚨 | Alert | Urgent issues |
| ℹ️ | Info | General info |
| ⚙️ | System | System messages |
| 👤 | User | User interactions |
| 📝 | Report | Report updates |
| 📍 | Location | Location-based |
| 📋 | Submission | Status updates |
| 📢 | Promotion | Announcements |
| 🔔 | Reminder | Reminders |

---

**Need more help?** Check the [API Documentation](./API_DOCUMENTATION.md) or contact support.

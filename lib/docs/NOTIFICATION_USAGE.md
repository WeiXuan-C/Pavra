# Notification System Usage Guide

Quick reference for using the notification system in Pavra.

---

## 🎯 Use Cases

### 1. App Updates & New Features
Send notifications about app updates, new features, or maintenance.

```dart
// Backend
await notificationEndpoint.sendAppUpdateNotification(
  session,
  version: '2.1.0',
  updateMessage: 'Bug fixes and performance improvements',
  isRequired: false,
);
```

### 2. User Activity Notifications
Notify users about actions related to their content.

```dart
// When a report is approved
await notificationEndpoint.sendToUser(
  session,
  userId: reportAuthorId,
  title: 'Report Approved ✅',
  message: 'Your report about road hazard has been approved',
  type: 'success',
  data: {
    'report_id': reportId,
    'action': 'view_report',
  },
);

// When someone comments on their report
await notificationEndpoint.sendToUser(
  session,
  userId: reportAuthorId,
  title: 'New Comment',
  message: 'Someone commented on your report',
  type: 'user',
  data: {
    'report_id': reportId,
    'comment_id': commentId,
  },
);
```

### 3. Location-Based Alerts
Send alerts to users in specific areas.

```dart
// Get users near a location (you need to implement this query)
final nearbyUserIds = await getNearbyUsers(latitude, longitude, radiusKm);

await notificationEndpoint.sendToUsers(
  session,
  userIds: nearbyUserIds,
  title: '⚠️ Safety Alert',
  message: 'A new hazard has been reported near your location',
  type: 'location_alert',
  data: {
    'report_id': reportId,
    'latitude': latitude,
    'longitude': longitude,
  },
);
```

### 4. System Announcements
Broadcast important messages to all users.

```dart
await notificationEndpoint.sendToAll(
  session,
  title: 'Scheduled Maintenance',
  message: 'The app will be under maintenance on Sunday 2AM-4AM',
  type: 'system',
  data: {
    'maintenance_start': '2024-10-27T02:00:00Z',
    'maintenance_end': '2024-10-27T04:00:00Z',
  },
);
```

---

## 📱 Frontend Integration

### Navigate to Notification Screen

```dart
// From anywhere in the app
Navigator.pushNamed(context, AppRoutes.notifications);
```

### Show Notification Badge

```dart
// In your app bar or bottom navigation
Consumer<NotificationProvider>(
  builder: (context, provider, _) {
    return Badge(
      label: Text('${provider.unreadCount}'),
      isLabelVisible: provider.unreadCount > 0,
      child: IconButton(
        icon: Icon(Icons.notifications),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.notifications);
        },
      ),
    );
  },
)
```

### Handle Notification Click

Update `lib/core/services/onesignal_service.dart`:

```dart
void _handleNotificationClick(Map<String, dynamic> data) {
  final action = data['action'] as String?;
  final reportId = data['report_id'] as String?;

  switch (action) {
    case 'view_report':
      if (reportId != null) {
        navigatorKey.currentState?.pushNamed('/report/$reportId');
      }
      break;
    case 'view_map':
      navigatorKey.currentState?.pushNamed(AppRoutes.mapView);
      break;
    default:
      navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
  }
}
```

### Link User on Login

```dart
// In your AuthProvider after successful login
final oneSignal = OneSignalService();
await oneSignal.setExternalUserId(user.id);

// Set user tags for targeting
await oneSignal.setTags({
  'role': user.role,
  'language': user.language,
  'city': user.city,
});
```

### Unlink User on Logout

```dart
// In your AuthProvider logout method
await OneSignalService().removeExternalUserId();
```

---

## 🔔 Notification Types

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| `success` | ✅ check_circle | Green | Successful actions |
| `warning` | ⚠️ warning | Orange | Warnings |
| `alert` | 🚨 error | Red | Critical alerts |
| `info` | ℹ️ info | Blue Grey | General information |
| `system` | ⚙️ settings | Grey | System messages |
| `user` | 👤 person | Blue | User interactions |
| `report` | 📝 report | Deep Orange | Report updates |
| `location_alert` | 📍 location_on | Pink | Location-based alerts |
| `submission_status` | 📋 assignment | Cyan | Submission updates |
| `promotion` | 📢 campaign | Purple | Promotions/announcements |
| `reminder` | 🔔 notifications | Amber | Reminders |

---

## 🎨 Custom Notification Data

You can pass custom data with notifications:

```dart
await notificationEndpoint.sendToUser(
  session,
  userId: userId,
  title: 'Custom Notification',
  message: 'This has custom data',
  type: 'info',
  data: {
    'custom_field_1': 'value1',
    'custom_field_2': 123,
    'custom_object': {
      'nested': 'data',
    },
  },
);
```

Access in frontend:

```dart
// In notification model
final customData = notification.data;
final customField1 = customData?['custom_field_1'];
```

---

## 🧪 Testing Notifications

### Test from Backend

Create a test endpoint:

```dart
// In your backend
Future<void> testNotification(Session session, String userId) async {
  await notificationEndpoint.sendToUser(
    session,
    userId: userId,
    title: 'Test Notification 🧪',
    message: 'This is a test notification from backend',
    type: 'info',
  );
}
```

### Test from OneSignal Dashboard

1. Go to OneSignal dashboard
2. Click **Messages** → **New Push**
3. Select **Send to Test Device**
4. Enter your device's Player ID
5. Send test notification

### Test Locally

```dart
// In your Flutter app (for testing only)
final repository = NotificationRepository();
await repository.createNotification(
  userId: 'your-user-id',
  title: 'Local Test',
  message: 'This is a local test notification',
  type: 'info',
);
```

---

## 📊 Monitoring

### Check Notification Delivery

```dart
// Backend - Get notification details
final notificationId = 'onesignal-notification-id';
final details = await oneSignalService.getNotification(notificationId);
print('Delivered: ${details['successful']}');
print('Failed: ${details['failed']}');
```

### View User's Notifications

```dart
// Frontend
final notifications = await NotificationRepository()
  .getUserNotifications(userId: userId, limit: 50);
```

### Check Unread Count

```dart
final unreadCount = await NotificationRepository()
  .getUnreadCount(userId);
```

---

## 🚀 Best Practices

1. **Don't spam users** - Limit notification frequency
2. **Use appropriate types** - Choose the right notification type
3. **Include actionable data** - Add data for navigation
4. **Test on real devices** - Push notifications don't work on simulators
5. **Handle errors gracefully** - Don't crash if notification fails
6. **Respect user preferences** - Check if notifications are enabled
7. **Use meaningful titles** - Make notifications clear and concise
8. **Localize messages** - Support multiple languages

---

## 🔒 Security

- Never expose OneSignal API Key in frontend
- Use backend to send notifications
- Validate user permissions before sending
- Use RLS policies in Supabase
- Don't include sensitive data in notifications

---

## 📚 Related Files

- `lib/core/services/onesignal_service.dart` - OneSignal SDK wrapper
- `lib/presentation/notification_screen/` - Notification UI
- `lib/data/repositories/notification_repository.dart` - Data access
- `pavra_server/.../endpoints/notification_endpoint.dart` - Backend API
- `lib/docs/ONESIGNAL_SETUP.md` - Setup guide

---

**Last Updated**: 2024-10-21  
**Maintainer**: Pavra Team

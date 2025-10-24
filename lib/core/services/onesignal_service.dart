import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// OneSignal service for push notification management
///
/// Handles initialization, permission requests, and notification events
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;
  String? _playerId;

  /// Get OneSignal Player ID (device token)
  String? get playerId => _playerId;

  /// Initialize OneSignal SDK
  ///
  /// Call this in main.dart after WidgetsFlutterBinding.ensureInitialized()
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null ||
        appId.isEmpty ||
        appId == 'your-onesignal-app-id-here') {
      print('⚠️ OneSignal App ID not configured in .env');
      return;
    }

    try {
      // Initialize OneSignal
      OneSignal.initialize(appId);

      // Request notification permission
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification event handlers
      _setupNotificationHandlers();

      // Get player ID
      _playerId = OneSignal.User.pushSubscription.id;
      print('✓ OneSignal initialized. Player ID: $_playerId');

      _isInitialized = true;
    } catch (e) {
      print('❌ OneSignal initialization failed: $e');
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    // Handle notification opened (user tapped on notification)
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.notificationId}');
      // Handle navigation based on notification data
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationClick(data);
      }
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Notification received in foreground: ${event.notification.title}');
      // You can prevent the notification from displaying by calling:
      // event.preventDefault();
    });

    // Handle permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      print('Notification permission state: $state');
    });

    // Handle subscription changes
    OneSignal.User.pushSubscription.addObserver((state) {
      _playerId = state.current.id;
      print('Push subscription changed. New Player ID: $_playerId');
    });
  }

  /// Handle notification click and navigate to appropriate screen
  void _handleNotificationClick(Map<String, dynamic> data) {
    // Example: Navigate based on notification type
    final type = data['type'] as String?;
    final targetId = data['target_id'] as String?;

    print('Notification data: type=$type, targetId=$targetId');
  }

  /// Set external user ID (link OneSignal with your user ID)
  Future<void> setExternalUserId(String userId) async {
    if (!_isInitialized) return;

    try {
      OneSignal.login(userId);
      print('✓ OneSignal external user ID set: $userId');
    } catch (e) {
      print('❌ Failed to set external user ID: $e');
    }
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    if (!_isInitialized) return;

    try {
      OneSignal.logout();
      print('✓ OneSignal external user ID removed');
    } catch (e) {
      print('❌ Failed to remove external user ID: $e');
    }
  }

  /// Set notification tags (for targeting)
  Future<void> setTags(Map<String, String> tags) async {
    if (!_isInitialized) return;

    try {
      OneSignal.User.addTags(tags);
      print('✓ OneSignal tags set: $tags');
    } catch (e) {
      print('❌ Failed to set tags: $e');
    }
  }

  /// Remove notification tags
  Future<void> removeTags(List<String> keys) async {
    if (!_isInitialized) return;

    try {
      OneSignal.User.removeTags(keys);
      print('✓ OneSignal tags removed: $keys');
    } catch (e) {
      print('❌ Failed to remove tags: $e');
    }
  }

  /// Check if notifications are enabled
  bool get areNotificationsEnabled {
    return OneSignal.Notifications.permission;
  }

  /// Prompt user to enable notifications
  Future<bool> promptForPushNotifications() async {
    if (!_isInitialized) return false;

    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      print('❌ Failed to request notification permission: $e');
      return false;
    }
  }
}

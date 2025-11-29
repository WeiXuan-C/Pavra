import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'audio_alert_service.dart';

/// Type definition for data notification action handlers
typedef DataNotificationActionHandler = Future<void> Function(Map<String, dynamic> data);

/// OneSignal service for push notification management
///
/// Handles initialization, permission requests, and notification events
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;
  String? _playerId;
  int _initializationAttempts = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Global navigator key for navigation from background
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Action handler registry for data notifications
  final Map<String, DataNotificationActionHandler> _actionHandlers = {};

  /// Get OneSignal Player ID (device token)
  String? get playerId => _playerId;

  /// Check if OneSignal is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize OneSignal SDK with retry logic
  ///
  /// Call this in main.dart after WidgetsFlutterBinding.ensureInitialized()
  /// Implements retry logic for failed initialization attempts
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null ||
        appId.isEmpty ||
        appId == 'your-onesignal-app-id-here') {
      debugPrint('⚠️ OneSignal: App ID not configured');
      return;
    }

    while (_initializationAttempts < _maxRetries && !_isInitialized) {
      _initializationAttempts++;
      
      try {
        debugPrint('🔄 OneSignal: Initialization attempt $_initializationAttempts/$_maxRetries');
        
        // Initialize OneSignal
        OneSignal.initialize(appId);

        // Request notification permission
        await OneSignal.Notifications.requestPermission(true);

        // Set up notification event handlers
        _setupNotificationHandlers();

        // Get player ID
        _playerId = OneSignal.User.pushSubscription.id;

        _isInitialized = true;
        debugPrint('✅ OneSignal: Initialized successfully (Player ID: $_playerId)');
        
        return;
      } catch (e, stackTrace) {
        debugPrint('❌ OneSignal: Initialization attempt $_initializationAttempts failed: $e');
        debugPrint('Stack trace: $stackTrace');
        
        if (_initializationAttempts < _maxRetries) {
          debugPrint('⏳ OneSignal: Retrying in ${_retryDelay.inSeconds} seconds...');
          await Future.delayed(_retryDelay);
        } else {
          debugPrint('❌ OneSignal: Max retry attempts reached. Initialization failed.');
          rethrow;
        }
      }
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    // Handle notification opened (user tapped on notification)
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('🔔 OneSignal: Notification clicked: ${event.notification.notificationId}');
      // Handle navigation based on notification data
      final data = event.notification.additionalData;
      if (data != null) {
        handleNotificationClick(data);
      }
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('🔔 OneSignal: Notification received in foreground: ${event.notification.title}');
      
      // Check if this is a data notification (silent notification)
      final notification = event.notification;
      final isDataNotification = (notification.title == null || notification.title!.isEmpty) &&
                                  (notification.body == null || notification.body!.isEmpty);
      
      if (isDataNotification) {
        // Process data notification without displaying
        debugPrint('🔔 OneSignal: Processing data notification');
        final data = notification.additionalData;
        if (data != null) {
          handleDataNotification(data);
        }
        // Prevent the notification from displaying
        event.preventDefault();
      } else {
        // Handle regular foreground notification
        handleForegroundNotification(event);
      }
    });

    // Handle permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint('🔔 OneSignal: Notification permission state: $state');
    });

    // Handle subscription changes
    OneSignal.User.pushSubscription.addObserver((state) {
      _playerId = state.current.id;
      debugPrint('🔔 OneSignal: Push subscription changed. New Player ID: $_playerId');
    });
  }

  /// Handle notification click and navigate to appropriate screen
  /// 
  /// Extracts navigation data from notification payload and routes to the correct screen
  /// Supports: report detail, user profile, and default home navigation
  void handleNotificationClick(Map<String, dynamic> data) {
    try {
      debugPrint('🔔 OneSignal: Processing notification click with data: $data');
      
      final type = data['type'] as String?;
      final reportId = data['report_id'] as String?;
      final userId = data['user_id'] as String?;

      // Extract route from notification data
      String? route;
      Object? arguments;

      if (type == 'report' && reportId != null) {
        // Navigate to report detail screen
        route = '/report-detail';
        arguments = {'reportId': reportId};
        debugPrint('🔔 OneSignal: Navigating to report detail: $reportId');
      } else if (type == 'user' && userId != null) {
        // Navigate to user profile screen
        route = '/profile';
        arguments = {'userId': userId};
        debugPrint('🔔 OneSignal: Navigating to user profile: $userId');
      } else {
        // Default navigation to home
        route = '/home';
        debugPrint('🔔 OneSignal: Navigating to home (default)');
      }

      // Navigate using the global navigator key
      navigateToScreen(route, arguments);
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Error handling notification click: $e');
      debugPrint('Stack trace: $stackTrace');
      // Navigate to home as fallback
      navigateToScreen('/home', null);
    }
  }

  /// Handle foreground notification display
  /// 
  /// Shows in-app notification banner when notification is received while app is active
  /// Also plays notification sound for important alerts
  void handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    try {
      debugPrint('🔔 OneSignal: Displaying foreground notification');
      
      // Play notification sound
      _playNotificationSound(event.notification);
      
      // Allow the notification to display
      // To prevent display, call: event.preventDefault();
      
      // Show in-app banner using SnackBar
      final context = navigatorKey.currentContext;
      if (context != null) {
        final notification = event.notification;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? 'Notification',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (notification.body != null) ...[
                  const SizedBox(height: 4),
                  Text(notification.body!),
                ],
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                final data = notification.additionalData;
                if (data != null) {
                  handleNotificationClick(data);
                }
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Error handling foreground notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Play notification sound based on notification type and priority
  void _playNotificationSound(OSNotification notification) {
    try {
      final data = notification.additionalData;
      final soundType = data?['sound'] as String?;
      final priority = data?['priority'] as int?;
      
      // Determine if we should play sound
      bool shouldPlaySound = true;
      
      // Check notification type for sound decision
      if (soundType == 'none' || soundType == 'silent') {
        shouldPlaySound = false;
      }
      
      if (shouldPlaySound) {
        // Import and use AudioAlertService
        final audioService = AudioAlertService();
        
        // Play sound based on priority or type
        if (priority != null && priority >= 8) {
          // High priority - play alert sound
          audioService.playAlertSound();
          debugPrint('🔊 OneSignal: Playing alert sound for high priority notification');
        } else if (soundType == 'alert' || soundType == 'warning') {
          // Alert/Warning type - play alert sound
          audioService.playAlertSound();
          debugPrint('🔊 OneSignal: Playing alert sound for $soundType notification');
        } else {
          // Normal notification - play default sound (or use lighter haptic)
          audioService.playNotificationSound();
          debugPrint('🔊 OneSignal: Playing notification sound');
        }
      }
    } catch (e) {
      debugPrint('⚠️ OneSignal: Error playing notification sound: $e');
      // Don't throw - sound playback failure shouldn't break notifications
    }
  }

  /// Navigate to a specific screen with optional parameters
  void navigateToScreen(String route, Object? arguments) {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamed(route, arguments: arguments);
        debugPrint('✅ OneSignal: Navigation successful to $route');
      } else {
        debugPrint('⚠️ OneSignal: Navigator context not available');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Navigation error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Set external user ID (link OneSignal with your user ID)
  /// 
  /// Handles 409 conflict errors when the external ID is already claimed
  /// by logging out first and then logging in again (logout-then-login pattern)
  Future<void> setExternalUserId(String userId) async {
    if (!_isInitialized) {
      debugPrint('⚠️ OneSignal: Cannot set external user ID - not initialized');
      return;
    }

    try {
      debugPrint('🔄 OneSignal: Setting external user ID: $userId');
      
      // First logout to clear any existing external ID association
      // This prevents 409 conflicts when the ID is already claimed
      try {
        await OneSignal.logout();
        debugPrint('✅ OneSignal: Logged out successfully');
        
        // Longer delay to ensure logout completes on server
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (logoutError) {
        debugPrint('⚠️ OneSignal: Logout error (continuing): $logoutError');
        // Continue even if logout fails - user might not be logged in
      }
      
      // Then login with the new user ID
      OneSignal.login(userId);
      debugPrint('✅ OneSignal: External user ID set: $userId');
      
      // Wait a bit to ensure login completes
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Failed to set external user ID: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // If we get a 409 error, force logout and retry with longer delay
      if (e.toString().contains('409') || e.toString().contains('claimed')) {
        try {
          debugPrint('🔄 OneSignal: Detected 409 conflict, forcing logout and retry...');
          
          // Force logout with longer delay
          await OneSignal.logout();
          await Future.delayed(const Duration(seconds: 2));
          
          // Retry login
          OneSignal.login(userId);
          debugPrint('✅ OneSignal: External user ID set after conflict resolution: $userId');
          
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (retryError) {
          debugPrint('❌ OneSignal: Failed after conflict resolution: $retryError');
          // Don't rethrow - this is non-critical for app functionality
        }
      }
    }
  }

  /// Remove external user ID (on logout)
  /// 
  /// Ensures clean logout flow by removing the external user ID association
  Future<void> removeExternalUserId() async {
    if (!_isInitialized) {
      debugPrint('⚠️ OneSignal: Cannot remove external user ID - not initialized');
      return;
    }

    try {
      debugPrint('🔄 OneSignal: Removing external user ID');
      OneSignal.logout();
      debugPrint('✅ OneSignal: External user ID removed');
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Failed to remove external user ID: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Set notification tags (for targeting)
  Future<void> setTags(Map<String, String> tags) async {
    if (!_isInitialized) {
      debugPrint('⚠️ OneSignal: Cannot set tags - not initialized');
      return;
    }

    try {
      OneSignal.User.addTags(tags);
      debugPrint('✅ OneSignal: Tags set: $tags');
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Failed to set tags: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Remove notification tags
  Future<void> removeTags(List<String> keys) async {
    if (!_isInitialized) {
      debugPrint('⚠️ OneSignal: Cannot remove tags - not initialized');
      return;
    }

    try {
      OneSignal.User.removeTags(keys);
      debugPrint('✅ OneSignal: Tags removed: $keys');
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Failed to remove tags: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Check if notifications are enabled
  bool get areNotificationsEnabled {
    return OneSignal.Notifications.permission;
  }

  /// Prompt user to enable notifications
  Future<bool> promptForPushNotifications() async {
    if (!_isInitialized) {
      debugPrint('⚠️ OneSignal: Cannot request permission - not initialized');
      return false;
    }

    try {
      final result = await OneSignal.Notifications.requestPermission(true);
      debugPrint('✅ OneSignal: Permission request result: $result');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ OneSignal: Failed to request notification permission: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Register an action handler for data notifications
  /// 
  /// Action handlers are invoked when a data notification with a matching action type is received
  /// 
  /// Example:
  /// ```dart
  /// oneSignalService.registerActionHandler('refresh_data', (data) async {
  ///   await refreshAppData();
  /// });
  /// ```
  void registerActionHandler(String actionType, DataNotificationActionHandler handler) {
    _actionHandlers[actionType] = handler;
    debugPrint('✅ OneSignal: Registered action handler for type: $actionType');
  }

  /// Unregister an action handler
  void unregisterActionHandler(String actionType) {
    _actionHandlers.remove(actionType);
    debugPrint('✅ OneSignal: Unregistered action handler for type: $actionType');
  }

  /// Handle data notification (silent notification with data payload)
  /// 
  /// Processes data notifications without displaying a visible notification
  /// Executes the corresponding action handler if one is registered
  /// Logs errors without affecting the user experience
  Future<void> handleDataNotification(Map<String, dynamic> data) async {
    try {
      debugPrint('🔔 OneSignal: Processing data notification with data: $data');
      
      // Extract action type from data
      final actionType = data['action_type'] as String?;
      
      if (actionType == null || actionType.isEmpty) {
        debugPrint('⚠️ OneSignal: Data notification has no action_type');
        return;
      }

      // Look up the action handler
      final handler = _actionHandlers[actionType];
      
      if (handler == null) {
        debugPrint('⚠️ OneSignal: No handler registered for action type: $actionType');
        return;
      }

      // Execute the action handler
      debugPrint('🔄 OneSignal: Executing action handler for type: $actionType');
      await handler(data);
      debugPrint('✅ OneSignal: Action handler completed successfully for type: $actionType');
      
    } catch (e, stackTrace) {
      // Log error without affecting user experience
      debugPrint('❌ OneSignal: Error processing data notification: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Log to error tracking service if available
      // Example: Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Register default action handlers
  /// 
  /// Call this method to register common action handlers used by the app
  void registerDefaultActionHandlers() {
    // Example: Refresh data handler
    registerActionHandler('refresh_data', (data) async {
      debugPrint('🔄 OneSignal: Refreshing app data');
      // Implement data refresh logic here
      // Example: await dataService.refreshAll();
    });

    // Example: Sync handler
    registerActionHandler('sync', (data) async {
      debugPrint('🔄 OneSignal: Syncing data');
      // Implement sync logic here
      // Example: await syncService.sync();
    });

    // Example: Update cache handler
    registerActionHandler('update_cache', (data) async {
      debugPrint('🔄 OneSignal: Updating cache');
      final cacheKey = data['cache_key'] as String?;
      if (cacheKey != null) {
        // Implement cache update logic here
        // Example: await cacheService.invalidate(cacheKey);
      }
    });

    // Example: Background task handler
    registerActionHandler('background_task', (data) async {
      debugPrint('🔄 OneSignal: Executing background task');
      final taskId = data['task_id'] as String?;
      if (taskId != null) {
        // Implement background task logic here
        // Example: await taskService.execute(taskId);
      }
    });

    debugPrint('✅ OneSignal: Default action handlers registered');
  }
}

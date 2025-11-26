import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../utils/retry_helper.dart';

/// OneSignal service for sending push notifications
///
/// Uses OneSignal REST API to send notifications to users
/// Includes comprehensive error handling, retry logic, and structured logging
class OneSignalService {
  static final _log = Logger('OneSignalService');

  final String appId;
  final String apiKey;
  final String apiUrl;
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const int initialRetryDelay = 1000; // 1 second
  static const int maxRetryDelay = 10000; // 10 seconds

  OneSignalService({
    required this.appId,
    required this.apiKey,
    this.apiUrl = 'https://api.onesignal.com/notifications',
  }) {
    _log.info('OneSignalService initialized (App ID: ${appId.substring(0, 8)}...)');
  }

  /// Send notification to specific user by external user ID
  ///
  /// [userId] - Your app's user ID (set via OneSignal.login())
  /// [title] - Notification title
  /// [message] - Notification message
  /// [data] - Additional data to send with notification
  /// [sound] - Custom sound file name (without extension)
  /// [category] - Android notification channel ID
  /// [priority] - Notification priority (1-10, default 5)
  ///
  /// Includes retry logic with exponential backoff for transient failures
  Future<Map<String, dynamic>> sendToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  }) async {
    _log.info('📤 Sending notification to user: $userId');
    _log.fine('   Title: $title');
    _log.fine('   Message: $message');
    _log.fine('   Sound: $sound, Category: $category, Priority: $priority');

    int attemptCount = 0;

    try {
      return await RetryHelper.execute(
        operation: () async {
          final payload = {
            'app_id': appId,
            'include_aliases': {
              'external_id': [userId],
            },
            'target_channel': 'push',
            'headings': {'en': title},
            'contents': {'en': message},
            if (data != null) 'data': data,
            if (sound != null) 'android_sound': sound,
            if (sound != null) 'ios_sound': '$sound.wav',
            if (category != null) 'android_channel_id': category,
            if (priority != null) 'priority': priority,
          };

          _log.fine('📡 Making OneSignal API request...');
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $apiKey',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final result = jsonDecode(response.body) as Map<String, dynamic>;
            final notificationId = result['id'] as String?;
            final recipients = result['recipients'] as int? ?? 0;
            
            _log.info('✅ Notification sent successfully');
            _log.info('   OneSignal ID: $notificationId');
            _log.info('   Recipients: $recipients');
            _log.fine('   Full response: $result');
            
            return result;
          } else {
            final errorBody = response.body;
            _log.warning('❌ OneSignal API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
              'OneSignal API error ${response.statusCode}: $errorBody',
            );
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: RetryHelper.isRetryableOneSignalError,
        onRetry: (attempt, error) {
          attemptCount = attempt;
          _log.warning('🔄 Retrying notification send (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to send notification to user $userId after $maxRetryAttempts attempts');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      
      // Store attempt count and error for alerting
      if (attemptCount >= maxRetryAttempts) {
        _log.severe('⚠️  REPEATED FAILURE: $attemptCount attempts exhausted');
      }
      
      rethrow;
    }
  }

  /// Send notification to multiple users
  ///
  /// [userIds] - List of user IDs
  /// [title] - Notification title
  /// [message] - Notification message
  /// [data] - Additional data
  /// [sound] - Custom sound file name (without extension)
  /// [category] - Android notification channel ID
  /// [priority] - Notification priority (1-10, default 5)
  ///
  /// Includes retry logic with exponential backoff for transient failures
  Future<Map<String, dynamic>> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  }) async {
    _log.info('📤 Sending notification to ${userIds.length} users');
    _log.fine('   Title: $title');
    _log.fine('   Message: $message');
    _log.fine('   User IDs: ${userIds.take(5).join(", ")}${userIds.length > 5 ? "..." : ""}');

    try {
      return await RetryHelper.execute(
        operation: () async {
          final payload = {
            'app_id': appId,
            'include_aliases': {
              'external_id': userIds,
            },
            'target_channel': 'push',
            'headings': {'en': title},
            'contents': {'en': message},
            if (data != null) 'data': data,
            if (sound != null) 'android_sound': sound,
            if (sound != null) 'ios_sound': '$sound.wav',
            if (category != null) 'android_channel_id': category,
            if (priority != null) 'priority': priority,
          };

          _log.fine('📡 Making OneSignal API request...');
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $apiKey',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final result = jsonDecode(response.body) as Map<String, dynamic>;
            final notificationId = result['id'] as String?;
            final recipients = result['recipients'] as int? ?? 0;
            
            _log.info('✅ Notification sent successfully');
            _log.info('   OneSignal ID: $notificationId');
            _log.info('   Recipients: $recipients/${userIds.length}');
            
            return result;
          } else {
            final errorBody = response.body;
            _log.warning('❌ OneSignal API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
              'OneSignal API error ${response.statusCode}: $errorBody',
            );
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: RetryHelper.isRetryableOneSignalError,
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying notification send (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to send notification to ${userIds.length} users after $maxRetryAttempts attempts');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send notification to all users
  ///
  /// [title] - Notification title
  /// [message] - Notification message
  /// [data] - Additional data
  /// [sound] - Custom sound file name (without extension)
  /// [category] - Android notification channel ID
  /// [priority] - Notification priority (1-10, default 5)
  ///
  /// Includes retry logic with exponential backoff for transient failures
  Future<Map<String, dynamic>> sendToAll({
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  }) async {
    _log.info('📤 Sending notification to ALL users (broadcast)');
    _log.fine('   Title: $title');
    _log.fine('   Message: $message');
    _log.warning('⚠️  Broadcasting to all users - use with caution!');

    try {
      return await RetryHelper.execute(
        operation: () async {
          final payload = {
            'app_id': appId,
            'included_segments': ['All'],
            'headings': {'en': title},
            'contents': {'en': message},
            if (data != null) 'data': data,
            if (sound != null) 'android_sound': sound,
            if (sound != null) 'ios_sound': '$sound.wav',
            if (category != null) 'android_channel_id': category,
            if (priority != null) 'priority': priority,
          };

          _log.fine('📡 Making OneSignal API request...');
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $apiKey',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final result = jsonDecode(response.body) as Map<String, dynamic>;
            final notificationId = result['id'] as String?;
            final recipients = result['recipients'] as int? ?? 0;
            
            _log.info('✅ Broadcast notification sent successfully');
            _log.info('   OneSignal ID: $notificationId');
            _log.info('   Recipients: $recipients');
            
            return result;
          } else {
            final errorBody = response.body;
            _log.warning('❌ OneSignal API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
              'OneSignal API error ${response.statusCode}: $errorBody',
            );
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: RetryHelper.isRetryableOneSignalError,
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying broadcast notification (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to send broadcast notification after $maxRetryAttempts attempts');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send notification with filters
  ///
  /// [title] - Notification title
  /// [message] - Notification message
  /// [filters] - OneSignal filters (see OneSignal docs)
  /// [data] - Additional data
  /// [sound] - Custom sound file name (without extension)
  /// [category] - Android notification channel ID
  /// [priority] - Notification priority (1-10, default 5)
  Future<Map<String, dynamic>> sendWithFilters({
    required String title,
    required String message,
    required List<Map<String, dynamic>> filters,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
    int? priority,
  }) async {
    try {
      final payload = {
        'app_id': appId,
        'filters': filters,
        'headings': {'en': title},
        'contents': {'en': message},
        if (data != null) 'data': data,
        if (sound != null) 'android_sound': sound,
        if (sound != null) 'ios_sound': '$sound.wav',
        if (category != null) 'android_channel_id': category,
        if (priority != null) 'priority': priority,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _log.info('✓ Notification sent with filters: ${result['id']}');
        return result;
      } else {
        _log.warning('❌ Failed to send notification: ${response.body}');
        throw Exception('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('❌ Error sending notification: $e');
      rethrow;
    }
  }

  /// Send data notification (silent notification with no visible alert)
  ///
  /// [userIds] - List of user IDs to send to
  /// [data] - Data payload to send
  ///
  /// Includes retry logic with exponential backoff for transient failures
  Future<Map<String, dynamic>> sendDataNotification({
    required List<String> userIds,
    required Map<String, dynamic> data,
  }) async {
    _log.info('📤 Sending data notification (silent) to ${userIds.length} users');
    _log.fine('   Data: $data');

    try {
      return await RetryHelper.execute(
        operation: () async {
          final payload = {
            'app_id': appId,
            'include_aliases': {
              'external_id': userIds,
            },
            'target_channel': 'push',
            'data': data,
            'content_available': true,
            'android_background_data': true,
            'ios_badgeType': 'None',
            'ios_badgeCount': 0,
          };

          _log.fine('📡 Making OneSignal API request...');
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $apiKey',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final result = jsonDecode(response.body) as Map<String, dynamic>;
            final notificationId = result['id'] as String?;
            final recipients = result['recipients'] as int? ?? 0;
            
            _log.info('✅ Data notification sent successfully');
            _log.info('   OneSignal ID: $notificationId');
            _log.info('   Recipients: $recipients/${userIds.length}');
            
            return result;
          } else {
            final errorBody = response.body;
            _log.warning('❌ OneSignal API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
              'OneSignal API error ${response.statusCode}: $errorBody',
            );
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: RetryHelper.isRetryableOneSignalError,
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying data notification send (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to send data notification after $maxRetryAttempts attempts');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Schedule a notification to be sent at a specific time
  ///
  /// [userIds] - List of user IDs to send to
  /// [title] - Notification title
  /// [message] - Notification message
  /// [sendAt] - DateTime when notification should be sent
  /// [data] - Additional data
  /// [sound] - Custom sound file name (without extension)
  /// [category] - Android notification channel ID
  Future<Map<String, dynamic>> scheduleNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required DateTime sendAt,
    Map<String, dynamic>? data,
    String? sound,
    String? category,
  }) async {
    try {
      // Convert DateTime to ISO 8601 string for OneSignal
      final sendAfter = sendAt.toUtc().toIso8601String();

      final payload = {
        'app_id': appId,
        'include_aliases': {
          'external_id': userIds,
        },
        'target_channel': 'push',
        'headings': {'en': title},
        'contents': {'en': message},
        'send_after': sendAfter,
        if (data != null) 'data': data,
        if (sound != null) 'android_sound': sound,
        if (sound != null) 'ios_sound': '$sound.wav',
        if (category != null) 'android_channel_id': category,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _log.info(
            '✓ Notification scheduled for ${userIds.length} users at $sendAfter: ${result['id']}');
        return result;
      } else {
        _log.warning('❌ Failed to schedule notification: ${response.body}');
        throw Exception(
            'Failed to schedule notification: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  ///
  /// [oneSignalNotificationId] - The OneSignal notification ID to cancel
  ///
  /// Handles cancellation errors gracefully. If the notification doesn't exist
  /// or has already been sent, logs a warning but doesn't throw an exception.
  /// Includes retry logic for transient failures.
  Future<void> cancelScheduledNotification(
      String oneSignalNotificationId) async {
    _log.info('🗑️  Cancelling scheduled notification: $oneSignalNotificationId');

    try {
      await RetryHelper.execute(
        operation: () async {
          _log.fine('📡 Making OneSignal API request to cancel notification...');
          final response = await http.delete(
            Uri.parse('$apiUrl/$oneSignalNotificationId?app_id=$appId'),
            headers: {
              'Authorization': 'Basic $apiKey',
            },
          );

          if (response.statusCode == 200) {
            _log.info('✅ Notification cancelled successfully: $oneSignalNotificationId');
            return;
          } else if (response.statusCode == 404) {
            // Notification doesn't exist or already sent - log but don't throw
            _log.warning(
                '⚠️  Notification not found or already sent: $oneSignalNotificationId');
            return; // Don't retry 404 errors
          } else {
            final errorBody = response.body;
            _log.warning('❌ OneSignal API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
                'OneSignal API error ${response.statusCode}: $errorBody');
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: (error) {
          // Don't retry 404 errors
          if (error.toString().contains('404')) {
            return false;
          }
          return RetryHelper.isRetryableOneSignalError(error);
        },
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying notification cancellation (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      // If it's a 404, don't treat it as a fatal error
      if (e.toString().contains('404')) {
        _log.warning('⚠️  Notification not found or already sent: $oneSignalNotificationId');
        return;
      }
      
      _log.severe('❌ Failed to cancel notification after $maxRetryAttempts attempts');
      _log.severe('   Notification ID: $oneSignalNotificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get notification status and details
  ///
  /// [oneSignalNotificationId] - The OneSignal notification ID
  ///
  /// Returns notification details including delivery status, recipient counts,
  /// and other metadata from OneSignal.
  /// Includes retry logic for transient failures.
  Future<Map<String, dynamic>> getNotificationStatus(
      String oneSignalNotificationId) async {
    _log.info('📊 Fetching notification status: $oneSignalNotificationId');

    try {
      return await RetryHelper.execute(
        operation: () async {
          _log.fine('📡 Making OneSignal API request...');
          final response = await http.get(
            Uri.parse('$apiUrl/$oneSignalNotificationId?app_id=$appId'),
            headers: {
              'Authorization': 'Basic $apiKey',
            },
          );

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body) as Map<String, dynamic>;
            
            _log.info('✅ Retrieved notification status successfully');
            _log.fine('   Status: ${result['completed_at'] != null ? "Completed" : "Pending"}');
            _log.fine('   Recipients: ${result['recipients']}');
            _log.fine('   Successful: ${result['successful']}');
            
            return result;
          } else {
            final errorBody = response.body;
            _log.warning('❌ OneSignal API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
                'OneSignal API error ${response.statusCode}: $errorBody');
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: RetryHelper.isRetryableOneSignalError,
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying status fetch (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to get notification status after $maxRetryAttempts attempts');
      _log.severe('   Notification ID: $oneSignalNotificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get delivery statistics for a notification
  ///
  /// [oneSignalNotificationId] - The OneSignal notification ID
  ///
  /// Returns parsed delivery statistics including:
  /// - recipients_count: Total number of recipients
  /// - successful_deliveries: Number of successful deliveries
  /// - failed_deliveries: Number of failed deliveries
  /// - converted: Number of users who opened the notification
  ///
  /// Includes comprehensive error handling and logging
  Future<Map<String, dynamic>> getDeliveryStats(
      String oneSignalNotificationId) async {
    _log.info('📊 Fetching delivery statistics: $oneSignalNotificationId');

    try {
      final notificationData =
          await getNotificationStatus(oneSignalNotificationId);

      // Parse OneSignal response for delivery statistics
      final recipientsCount = notificationData['recipients'] as int? ?? 0;
      final successful = notificationData['successful'] as int? ?? 0;
      final failed = notificationData['failed'] as int? ?? 0;
      final converted = notificationData['converted'] as int? ?? 0;
      final errored = notificationData['errored'] as int? ?? 0;
      final queued = notificationData['queued'] as int? ?? 0;
      final remaining = notificationData['remaining'] as int? ?? 0;

      final stats = {
        'recipients_count': recipientsCount,
        'successful_deliveries': successful,
        'failed_deliveries': failed + errored,
        'converted': converted,
        'queued': queued,
        'remaining': remaining,
      };

      // Calculate success rate
      final successRate = recipientsCount > 0
          ? (successful / recipientsCount * 100).toStringAsFixed(1)
          : '0.0';

      _log.info('✅ Delivery statistics retrieved successfully');
      _log.info('   Recipients: $recipientsCount');
      _log.info('   Successful: $successful ($successRate%)');
      _log.info('   Failed: ${failed + errored}');
      _log.info('   Converted: $converted');
      if (queued > 0 || remaining > 0) {
        _log.info('   Queued: $queued, Remaining: $remaining');
      }

      return stats;
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to get delivery statistics');
      _log.severe('   Notification ID: $oneSignalNotificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}

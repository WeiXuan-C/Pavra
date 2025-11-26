import 'supabase_service.dart';

/// Service for implementing rate limiting on notification operations
///
/// Prevents spam and abuse by limiting the number of notifications
/// a user can create within a time window
class RateLimitingService {
  final SupabaseService _supabase = SupabaseService.instance;

  /// Maximum notifications per user per hour
  static const int maxNotificationsPerHour = 100;

  /// Maximum notifications per user per day
  static const int maxNotificationsPerDay = 500;

  /// Maximum notifications per user per minute (for burst protection)
  static const int maxNotificationsPerMinute = 10;

  /// Maximum broadcast notifications per user per day
  static const int maxBroadcastsPerDay = 10;

  /// Check if user has exceeded rate limit for notification creation
  ///
  /// Returns error message if rate limit exceeded, null if within limits
  Future<String?> checkNotificationRateLimit(
    String userId, {
    bool isBroadcast = false,
  }) async {
    try {
      final now = DateTime.now();

      // Check minute limit (burst protection)
      final oneMinuteAgo = now.subtract(Duration(minutes: 1));
      final minuteCount = await _getNotificationCount(
        userId,
        startTime: oneMinuteAgo,
      );

      if (minuteCount >= maxNotificationsPerMinute) {
        return 'Rate limit exceeded: Maximum $maxNotificationsPerMinute notifications per minute. Please wait before creating more notifications.';
      }

      // Check hourly limit
      final oneHourAgo = now.subtract(Duration(hours: 1));
      final hourlyCount = await _getNotificationCount(
        userId,
        startTime: oneHourAgo,
      );

      if (hourlyCount >= maxNotificationsPerHour) {
        return 'Rate limit exceeded: Maximum $maxNotificationsPerHour notifications per hour. Please try again later.';
      }

      // Check daily limit
      final oneDayAgo = now.subtract(Duration(days: 1));
      final dailyCount = await _getNotificationCount(
        userId,
        startTime: oneDayAgo,
      );

      if (dailyCount >= maxNotificationsPerDay) {
        return 'Rate limit exceeded: Maximum $maxNotificationsPerDay notifications per day. Please try again tomorrow.';
      }

      // Check broadcast limit (stricter for broadcasts)
      if (isBroadcast) {
        final broadcastCount = await _getBroadcastCount(
          userId,
          startTime: oneDayAgo,
        );

        if (broadcastCount >= maxBroadcastsPerDay) {
          return 'Rate limit exceeded: Maximum $maxBroadcastsPerDay broadcast notifications per day. Please try again tomorrow.';
        }
      }

      return null; // Within limits
    } catch (e) {
      // If we can't check rate limits, allow the operation but log the error
      print('⚠️ Error checking rate limit: $e');
      return null;
    }
  }

  /// Get notification count for user within time window
  Future<int> _getNotificationCount(
    String userId, {
    required DateTime startTime,
  }) async {
    try {
      final notifications = await _supabase.select(
        'notifications',
        filters: {
          'created_by': userId,
        },
      );

      // Filter by created_at in memory (Supabase doesn't support >= in filters)
      final filteredNotifications = notifications.where((notification) {
        final createdAt = DateTime.parse(notification['created_at'] as String);
        return createdAt.isAfter(startTime) || createdAt.isAtSameMomentAs(startTime);
      }).toList();

      return filteredNotifications.length;
    } catch (e) {
      print('⚠️ Error getting notification count: $e');
      return 0;
    }
  }

  /// Get broadcast notification count for user within time window
  Future<int> _getBroadcastCount(
    String userId, {
    required DateTime startTime,
  }) async {
    try {
      final notifications = await _supabase.select(
        'notifications',
        filters: {
          'created_by': userId,
          'target_type': 'all',
        },
      );

      // Filter by created_at in memory
      final filteredNotifications = notifications.where((notification) {
        final createdAt = DateTime.parse(notification['created_at'] as String);
        return createdAt.isAfter(startTime) || createdAt.isAtSameMomentAs(startTime);
      }).toList();

      return filteredNotifications.length;
    } catch (e) {
      print('⚠️ Error getting broadcast count: $e');
      return 0;
    }
  }

  /// Get remaining notifications for user in current hour
  Future<int> getRemainingNotificationsThisHour(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      final hourlyCount = await _getNotificationCount(
        userId,
        startTime: oneHourAgo,
      );

      return maxNotificationsPerHour - hourlyCount;
    } catch (e) {
      print('⚠️ Error getting remaining notifications: $e');
      return maxNotificationsPerHour;
    }
  }

  /// Get remaining notifications for user in current day
  Future<int> getRemainingNotificationsToday(String userId) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(Duration(days: 1));
      final dailyCount = await _getNotificationCount(
        userId,
        startTime: oneDayAgo,
      );

      return maxNotificationsPerDay - dailyCount;
    } catch (e) {
      print('⚠️ Error getting remaining notifications: $e');
      return maxNotificationsPerDay;
    }
  }

  /// Get API usage statistics for user
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    try {
      final now = DateTime.now();

      // Get counts for different time windows
      final oneMinuteAgo = now.subtract(Duration(minutes: 1));
      final oneHourAgo = now.subtract(Duration(hours: 1));
      final oneDayAgo = now.subtract(Duration(days: 1));

      final minuteCount = await _getNotificationCount(
        userId,
        startTime: oneMinuteAgo,
      );

      final hourlyCount = await _getNotificationCount(
        userId,
        startTime: oneHourAgo,
      );

      final dailyCount = await _getNotificationCount(
        userId,
        startTime: oneDayAgo,
      );

      final broadcastCount = await _getBroadcastCount(
        userId,
        startTime: oneDayAgo,
      );

      return {
        'user_id': userId,
        'last_minute': {
          'count': minuteCount,
          'limit': maxNotificationsPerMinute,
          'remaining': maxNotificationsPerMinute - minuteCount,
        },
        'last_hour': {
          'count': hourlyCount,
          'limit': maxNotificationsPerHour,
          'remaining': maxNotificationsPerHour - hourlyCount,
        },
        'last_day': {
          'count': dailyCount,
          'limit': maxNotificationsPerDay,
          'remaining': maxNotificationsPerDay - dailyCount,
        },
        'broadcasts_today': {
          'count': broadcastCount,
          'limit': maxBroadcastsPerDay,
          'remaining': maxBroadcastsPerDay - broadcastCount,
        },
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      print('⚠️ Error getting usage stats: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Check if user is approaching rate limit (>80% of limit)
  Future<bool> isApproachingRateLimit(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      final hourlyCount = await _getNotificationCount(
        userId,
        startTime: oneHourAgo,
      );

      final threshold = (maxNotificationsPerHour * 0.8).round();
      return hourlyCount >= threshold;
    } catch (e) {
      print('⚠️ Error checking rate limit threshold: $e');
      return false;
    }
  }

  /// Log rate limit violation for monitoring
  Future<void> logRateLimitViolation(
    String userId,
    String violationType,
  ) async {
    try {
      // Log to action_log table for monitoring
      await _supabase.insert('action_log', [
        {
          'user_id': userId,
          'action_type': 'rate_limit_violation',
          'description': 'Rate limit violation: $violationType',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
    } catch (e) {
      print('⚠️ Error logging rate limit violation: $e');
    }
  }
}

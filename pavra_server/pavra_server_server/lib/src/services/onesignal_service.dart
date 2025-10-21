import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// OneSignal service for sending push notifications
///
/// Uses OneSignal REST API to send notifications to users
class OneSignalService {
  static final _log = Logger('OneSignalService');

  final String appId;
  final String apiKey;
  final String apiUrl;

  OneSignalService({
    required this.appId,
    required this.apiKey,
    this.apiUrl = 'https://api.onesignal.com/notifications',
  });

  /// Send notification to specific user by external user ID
  ///
  /// [userId] - Your app's user ID (set via OneSignal.login())
  /// [title] - Notification title
  /// [message] - Notification message
  /// [data] - Additional data to send with notification
  Future<Map<String, dynamic>> sendToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'include_aliases': {
            'external_id': [userId],
          },
          'target_channel': 'push',
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _log.info('✓ Notification sent to user $userId: ${result['id']}');
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

  /// Send notification to multiple users
  ///
  /// [userIds] - List of user IDs
  /// [title] - Notification title
  /// [message] - Notification message
  /// [data] - Additional data
  Future<Map<String, dynamic>> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'include_aliases': {
            'external_id': userIds,
          },
          'target_channel': 'push',
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _log.info(
            '✓ Notification sent to ${userIds.length} users: ${result['id']}');
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

  /// Send notification to all users
  ///
  /// [title] - Notification title
  /// [message] - Notification message
  /// [data] - Additional data
  Future<Map<String, dynamic>> sendToAll({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'included_segments': ['All'],
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _log.info('✓ Notification sent to all users: ${result['id']}');
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

  /// Send notification with filters
  ///
  /// [title] - Notification title
  /// [message] - Notification message
  /// [filters] - OneSignal filters (see OneSignal docs)
  /// [data] - Additional data
  Future<Map<String, dynamic>> sendWithFilters({
    required String title,
    required String message,
    required List<Map<String, dynamic>> filters,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'filters': filters,
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
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

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$notificationId?app_id=$appId'),
        headers: {
          'Authorization': 'Basic $apiKey',
        },
      );

      if (response.statusCode == 200) {
        _log.info('✓ Notification cancelled: $notificationId');
      } else {
        _log.warning('❌ Failed to cancel notification: ${response.body}');
        throw Exception(
            'Failed to cancel notification: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('❌ Error cancelling notification: $e');
      rethrow;
    }
  }

  /// View notification details
  Future<Map<String, dynamic>> getNotification(String notificationId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/$notificationId?app_id=$appId'),
        headers: {
          'Authorization': 'Basic $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get notification: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('❌ Error getting notification: $e');
      rethrow;
    }
  }
}

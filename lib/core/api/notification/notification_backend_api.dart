import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Backend API client for notification operations
///
/// Currently simplified to work directly with Supabase
/// without intermediate backend server
class NotificationBackendApi {
  final _logger = Logger();

  String get _baseUrl {
    final host = dotenv.env['PUBLIC_HOST'] ?? 'localhost';
    final port = dotenv.env['API_PORT'] ?? '8080';
    final useHttps = port == '443';
    return '${useHttps ? 'https' : 'http'}://$host${useHttps ? '' : ':$port'}';
  }

  /// Send notification to a specific user via backend
  ///
  /// This will create a notification record and send push notification
  Future<Map<String, dynamic>> sendToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/sendToUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'createdBy': createdBy,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error sending notification via backend', error: e);
      rethrow;
    }
  }

  /// Send notification to multiple users
  Future<Map<String, dynamic>> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/sendToUsers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userIds': userIds,
          'title': title,
          'message': message,
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send notifications: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error sending notifications via backend', error: e);
      rethrow;
    }
  }

  /// Send notification to all users (broadcast)
  Future<Map<String, dynamic>> sendToAll({
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/sendToAll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'message': message,
          'type': type,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send broadcast: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error sending broadcast via backend', error: e);
      rethrow;
    }
  }

  /// Schedule a notification to be sent at a specific time
  Future<Map<String, dynamic>> scheduleNotification({
    required String userId,
    required String title,
    required String message,
    required DateTime scheduledAt,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    String? createdBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/scheduleNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'message': message,
          'scheduledAt': scheduledAt.toIso8601String(),
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'targetType': targetType,
          'targetRoles': targetRoles,
          'targetUserIds': targetUserIds,
          'createdBy': createdBy,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to schedule notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error scheduling notification via backend', error: e);
      rethrow;
    }
  }

  /// Schedule notification for multiple users
  Future<Map<String, dynamic>> scheduleNotificationForUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required DateTime scheduledAt,
    String type = 'info',
    String? relatedAction,
    Map<String, dynamic>? data,
    String? createdBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/scheduleNotificationForUsers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userIds': userIds,
          'title': title,
          'message': message,
          'scheduledAt': scheduledAt.toIso8601String(),
          'type': type,
          'relatedAction': relatedAction,
          'data': data,
          'createdBy': createdBy,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to schedule notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error scheduling notifications via backend', error: e);
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  Future<Map<String, dynamic>> cancelScheduledNotification({
    required String notificationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/cancelScheduledNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notificationId': notificationId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to cancel notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error cancelling notification via backend', error: e);
      rethrow;
    }
  }

  /// Send app update notification
  Future<Map<String, dynamic>> sendAppUpdateNotification({
    required String version,
    required String updateMessage,
    bool isRequired = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/sendAppUpdateNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'version': version,
          'updateMessage': updateMessage,
          'isRequired': isRequired,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to send app update notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error sending app update notification', error: e);
      rethrow;
    }
  }

  /// Send feature announcement
  Future<Map<String, dynamic>> sendFeatureAnnouncement({
    required String featureName,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notification/sendFeatureAnnouncement'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'featureName': featureName,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to send feature announcement: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error sending feature announcement', error: e);
      rethrow;
    }
  }
}

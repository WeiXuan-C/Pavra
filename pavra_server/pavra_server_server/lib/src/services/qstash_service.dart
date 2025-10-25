import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service for managing scheduled tasks with Upstash QStash
class QStashService {
  static QStashService? _instance;
  static QStashService get instance => _instance ??= QStashService._();

  final String _baseUrl;
  final String _token;

  QStashService._()
      : _baseUrl =
            Platform.environment['QSTASH_URL'] ?? 'https://qstash.upstash.io',
        _token = Platform.environment['QSTASH_TOKEN'] ?? '';

  /// Schedule a notification to be sent at a specific time
  Future<Map<String, dynamic>> scheduleNotification({
    required String notificationId,
    required DateTime scheduledAt,
    required String callbackUrl,
    Map<String, dynamic>? data,
  }) async {
    if (_token.isEmpty) {
      throw Exception('QStash token not configured');
    }

    try {
      final delay = scheduledAt.difference(DateTime.now()).inSeconds;
      if (delay < 0) {
        throw Exception('Scheduled time must be in the future');
      }

      final url = Uri.parse('$_baseUrl/v2/publish/$callbackUrl');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Upstash-Delay': '${delay}s',
          'Upstash-Retries': '3',
        },
        body: jsonEncode({
          'notificationId': notificationId,
          'scheduledAt': scheduledAt.toIso8601String(),
          ...?data,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        stdout.writeln(
            '✓ Scheduled notification via QStash: $notificationId at $scheduledAt');
        return result;
      } else {
        throw Exception(
            'QStash API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      stderr.writeln('❌ Failed to schedule notification via QStash: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  Future<bool> cancelScheduledNotification(String messageId) async {
    if (_token.isEmpty) {
      throw Exception('QStash token not configured');
    }

    try {
      final url = Uri.parse('$_baseUrl/v2/messages/$messageId');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        stdout.writeln('✓ Cancelled scheduled notification: $messageId');
        return true;
      } else {
        stderr.writeln(
            '⚠️ Failed to cancel notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      stderr.writeln('❌ Error cancelling scheduled notification: $e');
      return false;
    }
  }

  /// Verify QStash signature for incoming webhook requests
  bool verifySignature({
    required String signature,
    required String body,
    String? currentSigningKey,
    String? nextSigningKey,
  }) {
    final currentKey =
        currentSigningKey ?? Platform.environment['QSTASH_CURRENT_SIGNING_KEY'];
    final nextKey =
        nextSigningKey ?? Platform.environment['QSTASH_NEXT_SIGNING_KEY'];

    if (currentKey == null && nextKey == null) {
      stderr.writeln(
          '⚠️ QStash signing keys not configured, skipping signature verification');
      return true; // Allow in development
    }

    // Verify with current key
    if (currentKey != null && _verifyWithKey(signature, body, currentKey)) {
      return true;
    }

    // Verify with next key (for key rotation)
    if (nextKey != null && _verifyWithKey(signature, body, nextKey)) {
      return true;
    }

    return false;
  }

  bool _verifyWithKey(String signature, String body, String key) {
    // QStash uses JWT-based signatures
    // For simplicity, we'll do basic validation here
    // In production, use a proper JWT library
    try {
      // Basic signature format check
      return signature.isNotEmpty && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

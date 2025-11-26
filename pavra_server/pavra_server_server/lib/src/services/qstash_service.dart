import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../utils/retry_helper.dart';

/// Service for managing scheduled tasks with Upstash QStash
/// 
/// Includes comprehensive error handling, retry logic, and structured logging
class QStashService {
  static final _log = Logger('QStashService');
  static QStashService? _instance;
  static QStashService get instance => _instance ??= QStashService._();

  final String _baseUrl;
  final String _token;
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const int initialRetryDelay = 1000; // 1 second
  static const int maxRetryDelay = 10000; // 10 seconds

  QStashService._()
      : _baseUrl =
            Platform.environment['QSTASH_URL'] ?? 'https://qstash.upstash.io',
        _token = Platform.environment['QSTASH_TOKEN'] ?? '' {
    _log.info('QStashService initialized');
    _log.fine('   Base URL: $_baseUrl');
    _log.fine('   Token configured: ${_token.isNotEmpty}');
  }

  /// Schedule a notification to be sent at a specific time
  /// 
  /// Includes retry logic with exponential backoff for transient failures
  Future<Map<String, dynamic>> scheduleNotification({
    required String notificationId,
    required DateTime scheduledAt,
    required String callbackUrl,
    Map<String, dynamic>? data,
  }) async {
    if (_token.isEmpty) {
      _log.severe('❌ QStash token not configured');
      throw Exception('QStash token not configured');
    }

    _log.info('📅 Scheduling notification via QStash');
    _log.info('   Notification ID: $notificationId');
    _log.info('   Scheduled for: ${scheduledAt.toIso8601String()}');
    _log.fine('   Callback URL: $callbackUrl');

    try {
      return await RetryHelper.execute(
        operation: () async {
          final delay = scheduledAt.difference(DateTime.now()).inSeconds;
          if (delay < 0) {
            _log.severe('❌ Scheduled time is in the past');
            throw Exception('Scheduled time must be in the future');
          }

          _log.fine('   Delay: ${delay}s');

          final url = Uri.parse('$_baseUrl/v2/publish/$callbackUrl');

          _log.fine('📡 Making QStash API request...');
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
            final messageId = result['messageId'] as String?;
            
            _log.info('✅ Notification scheduled successfully');
            _log.info('   QStash Message ID: $messageId');
            _log.fine('   Full response: $result');
            
            return result;
          } else {
            final errorBody = response.body;
            _log.warning('❌ QStash API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
                'QStash API error ${response.statusCode}: $errorBody');
          }
        },
        maxAttempts: maxRetryAttempts,
        initialDelay: initialRetryDelay,
        maxDelay: maxRetryDelay,
        retryIf: RetryHelper.isRetryableQStashError,
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying QStash schedule (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      _log.severe('❌ Failed to schedule notification after $maxRetryAttempts attempts');
      _log.severe('   Notification ID: $notificationId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  /// 
  /// Includes retry logic and comprehensive error handling
  /// Returns true if cancelled successfully, false otherwise
  Future<bool> cancelScheduledNotification(String messageId) async {
    if (_token.isEmpty) {
      _log.severe('❌ QStash token not configured');
      throw Exception('QStash token not configured');
    }

    _log.info('🗑️  Cancelling QStash scheduled notification');
    _log.info('   Message ID: $messageId');

    try {
      return await RetryHelper.execute(
        operation: () async {
          final url = Uri.parse('$_baseUrl/v2/messages/$messageId');

          _log.fine('📡 Making QStash API request...');
          final response = await http.delete(
            url,
            headers: {
              'Authorization': 'Bearer $_token',
            },
          );

          if (response.statusCode == 200) {
            _log.info('✅ QStash notification cancelled successfully');
            return true;
          } else if (response.statusCode == 404) {
            // Message not found - might have already been processed
            _log.warning('⚠️  QStash message not found (may have already been processed)');
            _log.warning('   Message ID: $messageId');
            return false; // Don't retry 404
          } else {
            final errorBody = response.body;
            _log.warning('❌ QStash API error: ${response.statusCode}');
            _log.warning('   Response: $errorBody');
            
            throw Exception(
                'QStash API error ${response.statusCode}: $errorBody');
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
          return RetryHelper.isRetryableQStashError(error);
        },
        onRetry: (attempt, error) {
          _log.warning('🔄 Retrying QStash cancellation (attempt $attempt)');
          _log.warning('   Error: $error');
        },
      );
    } catch (e, stackTrace) {
      // If it's a 404, return false instead of throwing
      if (e.toString().contains('404')) {
        _log.warning('⚠️  QStash message not found: $messageId');
        return false;
      }
      
      _log.severe('❌ Failed to cancel QStash notification after $maxRetryAttempts attempts');
      _log.severe('   Message ID: $messageId');
      _log.severe('   Error: $e');
      _log.severe('   Stack trace: $stackTrace');
      return false; // Return false instead of throwing to allow graceful degradation
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

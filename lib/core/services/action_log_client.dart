import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Action Log Client
///
/// Sends user action logs to the backend Serverpod server
/// which then stores them in Redis → Supabase
class ActionLogClient {
  // Singleton pattern
  static final ActionLogClient _instance = ActionLogClient._internal();
  factory ActionLogClient() => _instance;
  ActionLogClient._internal();

  // Backend server URL (from .env or default to localhost)
  String get _serverUrl {
    final host = dotenv.env['PUBLIC_HOST'] ?? 'localhost';
    final port = dotenv.env['API_PORT'] ?? '8080';
    return 'http://$host:$port';
  }

  /// Log user sign-in action
  Future<void> logSignIn({
    required String userId,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      developer.log('📝 Logging sign-in action for: $email', name: 'ActionLog');

      await _sendLog(
        endpoint: '/auth/signIn',
        data: {
          'userId': userId,
          'email': email,
          'metadata': {
            'timestamp': DateTime.now().toIso8601String(),
            ...?metadata,
          },
        },
      );

      developer.log('✅ Sign-in action logged', name: 'ActionLog');
    } catch (e) {
      developer.log('❌ Failed to log sign-in: $e', name: 'ActionLog', error: e);
      // Don't throw - logging failure shouldn't break auth flow
    }
  }

  /// Log user sign-up action
  Future<void> logSignUp({
    required String userId,
    required String email,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      developer.log('📝 Logging sign-up action for: $email', name: 'ActionLog');

      await _sendLog(
        endpoint: '/auth/signUp',
        data: {
          'userId': userId,
          'email': email,
          'username': username,
          'metadata': {
            'timestamp': DateTime.now().toIso8601String(),
            'registration_source': 'mobile_app',
            ...?metadata,
          },
        },
      );

      developer.log('✅ Sign-up action logged', name: 'ActionLog');
    } catch (e) {
      developer.log('❌ Failed to log sign-up: $e', name: 'ActionLog', error: e);
    }
  }

  /// Log user sign-out action
  Future<void> logSignOut({required String userId, String? email}) async {
    try {
      developer.log('📝 Logging sign-out action', name: 'ActionLog');

      await _sendLog(
        endpoint: '/auth/signOut',
        data: {'userId': userId, if (email != null) 'email': email},
      );

      developer.log('✅ Sign-out action logged', name: 'ActionLog');
    } catch (e) {
      developer.log(
        '❌ Failed to log sign-out: $e',
        name: 'ActionLog',
        error: e,
      );
    }
  }

  /// Test backend connection
  Future<bool> testConnection() async {
    try {
      developer.log('🔍 Testing backend connection...', name: 'ActionLog');

      final response = await _sendLog(
        endpoint: '/auth/testConnections',
        data: {},
      );

      final success = response['success'] == true;
      developer.log(
        success ? '✅ Backend connected' : '❌ Backend connection failed',
        name: 'ActionLog',
      );

      return success;
    } catch (e) {
      developer.log(
        '❌ Connection test failed: $e',
        name: 'ActionLog',
        error: e,
      );
      return false;
    }
  }

  /// Send log to backend server
  Future<Map<String, dynamic>> _sendLog({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$_serverUrl$endpoint');

    developer.log('Sending to: $url', name: 'ActionLog');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Request timeout - is backend server running?');
          },
        );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Server error: ${response.statusCode} - ${response.body}',
      );
    }
  }
}

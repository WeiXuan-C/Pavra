import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
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

    // 如果是 443 端口，使用 HTTPS；否则使用 HTTP
    final scheme = port == '443' ? 'https' : 'http';

    // 如果是标准端口（80/443），不需要显示端口号
    final portSuffix = (port == '80' || port == '443') ? '' : ':$port';

    final url = '$scheme://$host$portSuffix';
    developer.log('  Final URL: $url', name: 'ActionLog');

    return url;
  }

  // 🔥 检测是否为开发/测试环境
  bool get _isTestEnvironment {
    // 如果是 debug 模式，认为是测试环境
    if (kDebugMode) return true;

    // 如果连接的是 localhost，认为是测试环境
    final host = dotenv.env['PUBLIC_HOST'] ?? 'localhost';
    if (host == 'localhost' || host == '127.0.0.1') return true;

    return false;
  }

  // 🔥 获取环境标记
  Map<String, dynamic> get _environmentMetadata {
    return {
      'is_test': _isTestEnvironment,
      'environment': _isTestEnvironment ? 'development' : 'production',
      'debug_mode': kDebugMode,
    };
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
        endpoint: '/actionLog/log',
        data: {
          'userId': userId,
          'action': 'user_sign_in',
          'description': 'User signed in: $email',
          'metadata': {
            'email': email,
            'timestamp': DateTime.now().toIso8601String(),
            ..._environmentMetadata,
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
        endpoint: '/actionLog/log',
        data: {
          'userId': userId,
          'action': 'user_sign_up',
          'description': 'New user registered: $email',
          'metadata': {
            'email': email,
            'username': username,
            'timestamp': DateTime.now().toIso8601String(),
            'registration_source': 'mobile_app',
            ..._environmentMetadata,
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
        endpoint: '/actionLog/log',
        data: {
          'userId': userId,
          'action': 'user_sign_out',
          'description': 'User signed out${email != null ? ': $email' : ''}',
          'metadata': {
            if (email != null) 'email': email,
            'timestamp': DateTime.now().toIso8601String(),
            ..._environmentMetadata,
          },
        },
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
        endpoint: '/actionLog/healthCheck',
        data: {},
      );

      final redisOk = response['redis'] == true;
      final supabaseOk = response['supabase'] == true;
      final success = redisOk && supabaseOk;

      developer.log(
        success
            ? '✅ Backend connected (Redis: $redisOk, Supabase: $supabaseOk)'
            : '❌ Backend connection failed (Redis: $redisOk, Supabase: $supabaseOk)',
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

  /// Send log to backend server (Serverpod format)
  Future<Map<String, dynamic>> _sendLog({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    // Serverpod endpoint format: /endpointName/methodName
    final url = Uri.parse('$_serverUrl$endpoint');

    developer.log('Sending to: $url', name: 'ActionLog');
    developer.log('Data: ${jsonEncode(data)}', name: 'ActionLog');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Request timeout - is backend server running at $_serverUrl?',
              );
            },
          );

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'ActionLog',
      );
      developer.log('Response body: ${response.body}', name: 'ActionLog');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Serverpod wraps response in 'result' field
        if (result is Map && result.containsKey('result')) {
          return result['result'] as Map<String, dynamic>;
        }
        return result as Map<String, dynamic>;
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('Request failed: $e', name: 'ActionLog', error: e);
      rethrow;
    }
  }
}

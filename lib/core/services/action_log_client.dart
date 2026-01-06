import 'dart:developer' as developer;

/// Action Log Client
///
/// Simple HTTP client for logging user actions
/// Currently disabled - logs are handled by Supabase directly
class ActionLogClient {
  // Singleton pattern
  static final ActionLogClient _instance = ActionLogClient._internal();
  factory ActionLogClient() => _instance;
  ActionLogClient._internal();

  /// Log user sign-in action
  Future<void> logSignIn({
    required String userId,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    // Currently disabled - using Supabase analytics instead
    developer.log('📝 Sign-in logged locally: $email', name: 'ActionLog');
  }

  /// Log user sign-up action
  Future<void> logSignUp({
    required String userId,
    required String email,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    // Currently disabled - using Supabase analytics instead
    developer.log('📝 Sign-up logged locally: $email', name: 'ActionLog');
  }

  /// Log user sign-out action
  Future<void> logSignOut({required String userId, String? email}) async {
    // Currently disabled - using Supabase analytics instead
    developer.log('📝 Sign-out logged locally', name: 'ActionLog');
  }

  /// Test backend connection
  Future<bool> testConnection() async {
    // Always return true since we're using Supabase directly
    return true;
  }
}

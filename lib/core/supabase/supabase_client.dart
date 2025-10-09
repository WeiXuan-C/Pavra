import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_constants.dart';

/// Global Supabase client instance
/// 
/// This provides direct access to:
/// - Authentication: supabase.auth
/// - Storage: supabase.storage
/// - Realtime: supabase.realtime
/// - Database: supabase.from('table_name')
/// 
/// Or use the specialized services:
/// - AuthService() for authentication operations
/// - StorageService() for file storage operations
/// - RealtimeService() for realtime subscriptions
/// - DatabaseService() for database CRUD operations
SupabaseClient get supabase => Supabase.instance.client;

/// Main Supabase service for initialization
class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Initialize Supabase with authentication, storage, and realtime
  /// Call this in main() before runApp()
  /// 
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await SupabaseService.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        // detectSessionInUri: true, // Enable for deep linking with OAuth
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
        // eventsPerSecond: 2, // Throttle events if needed
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );
  }

  /// Check if Supabase is initialized
  static bool get isInitialized {
    try {
      // Access client to verify initialization
      // ignore: unnecessary_null_comparison
      return Supabase.instance.client != null;
    } catch (_) {
      return false;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    try {
      // Load environment variables first
      await dotenv.load(fileName: ".env");
    } catch (e) {
      throw Exception(
        '❌ Failed to load .env file: $e\n'
        'Please create a .env file in the project root with:\n'
        'SUPABASE_URL=your-url\n'
        'SUPABASE_ANON_KEY=your-key',
      );
    }

    // Validate required environment variables
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty) {
      throw Exception('❌ SUPABASE_URL not found in .env file');
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw Exception('❌ SUPABASE_ANON_KEY not found in .env file');
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
          detectSessionInUri: true, // Enable for deep linking with OAuth
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
          // eventsPerSecond: 2, // Throttle events if needed
        ),
        storageOptions: const StorageClientOptions(retryAttempts: 3),
      );
    } catch (e) {
      throw Exception('❌ Failed to initialize Supabase: $e');
    }
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

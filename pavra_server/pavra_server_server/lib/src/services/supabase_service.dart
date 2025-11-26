import 'dart:io';
import 'package:supabase/supabase.dart';
import '../../server.dart';

/// Supabase Service - Singleton pattern
/// Handles Supabase client initialization and configuration.
class SupabaseService {
  static SupabaseService? _instance;

  static SupabaseService get instance {
    if (_instance == null) {
      throw StateError(
        'SupabaseService not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _instance!;
  }

  late SupabaseClient _client;
  final String url;
  final String serviceRoleKey;

  SupabaseService._({
    required this.url,
    required this.serviceRoleKey,
  }) {
    _client = SupabaseClient(url, serviceRoleKey);
  }

  /// Initialize Supabase service once at server startup.
  static Future<void> initialize({
    String? url,
    String? serviceRoleKey,
  }) async {
    if (_instance != null) {
      PLog.warn('SupabaseService already initialized, skipping.');
      return;
    }

    // Get credentials from environment or parameters
    final supabaseUrl = url ?? Platform.environment['SUPABASE_URL'];
    final supabaseKey =
        serviceRoleKey ?? Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw StateError('SUPABASE_URL not found in environment variables');
    }

    if (supabaseKey == null || supabaseKey.isEmpty) {
      throw StateError(
          'SUPABASE_SERVICE_ROLE_KEY not found in environment variables');
    }

    _instance = SupabaseService._(
      url: supabaseUrl,
      serviceRoleKey: supabaseKey,
    );

    PLog.info('✅ Supabase initialized: $supabaseUrl');

    // Verify connection
    await _instance!._verifyConnection();
  }

  /// Verify Supabase connection by making a simple query
  Future<void> _verifyConnection() async {
    try {
      // Try to query action_log table (limit 1 to minimize load)
      await _client.from('action_log').select().limit(1);
      PLog.info('✅ Supabase connection verified.');
    } catch (e, stack) {
      PLog.error('⚠️ Supabase connection test failed.', e, stack);
      // Don't throw - allow service to continue, will retry on actual operations
    }
  }

  /// Get the Supabase client instance
  SupabaseClient get client => _client;

  /// Insert data into a table
  Future<List<Map<String, dynamic>>> insert(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final response = await _client.from(table).insert(data).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      PLog.error('Failed to insert into $table', e, stack);
      rethrow;
    }
  }

  /// Query data from a table
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
    int? limit,
  }) async {
    try {
      dynamic query = _client.from(table).select(columns);

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      PLog.error('Failed to select from $table', e, stack);
      rethrow;
    }
  }

  /// Update data in a table
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = _client.from(table).update(data);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      PLog.error('Failed to update $table', e, stack);
      rethrow;
    }
  }

  /// Delete data from a table
  Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = _client.from(table).delete();

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;
    } catch (e, stack) {
      PLog.error('Failed to delete from $table', e, stack);
      rethrow;
    }
  }

  /// Call a Postgres function via RPC
  Future<dynamic> rpc(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _client.rpc(functionName, params: params);
      return response;
    } catch (e, stack) {
      PLog.error('Failed to call RPC function $functionName', e, stack);
      rethrow;
    }
  }

  /// Health check - verify connection is working
  Future<bool> healthCheck() async {
    try {
      await _client.from('action_log').select().limit(1);
      return true;
    } catch (e) {
      PLog.error('Supabase health check failed', e);
      return false;
    }
  }

  /// Dispose singleton instance (useful for testing)
  static void dispose() {
    _instance = null;
    PLog.warn('SupabaseService instance disposed.');
  }
}

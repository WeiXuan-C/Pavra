import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Database Service
/// Handles all database operations (CRUD)
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Get query builder for a table
  SupabaseQueryBuilder from(String table) {
    return supabase.from(table);
  }

  /// Insert a single record
  Future<T> insert<T>({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final response = await supabase.from(table).insert(data).select().single();
    return response as T;
  }

  /// Insert multiple records
  Future<List<T>> insertMany<T>({
    required String table,
    required List<Map<String, dynamic>> data,
  }) async {
    final response = await supabase.from(table).insert(data).select();
    return response as List<T>;
  }

  /// Update records
  Future<List<T>> update<T>({
    required String table,
    required Map<String, dynamic> data,
    String? matchColumn,
    dynamic matchValue,
  }) async {
    var query = supabase.from(table).update(data);

    if (matchColumn != null && matchValue != null) {
      query = query.eq(matchColumn, matchValue);
    }

    final response = await query.select();
    return response as List<T>;
  }

  /// Upsert (insert or update if exists)
  Future<List<T>> upsert<T>({
    required String table,
    required dynamic data,
    List<String>? onConflict,
  }) async {
    final response = await supabase
        .from(table)
        .upsert(data, onConflict: onConflict?.join(','))
        .select();
    return response as List<T>;
  }

  /// Delete records
  Future<void> delete({
    required String table,
    String? matchColumn,
    dynamic matchValue,
  }) async {
    var query = supabase.from(table).delete();

    if (matchColumn != null && matchValue != null) {
      query = query.eq(matchColumn, matchValue);
    }

    await query;
  }

  /// Select all records from a table
  Future<List<Map<String, dynamic>>> selectAll({
    required String table,
    String columns = '*',
  }) async {
    return await supabase.from(table).select(columns);
  }

  /// Select records with filter
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    String? filterColumn,
    dynamic filterValue,
  }) async {
    var query = supabase.from(table).select(columns);

    if (filterColumn != null && filterValue != null) {
      query = query.eq(filterColumn, filterValue);
    }

    return await query;
  }

  /// Select a single record
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    final response = await supabase
        .from(table)
        .select(columns)
        .eq(filterColumn, filterValue)
        .maybeSingle();

    return response;
  }

  /// Count records in a table
  Future<int> count({
    required String table,
    String? filterColumn,
    dynamic filterValue,
  }) async {
    var query = supabase.from(table).select('*');

    if (filterColumn != null && filterValue != null) {
      query = query.eq(filterColumn, filterValue);
    }

    final response = await query;
    return response.length;
  }

  /// Execute a RPC (Remote Procedure Call) function
  Future<T> rpc<T>({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    return await supabase.rpc(functionName, params: params) as T;
  }

  /// Select with pagination
  Future<List<Map<String, dynamic>>> selectWithPagination({
    required String table,
    String columns = '*',
    int page = 1,
    int pageSize = 10,
    String? orderBy,
    bool ascending = true,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    dynamic query = supabase.from(table).select(columns).range(from, to);

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    return await query as List<Map<String, dynamic>>;
  }

  /// Select with multiple filters and ordering
  Future<List<Map<String, dynamic>>> selectAdvanced({
    required String table,
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    dynamic query = supabase.from(table).select(columns);

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

    return await query as List<Map<String, dynamic>>;
  }

  /// Search records using full-text search
  Future<List<Map<String, dynamic>>> search({
    required String table,
    required String column,
    required String searchTerm,
    String columns = '*',
  }) async {
    return await supabase
        .from(table)
        .select(columns)
        .textSearch(column, searchTerm);
  }
}

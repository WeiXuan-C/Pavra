import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import '../../../core/supabase/database_service.dart';
import '../../models/issue_type_model.dart';

/// Remote data source for issue types
/// Uses DatabaseService for all CRUD operations
/// RLS policies ensure proper access control
/// Note: Receives SupabaseClient via dependency injection from API layer
class IssueTypeRemoteSource {
  final DatabaseService _db;
  final SupabaseClient _supabase;

  IssueTypeRemoteSource(this._supabase) : _db = DatabaseService();

  /// Fetch all issue types (所有用户可访问)
  Future<List<IssueTypeModel>> fetchIssueTypes() async {
    final response = await _db.selectAdvanced(
      table: 'issue_types',
      filters: {'is_deleted': false},
      orderBy: 'created_at',
      ascending: true,
    );

    return response.map((json) => IssueTypeModel.fromJson(json)).toList();
  }

  /// Fetch single issue type by ID (所有用户可访问)
  Future<IssueTypeModel?> fetchIssueTypeById(String id) async {
    final response = await _db
        .from('issue_types')
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return IssueTypeModel.fromJson(response);
  }

  /// Create issue type (仅 Developer 可访问 - RLS 策略控制)
  Future<IssueTypeModel> createIssueType({
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'created_by': userId,
    };

    final response = await _db
        .from('issue_types')
        .insert(data)
        .select()
        .single();

    return IssueTypeModel.fromJson(response);
  }

  /// Update issue type (仅 Developer 可访问 - RLS 策略控制)
  Future<IssueTypeModel> updateIssueType(
    String id,
    Map<String, dynamic> updates,
  ) async {
    // 添加 updated_at
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _db
        .from('issue_types')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return IssueTypeModel.fromJson(response);
  }

  /// Delete issue type (仅 Developer 可访问 - RLS 策略控制)
  /// 软删除实现
  Future<void> deleteIssueType(String id) async {
    final now = DateTime.now().toIso8601String();

    await _db
        .from('issue_types')
        .update({'is_deleted': true, 'deleted_at': now, 'updated_at': now})
        .eq('id', id);
  }

  /// Fetch issue types by IDs
  Future<List<IssueTypeModel>> fetchIssueTypesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await _db
        .from('issue_types')
        .select()
        .inFilter('id', ids)
        .eq('is_deleted', false);

    return (response as List)
        .map((json) => IssueTypeModel.fromJson(json))
        .toList();
  }
}

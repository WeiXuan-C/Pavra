import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/issue_type_model.dart';

/// Remote data source for issue types
class IssueTypeRemoteSource {
  final SupabaseClient _supabase;

  IssueTypeRemoteSource(this._supabase);

  /// Fetch all issue types
  Future<List<IssueTypeModel>> fetchIssueTypes() async {
    final response = await _supabase
        .from('issue_types')
        .select()
        .eq('is_deleted', false)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => IssueTypeModel.fromJson(json))
        .toList();
  }

  /// Fetch single issue type by ID
  Future<IssueTypeModel?> fetchIssueTypeById(String id) async {
    final response = await _supabase
        .from('issue_types')
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return IssueTypeModel.fromJson(response);
  }

  /// Create issue type (Authority/Developer only)
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

    final response = await _supabase
        .from('issue_types')
        .insert(data)
        .select()
        .single();

    return IssueTypeModel.fromJson(response);
  }

  /// Update issue type (Authority/Developer only)
  Future<IssueTypeModel> updateIssueType(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('issue_types')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return IssueTypeModel.fromJson(response);
  }

  /// Delete issue type (Authority/Developer only)
  Future<void> deleteIssueType(String id) async {
    await _supabase.from('issue_types').delete().eq('id', id);
  }
}

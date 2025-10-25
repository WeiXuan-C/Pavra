import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/issue_type_model.dart';
import '../../../data/repositories/report_issue_repository.dart';
import '../../../data/sources/remote/report_issue_remote_source.dart';
import '../../../data/sources/remote/issue_type_remote_source.dart';
import '../../../data/sources/remote/issue_vote_remote_source.dart';

/// Issue Type API
/// High-level API for issue type operations
/// Used by UI layer (providers, screens)
class IssueTypeApi {
  late final ReportIssueRepository _repository;

  IssueTypeApi(SupabaseClient supabase) {
    _repository = ReportIssueRepository(
      reportRemoteSource: ReportIssueRemoteSource(supabase),
      typeRemoteSource: IssueTypeRemoteSource(supabase),
      voteRemoteSource: IssueVoteRemoteSource(supabase),
    );
  }

  /// Get all issue types
  Future<List<IssueTypeModel>> getAllIssueTypes() async {
    try {
      return await _repository.getIssueTypes();
    } catch (e) {
      throw Exception('Failed to fetch issue types: $e');
    }
  }

  /// Get issue type by ID
  Future<IssueTypeModel?> getIssueTypeById(String id) async {
    try {
      return await _repository.getIssueTypeById(id);
    } catch (e) {
      throw Exception('Failed to fetch issue type: $e');
    }
  }

  /// Get multiple issue types by IDs
  Future<List<IssueTypeModel>> getIssueTypesByIds(List<String> ids) async {
    try {
      final allTypes = await getAllIssueTypes();
      return allTypes.where((type) => ids.contains(type.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch issue types: $e');
    }
  }

  /// Create issue type (Authority/Developer only)
  Future<IssueTypeModel> createIssueType({
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    try {
      return await _repository.createIssueType(
        name: name,
        description: description,
        iconUrl: iconUrl,
      );
    } catch (e) {
      throw Exception('Failed to create issue type: $e');
    }
  }

  /// Update issue type (Authority/Developer only)
  Future<IssueTypeModel> updateIssueType(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _repository.updateIssueType(id, updates);
    } catch (e) {
      throw Exception('Failed to update issue type: $e');
    }
  }

  /// Delete issue type (Authority/Developer only)
  Future<void> deleteIssueType(String id) async {
    try {
      await _repository.deleteIssueType(id);
    } catch (e) {
      throw Exception('Failed to delete issue type: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/report_issue_model.dart';
import '../../models/issue_photo_model.dart';

/// Remote data source for report issues
class ReportIssueRemoteSource {
  final SupabaseClient _supabase;

  ReportIssueRemoteSource(this._supabase);

  /// Fetch all report issues (respects RLS policies)
  Future<List<ReportIssueModel>> fetchReportIssues({
    String? status,
    String? createdBy,
    int? limit,
    int? offset,
  }) async {
    dynamic query = _supabase
        .from('report_issues')
        .select()
        .eq('is_deleted', false);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (createdBy != null) {
      query = query.eq('created_by', createdBy);
    }

    query = query.order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }

    final response = await query;
    return (response as List)
        .map((json) => ReportIssueModel.fromJson(json))
        .toList();
  }

  /// Fetch single report issue by ID
  Future<ReportIssueModel?> fetchReportIssueById(String id) async {
    final response = await _supabase
        .from('report_issues')
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return ReportIssueModel.fromJson(response);
  }

  /// Create new report issue
  Future<ReportIssueModel> createReportIssue({
    String? title,
    String? description,
    List<String>? issueTypeIds,
    String? severity,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'title': title,
      'description': description,
      'issue_type_ids': issueTypeIds ?? [],
      'severity': severity ?? 'moderate',
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'draft',
      'created_by': userId,
    };

    final response = await _supabase
        .from('report_issues')
        .insert(data)
        .select()
        .single();

    return ReportIssueModel.fromJson(response);
  }

  /// Update report issue (only draft status for regular users)
  Future<ReportIssueModel> updateReportIssue(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('report_issues')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return ReportIssueModel.fromJson(response);
  }

  /// Submit report issue (change status from draft to submitted)
  Future<ReportIssueModel> submitReportIssue(String id) async {
    return updateReportIssue(id, {'status': 'submitted'});
  }

  /// Delete report issue (only draft status) - Soft delete
  Future<void> deleteReportIssue(String id) async {
    final now = DateTime.now();
    await _supabase
        .from('report_issues')
        .update({
          'is_deleted': true,
          'deleted_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', id);
  }

  /// Fetch photos for a report issue
  Future<List<IssuePhotoModel>> fetchIssuePhotos(String issueId) async {
    final response = await _supabase
        .from('issue_photos')
        .select()
        .eq('issue_id', issueId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => IssuePhotoModel.fromJson(json))
        .toList();
  }

  /// Upload photo for report issue
  Future<IssuePhotoModel> uploadIssuePhoto({
    required String issueId,
    required String photoUrl,
    String photoType = 'main',
    bool isPrimary = false,
  }) async {
    final data = {
      'issue_id': issueId,
      'photo_url': photoUrl,
      'photo_type': photoType,
      'is_primary': isPrimary,
    };

    final response = await _supabase
        .from('issue_photos')
        .insert(data)
        .select()
        .single();

    return IssuePhotoModel.fromJson(response);
  }

  /// Delete photo - Soft delete
  Future<void> deleteIssuePhoto(String photoId) async {
    final now = DateTime.now();
    await _supabase
        .from('issue_photos')
        .update({
          'is_deleted': true,
          'deleted_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', photoId);
  }

  /// Authority: Review report issue
  Future<ReportIssueModel> reviewReportIssue({
    required String id,
    required String status,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = {
      'status': status,
      'reviewed_by': userId,
      'reviewed_comment': comment,
      'reviewed_at': DateTime.now().toIso8601String(),
    };

    return updateReportIssue(id, updates);
  }
}

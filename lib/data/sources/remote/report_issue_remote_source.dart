import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import '../../models/report_issue_model.dart';
import '../../models/issue_photo_model.dart';
import '../../../core/services/reputation_service.dart';
import 'dart:developer' as developer;

/// Remote data source for report issues
/// Note: Only receives SupabaseClient via dependency injection from API layer
/// Does not directly access Supabase.instance
class ReportIssueRemoteSource {
  final SupabaseClient _supabase;
  final _reputationService = ReputationService();

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
    final result = await updateReportIssue(id, {'status': 'submitted'});

    // Add reputation for submitting issue
    if (result.createdBy != null) {
      try {
        await _reputationService.addReputationForUpload(result.createdBy!);
        developer.log(
          '✅ Added reputation for issue submission: ${result.id}',
          name: 'ReportIssueRemoteSource',
        );
      } catch (e) {
        developer.log(
          '⚠️ Failed to add reputation for submission: $e',
          name: 'ReportIssueRemoteSource',
          error: e,
        );
        // Don't fail the submission if reputation update fails
      }
    }

    return result;
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

    // Get the issue first to know who created it
    final issue = await fetchReportIssueById(id);
    if (issue == null) throw Exception('Issue not found');

    final updates = {
      'status': status,
      'reviewed_by': userId,
      'reviewed_comment': comment,
      'reviewed_at': DateTime.now().toIso8601String(),
    };

    final result = await updateReportIssue(id, updates);

    // Update reputation based on status change
    if (issue.createdBy != null) {
      try {
        if (status == 'spam') {
          // Deduct reputation for spam
          await _reputationService.deductReputationForSpam(issue.createdBy!);
          developer.log(
            '✅ Deducted reputation for spam issue: ${result.id}',
            name: 'ReportIssueRemoteSource',
          );
        } else if (status == 'reviewed') {
          // Add reputation for reviewed issue
          await _reputationService.addReputationForReview(issue.createdBy!);
          developer.log(
            '✅ Added reputation for reviewed issue: ${result.id}',
            name: 'ReportIssueRemoteSource',
          );
        }
      } catch (e) {
        developer.log(
          '⚠️ Failed to update reputation for review: $e',
          name: 'ReportIssueRemoteSource',
          error: e,
        );
        // Don't fail the review if reputation update fails
      }
    }

    return result;
  }
}

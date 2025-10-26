import 'dart:math' as math;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/report_issue_model.dart';
import '../../../data/models/issue_photo_model.dart';
import '../../../data/repositories/report_issue_repository.dart';
import '../../../data/sources/remote/report_issue_remote_source.dart';
import '../../../data/sources/remote/issue_type_remote_source.dart';
import '../../../data/sources/remote/issue_vote_remote_source.dart';

/// Report Issue API
/// High-level API for report issues operations
/// Used by UI layer (providers, screens)
class ReportIssueApi {
  late final ReportIssueRepository _repository;
  final SupabaseClient _supabase;

  ReportIssueApi(this._supabase) {
    _repository = ReportIssueRepository(
      reportRemoteSource: ReportIssueRemoteSource(_supabase),
      typeRemoteSource: IssueTypeRemoteSource(),
      voteRemoteSource: IssueVoteRemoteSource(_supabase),
    );
  }

  // ========== Report Issues ==========

  /// Get all submitted/reviewed reports (public feed)
  Future<List<ReportIssueModel>> getPublicReports({
    int? limit = 20,
    int? offset = 0,
  }) async {
    try {
      return await _repository.getReportIssues(
        status: null, // Will show submitted and reviewed based on RLS
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to fetch public reports: $e');
    }
  }

  /// Get my reports (all statuses including drafts)
  Future<List<ReportIssueModel>> getMyReports({
    String? status,
    int? limit = 20,
    int? offset = 0,
  }) async {
    try {
      return await _repository.getMyReportIssues(
        status: status,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to fetch my reports: $e');
    }
  }

  /// Get my draft reports
  Future<List<ReportIssueModel>> getMyDrafts() async {
    return getMyReports(status: 'draft');
  }

  /// Get report by ID
  Future<ReportIssueModel?> getReportById(String id) async {
    try {
      return await _repository.getReportIssueById(id);
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Create new report (starts as draft)
  Future<ReportIssueModel> createReport({
    String? title,
    String? description,
    List<String>? issueTypeIds,
    String? severity,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      return await _repository.createReportIssue(
        title: title,
        description: description,
        issueTypeIds: issueTypeIds,
        severity: severity,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Update report (only drafts for regular users)
  Future<ReportIssueModel> updateReport(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _repository.updateReportIssue(id, updates);
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  /// Submit report (change from draft to submitted)
  Future<ReportIssueModel> submitReport(String id) async {
    try {
      return await _repository.submitReportIssue(id);
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Delete report (only drafts)
  Future<void> deleteReport(String id) async {
    try {
      await _repository.deleteReportIssue(id);
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // ========== Photos ==========

  /// Get photos for a report
  Future<List<IssuePhotoModel>> getReportPhotos(String issueId) async {
    try {
      return await _repository.getIssuePhotos(issueId);
    } catch (e) {
      throw Exception('Failed to fetch photos: $e');
    }
  }

  /// Upload photo to Supabase Storage and link to report
  Future<IssuePhotoModel> uploadPhoto({
    required String issueId,
    required String filePath,
    required List<int> fileBytes,
    String photoType = 'main',
    bool isPrimary = false,
  }) async {
    try {
      // Upload to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$filePath';
      final storagePath = 'report_photos/$issueId/$fileName';

      await _supabase.storage
          .from('reports')
          .uploadBinary(storagePath, Uint8List.fromList(fileBytes));

      // Get public URL
      final photoUrl = _supabase.storage
          .from('reports')
          .getPublicUrl(storagePath);

      // Save to database
      return await _repository.uploadIssuePhoto(
        issueId: issueId,
        photoUrl: photoUrl,
        photoType: photoType,
        isPrimary: isPrimary,
      );
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete photo
  Future<void> deletePhoto(String photoId, String photoUrl) async {
    try {
      // Delete from database
      await _repository.deleteIssuePhoto(photoId);

      // Delete from storage
      final path = Uri.parse(photoUrl).path.split('/reports/').last;
      await _supabase.storage.from('reports').remove([path]);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  // ========== Voting ==========

  /// Get user's vote for a report
  Future<String?> getMyVote(String issueId) async {
    try {
      final vote = await _repository.getUserVote(issueId);
      return vote?.voteType;
    } catch (e) {
      return null;
    }
  }

  /// Vote to verify a report
  Future<void> voteVerify(String issueId) async {
    try {
      await _repository.castVote(issueId: issueId, voteType: 'verify');
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// Vote as spam
  Future<void> voteSpam(String issueId) async {
    try {
      await _repository.castVote(issueId: issueId, voteType: 'spam');
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// Remove vote
  Future<void> removeVote(String issueId, String voteType) async {
    try {
      await _repository.removeVote(issueId, voteType);
    } catch (e) {
      throw Exception('Failed to remove vote: $e');
    }
  }

  /// Get vote counts
  Future<Map<String, int>> getVoteCounts(String issueId) async {
    try {
      return await _repository.getVoteCounts(issueId);
    } catch (e) {
      return {'verified': 0, 'spam': 0};
    }
  }

  // ========== Search & Filter ==========

  /// Search reports by location (nearby)
  Future<List<ReportIssueModel>> searchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int? limit = 20,
  }) async {
    try {
      // This would require a PostGIS extension or custom function
      // For now, fetch all and filter client-side (not optimal for production)
      final reports = await getPublicReports(limit: 100);

      return reports
          .where((report) {
            if (report.latitude == null || report.longitude == null) {
              return false;
            }

            final distance = _calculateDistance(
              latitude,
              longitude,
              report.latitude!,
              report.longitude!,
            );

            return distance <= radiusKm;
          })
          .take(limit ?? 20)
          .toList();
    } catch (e) {
      throw Exception('Failed to search nearby reports: $e');
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}

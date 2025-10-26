import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/report_issue_model.dart';
import '../../../data/repositories/report_issue_repository.dart';
import '../../../data/sources/remote/report_issue_remote_source.dart';
import '../../../data/sources/remote/issue_type_remote_source.dart';
import '../../../data/sources/remote/issue_vote_remote_source.dart';

/// Report Authority API
/// High-level API for authority/developer operations on reports
/// Used by authority users to review and manage reports
class ReportAuthorityApi {
  late final ReportIssueRepository _repository;

  ReportAuthorityApi(SupabaseClient supabase) {
    _repository = ReportIssueRepository(
      reportRemoteSource: ReportIssueRemoteSource(supabase),
      typeRemoteSource: IssueTypeRemoteSource(),
      voteRemoteSource: IssueVoteRemoteSource(supabase),
    );
  }

  /// Get all reports (Authority/Developer can see all)
  Future<List<ReportIssueModel>> getAllReports({
    String? status,
    int? limit = 50,
    int? offset = 0,
  }) async {
    try {
      return await _repository.getReportIssues(
        status: status,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get pending reports (submitted, awaiting review)
  Future<List<ReportIssueModel>> getPendingReports({
    int? limit = 50,
    int? offset = 0,
  }) async {
    return getAllReports(status: 'submitted', limit: limit, offset: offset);
  }

  /// Get reviewed reports
  Future<List<ReportIssueModel>> getReviewedReports({
    int? limit = 50,
    int? offset = 0,
  }) async {
    return getAllReports(status: 'reviewed', limit: limit, offset: offset);
  }

  /// Get spam reports
  Future<List<ReportIssueModel>> getSpamReports({
    int? limit = 50,
    int? offset = 0,
  }) async {
    return getAllReports(status: 'spam', limit: limit, offset: offset);
  }

  /// Approve report (mark as reviewed)
  Future<ReportIssueModel> approveReport({
    required String id,
    String? comment,
  }) async {
    try {
      return await _repository.reviewReportIssue(
        id: id,
        status: 'reviewed',
        comment: comment,
      );
    } catch (e) {
      throw Exception('Failed to approve report: $e');
    }
  }

  /// Mark report as spam
  Future<ReportIssueModel> markAsSpam({
    required String id,
    String? comment,
  }) async {
    try {
      return await _repository.reviewReportIssue(
        id: id,
        status: 'spam',
        comment: comment,
      );
    } catch (e) {
      throw Exception('Failed to mark as spam: $e');
    }
  }

  /// Discard report
  Future<ReportIssueModel> discardReport({
    required String id,
    String? comment,
  }) async {
    try {
      return await _repository.reviewReportIssue(
        id: id,
        status: 'discard',
        comment: comment,
      );
    } catch (e) {
      throw Exception('Failed to discard report: $e');
    }
  }

  /// Update report status with comment
  Future<ReportIssueModel> updateReportStatus({
    required String id,
    required String status,
    String? comment,
  }) async {
    try {
      return await _repository.reviewReportIssue(
        id: id,
        status: status,
        comment: comment,
      );
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Get reports statistics
  Future<Map<String, int>> getReportsStatistics() async {
    try {
      final allReports = await getAllReports(limit: 1000);

      final stats = <String, int>{
        'total': allReports.length,
        'draft': 0,
        'submitted': 0,
        'reviewed': 0,
        'spam': 0,
        'discard': 0,
      };

      for (final report in allReports) {
        stats[report.status] = (stats[report.status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }

  /// Get high priority reports (high/critical severity)
  Future<List<ReportIssueModel>> getHighPriorityReports({
    int? limit = 20,
  }) async {
    try {
      final reports = await getAllReports(limit: 100);
      return reports
          .where((r) => r.severity == 'high' || r.severity == 'critical')
          .take(limit ?? 20)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch high priority reports: $e');
    }
  }
}

import '../models/report_issue_model.dart';
import '../models/issue_photo_model.dart';
import '../models/issue_type_model.dart';
import '../models/issue_vote_model.dart';
import '../sources/remote/report_issue_remote_source.dart';
import '../sources/remote/issue_type_remote_source.dart';
import '../sources/remote/issue_vote_remote_source.dart';

/// Repository for report issues
/// Handles business logic and data coordination
class ReportIssueRepository {
  final ReportIssueRemoteSource _reportRemoteSource;
  final IssueTypeRemoteSource _typeRemoteSource;
  final IssueVoteRemoteSource _voteRemoteSource;

  ReportIssueRepository({
    required ReportIssueRemoteSource reportRemoteSource,
    required IssueTypeRemoteSource typeRemoteSource,
    required IssueVoteRemoteSource voteRemoteSource,
  }) : _reportRemoteSource = reportRemoteSource,
       _typeRemoteSource = typeRemoteSource,
       _voteRemoteSource = voteRemoteSource;

  // ========== Report Issues ==========

  /// Get all report issues
  Future<List<ReportIssueModel>> getReportIssues({
    String? status,
    String? createdBy,
    int? limit,
    int? offset,
  }) async {
    return _reportRemoteSource.fetchReportIssues(
      status: status,
      createdBy: createdBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Get my report issues
  Future<List<ReportIssueModel>> getMyReportIssues({
    String? status,
    int? limit,
    int? offset,
  }) async {
    // createdBy will be filtered by RLS policy
    return _reportRemoteSource.fetchReportIssues(
      status: status,
      limit: limit,
      offset: offset,
    );
  }

  /// Get report issue by ID
  Future<ReportIssueModel?> getReportIssueById(String id) async {
    return _reportRemoteSource.fetchReportIssueById(id);
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
    return _reportRemoteSource.createReportIssue(
      title: title,
      description: description,
      issueTypeIds: issueTypeIds,
      severity: severity,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Update report issue
  Future<ReportIssueModel> updateReportIssue(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return _reportRemoteSource.updateReportIssue(id, updates);
  }

  /// Submit report issue
  Future<ReportIssueModel> submitReportIssue(String id) async {
    return _reportRemoteSource.submitReportIssue(id);
  }

  /// Delete report issue
  Future<void> deleteReportIssue(String id) async {
    return _reportRemoteSource.deleteReportIssue(id);
  }

  // ========== Issue Photos ==========

  /// Get photos for a report issue
  Future<List<IssuePhotoModel>> getIssuePhotos(String issueId) async {
    return _reportRemoteSource.fetchIssuePhotos(issueId);
  }

  /// Upload photo for report issue
  Future<IssuePhotoModel> uploadIssuePhoto({
    required String issueId,
    required String photoUrl,
    String photoType = 'main',
    bool isPrimary = false,
  }) async {
    return _reportRemoteSource.uploadIssuePhoto(
      issueId: issueId,
      photoUrl: photoUrl,
      photoType: photoType,
      isPrimary: isPrimary,
    );
  }

  /// Delete photo
  Future<void> deleteIssuePhoto(String photoId) async {
    return _reportRemoteSource.deleteIssuePhoto(photoId);
  }

  // ========== Issue Types ==========

  /// Get all issue types
  Future<List<IssueTypeModel>> getIssueTypes() async {
    return _typeRemoteSource.fetchIssueTypes();
  }

  /// Get issue type by ID
  Future<IssueTypeModel?> getIssueTypeById(String id) async {
    return _typeRemoteSource.fetchIssueTypeById(id);
  }

  /// Create issue type (Authority/Developer only)
  Future<IssueTypeModel> createIssueType({
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    return _typeRemoteSource.createIssueType(
      name: name,
      description: description,
      iconUrl: iconUrl,
    );
  }

  /// Update issue type (Authority/Developer only)
  Future<IssueTypeModel> updateIssueType(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return _typeRemoteSource.updateIssueType(id, updates);
  }

  /// Delete issue type (Authority/Developer only)
  Future<void> deleteIssueType(String id) async {
    return _typeRemoteSource.deleteIssueType(id);
  }

  // ========== Issue Votes ==========

  /// Get user's vote for an issue
  Future<IssueVoteModel?> getUserVote(String issueId) async {
    return _voteRemoteSource.fetchUserVote(issueId);
  }

  /// Cast vote on an issue
  Future<IssueVoteModel> castVote({
    required String issueId,
    required String voteType,
  }) async {
    return _voteRemoteSource.castVote(issueId: issueId, voteType: voteType);
  }

  /// Remove vote
  Future<void> removeVote(String issueId) async {
    return _voteRemoteSource.removeVote(issueId);
  }

  /// Get vote counts for an issue
  Future<Map<String, int>> getVoteCounts(String issueId) async {
    return _voteRemoteSource.getVoteCounts(issueId);
  }

  /// Get all votes for an issue
  Future<List<IssueVoteModel>> getAllVotesForIssue(String issueId) async {
    return _voteRemoteSource.fetchAllVotesForIssue(issueId);
  }

  // ========== Authority Functions ==========

  /// Review report issue (Authority/Developer only)
  Future<ReportIssueModel> reviewReportIssue({
    required String id,
    required String status,
    String? comment,
  }) async {
    return _reportRemoteSource.reviewReportIssue(
      id: id,
      status: status,
      comment: comment,
    );
  }

  // ========== Issue Types ==========

  /// Get issue types by IDs
  Future<List<IssueTypeModel>> getIssueTypesByIds(List<String> ids) async {
    return _typeRemoteSource.fetchIssueTypesByIds(ids);
  }
}

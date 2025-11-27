import 'dart:math' as math;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/report_issue_model.dart';
import '../../../data/models/issue_photo_model.dart';
import '../../../data/models/issue_type_model.dart';
import '../../../data/models/issue_vote_model.dart';
import '../../../data/repositories/report_issue_repository.dart';
import '../../../data/sources/remote/report_issue_remote_source.dart';
import '../../../data/sources/remote/issue_type_remote_source.dart';
import '../../../data/sources/remote/issue_vote_remote_source.dart';
import '../../supabase/storage_service.dart';
import '../../services/notification_helper_service.dart';
import '../user/user_api.dart';
import '../saved_route/saved_route_api.dart';

/// Report Issue API
/// High-level API for report issues operations
/// Used by UI layer (providers, screens)
class ReportIssueApi {
  late final ReportIssueRepository _repository;
  final SupabaseClient _supabase;
  final StorageService _storageService = StorageService();
  final NotificationHelperService? _notificationHelper;
  final UserApi? _userApi;
  final SavedRouteApi? _savedRouteApi;

  ReportIssueApi(
    this._supabase, {
    NotificationHelperService? notificationHelper,
    UserApi? userApi,
    SavedRouteApi? savedRouteApi,
  })  : _notificationHelper = notificationHelper,
        _userApi = userApi,
        _savedRouteApi = savedRouteApi {
    _repository = ReportIssueRepository(
      reportRemoteSource: ReportIssueRemoteSource(_supabase),
      typeRemoteSource: IssueTypeRemoteSource(_supabase),
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
      final report = await _repository.submitReportIssue(id);
      
      // Trigger notifications after successful submission
      if (_notificationHelper != null) {
        try {
          final userId = getCurrentUserId();
          if (userId != null) {
            // Notify report creator
            await _notificationHelper.notifyReportSubmitted(
              userId: userId,
              reportId: report.id,
              title: report.title ?? 'Road Issue',
            );
            
            // Notify nearby users if location is available
            if (report.latitude != null && report.longitude != null) {
              if (_userApi != null) {
                final nearbyUserIds = await _userApi.getNearbyUsers(
                  latitude: report.latitude!,
                  longitude: report.longitude!,
                  radiusKm: 5.0,
                );
                
                if (nearbyUserIds.isNotEmpty) {
                  await _notificationHelper.notifyNearbyUsers(
                    reportId: report.id,
                    title: report.title ?? 'Road Issue',
                    latitude: report.latitude!,
                    longitude: report.longitude!,
                    severity: report.severity,
                    nearbyUserIds: nearbyUserIds,
                  );
                }
              }
              
              // Notify users monitoring routes
              if (_savedRouteApi != null) {
                final monitoringUserIds = await _savedRouteApi.getUsersMonitoringRoute(
                  latitude: report.latitude!,
                  longitude: report.longitude!,
                  bufferKm: 0.5,
                );
                
                if (monitoringUserIds.isNotEmpty) {
                  await _notificationHelper.notifyMonitoredRouteIssue(
                    reportId: report.id,
                    title: report.title ?? 'Road Issue',
                    latitude: report.latitude!,
                    longitude: report.longitude!,
                    monitoringUserIds: monitoringUserIds,
                  );
                }
              }
            }
          }
        } catch (e) {
          // Log error but don't throw - notification failures shouldn't disrupt business logic
          print('Failed to send notifications for report submission: $e');
        }
      }
      
      return report;
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
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    String photoType = 'main',
    bool isPrimary = false,
  }) async {
    try {
      // Upload to Supabase Storage (issue_photos bucket)
      final photoUrl = await _storageService.uploadIssuePhoto(
        issueId: issueId,
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

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

  /// Upload multiple photos at once
  Future<List<IssuePhotoModel>> uploadPhotos({
    required String issueId,
    required List<({String fileName, Uint8List bytes, String? mimeType})> files,
    String photoType = 'additional',
  }) async {
    final uploadedPhotos = <IssuePhotoModel>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final photo = await uploadPhoto(
          issueId: issueId,
          fileName: file.fileName,
          fileBytes: file.bytes,
          mimeType: file.mimeType,
          photoType: photoType,
          isPrimary:
              i == 0 && photoType == 'main', // First main photo is primary
        );
        uploadedPhotos.add(photo);
      } catch (e) {
        // Continue uploading other photos even if one fails
        print('Failed to upload ${file.fileName}: $e');
      }
    }

    return uploadedPhotos;
  }

  /// Create photo record from existing URL (for AI detection images)
  /// This creates a database record without uploading a new file
  Future<IssuePhotoModel> createPhotoRecord({
    required String issueId,
    required String photoUrl,
    String photoType = 'main',
    bool isPrimary = false,
  }) async {
    try {
      // Save to database only (photo already exists at URL)
      return await _repository.uploadIssuePhoto(
        issueId: issueId,
        photoUrl: photoUrl,
        photoType: photoType,
        isPrimary: isPrimary,
      );
    } catch (e) {
      throw Exception('Failed to create photo record: $e');
    }
  }

  /// Delete photo from both database and storage
  Future<void> deletePhoto(String photoId, String photoUrl) async {
    try {
      // Delete from database (soft delete)
      await _repository.deleteIssuePhoto(photoId);

      // Delete from storage
      await _storageService.deleteIssuePhoto(photoUrl);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Delete all photos for an issue (used when deleting a report)
  Future<void> deleteAllPhotos(String issueId) async {
    try {
      // Get all photos for the issue
      final photos = await _repository.getIssuePhotos(issueId);

      // Delete from database
      for (final photo in photos) {
        await _repository.deleteIssuePhoto(photo.id);
      }

      // Delete from storage
      await _storageService.deleteIssuePhotos(issueId);
    } catch (e) {
      throw Exception('Failed to delete all photos: $e');
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
      
      // Check vote counts and trigger notification if threshold reached
      if (_notificationHelper != null) {
        try {
          final voteCounts = await getVoteCounts(issueId);
          final verifiedCount = voteCounts['verified'] ?? 0;
          
          // Notify when verification threshold (5 votes) is reached
          if (verifiedCount == 5) {
            final report = await getReportById(issueId);
            if (report != null && report.createdBy != null) {
              await _notificationHelper.notifyVoteThreshold(
                userId: report.createdBy!,
                reportId: issueId,
                voteType: 'verified',
                voteCount: verifiedCount,
              );
            }
          }
        } catch (e) {
          // Log error but don't throw - notification failures shouldn't disrupt business logic
          print('Failed to send notification for vote threshold: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// Vote as spam
  Future<void> voteSpam(String issueId) async {
    try {
      await _repository.castVote(issueId: issueId, voteType: 'spam');
      
      // Check vote counts and trigger notification if threshold reached
      if (_notificationHelper != null) {
        try {
          final voteCounts = await getVoteCounts(issueId);
          final spamCount = voteCounts['spam'] ?? 0;
          
          // Notify when spam threshold (3 votes) is reached
          if (spamCount == 3) {
            final report = await getReportById(issueId);
            if (report != null && report.createdBy != null) {
              await _notificationHelper.notifyVoteThreshold(
                userId: report.createdBy!,
                reportId: issueId,
                voteType: 'spam',
                voteCount: spamCount,
              );
            }
          }
        } catch (e) {
          // Log error but don't throw - notification failures shouldn't disrupt business logic
          print('Failed to send notification for vote threshold: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  /// Remove vote
  Future<void> removeVote(String issueId) async {
    try {
      await _repository.removeVote(issueId);
    } catch (e) {
      throw Exception('Failed to remove vote: $e');
    }
  }

  // ========== Authority Actions ==========

  /// Authority: Mark report as reviewed (verified)
  Future<ReportIssueModel> markAsReviewed(
    String issueId, {
    String? comment,
  }) async {
    try {
      final report = await _repository.reviewReportIssue(
        id: issueId,
        status: 'reviewed',
        comment: comment,
      );
      
      // Trigger notification after successful review
      if (_notificationHelper != null) {
        try {
          final reviewerId = getCurrentUserId();
          if (reviewerId != null && report.createdBy != null) {
            await _notificationHelper.notifyReportVerified(
              userId: report.createdBy!,
              reportId: report.id,
              reviewerId: reviewerId,
            );
          }
        } catch (e) {
          // Log error but don't throw - notification failures shouldn't disrupt business logic
          print('Failed to send notification for report verification: $e');
        }
      }
      
      return report;
    } catch (e) {
      throw Exception('Failed to mark as reviewed: $e');
    }
  }

  /// Authority: Mark report as spam
  Future<ReportIssueModel> markAsSpam(String issueId, {String? comment}) async {
    try {
      final report = await _repository.reviewReportIssue(
        id: issueId,
        status: 'spam',
        comment: comment,
      );
      
      // Trigger notification after marking as spam
      if (_notificationHelper != null) {
        try {
          final reviewerId = getCurrentUserId();
          if (reviewerId != null && report.createdBy != null) {
            await _notificationHelper.notifyReportSpam(
              userId: report.createdBy!,
              reportId: report.id,
              reviewerId: reviewerId,
              comment: comment,
            );
          }
        } catch (e) {
          // Log error but don't throw - notification failures shouldn't disrupt business logic
          print('Failed to send notification for spam marking: $e');
        }
      }
      
      return report;
    } catch (e) {
      throw Exception('Failed to mark as spam: $e');
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

  /// Get all votes for an issue (useful for admin/debugging)
  Future<List<IssueVoteModel>> getAllVotes(String issueId) async {
    try {
      return await _repository.getAllVotesForIssue(issueId);
    } catch (e) {
      throw Exception('Failed to fetch votes: $e');
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

  // ========== Helper Methods ==========

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Get public URL for storage file
  String getStoragePublicUrl(String bucket, String path) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Get issue types by IDs
  Future<List<IssueTypeModel>> getIssueTypesByIds(List<String> ids) async {
    try {
      return await _repository.getIssueTypesByIds(ids);
    } catch (e) {
      throw Exception('Failed to get issue types: $e');
    }
  }

  /// Get all issue types
  Future<List<IssueTypeModel>> getIssueTypes() async {
    try {
      return await _repository.getIssueTypes();
    } catch (e) {
      throw Exception('Failed to get issue types: $e');
    }
  }
}

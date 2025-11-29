import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/reputation/reputation_api.dart';
import '../api/notification/notification_api.dart';
import '../models/reputation_model.dart';
import '../../data/repositories/user_repository.dart';
import 'notification_helper_service.dart';

/// Reputation Service
/// Handles reputation score updates and history tracking
class ReputationService {
  final _supabase = Supabase.instance.client;
  late final ReputationApi _reputationApi;
  final _userRepository = UserRepository();
  late final NotificationHelperService _notificationHelper;

  // Reputation score constraints
  static const int minScore = 0;
  static const int maxScore = 100;

  ReputationService() {
    final notificationApi = NotificationApi();
    _notificationHelper = NotificationHelperService(notificationApi);
    _reputationApi = ReputationApi(_supabase, _notificationHelper);
  }

  /// Add reputation points for uploading an issue (+1)
  Future<int> addReputationForUpload(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'UPLOAD_ISSUE',
      changeAmount: 1,
      relatedIssueId: issueId,
      alwaysRecord: true, // Always record even if at max
    );
  }

  /// Add reputation points for issue being verified (+5)
  Future<int> addReputationForVerified(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'ISSUE_VERIFIED',
      changeAmount: 5,
      relatedIssueId: issueId,
    );
  }

  /// Add reputation points for helpful vote (+2)
  Future<int> addReputationForHelpfulVote(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'HELPFUL_VOTE',
      changeAmount: 2,
      relatedIssueId: issueId,
    );
  }

  /// Add reputation points for issue resolved (+10)
  Future<int> addReputationForResolved(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'ISSUE_RESOLVED',
      changeAmount: 10,
      relatedIssueId: issueId,
    );
  }

  /// Deduct reputation points for spam issue (-15)
  Future<int> deductReputationForSpam(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'ISSUE_SPAM',
      changeAmount: -15,
      relatedIssueId: issueId,
    );
  }

  /// Deduct reputation points for rejected issue (-10)
  Future<int> deductReputationForRejection(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'ISSUE_REJECTED',
      changeAmount: -10,
      relatedIssueId: issueId,
    );
  }

  /// Deduct reputation points for duplicate report (-5)
  Future<int> deductReputationForDuplicate(String userId, {String? issueId}) async {
    return await _addReputation(
      userId: userId,
      actionType: 'DUPLICATE_REPORT',
      changeAmount: -5,
      relatedIssueId: issueId,
    );
  }

  /// Internal method to add/deduct reputation
  Future<int> _addReputation({
    required String userId,
    required String actionType,
    required int changeAmount,
    String? relatedIssueId,
    String? notes,
    bool alwaysRecord = false,
  }) async {
    try {
      developer.log(
        '🔄 Starting reputation update: userId=$userId, action=$actionType, change=$changeAmount',
        name: 'ReputationService',
      );

      // Get current user profile
      final profile = await _userRepository.getProfileById(userId);
      if (profile == null) {
        throw Exception('User profile not found for userId: $userId');
      }

      final scoreBefore = profile.reputationScore;
      developer.log(
        '📊 Current score: $scoreBefore',
        name: 'ReputationService',
      );

      // Calculate new score with constraints
      int scoreAfter = scoreBefore + changeAmount;
      scoreAfter = scoreAfter.clamp(minScore, maxScore);

      developer.log(
        '📊 New score calculated: $scoreAfter (clamped from ${scoreBefore + changeAmount})',
        name: 'ReputationService',
      );

      // Update reputation score in profiles table only if it changed
      if (scoreAfter != scoreBefore) {
        developer.log(
          '💾 Updating profiles table...',
          name: 'ReputationService',
        );
        await _supabase
            .from('profiles')
            .update({'reputation_score': scoreAfter})
            .eq('id', userId);
        developer.log('✅ Profiles table updated', name: 'ReputationService');
      } else {
        developer.log(
          'ℹ️ Score unchanged, skipping profiles update',
          name: 'ReputationService',
        );
      }

      // Add reputation history record
      // Always record if alwaysRecord is true (e.g., for submissions at max score)
      developer.log(
        '💾 Creating reputation history record...',
        name: 'ReputationService',
      );

      await _reputationApi.addReputationRecord(
        userId: userId,
        actionType: actionType,
        changeAmount: changeAmount,
        scoreBefore: scoreBefore,
        scoreAfter: scoreAfter,
        relatedIssueId: relatedIssueId,
        notes: notes,
      );

      developer.log(
        '✅ Reputation history record created',
        name: 'ReputationService',
      );

      final statusMsg = scoreBefore == maxScore && scoreAfter == maxScore
          ? 'MAX (no change)'
          : '$scoreBefore -> $scoreAfter';

      developer.log(
        '✅ Reputation updated: $statusMsg ($actionType)',
        name: 'ReputationService',
      );

      // Send notification about reputation change (only if score changed)
      if (scoreAfter != scoreBefore) {
        try {
          await _notificationHelper.notifyReputationChange(
            userId: userId,
            changeAmount: changeAmount,
            actionType: actionType,
            scoreAfter: scoreAfter,
          );
          developer.log(
            '✅ Sent reputation change notification',
            name: 'ReputationService',
          );
        } catch (e) {
          developer.log(
            '⚠️ Failed to send reputation notification: $e',
            name: 'ReputationService',
            error: e,
          );
          // Don't fail the reputation update if notification fails
        }
      }

      // Check for milestone achievements
      if (scoreAfter != scoreBefore) {
        final milestones = [25, 50, 75, 100];
        for (final milestone in milestones) {
          // Check if we just crossed this milestone
          if (scoreBefore < milestone && scoreAfter >= milestone) {
            try {
              await _notificationHelper.notifyReputationMilestone(
                userId: userId,
                milestone: milestone,
              );
              developer.log(
                '🎉 Sent milestone notification for $milestone points',
                name: 'ReputationService',
              );
            } catch (e) {
              developer.log(
                '⚠️ Failed to send milestone notification: $e',
                name: 'ReputationService',
                error: e,
              );
            }
          }
        }
      }

      return scoreAfter;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to update reputation: $e',
        name: 'ReputationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if user has sufficient reputation to create reports
  Future<bool> canCreateReport(String userId) async {
    try {
      final profile = await _userRepository.getProfileById(userId);
      if (profile == null) return false;

      return profile.reputationScore >= 40;
    } catch (e) {
      developer.log(
        '⚠️ Error checking reputation: $e',
        name: 'ReputationService',
        error: e,
      );
      return false;
    }
  }

  /// Check if user has sufficient reputation to request authority role
  Future<bool> canRequestAuthority(String userId) async {
    try {
      final profile = await _userRepository.getProfileById(userId);
      if (profile == null) return false;

      return profile.reputationScore >= 40;
    } catch (e) {
      developer.log(
        '⚠️ Error checking reputation: $e',
        name: 'ReputationService',
        error: e,
      );
      return false;
    }
  }

  /// Get reputation history
  Future<List<ReputationModel>> getHistory(String userId) async {
    return await _reputationApi.getReputationHistory(userId: userId);
  }
}

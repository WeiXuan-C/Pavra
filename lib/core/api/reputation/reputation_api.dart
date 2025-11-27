import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/reputation_model.dart';
import '../../services/notification_helper_service.dart';

/// Reputation API
/// Handles reputation-related operations
class ReputationApi {
  final SupabaseClient _supabase;
  final NotificationHelperService _notificationHelper;

  ReputationApi(this._supabase, this._notificationHelper);

  /// Get reputation history for a user
  Future<List<ReputationModel>> getReputationHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('reputations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ReputationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reputation history: $e');
    }
  }

  /// Add reputation record
  Future<ReputationModel> addReputationRecord({
    required String userId,
    required String actionType,
    required int changeAmount,
    required int scoreBefore,
    required int scoreAfter,
    String? relatedIssueId,
    String? notes,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'action_type': actionType,
        'change_amount': changeAmount,
        'score_before': scoreBefore,
        'score_after': scoreAfter,
        if (relatedIssueId != null) 'related_issue_id': relatedIssueId,
        if (notes != null) 'notes': notes,
      };

      print('🔍 [ReputationApi] Inserting reputation record: $data');

      final response = await _supabase
          .from('reputations')
          .insert(data)
          .select()
          .single();

      print('✅ [ReputationApi] Reputation record created: ${response['id']}');
      
      // Trigger notifications (wrapped in try-catch to prevent disrupting business logic)
      try {
        // Skip notification if changeAmount is zero
        if (changeAmount != 0) {
          // Notify about reputation change
          await _notificationHelper.notifyReputationChange(
            userId: userId,
            changeAmount: changeAmount,
            actionType: actionType,
            scoreAfter: scoreAfter,
          );

          // Check if milestone reached (25, 50, 75, 100)
          final milestones = [25, 50, 75, 100];
          for (final milestone in milestones) {
            // Check if this reputation change crossed a milestone
            if (scoreBefore < milestone && scoreAfter >= milestone) {
              await _notificationHelper.notifyReputationMilestone(
                userId: userId,
                milestone: milestone,
              );
              break; // Only notify for the first milestone crossed
            }
          }
        }
      } catch (e, stackTrace) {
        print('⚠️ [ReputationApi] Failed to send reputation notification: $e');
        print('📋 [ReputationApi] Stack trace: $stackTrace');
        // Don't throw - notification failures shouldn't disrupt business logic
      }
      
      return ReputationModel.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ [ReputationApi] Failed to add reputation record: $e');
      print('📋 [ReputationApi] Stack trace: $stackTrace');
      throw Exception('Failed to add reputation record: $e');
    }
  }

  /// Get total reputation changes by action type
  Future<Map<String, int>> getReputationSummary(String userId) async {
    try {
      final response = await _supabase
          .from('reputations')
          .select('action_type, change_amount')
          .eq('user_id', userId);

      final summary = <String, int>{};
      for (final record in response as List) {
        final actionType = record['action_type'] as String;
        final changeAmount = record['change_amount'] as int;
        summary[actionType] = (summary[actionType] ?? 0) + changeAmount;
      }

      return summary;
    } catch (e) {
      throw Exception('Failed to fetch reputation summary: $e');
    }
  }
}

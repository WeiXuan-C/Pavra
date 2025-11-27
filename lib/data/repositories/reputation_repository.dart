import '../../core/api/reputation/reputation_api.dart';
import '../../core/api/notification/notification_api.dart';
import '../../core/models/reputation_model.dart';
import '../../core/services/notification_helper_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reputation Repository
/// Repository layer for reputation operations
class ReputationRepository {
  late final ReputationApi _api;

  ReputationRepository() {
    final supabaseClient = Supabase.instance.client;
    final notificationApi = NotificationApi();
    final notificationHelper = NotificationHelperService(notificationApi);
    _api = ReputationApi(supabaseClient, notificationHelper);
  }

  /// Get reputation history for a user
  Future<List<ReputationModel>> getReputationHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    return await _api.getReputationHistory(
      userId: userId,
      limit: limit,
      offset: offset,
    );
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
    return await _api.addReputationRecord(
      userId: userId,
      actionType: actionType,
      changeAmount: changeAmount,
      scoreBefore: scoreBefore,
      scoreAfter: scoreAfter,
      relatedIssueId: relatedIssueId,
      notes: notes,
    );
  }

  /// Get reputation summary
  Future<Map<String, int>> getReputationSummary(String userId) async {
    return await _api.getReputationSummary(userId);
  }
}

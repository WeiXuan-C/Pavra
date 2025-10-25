import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/issue_vote_model.dart';

/// Remote data source for issue votes
class IssueVoteRemoteSource {
  final SupabaseClient _supabase;

  IssueVoteRemoteSource(this._supabase);

  /// Fetch user's vote for an issue
  Future<IssueVoteModel?> fetchUserVote(String issueId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('issue_votes')
        .select()
        .eq('issue_id', issueId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return IssueVoteModel.fromJson(response);
  }

  /// Cast vote on an issue
  Future<IssueVoteModel> castVote({
    required String issueId,
    required String voteType, // 'verify' or 'spam'
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'issue_id': issueId,
      'user_id': userId,
      'vote_type': voteType,
    };

    // Use upsert to handle duplicate votes
    final response = await _supabase
        .from('issue_votes')
        .upsert(data, onConflict: 'issue_id,user_id,vote_type')
        .select()
        .single();

    return IssueVoteModel.fromJson(response);
  }

  /// Remove vote
  Future<void> removeVote(String issueId, String voteType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('issue_votes')
        .delete()
        .eq('issue_id', issueId)
        .eq('user_id', userId)
        .eq('vote_type', voteType);
  }

  /// Get vote counts for an issue
  Future<Map<String, int>> getVoteCounts(String issueId) async {
    final response = await _supabase
        .from('report_issues')
        .select('verified_votes, spam_votes')
        .eq('id', issueId)
        .single();

    return {
      'verified': response['verified_votes'] as int? ?? 0,
      'spam': response['spam_votes'] as int? ?? 0,
    };
  }
}

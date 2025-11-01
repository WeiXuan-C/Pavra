import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import '../../models/issue_vote_model.dart';

/// Remote data source for issue votes
/// Note: Only receives SupabaseClient via dependency injection from API layer
/// Does not directly access Supabase.instance
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
  /// Deletes any existing vote and creates a new one
  /// This ensures one vote per user per issue (either 'verify' or 'spam')
  Future<IssueVoteModel> castVote({
    required String issueId,
    required String voteType, // 'verify' or 'spam'
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // First, delete any existing vote by this user for this issue
    // This handles the case where user is changing from verify to spam or vice versa
    await _supabase
        .from('issue_votes')
        .delete()
        .eq('issue_id', issueId)
        .eq('user_id', userId);

    // Then insert the new vote
    final data = {
      'issue_id': issueId,
      'user_id': userId,
      'vote_type': voteType,
    };

    final response = await _supabase
        .from('issue_votes')
        .insert(data)
        .select()
        .single();

    return IssueVoteModel.fromJson(response);
  }

  /// Remove vote
  /// Deletes the user's vote record for the issue
  Future<void> removeVote(String issueId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('issue_votes')
        .delete()
        .eq('issue_id', issueId)
        .eq('user_id', userId);
  }

  /// Get vote counts for an issue by counting from issue_votes table
  /// This ensures accurate real-time counts by querying the actual votes
  Future<Map<String, int>> getVoteCounts(String issueId) async {
    // Fetch all votes for this issue
    final response = await _supabase
        .from('issue_votes')
        .select('vote_type')
        .eq('issue_id', issueId);

    // Count votes by type
    int verifiedCount = 0;
    int spamCount = 0;

    for (final vote in response as List) {
      final voteType = vote['vote_type'] as String?;
      if (voteType == 'verify') {
        verifiedCount++;
      } else if (voteType == 'spam') {
        spamCount++;
      }
    }

    return {'verified': verifiedCount, 'spam': spamCount};
  }

  /// Get all votes for an issue (useful for admin/debugging)
  /// Returns list of all vote records for the specified issue
  Future<List<IssueVoteModel>> fetchAllVotesForIssue(String issueId) async {
    final response = await _supabase
        .from('issue_votes')
        .select()
        .eq('issue_id', issueId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => IssueVoteModel.fromJson(json))
        .toList();
  }
}

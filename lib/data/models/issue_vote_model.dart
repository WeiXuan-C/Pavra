/// Issue Vote Model
/// Maps to issue_votes table in database
class IssueVoteModel {
  final String id;
  final String issueId;
  final String userId;
  final String voteType; // 'verify' or 'spam'
  final DateTime createdAt;
  final DateTime updatedAt;

  IssueVoteModel({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.voteType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IssueVoteModel.fromJson(Map<String, dynamic> json) {
    return IssueVoteModel(
      id: json['id'] as String,
      issueId: json['issue_id'] as String,
      userId: json['user_id'] as String,
      voteType: json['vote_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'user_id': userId,
      'vote_type': voteType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

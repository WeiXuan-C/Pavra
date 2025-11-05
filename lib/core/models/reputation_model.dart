/// Reputation Model
/// Represents reputation history from the reputations table
class ReputationModel {
  final String id;
  final String userId;
  final String
  actionType; // 'UPLOAD_ISSUE', 'ISSUE_REVIEWED', 'AUTHORITY_REJECTED', 'ISSUE_SPAM'
  final int changeAmount;
  final int scoreBefore;
  final int scoreAfter;
  final DateTime createdAt;

  ReputationModel({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.changeAmount,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.createdAt,
  });

  factory ReputationModel.fromJson(Map<String, dynamic> json) {
    return ReputationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      changeAmount: json['change_amount'] as int,
      scoreBefore: json['score_before'] as int,
      scoreAfter: json['score_after'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': actionType,
      'change_amount': changeAmount,
      'score_before': scoreBefore,
      'score_after': scoreAfter,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

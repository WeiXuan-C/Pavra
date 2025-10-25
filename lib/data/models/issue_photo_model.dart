/// Issue Photo Model
/// Maps to issue_photos table in database
class IssuePhotoModel {
  final String id;
  final String issueId;
  final String photoUrl;
  final String photoType; // 'main', 'additional', 'reviewed', 'ai_reference'
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  IssuePhotoModel({
    required this.id,
    required this.issueId,
    required this.photoUrl,
    this.photoType = 'main',
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  });

  factory IssuePhotoModel.fromJson(Map<String, dynamic> json) {
    return IssuePhotoModel(
      id: json['id'] as String,
      issueId: json['issue_id'] as String,
      photoUrl: json['photo_url'] as String,
      photoType: json['photo_type'] as String? ?? 'main',
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'photo_url': photoUrl,
      'photo_type': photoType,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}

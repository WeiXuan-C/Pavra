/// Report Issue Model
/// Maps to report_issues table in database
class ReportIssueModel {
  final String id;
  final String? title;
  final String? description;
  final List<String> issueTypeIds;
  final String severity; // 'minor', 'low', 'moderate', 'high', 'critical'
  final String? address;
  final double? latitude;
  final double? longitude;
  final String status; // 'draft', 'submitted', 'reviewed', 'spam', 'discard'
  final String? reviewedBy;
  final String? reviewedComment;
  final DateTime? reviewedAt;
  final int verifiedVotes;
  final int spamVotes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  ReportIssueModel({
    required this.id,
    this.title,
    this.description,
    this.issueTypeIds = const [],
    this.severity = 'moderate',
    this.address,
    this.latitude,
    this.longitude,
    this.status = 'draft',
    this.reviewedBy,
    this.reviewedComment,
    this.reviewedAt,
    this.verifiedVotes = 0,
    this.spamVotes = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  });

  factory ReportIssueModel.fromJson(Map<String, dynamic> json) {
    return ReportIssueModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      issueTypeIds:
          (json['issue_type_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      severity: json['severity'] as String? ?? 'moderate',
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      status: json['status'] as String? ?? 'draft',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedComment: json['reviewed_comment'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      verifiedVotes: json['verified_votes'] as int? ?? 0,
      spamVotes: json['spam_votes'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
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
      'title': title,
      'description': description,
      'issue_type_ids': issueTypeIds,
      'severity': severity,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_comment': reviewedComment,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'verified_votes': verifiedVotes,
      'spam_votes': spamVotes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  ReportIssueModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? issueTypeIds,
    String? severity,
    String? address,
    double? latitude,
    double? longitude,
    String? status,
    String? reviewedBy,
    String? reviewedComment,
    DateTime? reviewedAt,
    int? verifiedVotes,
    int? spamVotes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return ReportIssueModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      issueTypeIds: issueTypeIds ?? this.issueTypeIds,
      severity: severity ?? this.severity,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedComment: reviewedComment ?? this.reviewedComment,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      verifiedVotes: verifiedVotes ?? this.verifiedVotes,
      spamVotes: spamVotes ?? this.spamVotes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

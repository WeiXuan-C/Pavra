/// Authority Request Model
/// Maps to requests table in database
class AuthorityRequestModel {
  final String id;
  final String userId;
  final String idNumber;
  final String organization;
  final String location;
  final String? referrerCode;
  final String? remarks;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final String? reviewedComment;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  AuthorityRequestModel({
    required this.id,
    required this.userId,
    required this.idNumber,
    required this.organization,
    required this.location,
    this.referrerCode,
    this.remarks,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedComment,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
  });

  factory AuthorityRequestModel.fromJson(Map<String, dynamic> json) {
    return AuthorityRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      idNumber: json['id_number'] as String,
      organization: json['organization'] as String,
      location: json['location'] as String,
      referrerCode: json['referrer_code'] as String?,
      remarks: json['remarks'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedComment: json['reviewed_comment'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
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
      'user_id': userId,
      'id_number': idNumber,
      'organization': organization,
      'location': location,
      'referrer_code': referrerCode,
      'remarks': remarks,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_comment': reviewedComment,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  AuthorityRequestModel copyWith({
    String? id,
    String? userId,
    String? idNumber,
    String? organization,
    String? location,
    String? referrerCode,
    String? remarks,
    String? status,
    String? reviewedBy,
    String? reviewedComment,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return AuthorityRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      idNumber: idNumber ?? this.idNumber,
      organization: organization ?? this.organization,
      location: location ?? this.location,
      referrerCode: referrerCode ?? this.referrerCode,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedComment: reviewedComment ?? this.reviewedComment,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

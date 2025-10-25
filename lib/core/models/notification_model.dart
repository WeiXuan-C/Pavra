/// Notification model - 完全重构版本
///
/// 设计说明：
/// - notifications 表存储通知内容和发送配置
/// - user_notifications 表存储每个用户的独立状态
/// - isRead, isDeleted 默认为 false（非 nullable）
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? relatedAction;
  final Map<String, dynamic>? data;

  // Scheduling fields
  final String status; // draft, scheduled, sent, failed
  final DateTime? scheduledAt;
  final DateTime? sentAt;

  // Target audience fields
  final String targetType; // single, all, role, custom
  final List<String>? targetRoles;
  final List<String>? targetUserIds;

  // Admin metadata
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Admin soft delete (for draft/scheduled notifications)
  final bool isDeletedByAdmin; // notifications 表的 is_deleted
  final DateTime? deletedAt; // notifications 表的 deleted_at

  // User-specific state (from user_notifications join)
  final bool isRead; // 默认 false，非 nullable
  final bool isDeleted; // 默认 false，非 nullable（user_notifications 的 is_deleted）
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedAction,
    this.data,
    this.status = 'sent',
    this.scheduledAt,
    this.sentAt,
    this.targetType = 'single',
    this.targetRoles,
    this.targetUserIds,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isDeletedByAdmin = false,
    this.deletedAt,
    this.isRead = false,
    this.isDeleted = false,
    this.readAt,
  });

  /// Create from JSON (Supabase response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'info',
      relatedAction: json['related_action'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'sent',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      targetType: json['target_type'] as String? ?? 'single',
      targetRoles: json['target_roles'] != null
          ? List<String>.from(json['target_roles'] as List)
          : null,
      targetUserIds: json['target_user_ids'] != null
          ? List<String>.from(json['target_user_ids'] as List)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Admin soft delete fields
      isDeletedByAdmin:
          json['is_deleted_by_admin'] as bool? ??
          json['is_deleted'] as bool? ??
          false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      // User-specific fields (from user_notifications join)
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'related_action': relatedAction,
      'data': data,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'target_type': targetType,
      'target_roles': targetRoles,
      'target_user_ids': targetUserIds,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeletedByAdmin,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? relatedAction,
    Map<String, dynamic>? data,
    String? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? targetType,
    List<String>? targetRoles,
    List<String>? targetUserIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeletedByAdmin,
    DateTime? deletedAt,
    bool? isRead,
    bool? isDeleted,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedAction: relatedAction ?? this.relatedAction,
      data: data ?? this.data,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      targetType: targetType ?? this.targetType,
      targetRoles: targetRoles ?? this.targetRoles,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeletedByAdmin: isDeletedByAdmin ?? this.isDeletedByAdmin,
      deletedAt: deletedAt ?? this.deletedAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      readAt: readAt ?? this.readAt,
    );
  }

  /// 检查是否可以编辑
  /// 规则：只有创建者可以编辑，且状态必须是 draft
  bool canEdit(String? currentUserId) {
    if (currentUserId == null || createdBy == null) return false;
    return createdBy == currentUserId && status == 'draft';
  }

  /// 检查是否可以删除
  /// 规则：只有创建者可以删除，且状态必须是 draft 或 scheduled
  bool canDelete(String? currentUserId) {
    if (currentUserId == null || createdBy == null) return false;
    return createdBy == currentUserId &&
        (status == 'draft' || status == 'scheduled');
  }

  /// 检查是否已过期（发送超过 30 天）
  bool get isExpired {
    final sentDate = sentAt ?? createdAt;
    final daysSinceSent = DateTime.now().difference(sentDate).inDays;
    return daysSinceSent > 30;
  }

  /// Get icon based on notification type
  String get iconName {
    switch (type) {
      case 'success':
        return 'check_circle';
      case 'warning':
        return 'warning';
      case 'alert':
        return 'error';
      case 'system':
        return 'settings';
      case 'user':
        return 'person';
      case 'report':
        return 'report';
      case 'location_alert':
        return 'location_on';
      case 'submission_status':
        return 'assignment';
      case 'promotion':
        return 'campaign';
      case 'reminder':
        return 'notifications';
      default:
        return 'info';
    }
  }

  /// Get color based on notification type
  String get colorHex {
    switch (type) {
      case 'success':
        return '#4CAF50';
      case 'warning':
        return '#FF9800';
      case 'alert':
        return '#F44336';
      case 'system':
        return '#9E9E9E';
      case 'user':
        return '#2196F3';
      case 'report':
        return '#FF5722';
      case 'location_alert':
        return '#E91E63';
      case 'submission_status':
        return '#00BCD4';
      case 'promotion':
        return '#9C27B0';
      case 'reminder':
        return '#FFC107';
      default:
        return '#607D8B';
    }
  }
}

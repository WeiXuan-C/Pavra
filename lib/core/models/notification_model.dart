/// Notification model matching Supabase notifications table
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final bool isDeleted;
  final String? relatedAction;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.isDeleted,
    this.relatedAction,
    this.data,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Create from JSON (Supabase response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'info',
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      relatedAction: json['related_action'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'related_action': relatedAction,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    bool? isDeleted,
    String? relatedAction,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      relatedAction: relatedAction ?? this.relatedAction,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
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

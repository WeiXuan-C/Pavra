/// Service for validating notification input data
///
/// Centralizes all validation logic for notification operations
/// Ensures data integrity and security
class NotificationValidationService {
  /// Maximum length for notification title
  static const int maxTitleLength = 200;

  /// Maximum length for notification message
  static const int maxMessageLength = 2000;

  /// Maximum payload size in bytes (100KB)
  static const int maxPayloadSize = 100 * 1024;

  /// Maximum number of target users for custom targeting
  static const int maxTargetUsers = 1000;

  /// Valid notification types
  static const List<String> validTypes = [
    'success',
    'warning',
    'alert',
    'info',
    'system',
    'user',
    'report',
    'location_alert',
    'submission_status',
    'promotion',
    'reminder',
  ];

  /// Valid notification statuses
  static const List<String> validStatuses = [
    'draft',
    'scheduled',
    'sent',
    'failed',
    'cancelled',
  ];

  /// Valid target types
  static const List<String> validTargetTypes = [
    'single',
    'all',
    'role',
    'custom',
  ];

  /// Valid user roles
  static const List<String> validRoles = [
    'user',
    'developer',
    'authority',
    'admin',
  ];

  /// Valid notification categories (Android)
  static const List<String> validCategories = [
    'alarm',
    'call',
    'email',
    'err',
    'event',
    'msg',
    'navigation',
    'progress',
    'promo',
    'recommendation',
    'reminder',
    'service',
    'social',
    'status',
    'sys',
    'transport',
  ];

  /// Valid sound files
  static const List<String> validSounds = [
    'default',
    'alert',
    'warning',
    'success',
  ];

  /// Validate notification title
  ///
  /// Returns error message if invalid, null if valid
  String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Title is required';
    }

    if (title.length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or less';
    }

    // Check for potentially malicious content
    if (_containsMaliciousContent(title)) {
      return 'Title contains invalid characters';
    }

    return null;
  }

  /// Validate notification message
  ///
  /// Returns error message if invalid, null if valid
  String? validateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Message is required';
    }

    if (message.length > maxMessageLength) {
      return 'Message must be $maxMessageLength characters or less';
    }

    // Check for potentially malicious content
    if (_containsMaliciousContent(message)) {
      return 'Message contains invalid characters';
    }

    return null;
  }

  /// Validate notification type
  ///
  /// Returns error message if invalid, null if valid
  String? validateType(String? type) {
    if (type == null || type.trim().isEmpty) {
      return 'Type is required';
    }

    if (!validTypes.contains(type)) {
      return 'Invalid type. Must be one of: ${validTypes.join(", ")}';
    }

    return null;
  }

  /// Validate notification status
  ///
  /// Returns error message if invalid, null if valid
  String? validateStatus(String? status) {
    if (status == null || status.trim().isEmpty) {
      return 'Status is required';
    }

    if (!validStatuses.contains(status)) {
      return 'Invalid status. Must be one of: ${validStatuses.join(", ")}';
    }

    return null;
  }

  /// Validate target type
  ///
  /// Returns error message if invalid, null if valid
  String? validateTargetType(String? targetType) {
    if (targetType == null || targetType.trim().isEmpty) {
      return 'Target type is required';
    }

    if (!validTargetTypes.contains(targetType)) {
      return 'Invalid target type. Must be one of: ${validTargetTypes.join(", ")}';
    }

    return null;
  }

  /// Validate target user IDs
  ///
  /// Returns error message if invalid, null if valid
  String? validateTargetUserIds(List<String>? userIds, String targetType) {
    if (targetType == 'single' || targetType == 'custom') {
      if (userIds == null || userIds.isEmpty) {
        return 'Target user IDs are required for target type: $targetType';
      }

      if (userIds.length > maxTargetUsers) {
        return 'Cannot target more than $maxTargetUsers users at once';
      }

      // Validate UUID format for each user ID
      for (final userId in userIds) {
        if (!_isValidUuid(userId)) {
          return 'Invalid user ID format: $userId';
        }
      }
    }

    return null;
  }

  /// Validate target roles
  ///
  /// Returns error message if invalid, null if valid
  String? validateTargetRoles(List<String>? roles, String targetType) {
    if (targetType == 'role') {
      if (roles == null || roles.isEmpty) {
        return 'Target roles are required for target type: role';
      }

      // Validate each role
      for (final role in roles) {
        if (!validRoles.contains(role)) {
          return 'Invalid role: $role. Must be one of: ${validRoles.join(", ")}';
        }
      }
    }

    return null;
  }

  /// Validate scheduled time
  ///
  /// Returns error message if invalid, null if valid
  String? validateScheduledAt(DateTime? scheduledAt, String status) {
    if (status == 'scheduled') {
      if (scheduledAt == null) {
        return 'Scheduled time is required for status: scheduled';
      }

      // Must be in the future
      if (scheduledAt.isBefore(DateTime.now())) {
        return 'Scheduled time must be in the future';
      }

      // Not too far in the future (1 year max)
      final oneYearFromNow = DateTime.now().add(Duration(days: 365));
      if (scheduledAt.isAfter(oneYearFromNow)) {
        return 'Scheduled time cannot be more than 1 year in the future';
      }
    }

    return null;
  }

  /// Validate notification data payload
  ///
  /// Returns error message if invalid, null if valid
  String? validateData(Map<String, dynamic>? data) {
    if (data == null) {
      return null; // Data is optional
    }

    // Check payload size
    final jsonString = data.toString();
    final sizeInBytes = jsonString.length;

    if (sizeInBytes > maxPayloadSize) {
      return 'Data payload exceeds maximum size of ${maxPayloadSize ~/ 1024}KB';
    }

    // Validate data structure (no deeply nested objects)
    if (_isExcessivelyNested(data, 0)) {
      return 'Data payload is too deeply nested (max 5 levels)';
    }

    return null;
  }

  /// Validate notification category
  ///
  /// Returns error message if invalid, null if valid
  String? validateCategory(String? category) {
    if (category == null) {
      return null; // Category is optional
    }

    if (!validCategories.contains(category)) {
      return 'Invalid category. Must be one of: ${validCategories.join(", ")}';
    }

    return null;
  }

  /// Validate notification sound
  ///
  /// Returns error message if invalid, null if valid
  String? validateSound(String? sound) {
    if (sound == null) {
      return null; // Sound is optional
    }

    if (!validSounds.contains(sound)) {
      return 'Invalid sound. Must be one of: ${validSounds.join(", ")}';
    }

    return null;
  }

  /// Validate notification priority
  ///
  /// Returns error message if invalid, null if valid
  String? validatePriority(int? priority) {
    if (priority == null) {
      return null; // Priority is optional (defaults to 5)
    }

    if (priority < 1 || priority > 10) {
      return 'Priority must be between 1 and 10';
    }

    return null;
  }

  /// Validate complete notification data
  ///
  /// Returns list of validation errors, empty if valid
  List<String> validateNotification({
    required String title,
    required String message,
    required String type,
    String status = 'sent',
    DateTime? scheduledAt,
    String targetType = 'single',
    List<String>? targetUserIds,
    List<String>? targetRoles,
    Map<String, dynamic>? data,
    String? category,
    String? sound,
    int? priority,
  }) {
    final errors = <String>[];

    // Validate required fields
    final titleError = validateTitle(title);
    if (titleError != null) errors.add(titleError);

    final messageError = validateMessage(message);
    if (messageError != null) errors.add(messageError);

    final typeError = validateType(type);
    if (typeError != null) errors.add(typeError);

    final statusError = validateStatus(status);
    if (statusError != null) errors.add(statusError);

    final targetTypeError = validateTargetType(targetType);
    if (targetTypeError != null) errors.add(targetTypeError);

    // Validate conditional fields
    final userIdsError = validateTargetUserIds(targetUserIds, targetType);
    if (userIdsError != null) errors.add(userIdsError);

    final rolesError = validateTargetRoles(targetRoles, targetType);
    if (rolesError != null) errors.add(rolesError);

    final scheduledAtError = validateScheduledAt(scheduledAt, status);
    if (scheduledAtError != null) errors.add(scheduledAtError);

    // Validate optional fields
    final dataError = validateData(data);
    if (dataError != null) errors.add(dataError);

    final categoryError = validateCategory(category);
    if (categoryError != null) errors.add(categoryError);

    final soundError = validateSound(sound);
    if (soundError != null) errors.add(soundError);

    final priorityError = validatePriority(priority);
    if (priorityError != null) errors.add(priorityError);

    return errors;
  }

  /// Sanitize string input by removing potentially dangerous characters
  String sanitizeString(String input) {
    // Remove control characters and non-printable characters
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Sanitize notification data
  Map<String, dynamic> sanitizeNotificationData({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return {
      'title': sanitizeString(title.trim()),
      'message': sanitizeString(message.trim()),
      if (data != null) 'data': _sanitizeMap(data),
    };
  }

  /// Check if string contains potentially malicious content
  bool _containsMaliciousContent(String input) {
    // Check for script tags
    if (input.toLowerCase().contains('<script')) {
      return true;
    }

    // Check for SQL injection patterns
    if (RegExp(r"('|(--)|;|\/\*|\*\/|xp_|sp_)", caseSensitive: false)
        .hasMatch(input)) {
      return true;
    }

    return false;
  }

  /// Check if UUID is valid format
  bool _isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }

  /// Check if data structure is excessively nested
  bool _isExcessivelyNested(dynamic data, int depth) {
    const maxDepth = 5;

    if (depth > maxDepth) {
      return true;
    }

    if (data is Map) {
      for (final value in data.values) {
        if (_isExcessivelyNested(value, depth + 1)) {
          return true;
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (_isExcessivelyNested(item, depth + 1)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Sanitize map by removing potentially dangerous values
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        sanitized[key] = sanitizeString(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List) {
        sanitized[key] = _sanitizeList(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Sanitize list by removing potentially dangerous values
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return sanitizeString(item);
      } else if (item is Map<String, dynamic>) {
        return _sanitizeMap(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }
}

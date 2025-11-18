/// Queued Detection Model
/// Represents a detection that is queued for processing when offline
class QueuedDetection {
  final String id;
  final String imagePath; // Local file path to the image
  final double latitude;
  final double longitude;
  final String userId;
  final DateTime timestamp;
  final int retryCount;
  final int sensitivity;

  QueuedDetection({
    String? id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.userId,
    required this.timestamp,
    this.retryCount = 0,
    this.sensitivity = 3,
  }) : id = id ?? _generateId();

  /// Create QueuedDetection from JSON (for persistence)
  factory QueuedDetection.fromJson(Map<String, dynamic> json) {
    return QueuedDetection(
      id: json['id'] as String,
      imagePath: json['image_path'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      sensitivity: json['sensitivity'] as int? ?? 3,
    );
  }

  /// Convert QueuedDetection to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
      'sensitivity': sensitivity,
    };
  }

  /// Create a copy with modified fields
  QueuedDetection copyWith({
    String? id,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? userId,
    DateTime? timestamp,
    int? retryCount,
    int? sensitivity,
  }) {
    return QueuedDetection(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      sensitivity: sensitivity ?? this.sensitivity,
    );
  }

  /// Increment retry count
  QueuedDetection incrementRetry() {
    return copyWith(retryCount: retryCount + 1);
  }

  /// Generate a unique ID for the queued detection
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000000}';
  }

  @override
  String toString() {
    return 'QueuedDetection(id: $id, userId: $userId, retryCount: $retryCount, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QueuedDetection &&
        other.id == id &&
        other.imagePath == imagePath &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.retryCount == retryCount &&
        other.sensitivity == sensitivity;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      imagePath,
      latitude,
      longitude,
      userId,
      timestamp,
      retryCount,
      sensitivity,
    );
  }
}

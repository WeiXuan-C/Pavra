import 'detection_type.dart';

/// Detection Model
/// Represents an AI detection result from the backend API
class DetectionModel {
  final String id;
  final bool issueDetected;
  final DetectionType type;
  final int severity; // 1-5 scale
  final String description;
  final String suggestedAction;
  final double confidence; // 0.0-1.0
  final String imageUrl;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  DetectionModel({
    required this.id,
    required this.issueDetected,
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestedAction,
    required this.confidence,
    required this.imageUrl,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  /// Create DetectionModel from JSON response
  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      id: json['id'] as String,
      issueDetected: json['issue_detected'] as bool,
      type: DetectionType.fromString(json['type'] as String),
      severity: json['severity'] as int,
      description: json['description'] as String,
      suggestedAction: json['suggested_action'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  /// Convert DetectionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_detected': issueDetected,
      'type': type.value,
      'severity': severity,
      'description': description,
      'suggested_action': suggestedAction,
      'confidence': confidence,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create a copy with modified fields
  DetectionModel copyWith({
    String? id,
    bool? issueDetected,
    DetectionType? type,
    int? severity,
    String? description,
    String? suggestedAction,
    double? confidence,
    String? imageUrl,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return DetectionModel(
      id: id ?? this.id,
      issueDetected: issueDetected ?? this.issueDetected,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Check if this is a high severity detection (red alert)
  bool get isHighSeverity => severity >= 4 || type == DetectionType.accident;

  /// Check if this is a medium severity detection (yellow alert)
  bool get isMediumSeverity => severity >= 2 && severity <= 3 && !isHighSeverity;

  /// Check if this is a low severity detection (green status)
  bool get isLowSeverity => !issueDetected || type == DetectionType.normal || severity == 1;

  @override
  String toString() {
    return 'DetectionModel(id: $id, type: ${type.value}, severity: $severity, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetectionModel &&
        other.id == id &&
        other.issueDetected == issueDetected &&
        other.type == type &&
        other.severity == severity &&
        other.description == description &&
        other.suggestedAction == suggestedAction &&
        other.confidence == confidence &&
        other.imageUrl == imageUrl &&
        other.createdAt == createdAt &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      issueDetected,
      type,
      severity,
      description,
      suggestedAction,
      confidence,
      imageUrl,
      createdAt,
      latitude,
      longitude,
    );
  }
}

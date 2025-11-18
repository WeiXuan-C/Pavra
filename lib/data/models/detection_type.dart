/// Detection Type Enum
/// Represents the 8 types of road conditions that can be detected by AI
enum DetectionType {
  roadCrack('road_crack'),
  pothole('pothole'),
  unevenSurface('uneven_surface'),
  flood('flood'),
  accident('accident'),
  debris('debris'),
  obstacle('obstacle'),
  normal('normal');

  const DetectionType(this.value);

  final String value;

  /// Parse detection type from string value
  static DetectionType fromString(String value) {
    switch (value) {
      case 'road_crack':
        return DetectionType.roadCrack;
      case 'pothole':
        return DetectionType.pothole;
      case 'uneven_surface':
        return DetectionType.unevenSurface;
      case 'flood':
        return DetectionType.flood;
      case 'accident':
        return DetectionType.accident;
      case 'debris':
        return DetectionType.debris;
      case 'obstacle':
        return DetectionType.obstacle;
      case 'normal':
        return DetectionType.normal;
      default:
        return DetectionType.normal;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case DetectionType.roadCrack:
        return 'Road Crack';
      case DetectionType.pothole:
        return 'Pothole';
      case DetectionType.unevenSurface:
        return 'Uneven Surface';
      case DetectionType.flood:
        return 'Flood';
      case DetectionType.accident:
        return 'Accident';
      case DetectionType.debris:
        return 'Debris';
      case DetectionType.obstacle:
        return 'Obstacle';
      case DetectionType.normal:
        return 'Normal';
    }
  }
}

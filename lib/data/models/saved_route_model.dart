class SavedRouteModel {
  final String id;
  final String userId;
  final String name;
  final String fromLocationName;
  final double fromLatitude;
  final double fromLongitude;
  final String? fromAddress;
  final String toLocationName;
  final double toLatitude;
  final double toLongitude;
  final String? toAddress;
  final double? distanceKm;
  final String travelMode;
  final bool isMonitoring;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  SavedRouteModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.fromLocationName,
    required this.fromLatitude,
    required this.fromLongitude,
    this.fromAddress,
    required this.toLocationName,
    required this.toLatitude,
    required this.toLongitude,
    this.toAddress,
    this.distanceKm,
    this.travelMode = 'driving',
    required this.isMonitoring,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDeleted,
  });

  factory SavedRouteModel.fromJson(Map<String, dynamic> json) {
    return SavedRouteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      fromLocationName: json['from_location_name'] as String,
      fromLatitude: (json['from_latitude'] as num).toDouble(),
      fromLongitude: (json['from_longitude'] as num).toDouble(),
      fromAddress: json['from_address'] as String?,
      toLocationName: json['to_location_name'] as String,
      toLatitude: (json['to_latitude'] as num).toDouble(),
      toLongitude: (json['to_longitude'] as num).toDouble(),
      toAddress: json['to_address'] as String?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      travelMode: json['travel_mode'] as String? ?? 'driving',
      isMonitoring: json['is_monitoring'] as bool? ?? false,
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
      'name': name,
      'from_location_name': fromLocationName,
      'from_latitude': fromLatitude,
      'from_longitude': fromLongitude,
      'from_address': fromAddress,
      'to_location_name': toLocationName,
      'to_latitude': toLatitude,
      'to_longitude': toLongitude,
      'to_address': toAddress,
      'distance_km': distanceKm,
      'travel_mode': travelMode,
      'is_monitoring': isMonitoring,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  SavedRouteModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? fromLocationName,
    double? fromLatitude,
    double? fromLongitude,
    String? fromAddress,
    String? toLocationName,
    double? toLatitude,
    double? toLongitude,
    String? toAddress,
    double? distanceKm,
    String? travelMode,
    bool? isMonitoring,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return SavedRouteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      fromLocationName: fromLocationName ?? this.fromLocationName,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      fromAddress: fromAddress ?? this.fromAddress,
      toLocationName: toLocationName ?? this.toLocationName,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      toAddress: toAddress ?? this.toAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      travelMode: travelMode ?? this.travelMode,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String get distanceDisplay {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}

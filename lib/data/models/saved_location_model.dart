class SavedLocationModel {
  final String id;
  final String userId;
  final String label; // Home, Work, School, etc.
  final String locationName;
  final double latitude;
  final double longitude;
  final String? address;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  SavedLocationModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDeleted,
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    return SavedLocationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String,
      locationName: json['location_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      icon: json['icon'] as String? ?? 'place',
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
      'label': label,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  SavedLocationModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? locationName,
    double? latitude,
    double? longitude,
    String? address,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
  }) {
    return SavedLocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

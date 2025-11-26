import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteWaypointModel {
  final String id;
  final String routeId;
  final int waypointOrder;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime createdAt;

  RouteWaypointModel({
    required this.id,
    required this.routeId,
    required this.waypointOrder,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.createdAt,
  });

  factory RouteWaypointModel.fromJson(Map<String, dynamic> json) {
    return RouteWaypointModel(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      waypointOrder: json['waypoint_order'] as int,
      locationName: json['location_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'waypoint_order': waypointOrder,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  RouteWaypointModel copyWith({
    String? id,
    String? routeId,
    int? waypointOrder,
    String? locationName,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
  }) {
    return RouteWaypointModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      waypointOrder: waypointOrder ?? this.waypointOrder,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

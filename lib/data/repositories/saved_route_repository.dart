import '../models/saved_route_model.dart';
import '../models/saved_location_model.dart';
import '../models/route_waypoint_model.dart';
import '../../core/api/saved_route/saved_route_api.dart';

class SavedRouteRepository {
  final SavedRouteApi _api;

  SavedRouteRepository(this._api);

  // ========== Saved Routes ==========

  Future<List<SavedRouteModel>> getSavedRoutes() async {
    return await _api.getSavedRoutes();
  }

  Future<List<SavedRouteModel>> getActiveRoutes() async {
    return await _api.getActiveRoutes();
  }

  Future<SavedRouteModel> createRoute({
    required String name,
    required String fromLocationName,
    required double fromLatitude,
    required double fromLongitude,
    String? fromAddress,
    required String toLocationName,
    required double toLatitude,
    required double toLongitude,
    String? toAddress,
    double? distanceKm,
    bool isMonitoring = false,
    String travelMode = 'driving',
  }) async {
    return await _api.createRoute(
      name: name,
      fromLocationName: fromLocationName,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
      fromAddress: fromAddress,
      toLocationName: toLocationName,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
      toAddress: toAddress,
      distanceKm: distanceKm,
      isMonitoring: isMonitoring,
      travelMode: travelMode,
    );
  }

  /// Create a route with waypoints in a single operation
  Future<Map<String, dynamic>> createRouteWithWaypoints({
    required String name,
    required String fromLocationName,
    required double fromLatitude,
    required double fromLongitude,
    String? fromAddress,
    required String toLocationName,
    required double toLatitude,
    required double toLongitude,
    String? toAddress,
    required List<Map<String, dynamic>> waypoints,
    double? distanceKm,
    bool isMonitoring = false,
    String travelMode = 'driving',
  }) async {
    return await _api.createRouteWithWaypoints(
      name: name,
      fromLocationName: fromLocationName,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
      fromAddress: fromAddress,
      toLocationName: toLocationName,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
      toAddress: toAddress,
      waypoints: waypoints,
      distanceKm: distanceKm,
      isMonitoring: isMonitoring,
      travelMode: travelMode,
    );
  }

  /// Get a route with its waypoints
  Future<Map<String, dynamic>> getRouteWithWaypoints(String routeId) async {
    return await _api.getRouteWithWaypoints(routeId);
  }

  /// Update waypoints for a route (replaces all existing waypoints)
  Future<List<RouteWaypointModel>> updateRouteWaypoints({
    required String routeId,
    required List<Map<String, dynamic>> waypoints,
  }) async {
    return await _api.updateRouteWaypoints(
      routeId: routeId,
      waypoints: waypoints,
    );
  }

  Future<SavedRouteModel> updateRoute(
    String routeId,
    Map<String, dynamic> updates,
  ) async {
    return await _api.updateRoute(routeId, updates);
  }

  Future<void> toggleRouteMonitoring(String routeId, bool isMonitoring) async {
    await _api.toggleRouteMonitoring(routeId, isMonitoring);
  }

  Future<void> deleteRoute(String routeId) async {
    await _api.deleteRoute(routeId);
  }

  // ========== Saved Locations ==========

  Future<List<SavedLocationModel>> getSavedLocations() async {
    return await _api.getSavedLocations();
  }

  Future<SavedLocationModel?> getLocationByLabel(String label) async {
    return await _api.getLocationByLabel(label);
  }

  Future<SavedLocationModel> upsertLocation({
    required String label,
    required String locationName,
    required double latitude,
    required double longitude,
    String? address,
    String icon = 'place',
  }) async {
    return await _api.upsertLocation(
      label: label,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      address: address,
      icon: icon,
    );
  }

  Future<void> deleteLocation(String locationId) async {
    await _api.deleteLocation(locationId);
  }

  // ========== Route Waypoints ==========

  Future<List<RouteWaypointModel>> getRouteWaypoints(String routeId) async {
    return await _api.getRouteWaypoints(routeId);
  }

  Future<RouteWaypointModel> createWaypoint({
    required String routeId,
    required int waypointOrder,
    required String locationName,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    return await _api.createWaypoint(
      routeId: routeId,
      waypointOrder: waypointOrder,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  Future<void> deleteRouteWaypoints(String routeId) async {
    await _api.deleteRouteWaypoints(routeId);
  }
}

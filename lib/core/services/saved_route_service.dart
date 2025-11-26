import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_waypoint_model.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../utils/error_handler.dart';

/// Service for managing saved multi-stop routes
class SavedRouteService {
  final SavedRouteRepository _repository;

  SavedRouteService(this._repository);

  /// Save a multi-stop route with waypoints
  /// Throws InvalidWaypointCoordinatesException if coordinates are invalid
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<SavedRouteWithWaypoints> saveRoute({
    required String name,
    required LatLng start,
    required List<LatLng> waypoints,
    required LatLng destination,
    required String travelMode,
    double? totalDistance,
  }) async {
    try {
      // Validate coordinates
      ErrorHandler.validateCoordinates(start.latitude, start.longitude);
      ErrorHandler.validateCoordinates(destination.latitude, destination.longitude);
      for (final waypoint in waypoints) {
        ErrorHandler.validateCoordinates(waypoint.latitude, waypoint.longitude);
      }

      // Create the route
      final route = await _repository.createRoute(
        name: name,
        fromLocationName: 'Start',
        fromLatitude: start.latitude,
        fromLongitude: start.longitude,
        toLocationName: 'Destination',
        toLatitude: destination.latitude,
        toLongitude: destination.longitude,
        distanceKm: totalDistance,
      );

      // Update travel mode
      final updatedRoute = await _repository.updateRoute(
        route.id,
        {'travel_mode': travelMode},
      );

      // Insert waypoints
      final waypointModels = <RouteWaypointModel>[];
      for (int i = 0; i < waypoints.length; i++) {
        final waypoint = waypoints[i];
        final waypointModel = await _repository.createWaypoint(
          routeId: route.id,
          waypointOrder: i + 1,
          locationName: 'Waypoint ${i + 1}',
          latitude: waypoint.latitude,
          longitude: waypoint.longitude,
        );
        waypointModels.add(waypointModel);
      }

      return SavedRouteWithWaypoints(
        id: updatedRoute.id,
        name: updatedRoute.name,
        start: start,
        waypoints: waypoints,
        destination: destination,
        travelMode: travelMode,
        totalDistance: totalDistance,
        createdAt: updatedRoute.createdAt,
      );
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('SavedRouteService.saveRoute', e);
        rethrow;
      }

      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedRouteService.saveRoute', e);
      rethrow;
    }
  }

  /// Get all saved routes
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<List<SavedRouteWithWaypoints>> getSavedRoutes() async {
    try {
      final routes = await _repository.getSavedRoutes();
      final routesWithWaypoints = <SavedRouteWithWaypoints>[];

      for (final route in routes) {
        final waypoints = await _repository.getRouteWaypoints(route.id);
        routesWithWaypoints.add(
          SavedRouteWithWaypoints(
            id: route.id,
            name: route.name,
            start: LatLng(route.fromLatitude, route.fromLongitude),
            waypoints: waypoints.map((w) => w.toLatLng()).toList(),
            destination: LatLng(route.toLatitude, route.toLongitude),
            travelMode: route.travelMode,
            totalDistance: route.distanceKm,
            createdAt: route.createdAt,
          ),
        );
      }

      return routesWithWaypoints;
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedRouteService.getSavedRoutes', e);
      rethrow;
    }
  }

  /// Load a saved route with waypoints
  /// Throws RecordNotFoundException if route not found
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<SavedRouteWithWaypoints?> loadRoute(String routeId) async {
    try {
      // Get all routes and find the one we want
      final routes = await _repository.getSavedRoutes();
      final route = routes.where((r) => r.id == routeId).firstOrNull;

      if (route == null) {
        throw RecordNotFoundException('Route', routeId);
      }

      final waypoints = await _repository.getRouteWaypoints(routeId);

      return SavedRouteWithWaypoints(
        id: route.id,
        name: route.name,
        start: LatLng(route.fromLatitude, route.fromLongitude),
        waypoints: waypoints.map((w) => w.toLatLng()).toList(),
        destination: LatLng(route.toLatitude, route.toLongitude),
        travelMode: route.travelMode,
        totalDistance: route.distanceKm,
        createdAt: route.createdAt,
      );
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('SavedRouteService.loadRoute', e);
        rethrow;
      }

      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedRouteService.loadRoute', e);
      throw DatabaseException('Failed to load route: ${e.toString()}', originalError: e);
    }
  }

  /// Update a saved route
  /// Throws RecordNotFoundException if route not found
  /// Throws InvalidWaypointCoordinatesException if coordinates are invalid
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<SavedRouteWithWaypoints> updateRoute({
    required String routeId,
    String? name,
    List<LatLng>? waypoints,
  }) async {
    try {
      // Load existing route
      final existingRoute = await loadRoute(routeId);
      if (existingRoute == null) {
        throw RecordNotFoundException('Route', routeId);
      }

      // Validate waypoint coordinates if provided
      if (waypoints != null) {
        for (final waypoint in waypoints) {
          ErrorHandler.validateCoordinates(waypoint.latitude, waypoint.longitude);
        }
      }

      // Update route name if provided
      if (name != null) {
        await _repository.updateRoute(routeId, {'name': name});
      }

      // Update waypoints if provided
      if (waypoints != null) {
        // Delete existing waypoints
        await _repository.deleteRouteWaypoints(routeId);

        // Insert new waypoints
        for (int i = 0; i < waypoints.length; i++) {
          final waypoint = waypoints[i];
          await _repository.createWaypoint(
            routeId: routeId,
            waypointOrder: i + 1,
            locationName: 'Waypoint ${i + 1}',
            latitude: waypoint.latitude,
            longitude: waypoint.longitude,
          );
        }
      }

      // Return updated route
      return await loadRoute(routeId) ?? existingRoute;
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('SavedRouteService.updateRoute', e);
        rethrow;
      }

      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedRouteService.updateRoute', e);
      rethrow;
    }
  }

  /// Delete a saved route (soft delete)
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<void> deleteRoute(String routeId) async {
    try {
      await _repository.deleteRoute(routeId);
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedRouteService.deleteRoute', e);
      rethrow;
    }
  }

  /// Share route as text
  String shareRouteAsText(SavedRouteWithWaypoints route) {
    final buffer = StringBuffer();
    buffer.writeln('Route: ${route.name}');
    buffer.writeln('Travel Mode: ${route.travelMode}');
    buffer.writeln('Start: ${route.start.latitude},${route.start.longitude}');
    
    for (int i = 0; i < route.waypoints.length; i++) {
      final waypoint = route.waypoints[i];
      buffer.writeln('Waypoint ${i + 1}: ${waypoint.latitude},${waypoint.longitude}');
    }
    
    buffer.writeln('Destination: ${route.destination.latitude},${route.destination.longitude}');
    
    if (route.totalDistance != null) {
      buffer.writeln('Distance: ${route.totalDistance} km');
    }
    
    return buffer.toString();
  }

  /// Import route from shared text
  /// Throws DatabaseException if import fails
  /// Throws InvalidWaypointCoordinatesException if coordinates are invalid
  Future<SavedRouteWithWaypoints?> importRoute(String sharedText) async {
    try {
      final lines = sharedText.split('\n').where((line) => line.isNotEmpty).toList();
      
      String? name;
      String? travelMode;
      LatLng? start;
      LatLng? destination;
      final waypoints = <LatLng>[];
      double? totalDistance;

      for (final line in lines) {
        if (line.startsWith('Route: ')) {
          name = line.substring(7).trim();
        } else if (line.startsWith('Travel Mode: ')) {
          travelMode = line.substring(13).trim();
        } else if (line.startsWith('Start: ')) {
          final coords = line.substring(7).split(',');
          start = LatLng(double.parse(coords[0]), double.parse(coords[1]));
        } else if (line.startsWith('Waypoint ')) {
          final coords = line.split(': ')[1].split(',');
          waypoints.add(LatLng(double.parse(coords[0]), double.parse(coords[1])));
        } else if (line.startsWith('Destination: ')) {
          final coords = line.substring(13).split(',');
          destination = LatLng(double.parse(coords[0]), double.parse(coords[1]));
        } else if (line.startsWith('Distance: ')) {
          final distStr = line.substring(10).replaceAll(' km', '').trim();
          totalDistance = double.tryParse(distStr);
        }
      }

      if (name == null || travelMode == null || start == null || destination == null) {
        throw DatabaseException('Invalid route format: missing required fields');
      }

      return await saveRoute(
        name: name,
        start: start,
        waypoints: waypoints,
        destination: destination,
        travelMode: travelMode,
        totalDistance: totalDistance,
      );
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('SavedRouteService.importRoute', e);
        rethrow;
      }

      ErrorHandler.logError('SavedRouteService.importRoute', e);
      throw DatabaseException('Failed to import route: ${e.toString()}', originalError: e);
    }
  }

}

/// Model for saved route with waypoints
class SavedRouteWithWaypoints {
  final String id;
  final String name;
  final LatLng start;
  final List<LatLng> waypoints;
  final LatLng destination;
  final String travelMode;
  final double? totalDistance;
  final DateTime createdAt;

  SavedRouteWithWaypoints({
    required this.id,
    required this.name,
    required this.start,
    required this.waypoints,
    required this.destination,
    required this.travelMode,
    this.totalDistance,
    required this.createdAt,
  });

  SavedRouteWithWaypoints copyWith({
    String? id,
    String? name,
    LatLng? start,
    List<LatLng>? waypoints,
    LatLng? destination,
    String? travelMode,
    double? totalDistance,
    DateTime? createdAt,
  }) {
    return SavedRouteWithWaypoints(
      id: id ?? this.id,
      name: name ?? this.name,
      start: start ?? this.start,
      waypoints: waypoints ?? this.waypoints,
      destination: destination ?? this.destination,
      travelMode: travelMode ?? this.travelMode,
      totalDistance: totalDistance ?? this.totalDistance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

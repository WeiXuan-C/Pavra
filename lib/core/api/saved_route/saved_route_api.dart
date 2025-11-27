import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/saved_route_model.dart';
import '../../../data/models/saved_location_model.dart';
import '../../../data/models/route_waypoint_model.dart';
import '../../services/notification_helper_service.dart';

class SavedRouteApi {
  final SupabaseClient _supabase;
  final NotificationHelperService _notificationHelper;

  SavedRouteApi(this._supabase, this._notificationHelper);

  // ========== Route Monitoring Resolution ==========

  /// Get users monitoring routes that pass through a location
  /// 
  /// Returns a list of user IDs who are monitoring routes that pass within
  /// the specified buffer distance of the given location.
  /// 
  /// Parameters:
  /// - [latitude]: Latitude of the location
  /// - [longitude]: Longitude of the location
  /// - [bufferKm]: Buffer distance in kilometers (default: 0.5km)
  /// 
  /// Returns empty list on error to prevent disrupting business logic.
  Future<List<String>> getUsersMonitoringRoute({
    required double latitude,
    required double longitude,
    double bufferKm = 0.5,
  }) async {
    try {
      developer.log(
        'Getting users monitoring routes near location ($latitude, $longitude) within ${bufferKm}km buffer',
        name: 'SavedRouteApi',
      );

      final response = await _supabase.rpc(
        'get_users_monitoring_route',
        params: {
          'lat': latitude,
          'lng': longitude,
          'buffer_km': bufferKm,
        },
      );

      if (response == null) {
        developer.log(
          'No users monitoring routes found (null response)',
          name: 'SavedRouteApi',
        );
        return [];
      }

      // Response is a list of objects with user_id field
      final List<dynamic> results = response as List<dynamic>;
      final userIds = results
          .map((row) => row['user_id'] as String)
          .toList();

      developer.log(
        'Found ${userIds.length} users monitoring routes',
        name: 'SavedRouteApi',
      );

      return userIds;
    } catch (e, stackTrace) {
      // Log error with full context
      developer.log(
        'Failed to get users monitoring route',
        name: 'SavedRouteApi',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
      
      // Log query parameters for debugging
      developer.log(
        'Query context: latitude=$latitude, longitude=$longitude, bufferKm=$bufferKm',
        name: 'SavedRouteApi',
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
      
      // Return empty list on error to prevent disrupting business logic
      return [];
    }
  }

  // ========== Saved Routes ==========

  /// Get all saved routes for the current user
  Future<List<SavedRouteModel>> getSavedRoutes() async {
    try {
      final response = await _supabase
          .from('saved_routes')
          .select()
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedRouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch saved routes: $e');
    }
  }

  /// Get active monitoring routes
  Future<List<SavedRouteModel>> getActiveRoutes() async {
    try {
      final response = await _supabase
          .from('saved_routes')
          .select()
          .eq('is_deleted', false)
          .eq('is_monitoring', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedRouteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active routes: $e');
    }
  }

  /// Create a new saved route
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
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('saved_routes').insert({
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
        'is_monitoring': isMonitoring,
        'travel_mode': travelMode,
      }).select().single();

      final route = SavedRouteModel.fromJson(response);

      // Trigger notification for route save
      try {
        await _notificationHelper.notifyRouteSaved(
          userId: userId,
          routeId: route.id,
          routeName: name,
        );
      } catch (e, stackTrace) {
        // Log error but don't disrupt business logic
        developer.log(
          'Failed to send route saved notification',
          name: 'SavedRouteApi',
          error: e,
          stackTrace: stackTrace,
        );
      }

      return route;
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  /// Create a route with waypoints in a single transaction
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
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create the route first
      final routeResponse = await _supabase.from('saved_routes').insert({
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
        'is_monitoring': isMonitoring,
        'travel_mode': travelMode,
      }).select().single();

      final route = SavedRouteModel.fromJson(routeResponse);

      // Create waypoints if any
      List<RouteWaypointModel> createdWaypoints = [];
      if (waypoints.isNotEmpty) {
        final waypointsToInsert = waypoints.map((wp) {
          return {
            'route_id': route.id,
            'waypoint_order': wp['waypoint_order'] as int,
            'location_name': wp['location_name'] as String,
            'latitude': wp['latitude'] as double,
            'longitude': wp['longitude'] as double,
            'address': wp['address'] as String?,
          };
        }).toList();

        final waypointsResponse = await _supabase
            .from('route_waypoints')
            .insert(waypointsToInsert)
            .select();

        createdWaypoints = (waypointsResponse as List)
            .map((json) => RouteWaypointModel.fromJson(json))
            .toList();
      }

      return {
        'route': route,
        'waypoints': createdWaypoints,
      };
    } catch (e) {
      throw Exception('Failed to create route with waypoints: $e');
    }
  }

  /// Get a route with its waypoints
  Future<Map<String, dynamic>> getRouteWithWaypoints(String routeId) async {
    try {
      // Get the route
      final routeResponse = await _supabase
          .from('saved_routes')
          .select()
          .eq('id', routeId)
          .eq('is_deleted', false)
          .single();

      final route = SavedRouteModel.fromJson(routeResponse);

      // Get waypoints
      final waypoints = await getRouteWaypoints(routeId);

      return {
        'route': route,
        'waypoints': waypoints,
      };
    } catch (e) {
      throw Exception('Failed to get route with waypoints: $e');
    }
  }

  /// Update waypoints for a route (replaces all existing waypoints)
  Future<List<RouteWaypointModel>> updateRouteWaypoints({
    required String routeId,
    required List<Map<String, dynamic>> waypoints,
  }) async {
    try {
      // Delete existing waypoints
      await deleteRouteWaypoints(routeId);

      // Insert new waypoints if any
      if (waypoints.isEmpty) {
        return [];
      }

      final waypointsToInsert = waypoints.map((wp) {
        return {
          'route_id': routeId,
          'waypoint_order': wp['waypoint_order'] as int,
          'location_name': wp['location_name'] as String,
          'latitude': wp['latitude'] as double,
          'longitude': wp['longitude'] as double,
          'address': wp['address'] as String?,
        };
      }).toList();

      final response = await _supabase
          .from('route_waypoints')
          .insert(waypointsToInsert)
          .select();

      return (response as List)
          .map((json) => RouteWaypointModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to update route waypoints: $e');
    }
  }

  /// Update a saved route
  Future<SavedRouteModel> updateRoute(
    String routeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('saved_routes')
          .update(updates)
          .eq('id', routeId)
          .select()
          .single();

      return SavedRouteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update route: $e');
    }
  }

  /// Toggle route monitoring status
  Future<void> toggleRouteMonitoring(String routeId, bool isMonitoring) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('saved_routes')
          .update({'is_monitoring': isMonitoring})
          .eq('id', routeId);

      // Only notify when monitoring is enabled (not disabled)
      if (isMonitoring) {
        try {
          // Get route details for notification
          final routeResponse = await _supabase
              .from('saved_routes')
              .select()
              .eq('id', routeId)
              .single();
          
          final route = SavedRouteModel.fromJson(routeResponse);

          await _notificationHelper.notifyRouteMonitoringEnabled(
            userId: userId,
            routeId: routeId,
            routeName: route.name,
          );
        } catch (e, stackTrace) {
          // Log error but don't disrupt business logic
          developer.log(
            'Failed to send route monitoring enabled notification',
            name: 'SavedRouteApi',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle route monitoring: $e');
    }
  }

  /// Soft delete a route
  Future<void> deleteRoute(String routeId) async {
    try {
      await _supabase.from('saved_routes').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', routeId);
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }

  // ========== Saved Locations ==========

  /// Get all saved locations for the current user
  Future<List<SavedLocationModel>> getSavedLocations() async {
    try {
      final response = await _supabase
          .from('saved_locations')
          .select()
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedLocationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch saved locations: $e');
    }
  }

  /// Get a saved location by label
  Future<SavedLocationModel?> getLocationByLabel(String label) async {
    try {
      final response = await _supabase
          .from('saved_locations')
          .select()
          .eq('is_deleted', false)
          .eq('label', label)
          .maybeSingle();

      if (response == null) return null;
      return SavedLocationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch location: $e');
    }
  }

  /// Create or update a saved location
  Future<SavedLocationModel> upsertLocation({
    required String label,
    required String locationName,
    required double latitude,
    required double longitude,
    String? address,
    String icon = 'place',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.from('saved_locations').upsert({
        'user_id': userId,
        'label': label,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'icon': icon,
      }).select().single();

      return SavedLocationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save location: $e');
    }
  }

  /// Delete a saved location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _supabase.from('saved_locations').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', locationId);
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }

  // ========== Route Waypoints ==========

  /// Get waypoints for a route
  Future<List<RouteWaypointModel>> getRouteWaypoints(String routeId) async {
    try {
      final response = await _supabase
          .from('route_waypoints')
          .select()
          .eq('route_id', routeId)
          .order('waypoint_order', ascending: true);

      return (response as List)
          .map((json) => RouteWaypointModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch waypoints: $e');
    }
  }

  /// Create a waypoint
  Future<RouteWaypointModel> createWaypoint({
    required String routeId,
    required int waypointOrder,
    required String locationName,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final response = await _supabase.from('route_waypoints').insert({
        'route_id': routeId,
        'waypoint_order': waypointOrder,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      }).select().single();

      return RouteWaypointModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create waypoint: $e');
    }
  }

  /// Delete all waypoints for a route
  Future<void> deleteRouteWaypoints(String routeId) async {
    try {
      await _supabase
          .from('route_waypoints')
          .delete()
          .eq('route_id', routeId);
    } catch (e) {
      throw Exception('Failed to delete waypoints: $e');
    }
  }
}

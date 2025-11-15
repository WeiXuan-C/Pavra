import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/saved_route_model.dart';
import '../../../data/models/saved_location_model.dart';

class SavedRouteApi {
  final SupabaseClient _supabase;

  SavedRouteApi(this._supabase);

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
      }).select().single();

      return SavedRouteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create route: $e');
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
      await _supabase
          .from('saved_routes')
          .update({'is_monitoring': isMonitoring})
          .eq('id', routeId);
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
}

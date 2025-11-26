import 'dart:developer' as developer;
import '../../data/models/saved_location_model.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../utils/error_handler.dart';

/// Saved Location Service
/// Manages saved locations and quick access shortcuts (Home/Work)
class SavedLocationService {
  final SavedRouteRepository _repository;

  SavedLocationService(this._repository);

  /// Save a new location
  /// Throws DuplicateLabelException if label already exists
  /// Throws InvalidWaypointCoordinatesException if coordinates are invalid
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<SavedLocationModel> saveLocation({
    required String label,
    required String locationName,
    required double latitude,
    required double longitude,
    String? address,
    String icon = 'place',
  }) async {
    try {
      developer.log(
        '💾 Saving location: label=$label, name=$locationName',
        name: 'SavedLocationService',
      );

      // Validate coordinates
      ErrorHandler.validateCoordinates(latitude, longitude);

      // Check if label already exists
      final exists = await labelExists(label);
      if (exists) {
        throw DuplicateLabelException(label);
      }

      // Save the location
      final savedLocation = await _repository.upsertLocation(
        label: label,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        address: address,
        icon: icon,
      );

      developer.log(
        '✅ Location saved: ${savedLocation.id}',
        name: 'SavedLocationService',
      );

      return savedLocation;
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('SavedLocationService.saveLocation', e);
        rethrow;
      }

      // Check for network/database errors
      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedLocationService.saveLocation', e);
      rethrow;
    }
  }

  /// Get all saved locations (excluding deleted)
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<List<SavedLocationModel>> getSavedLocations() async {
    try {
      developer.log(
        '📍 Fetching saved locations',
        name: 'SavedLocationService',
      );

      final locations = await _repository.getSavedLocations();

      developer.log(
        '✅ Found ${locations.length} saved locations',
        name: 'SavedLocationService',
      );

      return locations;
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedLocationService.getSavedLocations', e);
      rethrow;
    }
  }

  /// Get Home location
  Future<SavedLocationModel?> getHomeLocation() async {
    try {
      developer.log(
        '🏠 Fetching Home location',
        name: 'SavedLocationService',
      );

      final location = await _repository.getLocationByLabel('Home');

      if (location != null) {
        developer.log(
          '✅ Home location found: ${location.locationName}',
          name: 'SavedLocationService',
        );
      } else {
        developer.log(
          'ℹ️ No Home location saved',
          name: 'SavedLocationService',
        );
      }

      return location;
    } catch (e) {
      developer.log(
        '❌ Failed to fetch Home location: $e',
        name: 'SavedLocationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Get Work location
  Future<SavedLocationModel?> getWorkLocation() async {
    try {
      developer.log(
        '💼 Fetching Work location',
        name: 'SavedLocationService',
      );

      final location = await _repository.getLocationByLabel('Work');

      if (location != null) {
        developer.log(
          '✅ Work location found: ${location.locationName}',
          name: 'SavedLocationService',
        );
      } else {
        developer.log(
          'ℹ️ No Work location saved',
          name: 'SavedLocationService',
        );
      }

      return location;
    } catch (e) {
      developer.log(
        '❌ Failed to fetch Work location: $e',
        name: 'SavedLocationService',
        error: e,
      );
      rethrow;
    }
  }

  /// Update saved location (preserving coordinates and address)
  /// Only updates label and icon
  /// Throws RecordNotFoundException if location not found
  /// Throws DuplicateLabelException if new label already exists
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<SavedLocationModel> updateLocation({
    required String locationId,
    String? label,
    String? icon,
  }) async {
    try {
      developer.log(
        '✏️ Updating location: id=$locationId',
        name: 'SavedLocationService',
      );

      // Get all locations to find the one to update
      final locations = await getSavedLocations();
      final location = locations.cast<SavedLocationModel?>().firstWhere(
        (loc) => loc?.id == locationId,
        orElse: () => null,
      );

      if (location == null) {
        throw RecordNotFoundException('Location', locationId);
      }

      // Check if new label already exists (if label is being changed)
      if (label != null && label != location.label) {
        final exists = await labelExists(label);
        if (exists) {
          throw DuplicateLabelException(label);
        }
      }

      // Use upsert with the location's existing coordinates and address
      // This preserves coordinates and address while updating label and icon
      final updatedLocation = await _repository.upsertLocation(
        label: label ?? location.label,
        locationName: location.locationName,
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        icon: icon ?? location.icon,
      );

      developer.log(
        '✅ Location updated: ${updatedLocation.id}',
        name: 'SavedLocationService',
      );

      return updatedLocation;
    } catch (e) {
      if (e is AppException) {
        ErrorHandler.logError('SavedLocationService.updateLocation', e);
        rethrow;
      }

      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedLocationService.updateLocation', e);
      rethrow;
    }
  }

  /// Delete saved location (soft delete)
  /// Throws DatabaseConnectionFailedException if database is unavailable
  Future<void> deleteLocation(String locationId) async {
    try {
      developer.log(
        '🗑️ Deleting location: id=$locationId',
        name: 'SavedLocationService',
      );

      await _repository.deleteLocation(locationId);

      developer.log(
        '✅ Location deleted (soft delete)',
        name: 'SavedLocationService',
      );
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        throw DatabaseConnectionFailedException(originalError: e);
      }

      ErrorHandler.logError('SavedLocationService.deleteLocation', e);
      rethrow;
    }
  }

  /// Check if a label already exists
  Future<bool> labelExists(String label) async {
    try {
      final location = await _repository.getLocationByLabel(label);
      return location != null;
    } catch (e) {
      developer.log(
        '⚠️ Error checking label existence: $e',
        name: 'SavedLocationService',
        error: e,
      );
      return false;
    }
  }

  /// Search saved locations by query string
  /// Searches in label, location name, and address
  List<SavedLocationModel> searchSavedLocations(
    String query,
    List<SavedLocationModel> locations,
  ) {
    if (query.isEmpty) {
      return locations;
    }

    final lowerQuery = query.toLowerCase();

    return locations.where((location) {
      final labelMatch = location.label.toLowerCase().contains(lowerQuery);
      final nameMatch = location.locationName.toLowerCase().contains(lowerQuery);
      final addressMatch = location.address?.toLowerCase().contains(lowerQuery) ?? false;

      return labelMatch || nameMatch || addressMatch;
    }).toList();
  }
}

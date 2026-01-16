import 'dart:math' as math;
import 'package:logger/logger.dart';
import '../api/alert_preferences/alert_preferences_api.dart';
import '../api/report_issue/report_issue_api.dart';
import '../supabase/supabase_client.dart';

class MapService {
  final _logger = Logger();
  late final AlertPreferencesApi _alertPreferencesApi;
  late final ReportIssueApi _reportIssueApi;
  
  // Cache for nearby issues to reduce API calls
  Map<String, dynamic>? _cachedIssues;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  MapService() {
    _alertPreferencesApi = AlertPreferencesApi(supabase);
    _reportIssueApi = ReportIssueApi(supabase);
  }

  /// Fetch user's alert radius preference
  Future<double> getUserAlertRadius(String userId) async {
    try {
      final preferences = await _alertPreferencesApi.getPreferences();
      return preferences.alertRadiusMiles;
    } catch (e) {
      _logger.e('Error fetching alert radius: $e');
      return 5.0; // Default fallback
    }
  }

  /// Fetch nearby report issues within radius with caching and optimization
  /// Uses the ReportIssueApi to fetch issues with photos
  Future<List<Map<String, dynamic>>> getNearbyIssues({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String status = 'submitted',
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && _cachedIssues != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheDuration) {
          final cachedLat = _cachedIssues!['latitude'] as double;
          final cachedLng = _cachedIssues!['longitude'] as double;
          final cachedRadius = _cachedIssues!['radius'] as double;
          
          // Check if cached location is close enough (within 0.5 miles)
          final distance = _calculateDistance(latitude, longitude, cachedLat, cachedLng) / 1.60934;
          if (distance < 0.5 && cachedRadius >= radiusMiles) {
            _logger.i('Using cached issues (age: ${cacheAge.inSeconds}s, distance: ${distance.toStringAsFixed(2)} miles)');
            return List<Map<String, dynamic>>.from(_cachedIssues!['issues'] as List);
          }
        }
      }

      // Convert miles to kilometers for the API
      final radiusKm = radiusMiles * 1.60934;

      _logger.i('Fetching nearby issues within $radiusMiles miles ($radiusKm km) from ($latitude, $longitude)');

      // Fetch nearby reports using the API with limit
      final reports = await _reportIssueApi.searchNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: 50, // Reduced from 100 for faster loading
      );

      _logger.i('Found ${reports.length} reports within radius');

      // Convert ReportIssueModel to Map format for compatibility
      // Load photos in batches for better performance
      final issuesWithPhotos = <Map<String, dynamic>>[];
      
      for (final report in reports) {
        // Skip if status doesn't match (if status filter is needed)
        if (status.isNotEmpty && report.status != status && report.status != 'reviewed') {
          continue;
        }

        // Only fetch photos for issues that will be displayed
        // This is a lazy loading approach
        final issueMap = {
          'id': report.id,
          'title': report.title,
          'description': report.description,
          'issue_type_ids': report.issueTypeIds,
          'severity': report.severity,
          'address': report.address,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'status': report.status,
          'created_at': report.createdAt.toIso8601String(),
          'updated_at': report.updatedAt.toIso8601String(),
          'is_deleted': report.isDeleted,
          'issue_photos': [], // Will be loaded on demand
          'photos_loaded': false,
          // Calculate distance
          'distance_miles': _calculateDistance(
            latitude,
            longitude,
            report.latitude ?? 0,
            report.longitude ?? 0,
          ) / 1.60934, // Convert km back to miles
        };
        
        issuesWithPhotos.add(issueMap);
      }

      // Sort by distance
      issuesWithPhotos.sort((a, b) {
        final distA = a['distance_miles'] as double;
        final distB = b['distance_miles'] as double;
        return distA.compareTo(distB);
      });

      _logger.i('Returning ${issuesWithPhotos.length} issues after filtering by status');
      
      // Log distances for verification
      if (issuesWithPhotos.isNotEmpty) {
        final nearest = issuesWithPhotos.first['distance_miles'];
        final farthest = issuesWithPhotos.last['distance_miles'];
        _logger.i('Distance range: ${nearest.toStringAsFixed(2)} - ${farthest.toStringAsFixed(2)} miles');
      }

      // Cache the results
      _cachedIssues = {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMiles,
        'issues': issuesWithPhotos,
      };
      _cacheTimestamp = DateTime.now();

      return issuesWithPhotos;
    } catch (e) {
      _logger.e('Error fetching nearby issues: $e');
      return [];
    }
  }

  /// Load photos for a specific issue (lazy loading)
  Future<void> loadIssuePhotos(Map<String, dynamic> issue) async {
    if (issue['photos_loaded'] == true) return;

    try {
      final photos = await _reportIssueApi.getReportPhotos(issue['id'] as String);
      issue['issue_photos'] = photos.map((photo) => {
        'photo_url': photo.photoUrl,
        'is_primary': photo.isPrimary,
        'photo_type': photo.photoType,
      }).toList();
      issue['photos_loaded'] = true;
    } catch (e) {
      _logger.e('Error loading photos for issue ${issue['id']}: $e');
    }
  }

  /// Clear cache to force refresh
  void clearCache() {
    _cachedIssues = null;
    _cacheTimestamp = null;
  }



  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

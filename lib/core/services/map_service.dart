import 'dart:math' as math;
import 'package:logger/logger.dart';
import '../supabase/supabase_client.dart';

class MapService {
  final _logger = Logger();

  /// Fetch user's alert radius preference
  Future<double> getUserAlertRadius(String userId) async {
    try {
      final response = await supabase
          .from('user_alert_preferences')
          .select('alert_radius_miles')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['alert_radius_miles'] != null) {
        return (response['alert_radius_miles'] as num).toDouble();
      }
      
      // Default to 5 miles if no preference found
      return 5.0;
    } catch (e) {
      _logger.e('Error fetching alert radius: $e');
      return 5.0; // Default fallback
    }
  }

  /// Fetch nearby report issues within radius
  /// Uses Haversine formula via PostGIS for distance calculation
  Future<List<Map<String, dynamic>>> getNearbyIssues({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String status = 'submitted',
  }) async {
    try {
      // Convert miles to meters for PostGIS calculation (1 mile = 1609.34 meters)
      final radiusMeters = radiusMiles * 1609.34;

      final response = await supabase.rpc(
        'get_nearby_issues',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_meters': radiusMeters,
          'issue_status': status,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      _logger.w('Error fetching nearby issues, using fallback: $e');
      // Fallback to simple query without distance calculation
      return await _getFallbackNearbyIssues(
        latitude: latitude,
        longitude: longitude,
        radiusMiles: radiusMiles,
        status: status,
      );
    }
  }

  /// Fallback method using simple bounding box query
  Future<List<Map<String, dynamic>>> _getFallbackNearbyIssues({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    required String status,
  }) async {
    try {
      // Approximate degrees per mile (varies by latitude)
      // At equator: 1 degree ≈ 69 miles
      final degreesPerMile = 1 / 69.0;
      final latDelta = radiusMiles * degreesPerMile;
      final lngDelta = radiusMiles * degreesPerMile;

      final response = await supabase
          .from('report_issues')
          .select('''
            id,
            title,
            description,
            issue_type_ids,
            severity,
            address,
            latitude,
            longitude,
            status,
            created_at,
            updated_at,
            issue_photos(photo_url, is_primary, photo_type)
          ''')
          .eq('status', status)
          .eq('is_deleted', false)
          .gte('latitude', latitude - latDelta)
          .lte('latitude', latitude + latDelta)
          .gte('longitude', longitude - lngDelta)
          .lte('longitude', longitude + lngDelta)
          .order('created_at', ascending: false);

      // Calculate actual distances and filter
      final issues = List<Map<String, dynamic>>.from(response);
      final nearbyIssues = <Map<String, dynamic>>[];

      for (var issue in issues) {
        if (issue['latitude'] != null && issue['longitude'] != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            issue['latitude'],
            issue['longitude'],
          );

          if (distance <= radiusMiles) {
            issue['distance'] = distance;
            nearbyIssues.add(issue);
          }
        }
      }

      // Sort by distance
      nearbyIssues.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double)
      );

      return nearbyIssues;
    } catch (e) {
      _logger.e('Error in fallback nearby issues: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in miles
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMiles = 3958.8; // Earth's radius in miles
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadiusMiles * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/user_alert_preferences_model.dart';

class AlertPreferencesApi {
  final SupabaseClient _supabase;

  AlertPreferencesApi(this._supabase);

  /// Get user alert preferences (creates default if not exists)
  Future<UserAlertPreferencesModel> getPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_alert_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        return await _createDefaultPreferences(userId);
      }

      return UserAlertPreferencesModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch alert preferences: $e');
    }
  }

  /// Create default preferences for a new user
  Future<UserAlertPreferencesModel> _createDefaultPreferences(String userId) async {
    try {
      final response = await _supabase
          .from('user_alert_preferences')
          .insert({
            'user_id': userId,
            'alert_radius_miles': 5.0,
            'road_damage_enabled': true,
            'construction_zones_enabled': true,
            'weather_hazards_enabled': true,
            'traffic_incidents_enabled': true,
            'sound_enabled': true,
            'vibration_enabled': false,
            'do_not_disturb_respect': false,
            'quiet_hours_enabled': false,
          })
          .select()
          .single();

      return UserAlertPreferencesModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create default preferences: $e');
    }
  }

  /// Update alert radius
  Future<UserAlertPreferencesModel> updateAlertRadius(double radiusMiles) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_alert_preferences')
          .update({
            'alert_radius_miles': radiusMiles,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .select()
          .single();

      return UserAlertPreferencesModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update alert radius: $e');
    }
  }

  /// Update alert type toggles
  Future<UserAlertPreferencesModel> updateAlertTypes({
    bool? roadDamageEnabled,
    bool? constructionZonesEnabled,
    bool? weatherHazardsEnabled,
    bool? trafficIncidentsEnabled,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (roadDamageEnabled != null) {
        updates['road_damage_enabled'] = roadDamageEnabled;
      }
      if (constructionZonesEnabled != null) {
        updates['construction_zones_enabled'] = constructionZonesEnabled;
      }
      if (weatherHazardsEnabled != null) {
        updates['weather_hazards_enabled'] = weatherHazardsEnabled;
      }
      if (trafficIncidentsEnabled != null) {
        updates['traffic_incidents_enabled'] = trafficIncidentsEnabled;
      }

      final response = await _supabase
          .from('user_alert_preferences')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return UserAlertPreferencesModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update alert types: $e');
    }
  }

  /// Update all preferences at once
  Future<UserAlertPreferencesModel> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('user_alert_preferences')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return UserAlertPreferencesModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }
}

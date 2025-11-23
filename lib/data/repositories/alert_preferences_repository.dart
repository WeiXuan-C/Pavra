import '../models/user_alert_preferences_model.dart';
import '../../core/api/alert_preferences/alert_preferences_api.dart';

class AlertPreferencesRepository {
  final AlertPreferencesApi _api;

  AlertPreferencesRepository(this._api);

  /// Get user alert preferences
  Future<UserAlertPreferencesModel> getPreferences() async {
    return await _api.getPreferences();
  }

  /// Update alert radius
  Future<UserAlertPreferencesModel> updateAlertRadius(double radiusMiles) async {
    return await _api.updateAlertRadius(radiusMiles);
  }

  /// Update alert type toggles
  Future<UserAlertPreferencesModel> updateAlertTypes({
    bool? roadDamageEnabled,
    bool? constructionZonesEnabled,
    bool? weatherHazardsEnabled,
    bool? trafficIncidentsEnabled,
  }) async {
    return await _api.updateAlertTypes(
      roadDamageEnabled: roadDamageEnabled,
      constructionZonesEnabled: constructionZonesEnabled,
      weatherHazardsEnabled: weatherHazardsEnabled,
      trafficIncidentsEnabled: trafficIncidentsEnabled,
    );
  }

  /// Update all preferences
  Future<UserAlertPreferencesModel> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    return await _api.updatePreferences(updates);
  }
}

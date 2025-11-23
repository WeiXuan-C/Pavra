class UserAlertPreferencesModel {
  final String id;
  final String userId;
  final double alertRadiusMiles;
  final bool roadDamageEnabled;
  final bool constructionZonesEnabled;
  final bool weatherHazardsEnabled;
  final bool trafficIncidentsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool doNotDisturbRespect;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAlertPreferencesModel({
    required this.id,
    required this.userId,
    required this.alertRadiusMiles,
    required this.roadDamageEnabled,
    required this.constructionZonesEnabled,
    required this.weatherHazardsEnabled,
    required this.trafficIncidentsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.doNotDisturbRespect,
    required this.quietHoursEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAlertPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserAlertPreferencesModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      alertRadiusMiles: (json['alert_radius_miles'] as num).toDouble(),
      roadDamageEnabled: json['road_damage_enabled'] as bool,
      constructionZonesEnabled: json['construction_zones_enabled'] as bool,
      weatherHazardsEnabled: json['weather_hazards_enabled'] as bool,
      trafficIncidentsEnabled: json['traffic_incidents_enabled'] as bool,
      soundEnabled: json['sound_enabled'] as bool,
      vibrationEnabled: json['vibration_enabled'] as bool,
      doNotDisturbRespect: json['do_not_disturb_respect'] as bool,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'alert_radius_miles': alertRadiusMiles,
      'road_damage_enabled': roadDamageEnabled,
      'construction_zones_enabled': constructionZonesEnabled,
      'weather_hazards_enabled': weatherHazardsEnabled,
      'traffic_incidents_enabled': trafficIncidentsEnabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'do_not_disturb_respect': doNotDisturbRespect,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserAlertPreferencesModel copyWith({
    String? id,
    String? userId,
    double? alertRadiusMiles,
    bool? roadDamageEnabled,
    bool? constructionZonesEnabled,
    bool? weatherHazardsEnabled,
    bool? trafficIncidentsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? doNotDisturbRespect,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAlertPreferencesModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      alertRadiusMiles: alertRadiusMiles ?? this.alertRadiusMiles,
      roadDamageEnabled: roadDamageEnabled ?? this.roadDamageEnabled,
      constructionZonesEnabled: constructionZonesEnabled ?? this.constructionZonesEnabled,
      weatherHazardsEnabled: weatherHazardsEnabled ?? this.weatherHazardsEnabled,
      trafficIncidentsEnabled: trafficIncidentsEnabled ?? this.trafficIncidentsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      doNotDisturbRespect: doNotDisturbRespect ?? this.doNotDisturbRespect,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

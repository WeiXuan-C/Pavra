/// User Profile Model
/// Represents user data from the profiles table
/// This extends the basic auth.users data with custom profile fields
class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? provider;
  final String? providerUserId;
  final String recoveryCode;
  final String role;
  final String language;
  final String themeMode;
  final int reportsCount;
  final int reputationScore;
  final bool notificationsEnabled;
  final String? deviceToken;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.provider,
    required this.providerUserId,
    required this.recoveryCode,
    required this.role,
    required this.language,
    required this.themeMode,
    required this.reportsCount,
    required this.reputationScore,
    required this.notificationsEnabled,
    required this.deviceToken,
    required this.updatedAt,
  });

  /// Create UserProfile from Supabase profiles table JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      provider: json['provider'] as String?,
      providerUserId: json['provider_user_id'] as String?,
      recoveryCode: json['recovery_code'] as String,
      role: json['role'] as String,
      language: json['language'] as String,
      themeMode: json['theme_mode'] as String,
      reportsCount: json['reports_count'] as int,
      reputationScore: json['reputation_score'] as int,
      notificationsEnabled: json['notifications_enabled'] as bool,
      deviceToken: json['device_token'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert UserProfile to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'provider': provider,
      'provider_user_id': providerUserId,
      'recovery_code': recoveryCode,
      'role': role,
      'language': language,
      'theme_mode': themeMode,
      'reports_count': reportsCount,
      'reputation_score': reputationScore,
      'notifications_enabled': notificationsEnabled,
      'device_token': deviceToken,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? provider,
    String? providerUserId,
    String? recoveryCode,
    String? role,
    String? language,
    String? themeMode,
    int? reportsCount,
    int? reputationScore,
    bool? notificationsEnabled,
    String? deviceToken,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      providerUserId: providerUserId ?? this.providerUserId,
      recoveryCode: recoveryCode ?? this.recoveryCode,
      role: role ?? this.role,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      reportsCount: reportsCount ?? this.reportsCount,
      reputationScore: reputationScore ?? this.reputationScore,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      deviceToken: deviceToken ?? this.deviceToken,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, avatarUrl: $avatarUrl, email: $email, provider: $provider, providerUserId: $providerUserId, recoveryCode: $recoveryCode, role: $role, language: $language, themeMode: $themeMode, reportsCount: $reportsCount, reputationScore: $reputationScore, notificationsEnabled: $notificationsEnabled, deviceToken: $deviceToken, updatedAt: $updatedAt)';
  }
}

// Backward compatibility: Keep original UserModel for existing code
class UserModel {
  final String id;
  final String email;
  final String name;

  UserModel({required this.id, required this.email, required this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(id: json['id'], email: json['email'], name: json['name']);
}

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
  final String role;
  final String language;
  final String themeMode;
  final int reportsCount;
  final int reputationScore;
  final bool notificationsEnabled;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.provider,
    required this.providerUserId,
    required this.role,
    required this.language,
    required this.themeMode,
    required this.reportsCount,
    required this.reputationScore,
    required this.notificationsEnabled,
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
      role: json['role'] as String? ?? 'user',
      language: json['language'] as String? ?? 'en',
      themeMode: json['theme_mode'] as String? ?? 'system',
      reportsCount: json['reports_count'] as int? ?? 0,
      reputationScore: json['reputation_score'] as int? ?? 0,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
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
      'role': role,
      'language': language,
      'theme_mode': themeMode,
      'reports_count': reportsCount,
      'reputation_score': reputationScore,
      'notifications_enabled': notificationsEnabled,
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
    String? role,
    String? language,
    String? themeMode,
    int? reportsCount,
    int? reputationScore,
    bool? notificationsEnabled,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      providerUserId: providerUserId ?? this.providerUserId,
      role: role ?? this.role,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      reportsCount: reportsCount ?? this.reportsCount,
      reputationScore: reputationScore ?? this.reputationScore,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, avatarUrl: $avatarUrl, email: $email, provider: $provider, providerUserId: $providerUserId, role: $role, language: $language, themeMode: $themeMode, reportsCount: $reportsCount, reputationScore: $reputationScore, notificationsEnabled: $notificationsEnabled, updatedAt: $updatedAt)';
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

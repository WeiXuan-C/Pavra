import 'dart:developer' as developer;
import '../../supabase/database_service.dart';
import '../../services/notification_helper_service.dart';

/// User API
/// 针对 users/profiles 表的业务逻辑
/// 使用 DatabaseService 进行数据库操作
class UserApi {
  final _db = DatabaseService();
  final NotificationHelperService? _notificationHelper;

  static const String _tableName = 'profiles';

  UserApi({NotificationHelperService? notificationHelper})
      : _notificationHelper = notificationHelper;

  // ========== CREATE ==========

  /// 创建用户 profile
  /// 通常在用户注册后自动触发（通过数据库触发器）
  /// 这是一个 fallback 方法，以防触发器失败
  Future<Map<String, dynamic>> createProfile({
    required String userId,
    required String username,
    String? email,
    String? avatarUrl,
    String? provider,
    String? providerUserId,
  }) async {
    try {
      final data = {
        'id': userId,
        'username': username,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (provider != null) 'provider': provider,
        if (providerUserId != null) 'provider_user_id': providerUserId,
      };

      final result = await _db.insert<Map<String, dynamic>>(
        table: _tableName,
        data: data,
      );

      // Send welcome notification to new user
      try {
        await _notificationHelper?.notifyWelcomeNewUser(userId: userId);
      } catch (e, stackTrace) {
        developer.log(
          'Failed to send welcome notification',
          name: 'UserApi',
          error: e,
          stackTrace: stackTrace,
        );
        // Don't rethrow - notification failures shouldn't disrupt profile creation
      }

      return result;
    } catch (e) {
      developer.log('Error creating profile: $e', name: 'UserApi', error: e);
      rethrow;
    }
  }

  // ========== READ ==========

  /// 获取用户 profile by ID
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      developer.log('=== UserApi.getProfileById ===', name: 'UserApi');
      developer.log('Querying profiles table for ID: $userId', name: 'UserApi');

      final result = await _db.selectSingle(
        table: _tableName,
        filterColumn: 'id',
        filterValue: userId,
      );

      if (result != null) {
        developer.log('✅ Profile found', name: 'UserApi');
        developer.log('Username: ${result['username']}', name: 'UserApi');
        developer.log('Role: ${result['role']}', name: 'UserApi');
      } else {
        developer.log(
          '⚠️ Profile NOT found (query returned null)',
          name: 'UserApi',
        );
      }

      developer.log('=============================', name: 'UserApi');
      return result;
    } catch (e) {
      developer.log('❌ Error fetching profile: $e', name: 'UserApi', error: e);
      return null;
    }
  }

  /// 获取用户 profile by username
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    try {
      return await _db.selectSingle(
        table: _tableName,
        filterColumn: 'username',
        filterValue: username,
      );
    } catch (e) {
      developer.log(
        'Error fetching profile by username: $e',
        name: 'UserApi',
        error: e,
      );
      return null;
    }
  }

  /// 获取用户 profile by email
  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    try {
      return await _db.selectSingle(
        table: _tableName,
        filterColumn: 'email',
        filterValue: email,
      );
    } catch (e) {
      developer.log(
        'Error fetching profile by email: $e',
        name: 'UserApi',
        error: e,
      );
      return null;
    }
  }

  /// 检查 profile 是否存在
  Future<bool> profileExists(String userId) async {
    final profile = await getProfileById(userId);
    return profile != null;
  }

  /// 获取所有用户 profiles (分页)
  Future<List<Map<String, dynamic>>> getAllProfiles({
    int page = 1,
    int pageSize = 20,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    return await _db.selectWithPagination(
      table: _tableName,
      page: page,
      pageSize: pageSize,
      orderBy: orderBy,
      ascending: ascending,
    );
  }

  /// 搜索用户 by username
  Future<List<Map<String, dynamic>>> searchByUsername(
    String searchTerm, {
    int limit = 10,
  }) async {
    return await _db.search(
      table: _tableName,
      column: 'username',
      searchTerm: searchTerm,
    );
  }

  /// 获取高声誉用户
  Future<List<Map<String, dynamic>>> getTopUsers({int limit = 10}) async {
    return await _db.selectAdvanced(
      table: _tableName,
      orderBy: 'reputation_score',
      ascending: false,
      limit: limit,
    );
  }

  // ========== UPDATE ==========

  /// 更新用户 profile
  Future<List<Map<String, dynamic>>> updateProfile({
    required String userId,
    String? username,
    String? email,
    String? avatarUrl,
    String? language,
    String? themeMode,
    String? role,
    bool? notificationsEnabled,
  }) async {
    // Get current profile to check for role changes
    final currentProfile = await getProfileById(userId);
    final oldRole = currentProfile?['role'] as String?;

    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (email != null) updates['email'] = email;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (language != null) updates['language'] = language;
    if (themeMode != null) updates['theme_mode'] = themeMode;
    if (role != null) updates['role'] = role;
    if (notificationsEnabled != null) {
      updates['notifications_enabled'] = notificationsEnabled;
    }

    if (updates.isEmpty) {
      throw ArgumentError('No fields to update');
    }

    final result = await _db.update<Map<String, dynamic>>(
      table: _tableName,
      data: updates,
      matchColumn: 'id',
      matchValue: userId,
    );

    // Send role change notification if role changed
    if (role != null && role != oldRole) {
      try {
        await _notificationHelper?.notifyRoleChanged(
          userId: userId,
          newRole: role,
        );
      } catch (e, stackTrace) {
        developer.log(
          'Failed to send role change notification',
          name: 'UserApi',
          error: e,
          stackTrace: stackTrace,
        );
        // Don't rethrow - notification failures shouldn't disrupt profile update
      }
    }

    return result;
  }

  /// 增加用户声誉分数
  Future<void> incrementReputationScore(String userId, int points) async {
    // 使用 RPC 函数来增加分数（需要在数据库中创建相应的函数）
    // 或者先获取当前分数，再更新
    final profile = await getProfileById(userId);
    if (profile != null) {
      final currentScore = profile['reputation_score'] as int? ?? 0;
      await _db.update(
        table: _tableName,
        data: {'reputation_score': currentScore + points},
        matchColumn: 'id',
        matchValue: userId,
      );
    }
  }

  /// 增加用户报告计数
  Future<void> incrementReportsCount(String userId) async {
    final profile = await getProfileById(userId);
    if (profile != null) {
      final currentCount = profile['reports_count'] as int? ?? 0;
      await _db.update(
        table: _tableName,
        data: {'reports_count': currentCount + 1},
        matchColumn: 'id',
        matchValue: userId,
      );
    }
  }

  // ========== LOCATION TRACKING ==========

  /// Update user's current location
  /// 
  /// Updates current_latitude, current_longitude, and location_updated_at
  /// in the profiles table.
  /// 
  /// Does not throw on failure - logs error instead to prevent
  /// disrupting location tracking.
  Future<void> updateCurrentLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.update(
        table: _tableName,
        data: {
          'current_latitude': latitude,
          'current_longitude': longitude,
          'location_updated_at': DateTime.now().toIso8601String(),
        },
        matchColumn: 'id',
        matchValue: userId,
      );

      developer.log(
        'Location updated: ($latitude, $longitude)',
        name: 'UserApi',
        time: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update location',
        name: 'UserApi',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
      // Don't throw - location update failures shouldn't disrupt app
    }
  }

  /// Enable/disable location tracking for user
  /// 
  /// Updates the location_tracking_enabled flag in the profiles table.
  Future<void> setLocationTrackingEnabled({
    required String userId,
    required bool enabled,
  }) async {
    await _db.update(
      table: _tableName,
      data: {'location_tracking_enabled': enabled},
      matchColumn: 'id',
      matchValue: userId,
    );

    developer.log(
      'Location tracking ${enabled ? 'enabled' : 'disabled'} for user $userId',
      name: 'UserApi',
      time: DateTime.now(),
    );
  }

  // ========== DELETE ==========

  /// 删除用户 profile
  Future<void> deleteProfile(String userId) async {
    await _db.delete(table: _tableName, matchColumn: 'id', matchValue: userId);
  }

  // ========== UPSERT ==========

  /// Upsert 用户 profile（如果存在则更新，否则创建）
  Future<List<Map<String, dynamic>>> upsertProfile({
    required String userId,
    required String username,
    String? email,
    String? avatarUrl,
    String? provider,
    String? providerUserId,
  }) async {
    final data = {
      'id': userId,
      'username': username,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (provider != null) 'provider': provider,
      if (providerUserId != null) 'provider_user_id': providerUserId,
    };

    return await _db.upsert<Map<String, dynamic>>(
      table: _tableName,
      data: data,
      onConflict: ['id'],
    );
  }

  // ========== NEARBY USERS ==========

  /// Get users within radius of a location who have location alerts enabled
  /// 
  /// Returns a list of user IDs for users who:
  /// - Have notifications enabled globally
  /// - Have location-based alerts enabled (road damage, construction, weather, traffic)
  /// - Have an alert radius that covers the specified location
  /// - Are not the current user
  /// 
  /// Note: Currently returns users based on alert preferences. Geographic filtering
  /// by actual user location requires location tracking to be implemented.
  /// 
  /// Returns empty list on error to prevent disrupting business logic.
  Future<List<String>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      developer.log(
        'Getting nearby users for location ($latitude, $longitude) within ${radiusKm}km',
        name: 'UserApi',
      );

      final result = await _db.rpc<List<dynamic>>(
        functionName: 'get_nearby_users',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
        },
      );

      // Extract user IDs from the result
      final userIds = result
          .map((row) => (row as Map<String, dynamic>)['id'] as String)
          .toList();

      developer.log(
        'Found ${userIds.length} nearby users',
        name: 'UserApi',
      );

      return userIds;
    } catch (e, stackTrace) {
      // Log error with full context
      developer.log(
        'Failed to get nearby users',
        name: 'UserApi',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
      
      // Log query parameters for debugging
      developer.log(
        'Query context: latitude=$latitude, longitude=$longitude, radiusKm=$radiusKm',
        name: 'UserApi',
        level: 1000, // ERROR level
        time: DateTime.now(),
      );
      
      // Return empty list on error to prevent disrupting business logic
      return [];
    }
  }
}

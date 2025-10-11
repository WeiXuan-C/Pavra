import 'dart:developer' as developer;
import '../../supabase/database_service.dart';

/// User API
/// 针对 users/profiles 表的业务逻辑
/// 使用 DatabaseService 进行数据库操作
class UserApi {
  final _db = DatabaseService();

  static const String _tableName = 'profiles';

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
    String? deviceToken,
  }) async {
    try {
      final data = {
        'id': userId,
        'username': username,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (provider != null) 'provider': provider,
        if (providerUserId != null) 'provider_user_id': providerUserId,
        if (deviceToken != null) 'device_token': deviceToken,
      };

      return await _db.insert<Map<String, dynamic>>(
        table: _tableName,
        data: data,
      );
    } catch (e) {
      developer.log('Error creating profile: $e', name: 'UserApi', error: e);
      rethrow;
    }
  }

  // ========== READ ==========

  /// 获取用户 profile by ID
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      return await _db.selectSingle(
        table: _tableName,
        filterColumn: 'id',
        filterValue: userId,
      );
    } catch (e) {
      developer.log('Error fetching profile: $e', name: 'UserApi', error: e);
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
    bool? notificationsEnabled,
    String? deviceToken,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (email != null) updates['email'] = email;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (language != null) updates['language'] = language;
    if (themeMode != null) updates['theme_mode'] = themeMode;
    if (notificationsEnabled != null) {
      updates['notifications_enabled'] = notificationsEnabled;
    }
    if (deviceToken != null) updates['device_token'] = deviceToken;

    if (updates.isEmpty) {
      throw ArgumentError('No fields to update');
    }

    return await _db.update<Map<String, dynamic>>(
      table: _tableName,
      data: updates,
      matchColumn: 'id',
      matchValue: userId,
    );
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
    String? deviceToken,
  }) async {
    final data = {
      'id': userId,
      'username': username,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (provider != null) 'provider': provider,
      if (providerUserId != null) 'provider_user_id': providerUserId,
      if (deviceToken != null) 'device_token': deviceToken,
    };

    return await _db.upsert<Map<String, dynamic>>(
      table: _tableName,
      data: data,
      onConflict: ['id'],
    );
  }
}

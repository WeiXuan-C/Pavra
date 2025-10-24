import '../../core/api/user/user_api.dart';
import '../../core/models/user_model.dart';

/// User Repository
/// 数据仓库层，用来封装 API 调用逻辑
/// 是 Provider 与核心服务（UserApi）之间的桥梁
/// 负责将 API 返回的 JSON 转换为 Model
class UserRepository {
  final _userApi = UserApi();

  // ========== CREATE ==========

  /// 创建用户 profile，返回 UserProfile model
  Future<UserProfile> createProfile({
    required String userId,
    required String username,
    String? email,
    String? avatarUrl,
    String? provider,
    String? providerUserId,
  }) async {
    final json = await _userApi.createProfile(
      userId: userId,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      provider: provider,
      providerUserId: providerUserId,
    );

    return UserProfile.fromJson(json);
  }

  // ========== READ ==========

  /// 获取用户 profile by ID，返回 UserProfile model
  Future<UserProfile?> getProfileById(String userId) async {
    final json = await _userApi.getProfileById(userId);
    if (json == null) return null;

    return UserProfile.fromJson(json);
  }

  /// 获取用户 profile by username
  Future<UserProfile?> getProfileByUsername(String username) async {
    final json = await _userApi.getProfileByUsername(username);
    if (json == null) return null;

    return UserProfile.fromJson(json);
  }

  /// 获取用户 profile by email
  Future<UserProfile?> getProfileByEmail(String email) async {
    final json = await _userApi.getProfileByEmail(email);
    if (json == null) return null;

    return UserProfile.fromJson(json);
  }

  /// 检查 profile 是否存在
  Future<bool> profileExists(String userId) async {
    return await _userApi.profileExists(userId);
  }

  /// 获取所有用户 profiles (分页)
  Future<List<UserProfile>> getAllProfiles({
    int page = 1,
    int pageSize = 20,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    final jsonList = await _userApi.getAllProfiles(
      page: page,
      pageSize: pageSize,
      orderBy: orderBy,
      ascending: ascending,
    );

    return jsonList.map((json) => UserProfile.fromJson(json)).toList();
  }

  /// 搜索用户 by username
  Future<List<UserProfile>> searchByUsername(
    String searchTerm, {
    int limit = 10,
  }) async {
    final jsonList = await _userApi.searchByUsername(searchTerm, limit: limit);

    return jsonList.map((json) => UserProfile.fromJson(json)).toList();
  }

  /// 获取高声誉用户
  Future<List<UserProfile>> getTopUsers({int limit = 10}) async {
    final jsonList = await _userApi.getTopUsers(limit: limit);
    return jsonList.map((json) => UserProfile.fromJson(json)).toList();
  }

  // ========== UPDATE ==========

  /// 更新用户 profile，返回更新后的 UserProfile model
  Future<UserProfile> updateProfile({
    required String userId,
    String? username,
    String? email,
    String? avatarUrl,
    String? language,
    String? themeMode,
    bool? notificationsEnabled,
  }) async {
    final jsonList = await _userApi.updateProfile(
      userId: userId,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      language: language,
      themeMode: themeMode,
      notificationsEnabled: notificationsEnabled,
    );

    // update 返回 list，取第一个
    return UserProfile.fromJson(jsonList.first);
  }

  /// 增加用户声誉分数
  Future<void> incrementReputationScore(String userId, int points) async {
    await _userApi.incrementReputationScore(userId, points);
  }

  /// 增加用户报告计数
  Future<void> incrementReportsCount(String userId) async {
    await _userApi.incrementReportsCount(userId);
  }

  // ========== DELETE ==========

  /// 删除用户 profile
  Future<void> deleteProfile(String userId) async {
    await _userApi.deleteProfile(userId);
  }

  // ========== UPSERT ==========

  /// Upsert 用户 profile，返回 UserProfile model
  Future<UserProfile> upsertProfile({
    required String userId,
    required String username,
    String? email,
    String? avatarUrl,
    String? provider,
    String? providerUserId,
  }) async {
    final jsonList = await _userApi.upsertProfile(
      userId: userId,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      provider: provider,
      providerUserId: providerUserId,
    );

    return UserProfile.fromJson(jsonList.first);
  }
}

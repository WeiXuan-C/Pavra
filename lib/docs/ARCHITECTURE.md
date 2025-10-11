# 项目架构说明

## 三层架构设计

本项目采用三层架构，将数据访问逻辑清晰分离：

```
┌─────────────────────────────────────────────────┐
│           Presentation Layer (UI)               │
│        - Screens                                │
│        - Widgets                                │
│        - Providers (State Management)           │
└──────────────────┬──────────────────────────────┘
                   │ 调用
                   ▼
┌─────────────────────────────────────────────────┐
│         Repository Layer (数据仓库层)            │
│  - lib/data/repositories/                       │
│  - 将 Map<String, dynamic> 转换为 Model          │
│  - 提供类型安全的接口                            │
└──────────────────┬──────────────────────────────┘
                   │ 调用
                   ▼
┌─────────────────────────────────────────────────┐
│            API Layer (业务逻辑层)                │
│  - lib/core/api/                                │
│  - 针对具体表的业务逻辑                          │
│  - 返回 Map<String, dynamic>                    │
└──────────────────┬──────────────────────────────┘
                   │ 调用
                   ▼
┌─────────────────────────────────────────────────┐
│      Database Service (通用 CRUD 层)            │
│  - lib/core/supabase/database_service.dart      │
│  - 通用的数据库操作方法                          │
│  - 不关心具体业务逻辑                            │
└─────────────────────────────────────────────────┘
```

## 各层职责

### 1. Database Service (通用 CRUD 层)

**文件**: `lib/core/supabase/database_service.dart`

**职责**:
- 提供通用的 CRUD 操作 (insert, update, delete, select)
- 不包含任何业务逻辑
- 所有方法都是表无关的，可以操作任何表

**特点**:
- 接收表名作为参数
- 返回原始的 `Map<String, dynamic>` 或 `List<Map<String, dynamic>>`
- 单例模式

**示例方法**:
```dart
Future<T> insert<T>({required String table, required Map<String, dynamic> data})
Future<List<Map<String, dynamic>>> select({required String table, String columns = '*'})
Future<List<T>> update<T>({required String table, required Map<String, dynamic> data})
```

---

### 2. API Layer (业务逻辑层)

**文件**: `lib/core/api/user/user_api.dart` (示例)

**职责**:
- 针对特定表（如 `profiles`）的业务逻辑
- 使用 `DatabaseService` 进行数据库操作
- 提供语义化的方法名（如 `getProfileById`, `incrementReputationScore`）
- 返回 `Map<String, dynamic>` (JSON)

**特点**:
- 每个表一个 API 文件 (如 `user_api.dart`, `report_api.dart`)
- 包含业务规则和数据验证
- 不依赖 Model，只处理 JSON

**示例**:
```dart
class UserApi {
  final _db = DatabaseService();
  static const String _tableName = 'profiles';

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    return await _db.selectSingle(
      table: _tableName,
      filterColumn: 'id',
      filterValue: userId,
    );
  }

  Future<void> incrementReputationScore(String userId, int points) async {
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
}
```

---

### 3. Repository Layer (数据仓库层)

**文件**: `lib/data/repositories/user_repository.dart` (示例)

**职责**:
- 调用 API Layer 的方法
- 将 JSON 转换为 Model (`UserProfile`, `ReportModel` 等)
- 提供类型安全的接口给 Presentation Layer
- 是 Provider 和 API 之间的桥梁

**特点**:
- 使用 Model 的 `fromJson()` 进行数据转换
- 返回强类型的 Model 对象
- 每个 API 对应一个 Repository

**示例**:
```dart
class UserRepository {
  final _userApi = UserApi();

  Future<UserProfile?> getProfileById(String userId) async {
    final json = await _userApi.getProfileById(userId);
    if (json == null) return null;
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> updateProfile({
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    final jsonList = await _userApi.updateProfile(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
    );
    return UserProfile.fromJson(jsonList.first);
  }
}
```

---

## 使用示例

### 在 Provider 中使用 Repository

```dart
import '../../data/repositories/user_repository.dart';
import '../../core/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final _userRepository = UserRepository();
  UserProfile? _currentProfile;

  UserProfile? get currentProfile => _currentProfile;

  Future<void> loadUserProfile(String userId) async {
    _currentProfile = await _userRepository.getProfileById(userId);
    notifyListeners();
  }

  Future<void> updateUsername(String userId, String newUsername) async {
    final updated = await _userRepository.updateProfile(
      userId: userId,
      username: newUsername,
    );
    _currentProfile = updated;
    notifyListeners();
  }
}
```

### 在 AuthService 中使用 Repository

```dart
class AuthService {
  final _userRepository = UserRepository();

  Future<UserProfile?> getUserProfile(String userId) async {
    return await _userRepository.getProfileById(userId);
  }

  Future<void> createProfileIfNotExists(User user) async {
    final exists = await _userRepository.profileExists(user.id);
    if (!exists) {
      await _userRepository.createProfile(
        userId: user.id,
        username: user.email?.split('@')[0] ?? 'user',
        email: user.email,
      );
    }
  }
}
```

---

## 为什么采用这种架构？

### ✅ 优点

1. **关注点分离**: 每层只关注自己的职责
   - DatabaseService: 通用 CRUD
   - API: 业务逻辑
   - Repository: 数据转换

2. **可维护性**: 
   - 修改数据库结构只需要改 API 层
   - 修改 Model 只需要改 Repository 层
   - DatabaseService 基本不需要修改

3. **可测试性**:
   - 每层都可以独立测试
   - 容易 mock 依赖

4. **类型安全**:
   - Repository 返回强类型 Model
   - 减少运行时错误

5. **代码复用**:
   - DatabaseService 可以被所有 API 复用
   - API 方法可以组合成更复杂的业务逻辑

### 📝 最佳实践

1. **不要跨层调用**: Provider 不应该直接调用 API 或 DatabaseService
2. **保持 DatabaseService 通用**: 不要在 DatabaseService 中写业务逻辑
3. **一个表一个 API 文件**: 便于组织和维护
4. **在 Repository 中使用 Model**: 让上层代码类型安全

---

## 文件组织

```
lib/
├── core/
│   ├── api/                      # API Layer
│   │   ├── user/
│   │   │   └── user_api.dart     # Users/Profiles 表的业务逻辑
│   │   └── report/
│   │       └── report_api.dart   # Reports 表的业务逻辑
│   ├── models/                   # Data Models
│   │   └── user_model.dart
│   └── supabase/
│       ├── database_service.dart # 通用 CRUD
│       └── auth_service.dart     # 认证服务
│
└── data/
    ├── models/                   # Additional Models
    │   └── report_model.dart
    └── repositories/             # Repository Layer
        ├── user_repository.dart  # 调用 UserApi + Model 转换
        └── report_repository.dart
```

---

## 扩展指南

### 添加新表的支持

1. **创建 Model** (如果需要)
   ```dart
   // lib/data/models/comment_model.dart
   class CommentModel {
     final String id;
     final String content;
     // ...
     factory CommentModel.fromJson(Map<String, dynamic> json) { ... }
   }
   ```

2. **创建 API**
   ```dart
   // lib/core/api/comment/comment_api.dart
   class CommentApi {
     final _db = DatabaseService();
     static const String _tableName = 'comments';
     
     Future<Map<String, dynamic>?> getCommentById(String id) async {
       return await _db.selectSingle(
         table: _tableName,
         filterColumn: 'id',
         filterValue: id,
       );
     }
   }
   ```

3. **创建 Repository**
   ```dart
   // lib/data/repositories/comment_repository.dart
   class CommentRepository {
     final _commentApi = CommentApi();
     
     Future<CommentModel?> getCommentById(String id) async {
       final json = await _commentApi.getCommentById(id);
       if (json == null) return null;
       return CommentModel.fromJson(json);
     }
   }
   ```

4. **在 Provider 中使用**
   ```dart
   class CommentProvider extends ChangeNotifier {
     final _commentRepository = CommentRepository();
     // ...
   }
   ```

---

## 总结

这种三层架构提供了清晰的职责划分，使代码更易于维护、测试和扩展。每一层都有明确的输入输出，降低了耦合度，提高了代码质量。

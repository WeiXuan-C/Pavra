# Supabase 集成指南

## 📁 文件结构

```
supabase/
├── supabase_constants.dart    # Supabase 配置（URL 和 API Key）
├── supabase_client.dart        # 主客户端和初始化
├── auth_service.dart           # 认证服务
├── storage_service.dart        # 存储服务
├── realtime_service.dart       # 实时订阅服务
└── database_service.dart       # 数据库 CRUD 服务
```

## ⚙️ 配置步骤

### 1. 添加 Supabase 凭据

在 `supabase_constants.dart` 中替换你的 Supabase 项目凭据：

```dart
class SupabaseConstants {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

在 https://app.supabase.com/project/YOUR_PROJECT_ID/settings/api 获取凭据

### 2. 已完成的初始化

`main.dart` 已经配置好了 Supabase 初始化，无需额外操作。

## 🔐 认证服务 (AuthService)

```dart
final authService = AuthService();

// 注册
await authService.signUpWithPassword(
  email: 'user@example.com',
  password: 'password123',
);

// 登录
await authService.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);

// 登出
await authService.signOut();

// 检查认证状态
if (authService.isAuthenticated) {
  print('已登录: ${authService.currentUser!.email}');
}

// 监听认证状态变化
authService.authStateChanges.listen((data) {
  final event = data.event;
  final session = data.session;
  // 处理状态变化
});
```

## 💾 数据库服务 (DatabaseService)

```dart
final dbService = DatabaseService();

// 插入数据
await dbService.insert(
  table: 'todos',
  data: {'title': '买菜', 'completed': false},
);

// 查询所有数据
final todos = await dbService.selectAll(table: 'todos');

// 查询单条数据
final todo = await dbService.selectSingle(
  table: 'todos',
  filterColumn: 'id',
  filterValue: '123',
);

// 更新数据
await dbService.update(
  table: 'todos',
  data: {'completed': true},
  matchColumn: 'id',
  matchValue: '123',
);

// 删除数据
await dbService.delete(
  table: 'todos',
  matchColumn: 'id',
  matchValue: '123',
);

// 分页查询
final page1 = await dbService.selectWithPagination(
  table: 'todos',
  page: 1,
  pageSize: 10,
  orderBy: 'created_at',
);
```

## 📦 存储服务 (StorageService)

```dart
final storageService = StorageService();

// 上传文件
final url = await storageService.uploadFile(
  bucket: 'avatars',
  path: 'user/123/profile.jpg',
  file: fileBytes, // Uint8List 或 File
);

// 下载文件
final bytes = await storageService.downloadFile(
  bucket: 'avatars',
  path: 'user/123/profile.jpg',
);

// 获取公开 URL
final publicUrl = storageService.getPublicUrl(
  bucket: 'avatars',
  path: 'user/123/profile.jpg',
);

// 删除文件
await storageService.deleteFiles(
  bucket: 'avatars',
  paths: ['user/123/profile.jpg'],
);

// 列出文件
final files = await storageService.listFiles(
  bucket: 'avatars',
  path: 'user/123/',
);
```

## ⚡ 实时服务 (RealtimeService)

```dart
final realtimeService = RealtimeService();

// 订阅表的所有变化
final channel = realtimeService.subscribeToTable(
  table: 'todos',
  callback: (payload) {
    print('事件: ${payload.eventType}');
    print('新数据: ${payload.newRecord}');
    print('旧数据: ${payload.oldRecord}');
  },
);

// 只订阅插入事件
realtimeService.subscribeToInserts(
  table: 'todos',
  callback: (payload) {
    print('新增: ${payload.newRecord}');
  },
);

// 只订阅更新事件
realtimeService.subscribeToUpdates(
  table: 'todos',
  callback: (payload) {
    print('更新: ${payload.newRecord}');
  },
);

// 取消订阅
await realtimeService.unsubscribe('table:todos');

// 取消所有订阅
await realtimeService.unsubscribeAll();
```

## 🚀 直接使用 Supabase 客户端

如果你需要更灵活的操作，可以直接使用全局 `supabase` 客户端：

```dart
import 'package:pavra/core/supabase/supabase_client.dart';

// 复杂查询
final posts = await supabase
    .from('posts')
    .select('''
      id,
      title,
      author:profiles!user_id(username, avatar),
      comments(content, created_at)
    ''')
    .eq('status', 'published')
    .gte('created_at', DateTime.now().subtract(Duration(days: 7)).toIso8601String())
    .order('created_at', ascending: false)
    .limit(10);

// 调用 Edge Functions
final response = await supabase.functions.invoke(
  'my-function',
  body: {'key': 'value'},
);

// RPC 调用
final result = await supabase.rpc('my_function', params: {'param': 'value'});
```

## ⚠️ 注意事项

1. **Row Level Security (RLS)**：确保在 Supabase 后台设置好表的 RLS 策略
2. **API Key 安全**：不要将 API Key 提交到公开的 Git 仓库
3. **错误处理**：所有服务方法都可能抛出异常，请使用 try-catch
4. **实时订阅**：记得在不需要时取消订阅，避免内存泄漏

## 📚 更多资源

- [Supabase Flutter 文档](https://supabase.com/docs/reference/dart)
- [Supabase 控制台](https://app.supabase.com)

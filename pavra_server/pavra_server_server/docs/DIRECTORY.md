# Pavra Server 项目结构文档

这份文档详细说明了 `pavra_server_server` 项目的文件结构和每个文件的作用。

## 📁 项目根目录

```
pavra_server_server/
├── bin/                    # 可执行文件入口
├── config/                 # 配置文件
├── deploy/                 # 部署脚本和配置
├── docs/                   # 项目文档
├── lib/                    # 主要代码库
├── migrations/             # 数据库迁移文件
├── test/                   # 测试文件
├── web/                    # 静态资源和模板
├── docker-compose.yaml     # Docker 编排配置
├── Dockerfile              # Docker 镜像构建文件
└── pubspec.yaml            # Dart 依赖配置
```

---

## 🚀 bin/ - 应用入口

### `bin/main.dart`
**作用**: 服务器启动入口点
- 调用 `lib/server.dart` 中的 `run()` 函数
- 传递命令行参数给 Serverpod

**使用场景**: 
```bash
dart run bin/main.dart
```

---

## ⚙️ config/ - 配置文件

### `config/development.yaml`
**作用**: 开发环境配置
- 本地数据库连接
- 本地 Redis 配置
- 开发模式日志级别

### `config/production.yaml`
**作用**: 生产环境配置（Railway）
- Railway PostgreSQL 连接
- Railway Redis 连接
- 生产环境优化设置

### `config/staging.yaml`
**作用**: 预发布环境配置
- 用于测试生产环境配置

### `config/passwords.yaml`
**作用**: 敏感信息配置（不提交到 Git）
- 数据库密码
- API 密钥
- Supabase 凭证

**⚠️ 重要**: 此文件应在 `.gitignore` 中

### `config/generator.yaml`
**作用**: Serverpod 代码生成器配置
- 定义协议文件位置
- 配置自动生成的代码

---

## 📚 lib/ - 核心代码库

### `lib/server.dart`
**作用**: 服务器主配置和初始化
- 初始化 Serverpod
- 初始化 Redis 连接
- 初始化 Supabase 连接
- 注册后台任务
- 配置 Web 路由

**关键函数**:
- `run()`: 启动服务器
- `_initializeRedis()`: 连接 Redis
- `_initializeSupabase()`: 连接 Supabase

**日志工具**:
- `PLog.info()`: 信息日志
- `PLog.warn()`: 警告日志
- `PLog.error()`: 错误日志

---

## 🔌 lib/src/endpoints/ - API 端点

### `endpoints/greeting_endpoint.dart`
**作用**: 示例端点（Serverpod 默认）
- 演示基本的 RPC 调用

### `endpoints/redis_health_endpoint.dart`
**作用**: Redis 健康检查端点
- 检查 Redis 连接状态
- 测试 Redis 读写功能

**API 方法**:
```dart
await client.redisHealth.ping();  // 返回 true/false
```

### `endpoints/user_actions_endpoint.dart`
**作用**: 用户行为日志 API
- 记录用户操作到 Redis
- 查询用户操作历史
- 批量记录操作

**API 方法**:
```dart
// 记录单个操作
await client.userActions.logAction(
  userId: 123,
  action: 'viewed_profile',
  metadata: {'profileId': '456'},
);

// 获取用户操作历史
final logs = await client.userActions.getUserActions(
  userId: 123,
  limit: 50,
);

// 批量记录
await client.userActions.logBatchActions(
  userId: 123,
  actions: ['login', 'view_dashboard', 'logout'],
);

// 清空用户日志
await client.userActions.clearUserActions(userId: 123);
```

---

## 🛠️ lib/src/services/ - 服务层

### `services/redis_service.dart`
**作用**: Redis 连接和操作管理（单例模式）

**初始化**:
```dart
await RedisService.initialize(
  host: 'localhost',
  port: 6379,
  password: 'your-password',  // 可选
);
```

**主要方法**:
```dart
final redis = RedisService.instance;

// 基本操作
await redis.set('key', 'value', expireSeconds: 3600);
final value = await redis.get('key');
await redis.delete('key');

// 健康检查
final isHealthy = await redis.ping();

// 用户行为日志
await redis.addAction(
  userId: 123,
  action: 'login',
  metadata: {'device': 'mobile'},
  maxLogs: 100,  // 保留最近 100 条
);

final actions = await redis.getActions(userId: 123, limit: 50);
```

**特点**:
- 自动重连机制
- 支持 Railway Redis（带密码）
- 支持本地 Redis（无密码）

---

### `services/supabase_service.dart`
**作用**: Supabase 连接和操作管理（单例模式）

**初始化**:
```dart
await SupabaseService.initialize(
  url: 'https://your-project.supabase.co',
  serviceRoleKey: 'your-service-role-key',
);
```

**主要方法**:
```dart
final supabase = SupabaseService.instance;

// 插入数据
await supabase.insert('action_log', [
  {'user_id': 'user-123', 'action': 'login'},
]);

// 查询数据
final logs = await supabase.select(
  'action_log',
  filters: {'user_id': 'user-123'},
  orderBy: 'created_at',
  ascending: false,
  limit: 20,
);

// 更新数据
await supabase.update(
  'action_log',
  {'is_synced': true},
  filters: {'id': 'log-id'},
);

// 删除数据
await supabase.delete(
  'action_log',
  filters: {'id': 'log-id'},
);

// 健康检查
final isHealthy = await supabase.healthCheck();
```

**特点**:
- 自动从环境变量读取配置
- 连接验证
- 统一的错误处理

---

### `services/action_log_service.dart`
**作用**: 整合 Redis 和 Supabase 的日志服务

**核心职责**:
1. **记录日志到 Redis** - 高性能异步写入
2. **批量同步到 Supabase** - 定期将 Redis 日志持久化到云端
3. **查询历史日志** - 从 Supabase 读取用户操作历史
4. **健康检查** - 监控 Redis 和 Supabase 连接状态

**详细功能说明**:

#### 1. `logAction()` - 记录用户操作
```dart
await service.logAction(
  userId: 'user-123',           // 用户 ID
  action: 'profile_updated',    // 操作类型
  targetId: 'profile-456',      // 目标资源 ID（可选）
  targetTable: 'profiles',      // 目标表名（可选）
  description: 'User updated profile picture',  // 描述（可选）
  metadata: {                   // 额外元数据（可选）
    'field': 'avatar_url',
    'old_value': 'default.png',
    'new_value': 'custom.png',
  },
);
```

**内部流程**:
1. 构建日志对象（包含时间戳）
2. 调用 `RedisService.addAction()` 写入 Redis
3. 日志记录到 `user:{userId}:actions` 列表
4. 自动限制每个用户最多保留 100 条日志

**适用场景**:
- 用户浏览行为（页面访问、点击）
- 非关键操作（点赞、收藏）
- 高频操作（搜索、筛选）

---

#### 2. `flushLogsToSupabase()` - 批量同步到云端
```dart
final syncedCount = await service.flushLogsToSupabase(
  batchSize: 50,  // 每次最多同步 50 条
);
print('同步了 $syncedCount 条日志');
```

**内部流程**:
1. 从 Redis 队列 `action_logs:queue` 读取日志
2. 解析 JSON 格式的日志数据
3. 调用 `SupabaseService.insert()` 插入到 Supabase
4. 插入成功后从 Redis 删除该日志
5. 返回成功同步的日志数量

**错误处理**:
- JSON 解析失败：记录警告并跳过
- Supabase 插入失败：记录错误但继续处理其他日志
- 网络异常：捕获异常并返回已同步数量

**性能优化**:
- 批量处理减少网络往返
- 失败的日志不会阻塞后续日志
- 使用 `batchSize` 控制单次处理量

---

#### 3. `getUserActions()` - 查询用户历史
```dart
final actions = await service.getUserActions(
  userId: 'user-123',
  limit: 20,  // 最多返回 20 条
);

// 返回格式
[
  {
    'user_id': 'user-123',
    'action': 'login',
    'created_at': '2024-10-16T10:30:00Z',
    'metadata': {'device': 'mobile'},
  },
  // ...
]
```

**内部流程**:
1. 调用 `SupabaseService.select()` 查询
2. 按 `user_id` 过滤
3. 按 `created_at` 降序排序（最新的在前）
4. 限制返回数量

**使用场景**:
- 用户活动时间线
- 操作审计日志
- 用户行为分析

---

#### 4. `healthCheck()` - 健康检查
```dart
final health = await service.healthCheck();
// 返回: {'redis': true, 'supabase': true}

if (!health['redis']) {
  print('⚠️ Redis 连接异常');
}
if (!health['supabase']) {
  print('⚠️ Supabase 连接异常');
}
```

**检查内容**:
- **Redis**: 发送 PING 命令测试连接
- **Supabase**: 查询 `action_log` 表测试连接

**使用场景**:
- 服务启动时验证依赖
- 健康检查端点
- 监控告警

---

**完整工作流程**:
```
┌─────────────┐
│  用户操作    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│  ActionLogService.logAction()       │
│  - 构建日志对象                      │
│  - 添加时间戳                        │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  RedisService.addAction()           │
│  - 写入 Redis 列表                   │
│  - Key: user:{userId}:actions       │
│  - 限制最多 100 条                   │
└──────┬──────────────────────────────┘
       │
       │ (定时触发或手动调用)
       ▼
┌─────────────────────────────────────┐
│  ActionLogService.flushToSupabase() │
│  - 从 Redis 读取日志                 │
│  - 批量插入 Supabase                 │
│  - 删除已同步的日志                  │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Supabase action_log 表              │
│  - 云端持久化存储                    │
│  - 支持复杂查询和分析                │
└─────────────────────────────────────┘
```

**依赖关系**:
- 依赖 `RedisService` 单例（必须先初始化）
- 依赖 `SupabaseService` 单例（必须先初始化）
- 使用 `PLog` 记录操作日志

**注意事项**:
⚠️ Redis 中的日志是临时的，定期同步到 Supabase 才能永久保存
⚠️ 如果 Redis 重启，未同步的日志会丢失
⚠️ 建议配合 `sync_action_logs.dart` 任务自动同步

---

## ⏰ lib/src/tasks/ - 后台任务

### `tasks/sync_action_logs.dart`
**作用**: 定时同步 PostgreSQL 日志到 Supabase（双数据库同步方案）

**核心职责**:
1. **定时执行** - 每 10 分钟自动运行一次
2. **读取未同步日志** - 从本地 PostgreSQL 查询 `is_synced = FALSE` 的记录
3. **推送到 Supabase** - 批量插入到云端 Supabase 数据库
4. **标记已同步** - 更新本地数据库的同步状态
5. **自动调度** - 完成后自动安排下一次执行

---

### 详细功能说明

#### 1. `ActionLogSyncTask.invoke()` - 主同步逻辑

**执行流程**:
```dart
@override
Future<void> invoke(Session session, SerializableModel? object) async {
  // 1. 初始化 ActionLogService（单例模式）
  _actionLogService ??= ActionLogService();
  
  // 2. 从 PostgreSQL 读取未同步日志
  final unsyncedLogs = await _fetchUnsyncedLogs(session);
  
  // 3. 如果没有未同步日志，跳过
  if (unsyncedLogs.isEmpty) {
    PLog.info('No unsynced logs found');
    _scheduleNextSync(session);
    return;
  }
  
  // 4. 推送到 Supabase
  final syncedIds = await _pushToSupabase(session, unsyncedLogs);
  
  // 5. 标记为已同步
  if (syncedIds.isNotEmpty) {
    await _markAsSynced(session, syncedIds);
  }
  
  // 6. 安排下一次执行
  _scheduleNextSync(session);
}
```

**错误处理**:
- 使用 `try-catch-finally` 确保任务不会中断
- 即使发生错误，也会在 `finally` 中调度下一次执行
- 所有错误都通过 `PLog.error()` 记录

---

#### 2. `_fetchUnsyncedLogs()` - 读取未同步日志

**SQL 查询**:
```sql
SELECT id, user_id, action_type, target_id, target_table, 
       description, metadata, created_at
FROM action_log
WHERE is_synced = FALSE
ORDER BY created_at ASC
LIMIT 100
```

**返回格式**:
```dart
[
  {
    'id': 1,
    'user_id': 'uuid-123',
    'action_type': 'user_login',
    'target_id': 'session-456',
    'target_table': 'sessions',
    'description': 'User logged in',
    'metadata': {'device': 'mobile'},
    'created_at': '2024-10-16T10:30:00Z',
  },
  // ... 最多 100 条
]
```

**设计考虑**:
- **批量处理**: 每次最多 100 条，避免单次处理过多数据
- **按时间排序**: 确保日志按时间顺序同步
- **使用 unsafeQuery**: 直接执行 SQL，性能更高

---

#### 3. `_pushToSupabase()` - 推送到云端

**核心逻辑**:
```dart
Future<List<int>> _pushToSupabase(
  Session session,
  List<Map<String, dynamic>> logs,
) async {
  final syncedIds = <int>[];
  final service = _actionLogService!;
  
  // 处理每条日志
  final logsForSupabase = logs.map((log) {
    final logCopy = Map<String, dynamic>.from(log);
    final localId = logCopy.remove('id');  // 移除本地 ID
    return {'localId': localId, 'data': logCopy};
  }).toList();
  
  // 逐条插入 Supabase
  for (final entry in logsForSupabase) {
    try {
      await service.supabase.insert('action_log', [entry['data']]);
      syncedIds.add(entry['localId'] as int);  // 记录成功的 ID
    } catch (e) {
      PLog.error('Failed to sync log ${entry['localId']}', e);
      // 继续处理其他日志，不中断
    }
  }
  
  return syncedIds;  // 返回成功同步的本地 ID 列表
}
```

**关键设计**:
1. **移除本地 ID**: Supabase 会生成自己的 UUID，不使用本地自增 ID
2. **逐条插入**: 确保单条失败不影响其他日志
3. **记录成功 ID**: 只标记成功同步的日志
4. **错误容忍**: 失败的日志会在下次同步时重试

**数据转换**:
```
PostgreSQL 日志                    Supabase 日志
┌─────────────────┐               ┌─────────────────┐
│ id: 1 (移除)     │               │ id: uuid (新生成)│
│ user_id: uuid   │  ────────────> │ user_id: uuid   │
│ action_type: .. │               │ action_type: .. │
│ metadata: {...} │               │ metadata: {...} │
│ is_synced: false│               │ (无此字段)       │
└─────────────────┘               └─────────────────┘
```

---

#### 4. `_markAsSynced()` - 标记已同步

**SQL 更新**:
```sql
UPDATE action_log
SET is_synced = TRUE
WHERE id IN (1, 2, 3, ...)
```

**实现**:
```dart
Future<void> _markAsSynced(Session session, List<int> logIds) async {
  final idsString = logIds.join(',');  // "1,2,3,4,5"
  await session.db.unsafeQuery(
    'UPDATE action_log SET is_synced = TRUE WHERE id IN ($idsString)'
  );
}
```

**作用**:
- 防止重复同步
- 下次执行时跳过已同步的日志
- 保持本地数据库的同步状态

---

#### 5. `_scheduleNextSync()` - 调度下一次执行

**调度逻辑**:
```dart
void _scheduleNextSync(Session session) {
  // 检查前置条件
  if (!session.serverpod.config.futureCallExecutionEnabled ||
      session.serverpod.config.redis?.enabled != true) {
    PLog.warn('Future calls or Redis not enabled');
    return;
  }
  
  // 安排 10 分钟后执行
  session.serverpod.futureCallAtTime(
    'actionLogSync',
    null,
    DateTime.now().add(Duration(minutes: 10)),
  );
}
```

**依赖条件**:
- ✅ `futureCallExecutionEnabled: true` - 启用后台任务
- ✅ `redis.enabled: true` - Redis 用于任务调度
- ✅ 环境变量配置正确

---

#### 6. `initializeActionLogSync()` - 初始化任务

**在服务器启动时调用**:
```dart
// 在 lib/server.dart 中
await initializeActionLogSync(pod);
```

**实现**:
```dart
Future<void> initializeActionLogSync(Serverpod pod) async {
  // 检查配置
  if (!pod.config.futureCallExecutionEnabled ||
      pod.config.redis?.enabled != true) {
    print('⚠️ Future calls disabled, skipping action log sync.');
    return;
  }
  
  // 延迟 10 分钟后首次执行
  await pod.futureCallWithDelay(
    FutureCallNames.actionLogSync.name,
    null,
    Duration(minutes: 10),
  );
  
  print('✓ Action log sync task registered.');
}
```

**首次执行时间**: 服务器启动后 10 分钟

---

### 完整工作流程图

```
┌──────────────────────────────────────────────────────┐
│  服务器启动                                           │
│  └─> initializeActionLogSync(pod)                   │
│      └─> 注册任务，10 分钟后首次执行                  │
└──────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│  每 10 分钟执行一次                                   │
│  ActionLogSyncTask.invoke()                         │
└──────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│  步骤 1: 从 PostgreSQL 读取未同步日志                 │
│  _fetchUnsyncedLogs()                               │
│  ├─ SELECT * FROM action_log                        │
│  ├─ WHERE is_synced = FALSE                         │
│  └─ LIMIT 100                                       │
└──────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│  步骤 2: 推送到 Supabase                             │
│  _pushToSupabase()                                  │
│  ├─ 移除本地 ID                                      │
│  ├─ 逐条插入 Supabase                                │
│  └─ 记录成功的 ID                                    │
└──────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│  步骤 3: 标记为已同步                                 │
│  _markAsSynced()                                    │
│  └─ UPDATE action_log SET is_synced = TRUE          │
└──────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│  步骤 4: 调度下一次执行                               │
│  _scheduleNextSync()                                │
│  └─ 10 分钟后再次执行                                │
└──────────────────────────────────────────────────────┘
```

---

### 数据库表结构要求

**PostgreSQL (本地数据库)**:
```sql
CREATE TABLE action_log (
  id SERIAL PRIMARY KEY,              -- 自增 ID
  user_id UUID,                       -- 用户 ID
  action_type TEXT,                   -- 操作类型
  target_id UUID,                     -- 目标资源 ID
  target_table TEXT,                  -- 目标表名
  description TEXT,                   -- 描述
  metadata JSONB,                     -- 元数据
  created_at TIMESTAMPTZ DEFAULT NOW(), -- 创建时间
  is_synced BOOLEAN DEFAULT FALSE     -- 同步标记 ⭐
);

-- 索引优化
CREATE INDEX idx_action_log_is_synced ON action_log(is_synced);
CREATE INDEX idx_action_log_created_at ON action_log(created_at);
```

**Supabase (云端数据库)**:
```sql
CREATE TABLE action_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,  -- UUID 主键
  user_id TEXT,                       -- 用户 ID（可以是 TEXT 或 UUID）
  action_type TEXT,                   -- 操作类型
  target_id TEXT,                     -- 目标资源 ID
  target_table TEXT,                  -- 目标表名
  description TEXT,                   -- 描述
  metadata JSONB,                     -- 元数据
  created_at TIMESTAMPTZ DEFAULT NOW() -- 创建时间
  -- 注意：没有 is_synced 字段
);

-- 索引优化
CREATE INDEX idx_action_log_user_id ON action_log(user_id);
CREATE INDEX idx_action_log_created_at ON action_log(created_at DESC);
```

---

### 配置要求

**1. 在 `config/production.yaml` 中启用 Redis 和 Future Calls**:
```yaml
redis:
  enabled: true
  host: 'redis-host'
  port: 6379

futureCallExecutionEnabled: true
```

**2. 在 Railway 环境变量中配置 Supabase**:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
```

**3. 在 `lib/server.dart` 中注册任务**:
```dart
enum FutureCallNames { 
  birthdayReminder, 
  actionLogSync  // ⭐ 添加这个
}

// 在 run() 函数中
await initializeActionLogSync(pod);
```

---

### 使用场景

#### 场景 1: 双数据库备份
- **本地 PostgreSQL**: 主数据库，快速写入
- **Supabase**: 备份数据库，云端持久化
- **优势**: 本地故障时，云端数据仍然安全

#### 场景 2: 前端直接访问 Supabase
- **后端**: 写入本地 PostgreSQL
- **前端**: 通过 Supabase Client 直接读取云端数据
- **优势**: 减轻后端 API 压力

#### 场景 3: 数据分析和报表
- **本地**: 实时业务数据
- **Supabase**: 用于数据分析、BI 工具
- **优势**: 分析查询不影响生产数据库

---

### 监控和调试

**查看同步状态**:
```sql
-- 查看未同步日志数量
SELECT COUNT(*) FROM action_log WHERE is_synced = FALSE;

-- 查看最近的未同步日志
SELECT * FROM action_log 
WHERE is_synced = FALSE 
ORDER BY created_at DESC 
LIMIT 10;

-- 查看同步失败的日志（超过 1 小时未同步）
SELECT * FROM action_log 
WHERE is_synced = FALSE 
  AND created_at < NOW() - INTERVAL '1 hour';
```

**日志输出**:
```
ℹ️ [INFO] Starting action log sync...
ℹ️ [INFO] Found 45 unsynced logs
ℹ️ [INFO] Successfully pushed 45/45 logs to Supabase
ℹ️ [INFO] Successfully synced 45 action logs
```

**常见问题**:
1. **任务不执行**: 检查 Redis 和 Future Calls 配置
2. **同步失败**: 检查 Supabase 凭证和网络连接
3. **重复同步**: 检查 `is_synced` 字段是否正确更新

---

### 性能优化建议

1. **批量大小**: 默认 100 条，可根据网络情况调整
2. **执行频率**: 默认 10 分钟，可根据数据量调整
3. **索引优化**: 在 `is_synced` 和 `created_at` 上建立索引
4. **错误重试**: 失败的日志会在下次自动重试
5. **监控告警**: 监控未同步日志数量，超过阈值时告警

---

## 🔧 lib/src/utils/ - 工具类

### `utils/action_logger.dart`
**作用**: 直接写入 PostgreSQL 的日志工具

**使用场景**: 
- 关键操作需要立即持久化
- 不能依赖 Redis 的场景

**使用示例**:
```dart
await ActionLogger.log(
  session,
  userId: 'user-uuid-123',
  actionType: 'user_login',
  targetId: 'session-id',
  targetTable: 'sessions',
  description: 'User logged in from mobile',
  metadata: {
    'device': 'iPhone 14',
    'ip': '192.168.1.1',
  },
);

// 查询日志
final logs = await ActionLogger.getRecentActions(
  session,
  'user-uuid-123',
  limit: 20,
);
```

**特点**:
- 直接写入数据库（不经过 Redis）
- SQL 注入防护
- 同步到 Serverpod 内置日志

---

## 📖 lib/src/examples/ - 示例代码

### `examples/action_logging_example.dart`
**作用**: 演示三种日志记录方式

**示例 1: 直接写入 PostgreSQL**
```dart
await ActionLoggingExample.logToPostgreSQL(session);
```

**示例 2: 通过 Redis 队列**
```dart
// 使用 UserActionsEndpoint
await client.userActions.logAction(...);
```

**示例 3: 使用 ActionLogService**
```dart
await ActionLoggingExample.demonstrateActionLogService();
```

---

## 🗄️ migrations/ - 数据库迁移

### `migrations/20251013093515748/`
**作用**: 数据库版本控制

**文件说明**:
- `definition.sql`: 数据库结构定义
- `migration.sql`: 迁移 SQL 脚本
- `definition.json`: 结构的 JSON 表示

**运行迁移**:
```bash
serverpod create-migration
serverpod migrate
```

---

## 🌐 web/ - Web 资源

### `web/static/`
**作用**: 静态文件（CSS、图片等）

### `web/templates/`
**作用**: HTML 模板

---

## 🚢 部署相关

### `Dockerfile`
**作用**: Docker 镜像构建
- 用于 Railway 部署
- 多阶段构建优化

### `docker-compose.yaml`
**作用**: 本地开发环境
- PostgreSQL 容器
- Redis 容器
- Serverpod 容器

**启动本地环境**:
```bash
docker-compose up -d
```

---

## 📊 日志系统架构

### 三层日志架构

```
┌─────────────────────────────────────────────────────────┐
│                    用户操作                              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │         选择日志记录方式              │
        └─────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ ActionLogger │  │ RedisService │  │ActionLogSvc  │
│  (直接写DB)   │  │  (队列缓存)   │  │ (整合方案)   │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  PostgreSQL  │  │    Redis     │  │Redis+Supabase│
│   (本地DB)    │  │   (缓存)     │  │  (云+缓存)   │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ▼
                ┌──────────────────┐
                │  SyncActionLogs  │
                │   (定时同步任务)   │
                └──────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │    Supabase      │
                │   (云端持久化)    │
                └──────────────────┘
```

### 日志记录方式对比

| 方式 | 优点 | 缺点 | 使用场景 |
|------|------|------|----------|
| **ActionLogger** | 立即持久化、可靠 | 性能开销大 | 关键操作（登录、支付） |
| **RedisService** | 高性能、异步 | 可能丢失数据 | 高频操作（浏览、点击） |
| **ActionLogService** | 平衡性能和可靠性 | 配置复杂 | 通用日志记录 |

---

## 🔐 环境变量配置

### Railway 生产环境

在 Railway 项目设置中添加：

```bash
# PostgreSQL (Railway 自动提供)
DATABASE_URL=postgresql://...

# Redis (Railway 自动提供)
REDIS_URL=redis://default:password@host:port

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...

# 可选：Supabase Anon Key（前端使用）
SUPABASE_ANON_KEY=eyJhbGc...
```

### 本地开发环境

在 `config/passwords.yaml` 中配置：

```yaml
development:
  database: 'your_local_password'
  redis: ''  # 本地 Redis 通常无密码
  
shared:
  supabaseUrl: 'https://your-project.supabase.co'
  supabaseServiceRoleKey: 'eyJhbGc...'
```

---

## 🧪 测试

### 运行测试
```bash
dart test
```

### 测试文件位置
- `test/integration/`: 集成测试
- `test/unit/`: 单元测试（需自行创建）

---

## 📝 开发工作流

### 1. 添加新的 API 端点

```dart
// 1. 在 lib/src/endpoints/ 创建新文件
class MyEndpoint extends Endpoint {
  Future<String> myMethod(Session session, String param) async {
    return 'Hello $param';
  }
}

// 2. Serverpod 会自动注册端点
// 3. 客户端调用
await client.my.myMethod('World');
```

### 2. 添加新的后台任务

```dart
// 1. 在 lib/src/tasks/ 创建任务类
class MyTask extends FutureCall {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    // 任务逻辑
  }
}

// 2. 在 server.dart 中注册
enum FutureCallNames { myTask }

// 3. 调度任务
await pod.futureCallWithDelay(
  FutureCallNames.myTask.name,
  null,
  Duration(minutes: 5),
);
```

### 3. 数据库迁移

```bash
# 1. 修改 .spy.yaml 文件
# 2. 生成迁移
serverpod create-migration

# 3. 应用迁移
serverpod migrate
```

---

## 🐛 常见问题

### Redis 连接失败
```
❌ Failed to connect to Redis
```
**解决方案**:
1. 检查 Railway Redis 是否启动
2. 验证 `REDIS_URL` 环境变量
3. 检查防火墙设置

### Supabase 同步失败
```
⚠️ Supabase connection test failed
```
**解决方案**:
1. 验证 `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY`
2. 确认 Supabase 项目中存在 `action_log` 表
3. 检查 Service Role Key 权限

### Future Calls 不执行
```
⚠️ Future calls disabled or Redis not enabled
```
**解决方案**:
1. 在 `config/production.yaml` 中启用 Redis
2. 设置 `futureCallExecutionEnabled: true`

---

## 📚 相关文档

- [Serverpod 官方文档](https://docs.serverpod.dev/)
- [Redis 命令参考](https://redis.io/commands/)
- [Supabase 文档](https://supabase.com/docs)
- [Railway 部署指南](https://docs.railway.app/)

---

## 🎯 快速参考

### 启动服务器
```bash
dart run bin/main.dart
```

### 生成代码
```bash
serverpod generate
```

### 运行测试
```bash
dart test
```

### 部署到 Railway
```bash
git push origin main  # Railway 自动部署
```

---

**最后更新**: 2024-10-16
**维护者**: Pavra Team

# Redis 文件使用说明

本文档整理了 Pavra Server 中所有 Redis 相关文件的用途和使用情况。

## 📋 文件概览

### ✅ 正在使用的文件

| 文件路径 | 状态 | 用途 |
|---------|------|------|
| `lib/src/services/upstash_redis_service.dart` | ✅ 使用中 | Upstash Redis REST API 服务（主要使用） |
| `lib/src/endpoints/redis_health_endpoint.dart` | ✅ 使用中 | Redis 健康检查端点 |
| `lib/src/services/action_log_service.dart` | ✅ 使用中 | 用户行为日志服务（使用 Upstash Redis） |
| `lib/src/endpoints/action_log_endpoint.dart` | ✅ 使用中 | 用户行为日志 API 端点 |
| `lib/src/tasks/sync_action_logs.dart` | ✅ 使用中 | 定时任务：同步日志到 Supabase |

---

## 📁 详细说明

### 1. ✅ `upstash_redis_service.dart` - Upstash Redis REST API 服务

**用途**: 通过 HTTP REST API 连接 Upstash Redis，适合云端/无服务器部署

**主要功能**:
- `ping()` - 健康检查
- `set(key, value, expireSeconds)` - 设置键值对
- `get(key)` - 获取值
- `delete(key)` - 删除键
- `lpush(key, value)` - 列表左侧推入
- `rpop(key)` - 列表右侧弹出
- `llen(key)` - 获取列表长度

**初始化位置**: `lib/server.dart` 的 `_initializeUpstashRedis()` 函数

**环境变量**:
```env
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token
```

**使用场景**:
- 用户行为日志队列（`action_logs:queue`）
- 临时数据缓存

---

### 2. ✅ `redis_health_endpoint.dart` - Redis 健康检查端点

**用途**: 提供 API 端点检查 Upstash Redis 连接状态

**API 端点**:
- `POST /redisHealth/check` - 执行完整健康检查（PING + 读写测试）
- `POST /redisHealth/info` - 获取 Redis 连接信息

**调用示例**:
```dart
final health = await client.redisHealth.check();
print('Redis connected: ${health['connected']}');
```

**返回数据**:
```json
{
  "connected": true,
  "writeTest": true,
  "readTest": true,
  "error": null
}
```

---

### 3. ✅ `action_log_service.dart` - 用户行为日志服务

**用途**: 管理用户行为日志的记录和同步

**核心流程**:
1. 用户行为 → 写入 Upstash Redis 队列（`action_logs:queue`）
2. 定时任务每分钟从 Redis 队列读取日志
3. 批量写入 Supabase 数据库（`action_log` 表）

**主要方法**:
- `logAction()` - 记录用户行为到 Redis 队列
- `flushLogsToSupabase()` - 将 Redis 队列中的日志同步到 Supabase
- `getUserActions()` - 从 Supabase 查询用户历史行为
- `healthCheck()` - 检查 Redis 和 Supabase 连接状态

**使用位置**:
- `lib/src/endpoints/action_log_endpoint.dart` - API 端点
- `lib/src/tasks/sync_action_logs.dart` - 定时同步任务

---

### 4. ✅ `action_log_endpoint.dart` - 用户行为日志 API 端点

**用途**: 提供 REST API 供客户端记录和查询用户行为

**API 端点**:

#### `POST /actionLog/log` - 记录用户行为
```dart
await client.actionLog.log(
  userId: 'user-123',
  action: 'profile_viewed',
  targetId: 'profile-456',
  description: 'User viewed another profile',
);
```

#### `POST /actionLog/getUserActions` - 查询用户历史行为
```dart
final actions = await client.actionLog.getUserActions('user-123', limit: 20);
```

#### `POST /actionLog/flushLogs` - 手动触发日志同步
```dart
final count = await client.actionLog.flushLogs(batchSize: 100);
```

#### `POST /actionLog/healthCheck` - 健康检查
```dart
final health = await client.actionLog.healthCheck();
// { "upstash_redis": true, "supabase": true }
```

---

### 5. ✅ `sync_action_logs.dart` - 定时同步任务

**用途**: 后台定时任务，每分钟自动将 Redis 队列中的日志同步到 Supabase

**执行频率**: 每 1 分钟

**批量大小**: 每次最多同步 100 条日志

**初始化位置**: `lib/server.dart` 的 `initializeActionLogSync()` 函数

**任务流程**:
1. 从 Redis 队列 `action_logs:queue` 使用 `RPOP` 弹出日志
2. 解析 JSON 数据
3. 插入到 Supabase `action_log` 表
4. 如果失败，重新放回队列
5. 调度下一次执行

**依赖条件**:
- Serverpod 配置中启用 `futureCallExecutionEnabled`
- Upstash Redis 和 Supabase 服务已初始化

---

## 🔄 数据流程图

```
用户行为
    ↓
action_log_endpoint.log()
    ↓
action_log_service.logAction()
    ↓
Upstash Redis 队列 (action_logs:queue)
    ↓ (每分钟)
sync_action_logs.dart (定时任务)
    ↓
action_log_service.flushLogsToSupabase()
    ↓
Supabase 数据库 (action_log 表)
```

---

## 🔧 配置要求

### 必需的环境变量

```env
# Upstash Redis REST API
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token

# Supabase (用于持久化存储)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### Supabase 数据库表结构

需要在 Supabase 中创建 `action_log` 表：

```sql
CREATE TABLE action_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT,
  action_type TEXT NOT NULL,
  target_id TEXT,
  target_table TEXT,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_synced BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_action_log_user_id ON action_log(user_id);
CREATE INDEX idx_action_log_created_at ON action_log(created_at DESC);
```

---

## 🚀 快速开始

### 1. 配置环境变量
在 `.env` 文件中添加 Upstash Redis 和 Supabase 配置

### 2. 启动服务器
```bash
dart run bin/main.dart
```

### 3. 测试 Redis 连接
```bash
curl -X POST http://localhost:8080/redisHealth/check
```

### 4. 记录用户行为
```dart
await client.actionLog.log(
  userId: 'user-123',
  action: 'login',
  description: 'User logged in',
);
```

### 5. 查看日志
等待 1 分钟后，日志会自动同步到 Supabase，可以通过 API 查询：
```dart
final actions = await client.actionLog.getUserActions('user-123');
```

---
# Redis Architecture Overview

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client                          │
│  (pavra_flutter / pavra_client)                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTP/WebSocket
                     │
┌────────────────────▼────────────────────────────────────────┐
│              Serverpod Server (Railway)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  server.dart                                         │  │
│  │  - Initialize Serverpod                             │  │
│  │  - Initialize Redis (on startup)                    │  │
│  │  - Setup routes                                     │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                       │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  Endpoints                                           │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ UserActionsEndpoint                            │ │  │
│  │  │ - logAction()                                  │ │  │
│  │  │ - getUserActions()                             │ │  │
│  │  │ - logBatchActions()                            │ │  │
│  │  │ - clearUserActions()                           │ │  │
│  │  └────────────────┬───────────────────────────────┘ │  │
│  │  ┌────────────────▼───────────────────────────────┐ │  │
│  │  │ RedisHealthEndpoint                            │ │  │
│  │  │ - check()                                      │ │  │
│  │  │ - info()                                       │ │  │
│  │  └────────────────┬───────────────────────────────┘ │  │
│  │  ┌────────────────▼───────────────────────────────┐ │  │
│  │  │ Your Custom Endpoints                          │ │  │
│  │  │ - Can use RedisService.instance               │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                       │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  RedisService (Singleton)                           │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ Connection Management                          │ │  │
│  │  │ - _connect()                                   │ │  │
│  │  │ - _ensureConnected()                           │ │  │
│  │  │ - Auto-reconnection                            │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ Action Logging                                 │ │  │
│  │  │ - addAction() → LPUSH + LTRIM                  │ │  │
│  │  │ - getActions() → LRANGE                        │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ Key-Value Operations                           │ │  │
│  │  │ - set() → SET + EXPIRE                         │ │  │
│  │  │ - get() → GET                                  │ │  │
│  │  │ - delete() → DEL                               │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────┬───────────────────────────────────┘  │
└────────────────────┼────────────────────────────────────────┘
                     │
                     │ Redis Protocol
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  Redis Server (Railway)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Data Structures                                     │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ user:{userId}:actions (LIST)                   │ │  │
│  │  │ - Most recent 100 actions per user             │ │  │
│  │  │ - Auto-trimmed with LTRIM                      │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ Custom Keys (STRING)                           │ │  │
│  │  │ - session:*, cache:*, etc.                     │ │  │
│  │  │ - Optional TTL with EXPIRE                     │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### Action Logging Flow

```
1. Flutter Client
   └─> client.userActions.logAction(userId: 123, action: 'login')
       │
2. Serverpod Endpoint
   └─> UserActionsEndpoint.logAction()
       │
3. Redis Service
   └─> RedisService.instance.addAction()
       │
       ├─> LPUSH user:123:actions "{action: 'login', timestamp: '...'}"
       │   (Add to beginning of list)
       │
       └─> LTRIM user:123:actions 0 99
           (Keep only last 100 entries)
       │
4. Redis Server
   └─> Stores in LIST data structure
```

### Action Retrieval Flow

```
1. Flutter Client
   └─> client.userActions.getUserActions(userId: 123, limit: 50)
       │
2. Serverpod Endpoint
   └─> UserActionsEndpoint.getUserActions()
       │
3. Redis Service
   └─> RedisService.instance.getActions()
       │
       └─> LRANGE user:123:actions 0 49
           (Get first 50 entries)
       │
4. Redis Server
   └─> Returns list of actions (most recent first)
       │
5. Return to Client
   └─> List<String> of action logs
```

## 🔌 Connection Management

### Initialization (Server Startup)

```
1. server.dart run()
   │
2. Serverpod initialized
   │
3. _initializeRedis(pod)
   │
   ├─> Read config from production.yaml
   │   - REDIS_HOST
   │   - REDIS_PORT
   │   - REDIS_PASSWORD
   │
   └─> RedisService.initialize()
       │
       ├─> Create connection
       │
       ├─> Authenticate (if password provided)
       │
       └─> Mark as connected
```

### Auto-Reconnection

```
1. Any Redis operation
   │
2. _ensureConnected()
   │
   ├─> Check if connected
   │
   └─> If not connected:
       └─> _connect()
           └─> Reconnect to Redis
```

## 📊 Data Structures

### Action Logs (LIST)

```
Key: user:{userId}:actions
Type: LIST
Structure:
[
  "{action: 'logout', timestamp: '2025-10-15T14:30:00Z', metadata: {...}}",
  "{action: 'view_profile', timestamp: '2025-10-15T14:25:00Z', metadata: {...}}",
  "{action: 'login', timestamp: '2025-10-15T14:20:00Z', metadata: {...}}",
  ...
]
Max Size: 100 entries (configurable)
Order: Most recent first (LPUSH adds to beginning)
```

### Cache Data (STRING)

```
Key: session:{sessionId}
Type: STRING
Value: JSON-encoded data
TTL: Optional (set with EXPIRE)
Example:
  Key: session:abc123
  Value: '{"userId": 123, "token": "..."}'
  TTL: 3600 seconds (1 hour)
```

## 🛡️ Error Handling

### Connection Failures

```
Try Operation
│
├─> Success
│   └─> Return result
│
└─> Failure
    │
    ├─> Log error
    │
    ├─> Mark as disconnected
    │
    ├─> Next operation will trigger reconnection
    │
    └─> Return gracefully (don't crash)
```

### Graceful Degradation

```
Redis Operation Fails
│
├─> Log error to Serverpod logs
│
├─> Return default value (empty list, null, false)
│
└─> Application continues normally
    (Redis failures don't break the app)
```

## 🔐 Security

### Authentication

```
1. Server reads REDIS_PASSWORD from environment
   │
2. On connection:
   └─> AUTH {password}
       │
       ├─> Success: Connection established
       │
       └─> Failure: Log error, retry
```

### Environment Variables

```
production.yaml:
  redis:
    host: ${REDIS_HOST}      # From Railway
    port: ${REDIS_PORT}      # From Railway
    password: ${REDIS_PASSWORD}  # From Railway

Railway automatically injects these at runtime
```

## 📈 Scalability

### Singleton Pattern

```
Single RedisService instance
│
├─> One connection shared across all endpoints
│
├─> Reduces connection overhead
│
└─> Thread-safe operations (Dart is single-threaded)
```

### Memory Management

```
Action Logs:
│
├─> LTRIM keeps only last 100 entries per user
│
├─> Prevents unbounded growth
│
└─> Automatic cleanup

Cache Data:
│
├─> Set TTL on cached entries
│
├─> Redis automatically expires old data
│
└─> No manual cleanup needed
```

## 🎯 Best Practices

### Key Naming Convention

```
Pattern: resource:id:attribute

Examples:
- user:123:actions
- session:abc123:data
- cache:profile:456
- rate_limit:user:123:hour:14
```

### TTL Strategy

```
Session Data: 1-24 hours
Cache Data: 5-60 minutes
Rate Limits: 1 hour
Temporary Tokens: 15 minutes
```

### Error Handling

```
Always wrap Redis operations in try-catch
Let RedisService handle reconnection
Don't let Redis failures break your app
Log errors for monitoring
```

## 🔍 Monitoring

### Health Checks

```
RedisHealthEndpoint.check()
│
├─> Connection status
├─> Write test (SET)
├─> Read test (GET)
└─> Returns health report
```

### Logging

```
Server logs show:
- Connection initialization
- Authentication status
- Operation errors
- Reconnection attempts
```

## 🚀 Performance

### Efficient Operations

```
LPUSH + LTRIM: O(1) + O(N) where N = 100
LRANGE: O(S+N) where S = start, N = count
SET: O(1)
GET: O(1)
DEL: O(1)

All operations are fast and non-blocking
```

### Connection Pooling

```
Single connection (singleton)
│
├─> No connection pool needed
│   (Dart is single-threaded)
│
└─> One connection handles all requests
    (Non-blocking async operations)
```

---

This architecture provides a robust, scalable, and maintainable Redis integration for your Serverpod backend!

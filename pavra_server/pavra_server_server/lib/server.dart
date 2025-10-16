import 'package:serverpod/serverpod.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/services/redis_service.dart';
import 'src/tasks/sync_action_logs.dart';

/// ✅ Declare all future calls here to avoid undefined reference issues.
enum FutureCallNames { birthdayReminder, actionLogSync }

/// ✅ Custom logger for dev / production modes.
class PLog {
  static bool get _isDebug => !bool.fromEnvironment('dart.vm.product');
  static final _logger = Logger('PavraServer');

  static void info(String message) {
    if (_isDebug) {
      print('ℹ️ [INFO] $message');
    } else {
      _logger.info(message);
    }
  }

  static void warn(String message) {
    if (_isDebug) {
      print('⚠️ [WARN] $message');
    } else {
      _logger.warning(message);
    }
  }

  static void error(String message, [Object? e, StackTrace? stack]) {
    if (_isDebug) {
      print('❌ [ERROR] $message');
      if (e != null) print('Exception: $e');
      if (stack != null) print(stack);
    } else {
      _logger.severe(message, e, stack);
    }
  }
}

/// ✅ Entry point of the Pavra Serverpod backend.
void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());

  // 1️⃣ Start core server (HTTP, database)
  await pod.start();

  // 2️⃣ Initialize Redis connection (Railway)
  await _initializeRedis(pod);

  // 3️⃣ Start background task: Action Log Sync
  await initializeActionLogSync(pod);

  // 4️⃣ Setup web routes
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // ✅ Final log
  PLog.info('🚀 Pavra Server started successfully!');
}

/// ✅ Redis initialization (auto-loads Railway environment variables)
Future<void> _initializeRedis(Serverpod pod) async {
  try {
    final config = pod.config;

    // Check if Redis is enabled
    if (config.redis?.enabled != true) {
      PLog.warn('Redis is disabled in configuration (check your config file).');
      return;
    }

    // Railway sets REDIS_URL in this format:
    // redis://default:<password>@<host>:<port>
    final redisUrl = Platform.environment['REDIS_URL'];
    String? redisHost = config.redis?.host;
    int redisPort = config.redis?.port ?? 6379;
    String? redisPassword = config.redis?.password;

    if (redisUrl != null && redisUrl.startsWith('redis://')) {
      final uri = Uri.parse(redisUrl);
      redisHost = uri.host;
      redisPort = uri.port;
      redisPassword = uri.userInfo.split(':').length > 1
          ? uri.userInfo.split(':')[1]
          : null;
      PLog.info('Detected Railway Redis URL -> $redisHost:$redisPort');
    }

    if (redisHost == null || redisHost.isEmpty) {
      PLog.error('Redis host not configured or missing.');
      return;
    }

    // Connect Redis
    PLog.info('🔌 Connecting to Redis at $redisHost:$redisPort...');
    await RedisService.initialize(
      host: redisHost,
      port: redisPort,
      password: redisPassword,
    );

    // ✅ Verify Redis connection
    final redis = RedisService.instance;
    const testKey = 'pavra:test:connection';
    const testValue = 'connected';

    await redis.set(testKey, testValue);
    final result = await redis.get(testKey);

    if (result == testValue) {
      PLog.info('✅ Redis connection verified (Railway OK).');
      await redis.delete(testKey);
    } else {
      PLog.warn('⚠️ Redis test read/write failed. Check Railway credentials.');
    }
  } catch (e, stack) {
    PLog.error('❌ Failed to initialize Redis.', e, stack);
  }
}

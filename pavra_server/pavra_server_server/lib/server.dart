import 'package:serverpod/serverpod.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/services/redis_service.dart';
import 'src/services/supabase_service.dart';
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
  print('🔧 Starting Pavra Server...');

  final pod = Serverpod(args, Protocol(), Endpoints());

  // 1️⃣ Start core server (HTTP, database)
  print('1️⃣ Starting Serverpod core...');
  await pod.start();
  print('✅ Serverpod core started');

  // 2️⃣ Initialize Redis connection (Railway)
  print('2️⃣ Initializing Redis...');
  await _initializeRedis(pod);

  // 3️⃣ Initialize Supabase connection
  print('3️⃣ Initializing Supabase...');
  await _initializeSupabase(pod);

  // 4️⃣ Start background task: Action Log Sync
  print('4️⃣ Initializing Action Log Sync...');
  // ⚠️ Temporarily disabled - we're using Redis → Supabase direct sync instead
  // await initializeActionLogSync(pod);
  print('⚠️ Action Log Sync disabled (using Redis queue instead)');

  // 5️⃣ Setup web routes
  print('5️⃣ Setting up web routes...');
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // ✅ Final log
  print('🚀 Pavra Server started successfully!');
  print('📡 Server listening on port ${pod.config.apiServer.port}');
  PLog.info('🚀 Pavra Server started successfully!');
}

/// ✅ Redis initialization (auto-loads Railway environment variables)
Future<void> _initializeRedis(Serverpod pod) async {
  try {
    final config = pod.config;

    // Check if Redis is enabled in config
    if (config.redis?.enabled != true) {
      PLog.warn('⚠️ Redis is disabled in configuration.');
      return;
    }

    // Get Redis configuration from config file (which loads from environment variables)
    final redisHost = config.redis?.host;
    final redisPort = config.redis?.port ?? 6379;
    final redisPassword = config.redis?.password;

    if (redisHost == null || redisHost.isEmpty) {
      PLog.error('❌ Redis host not configured. Check your .env file.');
      PLog.info(
          '   Required: REDIS_HOST, REDIS_PORT, REDIS_PASSWORD, REDIS_USER');
      return;
    }

    // Connect to Redis using our custom RedisService
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
      PLog.info('✅ Redis connection verified successfully!');
      await redis.delete(testKey);
    } else {
      PLog.warn('⚠️ Redis test read/write failed. Check credentials.');
    }
  } catch (e, stack) {
    PLog.error('❌ Failed to connect to Redis.', e, stack);
    PLog.warn('⚠️ Action logging will be disabled without Redis.');
  }
}

/// ✅ Supabase initialization
Future<void> _initializeSupabase(Serverpod pod) async {
  try {
    final supabaseUrl =
        Platform.environment['SUPABASE_URL'] ?? pod.getPassword('SUPABASE_URL');
    final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
        pod.getPassword('SUPABASE_SERVICE_ROLE_KEY');

    if (supabaseUrl == null || supabaseKey == null) {
      PLog.warn(
          '⚠️ Supabase credentials not found. Action log sync will be disabled.');
      return;
    }

    PLog.info('🔌 Connecting to Supabase...');
    await SupabaseService.initialize(
      url: supabaseUrl,
      serviceRoleKey: supabaseKey,
    );

    PLog.info('✅ Supabase initialized successfully.');
  } catch (e, stack) {
    PLog.error('❌ Failed to initialize Supabase.', e, stack);
  }
}

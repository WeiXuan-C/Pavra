import 'package:serverpod/serverpod.dart';
import 'package:logging/logging.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/services/supabase_service.dart';
import 'src/services/upstash_redis_service.dart';
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
  // 0️⃣ Load environment variables from .env file (development)
  DotEnv? dotenv;
  try {
    dotenv = DotEnv()..load();
    PLog.info('✅ Loaded .env file successfully');
  } catch (e) {
    PLog.warn('⚠️ No .env file found, using system environment variables');
  }

  final pod = Serverpod(args, Protocol(), Endpoints());

  // 1️⃣ Start core server (HTTP, database)
  await pod.start();

  // 2️⃣ Initialize Upstash Redis REST API
  await _initializeUpstashRedis(dotenv);

  // 3️⃣ Initialize Supabase connection
  await _initializeSupabase(pod, dotenv);

  // 4️⃣ Start background task: Action Log Sync
  await initializeActionLogSync(pod);

  // 5️⃣ Setup web routes
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // ✅ Final log
  PLog.info('🚀 Pavra Server started successfully!');
}

/// ✅ Upstash Redis REST API initialization
Future<void> _initializeUpstashRedis(DotEnv? dotenv) async {
  try {
    // Get Upstash REST API credentials from environment or .env file
    final restUrl = Platform.environment['UPSTASH_REDIS_REST_URL'] ??
        dotenv?['UPSTASH_REDIS_REST_URL'];
    final restToken = Platform.environment['UPSTASH_REDIS_REST_TOKEN'] ??
        dotenv?['UPSTASH_REDIS_REST_TOKEN'];

    if (restUrl == null || restToken == null) {
      PLog.warn(
          '⚠️ Upstash Redis REST API credentials not found. Action log caching will be disabled.');
      PLog.warn(
          '   Please set: UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN');
      return;
    }

    PLog.info('🔌 Initializing Upstash Redis REST API...');

    UpstashRedisService.initialize(
      restUrl: restUrl,
      restToken: restToken,
    );

    PLog.info('✅ Upstash Redis REST API initialized successfully');
  } catch (e, stack) {
    PLog.error('❌ Failed to initialize Upstash Redis REST API.', e, stack);
  }
}

/// ✅ Supabase initialization
Future<void> _initializeSupabase(Serverpod pod, DotEnv? dotenv) async {
  try {
    final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
        dotenv?['SUPABASE_URL'] ??
        pod.getPassword('SUPABASE_URL');
    final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
        dotenv?['SUPABASE_SERVICE_ROLE_KEY'] ??
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

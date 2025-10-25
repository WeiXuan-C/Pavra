import 'package:serverpod/serverpod.dart';
import 'package:logging/logging.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/services/supabase_service.dart';
import 'src/services/upstash_redis_service.dart';
import 'src/services/qstash_service.dart';
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
  // 0️⃣ Load environment variables from .env file (development only)
  DotEnv? dotenv;
  final envFile = File('.env');
  if (envFile.existsSync()) {
    try {
      dotenv = DotEnv()..load();
      PLog.info('✅ Loaded .env file successfully');
    } catch (e) {
      PLog.warn('⚠️ Failed to load .env file: $e');
    }
  } else {
    PLog.info(
        'ℹ️ No .env file found, using system environment variables (production mode)');
  }

  // 1️⃣ Initialize Upstash Redis REST API (before Serverpod)
  await _initializeUpstashRedis(dotenv);

  // 2️⃣ Initialize Supabase connection (before Serverpod)
  await _initializeSupabaseEarly(dotenv);

  final pod = Serverpod(args, Protocol(), Endpoints());

  // 3️⃣ Start core server (HTTP, database)
  await pod.start();

  // 4️⃣ Initialize OneSignal credentials
  _initializeOneSignal(pod, dotenv);

  // 5️⃣ Start background task: Action Log Sync
  await initializeActionLogSync(pod);

  // 6️⃣ Initialize QStash service
  await _initializeQStash(dotenv);

  // 7️⃣ Setup web routes
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

/// ✅ Supabase initialization (early, before Serverpod)
Future<void> _initializeSupabaseEarly(DotEnv? dotenv) async {
  try {
    final supabaseUrl =
        Platform.environment['SUPABASE_URL'] ?? dotenv?['SUPABASE_URL'];
    final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
        dotenv?['SUPABASE_SERVICE_ROLE_KEY'];

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

/// ✅ OneSignal credentials initialization
void _initializeOneSignal(Serverpod pod, DotEnv? dotenv) {
  try {
    // Try to get from passwords.yaml first, then fall back to environment variables
    var appId = pod.getPassword('oneSignalAppId');
    var apiKey = pod.getPassword('oneSignalApiKey');

    // If not in passwords.yaml, try environment variables
    if (appId == null || appId.isEmpty || appId.startsWith('\${')) {
      appId = Platform.environment['ONESIGNAL_APP_ID'] ??
          dotenv?['ONESIGNAL_APP_ID'];
    }
    if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('\${')) {
      apiKey = Platform.environment['ONESIGNAL_API_KEY'] ??
          dotenv?['ONESIGNAL_API_KEY'];
    }

    if (appId == null || apiKey == null || appId.isEmpty || apiKey.isEmpty) {
      PLog.warn(
          '⚠️ OneSignal credentials not found. Push notifications will be disabled.');
      PLog.warn('   Please set: ONESIGNAL_APP_ID and ONESIGNAL_API_KEY');
      return;
    }

    PLog.info('✅ OneSignal credentials loaded successfully');
    PLog.info('   App ID: ${appId.substring(0, 8)}...');
    PLog.info('   API Key: ${apiKey.substring(0, 10)}...');
  } catch (e, stack) {
    PLog.error('❌ Failed to initialize OneSignal credentials.', e, stack);
  }
}

/// ✅ Initialize QStash service
Future<void> _initializeQStash(DotEnv? dotenv) async {
  try {
    final qstashUrl =
        Platform.environment['QSTASH_URL'] ?? dotenv?['QSTASH_URL'];
    final qstashToken =
        Platform.environment['QSTASH_TOKEN'] ?? dotenv?['QSTASH_TOKEN'];

    if (qstashUrl == null || qstashToken == null || qstashToken.isEmpty) {
      PLog.warn(
          '⚠️ QStash credentials not found. Scheduled notifications will be disabled.');
      PLog.warn('   Please set: QSTASH_URL and QSTASH_TOKEN');
      return;
    }

    PLog.info('🔔 Initializing QStash service...');
    // QStash service is initialized via singleton pattern
    QStashService.instance;
    PLog.info('✅ QStash service initialized successfully');
    PLog.info('   URL: $qstashUrl');
    PLog.info('   Token: ${qstashToken.substring(0, 10)}...');
    PLog.info(
        '   Webhook endpoint: /qstashWebhook/processScheduledNotification');
  } catch (e, stack) {
    PLog.error('❌ Failed to initialize QStash service.', e, stack);
  }
}

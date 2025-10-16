import 'package:serverpod/serverpod.dart';
import 'package:logging/logging.dart'; // ✅ Add this line
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/services/redis_service.dart';
import 'src/tasks/sync_action_logs.dart';

/// Names of all future calls in the server.
///
/// Declaring it here ensures it's globally accessible and avoids syntax errors.
enum FutureCallNames { birthdayReminder, actionLogSync }

/// Custom logging helper that adapts to dev / production mode.
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

/// Entry point of the Serverpod backend.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize Redis connection
  await _initializeRedis(pod);

  // Initialize action log sync to Supabase
  await initializeActionLogSync(pod);

  // Setup a default page at the web root.
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  // Serve all files in the /static directory.
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // Start the server.
  await pod.start();
}

/// Initialize Redis connection using configuration from yaml files.
Future<void> _initializeRedis(Serverpod pod) async {
  try {
    final config = pod.config;

    // Check if Redis is enabled in config
    if (config.redis?.enabled != true) {
      PLog.warn('Redis is disabled in configuration.');
      return;
    }

    final redisHost = config.redis?.host;
    final redisPort = config.redis?.port ?? 6379;
    final redisPassword = config.redis?.password;

    if (redisHost == null || redisHost.isEmpty) {
      PLog.error('Redis host not configured.');
      return;
    }

    PLog.info('Connecting to Redis at $redisHost:$redisPort...');
    await RedisService.initialize(
      host: redisHost,
      port: redisPort,
      password: redisPassword,
    );
    PLog.info('✓ Redis connection established successfully.');
  } catch (e, stack) {
    PLog.error('Failed to initialize Redis.', e, stack);
    // Don't rethrow - server should continue even if Redis fails
  }
}

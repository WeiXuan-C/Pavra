import 'package:serverpod/serverpod.dart';
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/services/redis_service.dart';

/// Names of all future calls in the server.
///
/// Declaring it here ensures it's globally accessible and avoids syntax errors.
enum FutureCallNames { birthdayReminder }

void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize Redis connection
  await _initializeRedis(pod);

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

  // (Optional) Example only – comment out if not ready:
  // if (!pod.runtimeOptions.runMode.isDevelopment) {
  //   await pod.futureCallWithDelay(
  //     FutureCallNames.birthdayReminder,
  //     Duration(days: 1),
  //     {'userId': 123},
  //   );
  // }
}

/// Initialize Redis connection using configuration from yaml files.
Future<void> _initializeRedis(Serverpod pod) async {
  try {
    final config = pod.config;

    // Check if Redis is enabled in config
    if (config.redis?.enabled != true) {
      print('Redis is disabled in configuration');
      return;
    }

    final redisHost = config.redis?.host;
    final redisPort = config.redis?.port ?? 6379;
    final redisPassword = config.redis?.password;

    if (redisHost == null || redisHost.isEmpty) {
      print('ERROR: Redis host not configured');
      return;
    }

    print('Initializing Redis connection to $redisHost:$redisPort...');

    await RedisService.initialize(
      host: redisHost,
      port: redisPort,
      password: redisPassword,
    );

    print('✓ Redis initialized successfully');
  } catch (e, stackTrace) {
    print('ERROR: Failed to initialize Redis: $e');
    print(stackTrace);
    // Don't rethrow - server should continue even if Redis fails
  }
}

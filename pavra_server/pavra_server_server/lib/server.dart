import 'package:serverpod/serverpod.dart';
import 'package:pavra_server_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

/// Names of all future calls in the server.
///
/// Declaring it here ensures it's globally accessible and avoids syntax errors.
enum FutureCallNames { birthdayReminder }

void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

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

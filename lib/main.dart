import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import 'core/supabase/supabase_client.dart';
import 'core/services/onesignal_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'presentation/notification_screen/notification_provider.dart';
import 'core/middleware/route_guard.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure timeago with short format
  timeago.setLocaleMessages('en', timeago.EnShortMessages());
  timeago.setLocaleMessages('zh', timeago.ZhMessages());

  // 🚨 CRITICAL: Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Show initialization error and prevent app from starting
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red[900],
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Environment Configuration Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load .env file: ${e.toString()}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // Stop execution
  }

  // 🚨 CRITICAL: Initialize Supabase - DO NOT REMOVE
  try {
    await SupabaseService.initialize();
  } catch (e) {
    // Show initialization error and prevent app from starting
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red[900],
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // Stop execution
  }

  // 🔔 Initialize OneSignal for push notifications
  try {
    await OneSignalService().initialize();
  } catch (e) {
    debugPrint('⚠️ OneSignal initialization failed: $e');
    // Don't block app startup if OneSignal fails
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 🚨 CRITICAL: Run app AFTER all initialization is complete
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider2<
          LocaleProvider,
          ThemeProvider,
          AuthProvider
        >(
          create: (context) {
            final authProvider = AuthProvider();
            final localeProvider = context.read<LocaleProvider>();
            final themeProvider = context.read<ThemeProvider>();
            authProvider.setProviders(
              localeProvider: localeProvider,
              themeProvider: themeProvider,
            );
            return authProvider;
          },
          update: (context, localeProvider, themeProvider, authProvider) {
            authProvider?.setProviders(
              localeProvider: localeProvider,
              themeProvider: themeProvider,
            );
            return authProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, LocaleProvider, ThemeProvider>(
      builder: (context, authProvider, localeProvider, themeProvider, child) {
        return Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(
              title: 'pavra',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              // Localization support
              locale: localeProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('zh')],
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              routes: AppRouter.routes,
              // Use RouteGuard for authentication-based routing
              home: const RouteGuard(),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../presentation/authentication_screen/authentication_screen.dart';
import '../../presentation/home_screen/home_screen.dart';

/// Route Guard Middleware
/// Manages authentication-based routing and displays appropriate screens
/// based on the current authentication state
class RouteGuard extends StatelessWidget {
  const RouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 1️⃣ Initializing State - Show splash screen (app startup only)
        if (authProvider.isInitializing) {
          return const _SplashScreen();
        }

        // 2️⃣ Not Authenticated - Show login screen
        if (!authProvider.isAuthenticated) {
          return const AuthenticationScreen();
        }

        // 3️⃣ Authenticated - Show home screen
        return const HomeScreen();
      },
    );
  }
}

/// Splash Screen
/// Displayed while authentication state is being initialized
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon
            Icon(
              Icons.security_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Pavra',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

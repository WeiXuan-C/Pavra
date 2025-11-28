import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../presentation/authentication_screen/authentication_screen.dart';
import '../../presentation/home_screen/home_screen.dart';
import '../../presentation/onboarding_screen/onboarding_screen.dart';

/// Route Guard Middleware
/// Manages authentication-based routing and displays appropriate screens
/// based on the current authentication state
class RouteGuard extends StatefulWidget {
  const RouteGuard({super.key});

  @override
  State<RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 1️⃣ Initializing State - Show splash screen (app startup only)
        if (authProvider.isInitializing || _hasCompletedOnboarding == null) {
          return const _SplashScreen();
        }

        // 2️⃣ Not Authenticated - Show login screen
        if (!authProvider.isAuthenticated) {
          return const AuthenticationScreen();
        }

        // 3️⃣ Authenticated but first time user - Show onboarding
        if (!_hasCompletedOnboarding!) {
          return const OnboardingScreen();
        }

        // 4️⃣ Authenticated and onboarding completed - Show home screen
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

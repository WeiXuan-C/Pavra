import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Home Screen
/// Main dashboard shown after successful authentication
/// This screen is wrapped by MainLayout which provides the navigation bar
class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Home screen is now wrapped by MainLayout
    return const MainLayout(initialIndex: 0);
  }
}

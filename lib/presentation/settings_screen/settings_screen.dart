import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../data/repositories/user_repository.dart';
import '../layouts/header_layout.dart';
import 'widgets/theme_settings_card.dart';
import 'widgets/notification_settings_card.dart';
import 'widgets/app_info_card.dart';

/// Settings Screen
/// Shared settings screen for app preferences
/// Used by both profile screen and safety alerts screen
class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: HeaderLayout(title: l10n.home_settings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Theme Settings
            ThemeSettingsCard(userRepository: _userRepository),
            const SizedBox(height: 16),

            // Notification Settings
            const NotificationSettingsCard(),
            const SizedBox(height: 16),

            // App Info & Authority Request
            AppInfoCard(
              userRepository: _userRepository,
            ),
            const SizedBox(height: 16),

            // Help & Support Section
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('Help & FAQ'),
                    subtitle: Text('Get help and find answers'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/help');
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text('About Pavra'),
                    subtitle: Text('App info and version'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../layouts/header_layout.dart';

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
  // Notification settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(title: l10n.home_settings),
      body: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Theme Settings Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.home_appearance,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Theme Mode
                        Row(
                          children: [
                            Icon(
                              Icons.brightness_6_outlined,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.home_themeMode,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            DropdownButton<ThemeMode>(
                              value: themeProvider.themeMode,
                              underline: const SizedBox(),
                              onChanged: (ThemeMode? mode) {
                                if (mode != null) {
                                  themeProvider.setThemeMode(mode);
                                }
                              },
                              items: [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(l10n.home_themeSystem),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text(l10n.home_themeLight),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text(l10n.home_themeDark),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        // Language
                        Row(
                          children: [
                            Icon(
                              Icons.language_outlined,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.home_language,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            DropdownButton<Locale>(
                              value: localeProvider.locale,
                              underline: const SizedBox(),
                              onChanged: (Locale? locale) {
                                if (locale != null) {
                                  localeProvider.setLocale(locale);
                                }
                              },
                              items: [
                                DropdownMenuItem(
                                  value: const Locale('en'),
                                  child: Text(l10n.language_english),
                                ),
                                DropdownMenuItem(
                                  value: const Locale('zh'),
                                  child: Text(l10n.language_chinese),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notification Settings Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settings_notifications,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Push Notifications
                        SwitchListTile(
                          title: Text(l10n.settings_pushNotifications),
                          subtitle: Text(l10n.settings_pushNotificationsDesc),
                          value: _pushNotificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _pushNotificationsEnabled = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),

                        const Divider(height: 8),

                        // Alert Type Notifications
                        const SizedBox(height: 8),

                        // Sound
                        SwitchListTile(
                          title: Text(l10n.settings_sound),
                          subtitle: Text(l10n.settings_soundDesc),
                          value: _soundEnabled,
                          onChanged: _pushNotificationsEnabled
                              ? (value) {
                                  setState(() {
                                    _soundEnabled = value;
                                  });
                                }
                              : null,
                          contentPadding: EdgeInsets.zero,
                        ),

                        // Vibration
                        SwitchListTile(
                          title: Text(l10n.settings_vibration),
                          subtitle: Text(l10n.settings_vibrationDesc),
                          value: _vibrationEnabled,
                          onChanged: _pushNotificationsEnabled
                              ? (value) {
                                  setState(() {
                                    _vibrationEnabled = value;
                                  });
                                }
                              : null,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

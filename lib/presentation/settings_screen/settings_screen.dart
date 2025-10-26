import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/repositories/user_repository.dart';
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

  // Developer mode
  static const String _appVersion = '1.0.0';
  static const String _accessCode = '052005';
  int _versionTapCount = 0;
  DateTime? _lastTapTime;

  // User repository
  final _userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(title: l10n.home_settings),
      body: Consumer3<LocaleProvider, ThemeProvider, AuthProvider>(
        builder: (context, localeProvider, themeProvider, authProvider, child) {
          final userRole = authProvider.userProfile?.role ?? 'user';
          final isDeveloper = userRole == 'developer';
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
                              onChanged: (ThemeMode? mode) async {
                                if (mode != null) {
                                  themeProvider.setThemeMode(mode);
                                  // Update theme mode in database
                                  await _updateThemeMode(authProvider, mode);
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
                              onChanged: (Locale? locale) async {
                                if (locale != null) {
                                  localeProvider.setLocale(locale);
                                  // Update language in database
                                  await _updateLanguage(
                                    authProvider,
                                    locale.languageCode,
                                  );
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

                const SizedBox(height: 16),

                // App Info Card
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
                          l10n.settings_appInformation,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Version with tap detector (no visual effect)
                        GestureDetector(
                          onTap: () => _handleVersionTap(
                            context,
                            authProvider,
                            userRole,
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.settings_version,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _appVersion,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  // Show exit developer mode button if user is developer
                                  if (isDeveloper) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _exitDeveloperMode(
                                        context,
                                        authProvider,
                                      ),
                                      icon: const Icon(
                                        Icons.exit_to_app,
                                        size: 20,
                                      ),
                                      color: Colors.orange,
                                      tooltip: l10n.settings_exitDeveloperMode,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Request Authority Button (only for regular users)
                        if (userRole == 'user') ...[
                          const Divider(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _requestAuthority(context),
                              icon: const Icon(Icons.admin_panel_settings),
                              label: Text(l10n.settings_requestAuthority),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  /// Handle version tap for developer mode activation
  void _handleVersionTap(
    BuildContext context,
    AuthProvider authProvider,
    String userRole,
  ) {
    final now = DateTime.now();

    // Reset counter if more than 7 seconds have passed
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 7) {
      _versionTapCount = 0;
    }

    _lastTapTime = now;
    _versionTapCount++;

    // Show developer mode dialog after 7 taps
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _lastTapTime = null;

      // If authority, show warning first
      if (userRole == 'authority') {
        _showAuthorityWarning(context, authProvider);
      } else {
        _showAccessCodeDialog(context, authProvider);
      }
    }
  }

  /// Show warning dialog for authority users
  Future<void> _showAuthorityWarning(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_authorityWarning),
        content: Text(l10n.settings_authorityWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      _showAccessCodeDialog(context, authProvider);
    }
  }

  /// Show access code dialog
  Future<void> _showAccessCodeDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_enterAccessCode),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: l10n.settings_accessCodeHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == _accessCode) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settings_accessCodeIncorrect)),
                );
              }
            },
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await _enableDeveloperMode(context, authProvider);
    }
  }

  /// Update theme mode in database
  Future<void> _updateThemeMode(
    AuthProvider authProvider,
    ThemeMode mode,
  ) async {
    try {
      final userId = authProvider.user?.id;
      if (userId == null) return;

      String themeModeString;
      switch (mode) {
        case ThemeMode.light:
          themeModeString = 'light';
        case ThemeMode.dark:
          themeModeString = 'dark';
        case ThemeMode.system:
          themeModeString = 'system';
      }

      await _userRepository.updateProfile(
        userId: userId,
        themeMode: themeModeString,
      );

      // Reload user profile
      await authProvider.reloadUserProfile();
    } catch (e) {
      // Silently fail - user can still use the app
      debugPrint('Error updating theme mode: $e');
    }
  }

  /// Update language in database
  Future<void> _updateLanguage(
    AuthProvider authProvider,
    String languageCode,
  ) async {
    try {
      final userId = authProvider.user?.id;
      if (userId == null) return;

      await _userRepository.updateProfile(
        userId: userId,
        language: languageCode,
      );

      // Reload user profile
      await authProvider.reloadUserProfile();
    } catch (e) {
      // Silently fail - user can still use the app
      debugPrint('Error updating language: $e');
    }
  }

  /// Enable developer mode
  Future<void> _enableDeveloperMode(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);

    try {
      final userId = authProvider.user?.id;
      if (userId == null) return;

      // Update user role to developer using repository
      await _userRepository.updateProfile(userId: userId, role: 'developer');

      // Reload user profile
      await authProvider.reloadUserProfile();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settings_developerModeEnabled)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Exit developer mode
  Future<void> _exitDeveloperMode(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_exitDeveloperMode),
        content: Text(l10n.settings_exitDeveloperModeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final userId = authProvider.user?.id;
        if (userId == null) return;

        // Update user role back to user using repository
        await _userRepository.updateProfile(userId: userId, role: 'user');

        // Reload user profile
        await authProvider.reloadUserProfile();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settings_developerModeDisabled)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  /// Request authority role
  Future<void> _requestAuthority(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_requestAuthority),
        content: Text(l10n.settings_requestAuthorityConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.common_submit),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Implement backend request submission
      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settings_requestAuthorityMessage)),
      );
    }
  }
}

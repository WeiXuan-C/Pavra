import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/repositories/user_repository.dart';

/// Theme Settings Card
/// Handles theme mode and language settings
class ThemeSettingsCard extends StatelessWidget {
  final UserRepository userRepository;

  const ThemeSettingsCard({super.key, required this.userRepository});

  Future<void> _updateThemeMode(
    BuildContext context,
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

      await userRepository.updateProfile(
        userId: userId,
        themeMode: themeModeString,
      );

      await authProvider.reloadUserProfile();
    } catch (e) {
      debugPrint('Error updating theme mode: $e');
    }
  }

  Future<void> _updateLanguage(
    BuildContext context,
    AuthProvider authProvider,
    String languageCode,
  ) async {
    try {
      final userId = authProvider.user?.id;
      if (userId == null) return;

      await userRepository.updateProfile(
        userId: userId,
        language: languageCode,
      );

      await authProvider.reloadUserProfile();
    } catch (e) {
      debugPrint('Error updating language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer3<LocaleProvider, ThemeProvider, AuthProvider>(
          builder: (context, localeProvider, themeProvider, authProvider, _) {
            return Column(
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
                          await _updateThemeMode(context, authProvider, mode);
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
                          await _updateLanguage(
                            context,
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
            );
          },
        ),
      ),
    );
  }
}

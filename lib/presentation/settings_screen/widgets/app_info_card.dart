import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/repositories/user_repository.dart';

/// App Info Card
/// Displays app version, developer mode, and authority request
class AppInfoCard extends StatefulWidget {
  final UserRepository userRepository;

  const AppInfoCard({
    super.key,
    required this.userRepository,
  });

  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> {
  static const String _appVersion = '1.0.0';
  static const String _accessCode = '052005';
  int _versionTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
  }

  void _handleVersionTap(BuildContext context, String userRole) {
    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 7) {
      _versionTapCount = 0;
    }

    _lastTapTime = now;
    _versionTapCount++;

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _lastTapTime = null;

      if (userRole == 'authority') {
        _showAuthorityWarning(context);
      } else {
        _showAccessCodeDialog(context);
      }
    }
  }

  Future<void> _showAuthorityWarning(BuildContext context) async {
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
      _showAccessCodeDialog(context);
    }
  }

  Future<void> _showAccessCodeDialog(BuildContext context) async {
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
      await _enableDeveloperMode(context);
    }
  }

  Future<void> _enableDeveloperMode(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      final userId = authProvider.user?.id;
      if (userId == null) return;

      await widget.userRepository.updateProfile(
        userId: userId,
        role: 'developer',
      );

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

  Future<void> _exitDeveloperMode(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();

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

        await widget.userRepository.updateProfile(userId: userId, role: 'user');

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userRole = authProvider.userProfile?.role ?? 'user';
        final isDeveloper = userRole == 'developer';

        return Card(
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

                // Version with tap detector
                GestureDetector(
                  onTap: () => _handleVersionTap(context, userRole),
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
                          if (isDeveloper) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _exitDeveloperMode(context),
                              icon: const Icon(Icons.exit_to_app, size: 20),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

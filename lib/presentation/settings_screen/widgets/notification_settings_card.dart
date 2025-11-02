import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Notification Settings Card
/// Handles notification preferences
class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
}

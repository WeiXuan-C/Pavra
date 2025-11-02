import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Request Status Card
/// Displays the current status of authority request
class RequestStatusCard extends StatelessWidget {
  final String status;

  const RequestStatusCard({super.key, required this.status});

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.settings_statusPending;
      case 'approved':
        return l10n.settings_statusApproved;
      case 'rejected':
        return l10n.settings_statusRejected;
      default:
        return status;
    }
  }

  String _getStatusDescription(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.settings_statusPendingDesc;
      case 'approved':
        return l10n.settings_statusApprovedDesc;
      case 'rejected':
        return l10n.settings_statusRejectedDesc;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(theme, status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(theme, status), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(theme, status),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(l10n, status),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _getStatusColor(theme, status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(l10n, status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

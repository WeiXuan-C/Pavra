import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/notification_model.dart';
import '../../../l10n/app_localizations.dart';

/// Widget for displaying a single notification item
class NotificationItemWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canDelete;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    final child = InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _getTypeColor(notification.type),
                width: 4,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Time and type
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(notification.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              notification.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(context, notification.type),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getTypeColor(notification.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit button
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: AppLocalizations.of(context).notification_edit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      );

    // Only wrap with Dismissible if user can delete
    if (canDelete && onDelete != null) {
      return Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          final l10n = AppLocalizations.of(context);
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.notification_delete),
              content: Text(l10n.notification_deleteConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.common_cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.common_delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) => onDelete!(),
        child: child,
      );
    }

    return child;
  }

  /// Get icon based on notification type
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'alert':
        return Icons.error;
      case 'system':
        return Icons.settings;
      case 'user':
        return Icons.person;
      case 'report':
        return Icons.report;
      case 'location_alert':
        return Icons.location_on;
      case 'submission_status':
        return Icons.assignment;
      case 'promotion':
        return Icons.campaign;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  /// Get color based on notification type
  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'alert':
        return Colors.red;
      case 'system':
        return Colors.grey;
      case 'user':
        return Colors.blue;
      case 'report':
        return Colors.deepOrange;
      case 'location_alert':
        return Colors.pink;
      case 'submission_status':
        return Colors.cyan;
      case 'promotion':
        return Colors.purple;
      case 'reminder':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  /// Get label based on notification type
  String _getTypeLabel(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case 'success':
        return l10n.notification_typeSuccess;
      case 'warning':
        return l10n.notification_typeWarning;
      case 'alert':
        return l10n.notification_typeAlert;
      case 'system':
        return l10n.notification_typeSystem;
      case 'user':
        return l10n.notification_typeUser;
      case 'report':
        return l10n.notification_typeReport;
      case 'location_alert':
        return l10n.notification_typeLocation;
      case 'submission_status':
        return l10n.notification_typeStatus;
      case 'promotion':
        return l10n.notification_typePromotion;
      case 'reminder':
        return l10n.notification_typeReminder;
      default:
        return l10n.notification_typeInfo;
    }
  }
}

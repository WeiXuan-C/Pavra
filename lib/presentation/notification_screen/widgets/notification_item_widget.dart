import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/notification_model.dart';

/// Widget for displaying a single notification item
class NotificationItemWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

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
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete notification'),
            content: const Text(
              'Are you sure you want to delete this notification?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? theme.colorScheme.primaryContainer.withOpacity(0.1)
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
                  color: _getTypeColor(notification.type).withOpacity(0.1),
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
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type),
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
            ],
          ),
        ),
      ),
    );
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
  String _getTypeLabel(String type) {
    switch (type) {
      case 'success':
        return 'Success';
      case 'warning':
        return 'Warning';
      case 'alert':
        return 'Alert';
      case 'system':
        return 'System';
      case 'user':
        return 'User';
      case 'report':
        return 'Report';
      case 'location_alert':
        return 'Location';
      case 'submission_status':
        return 'Status';
      case 'promotion':
        return 'Promotion';
      case 'reminder':
        return 'Reminder';
      default:
        return 'Info';
    }
  }
}

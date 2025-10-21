import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/auth_provider.dart';
import 'notification_provider.dart';
import 'widgets/notification_item_widget.dart';

/// Notification screen displaying user notifications
///
/// Features:
/// - List of notifications with read/unread status
/// - Mark as read functionality
/// - Delete notifications
/// - Pull to refresh
/// - Empty state
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId != null) {
      context.read<NotificationProvider>().loadNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read button
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                  onPressed: () async {
                    if (userId != null) {
                      await provider.markAllAsRead(userId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Delete all button
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_all' && userId != null) {
                final confirmed = await _showDeleteAllDialog();
                if (confirmed == true && mounted) {
                  await context
                      .read<NotificationProvider>()
                      .deleteAllNotifications(userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          // Loading state
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadNotifications,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you receive them',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Notification list
          return RefreshIndicator(
            onRefresh: () async {
              if (userId != null) {
                await provider.refresh(userId);
              }
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return NotificationItemWidget(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDelete: () => _handleDelete(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if unread
    if (!notification.isRead) {
      await context.read<NotificationProvider>().markAsRead(notification.id);
    }

    // TODO: Navigate based on notification type and data
    // Example:
    // if (notification.type == 'report' && notification.data?['report_id'] != null) {
    //   Navigator.pushNamed(context, '/report/${notification.data!['report_id']}');
    // }
  }

  /// Handle notification delete
  Future<void> _handleDelete(String notificationId) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true && mounted) {
      await context.read<NotificationProvider>().deleteNotification(
        notificationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
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
  }

  /// Show delete all confirmation dialog
  Future<bool?> _showDeleteAllDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
  }
}

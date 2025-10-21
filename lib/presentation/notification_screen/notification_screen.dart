import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'notification_form_screen.dart';
import 'notification_provider.dart';
import 'widgets/notification_item_widget.dart';
import 'widgets/notification_skeleton.dart';

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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notification_title),
        actions: [
          // Mark all as read button
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: l10n.notification_markAllAsRead,
                  onPressed: () async {
                    if (userId != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      final localizations = AppLocalizations.of(context);
                      await provider.markAllAsRead(userId);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.notification_allMarkedAsRead,
                            ),
                            duration: const Duration(seconds: 2),
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
          // Create notification button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.notification_create,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationFormScreen(),
                ),
              );
            },
          ),
          // Delete all button
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_all' && userId != null) {
                // Capture context values before any async operation
                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                final localizations = AppLocalizations.of(context);
                final provider = context.read<NotificationProvider>();

                final confirmed = await _showDeleteAllDialog();
                if (confirmed == true && mounted) {
                  await provider.deleteAllNotifications(userId);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(localizations.notification_allDeleted),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.notification_deleteAll),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          // Loading state with skeleton
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const NotificationSkeleton();
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
                    l10n.notification_errorLoading,
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
                    label: Text(l10n.common_retry),
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
                    l10n.notification_empty,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.notification_emptyMessage,
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
                  onEdit: () => _handleEdit(notification),
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
  }

  /// Handle notification edit
  void _handleEdit(NotificationModel notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationFormScreen(notification: notification),
      ),
    );
  }

  /// Handle notification delete
  Future<void> _handleDelete(String notificationId) async {
    // Capture context values before any async operation
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);
    final provider = context.read<NotificationProvider>();

    final confirmed = await _showDeleteDialog();
    if (confirmed == true && mounted) {
      await provider.deleteNotification(notificationId);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(localizations.notification_deleted),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteDialog() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
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
  }

  /// Show delete all confirmation dialog
  Future<bool?> _showDeleteAllDialog() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notification_deleteAllTitle),
        content: Text(l10n.notification_deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.notification_deleteAll),
          ),
        ],
      ),
    );
  }
}

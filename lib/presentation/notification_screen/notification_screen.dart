import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import 'notification_form_screen.dart';
import 'notification_provider.dart';
import 'widgets/notification_item_widget.dart';
import 'widgets/notification_skeleton.dart';

/// Notification filter type
enum NotificationFilter {
  all, // All notifications
  unread, // Unread notifications (user/authority/developer)
  read, // Read notifications (user/authority/developer)
  sentByMe, // Sent by me (authority/developer)
  sentToMe, // Sent to me (authority/developer)
  allUsers, // All users' notifications (developer only)
}

/// Notification screen displaying user notifications
///
/// Features:
/// - List of notifications with read/unread status
/// - Filter notifications (all, unread, read)
/// - Mark as read functionality
/// - Delete notifications (with permission check)
/// - Pull to refresh
/// - Empty state
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Set<NotificationFilter> _selectedFilters = {NotificationFilter.all};

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
    final userRole = authProvider.userProfile?.role;

    if (userId != null) {
      context.read<NotificationProvider>().loadNotifications(
        userId,
        userRole: userRole,
      );
    }
  }

  /// Check if user can delete a notification
  bool _canDeleteNotification(NotificationModel notification) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final userRole = authProvider.userProfile?.role.toLowerCase();

    // Only developer or authority can delete
    if (userRole != 'developer' && userRole != 'authority') {
      return false;
    }

    // Must be the creator
    if (notification.createdBy != currentUserId) {
      return false;
    }

    // Check if notification is not expired (sent within last 30 days)
    final now = DateTime.now();
    final sentAt = notification.sentAt ?? notification.createdAt;
    final daysSinceSent = now.difference(sentAt).inDays;

    return daysSinceSent <= 30;
  }

  /// Get available filters based on user role
  List<NotificationFilter> _getAvailableFilters(String? userRole) {
    final role = userRole?.toLowerCase();

    if (role == 'developer') {
      return [
        NotificationFilter.all,
        NotificationFilter.unread,
        NotificationFilter.read,
        NotificationFilter.sentByMe,
        NotificationFilter.sentToMe,
        NotificationFilter.allUsers,
      ];
    } else if (role == 'authority') {
      return [
        NotificationFilter.all,
        NotificationFilter.unread,
        NotificationFilter.read,
        NotificationFilter.sentByMe,
        NotificationFilter.sentToMe,
      ];
    } else {
      // user role
      return [
        NotificationFilter.all,
        NotificationFilter.unread,
        NotificationFilter.read,
      ];
    }
  }

  /// Get filter label
  String _getFilterLabel(NotificationFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case NotificationFilter.all:
        return l10n.notification_filterAll;
      case NotificationFilter.unread:
        return l10n.notification_filterUnread;
      case NotificationFilter.read:
        return l10n.notification_filterRead;
      case NotificationFilter.sentByMe:
        return l10n.notification_filterSentByMe;
      case NotificationFilter.sentToMe:
        return l10n.notification_filterSentToMe;
      case NotificationFilter.allUsers:
        return l10n.notification_filterAllUsers;
    }
  }

  /// Check if notification matches a specific filter
  bool _matchesFilter(
    NotificationModel notification,
    NotificationFilter filter,
    String? currentUserId,
  ) {
    switch (filter) {
      case NotificationFilter.unread:
        return !notification.isRead;
      case NotificationFilter.read:
        return notification.isRead;
      case NotificationFilter.sentByMe:
        return notification.createdBy == currentUserId;
      case NotificationFilter.sentToMe:
        return notification.targetUserIds?.contains(currentUserId) ?? false;
      case NotificationFilter.allUsers:
        return true;
      case NotificationFilter.all:
        return true;
    }
  }

  /// Filter notifications based on selected filters
  List<NotificationModel> _getFilteredNotifications(
    List<NotificationModel> notifications,
    String? currentUserId,
  ) {
    // If "all" is selected or no filters, show all
    if (_selectedFilters.contains(NotificationFilter.all) ||
        _selectedFilters.isEmpty) {
      return notifications;
    }

    // Apply all selected filters (OR logic)
    return notifications.where((notification) {
      return _selectedFilters.any(
        (filter) => _matchesFilter(notification, filter, currentUserId),
      );
    }).toList();
  }

  /// Toggle filter selection
  void _toggleFilter(NotificationFilter filter) {
    setState(() {
      if (filter == NotificationFilter.all) {
        // If "all" is selected, clear other filters
        _selectedFilters = {NotificationFilter.all};
      } else {
        // Remove "all" if selecting specific filter
        _selectedFilters.remove(NotificationFilter.all);

        // Toggle the filter
        if (_selectedFilters.contains(filter)) {
          _selectedFilters.remove(filter);
          // If no filters left, default to "all"
          if (_selectedFilters.isEmpty) {
            _selectedFilters.add(NotificationFilter.all);
          }
        } else {
          _selectedFilters.add(filter);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.id;
    final userRole = authProvider.userProfile?.role.toLowerCase();
    final l10n = AppLocalizations.of(context);

    // Check if user can create notifications
    final canCreateNotifications =
        userRole == 'developer' || userRole == 'authority';

    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.notification_title,
        centerTitle: false,
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
          // Create notification button (only for developer/authority)
          if (canCreateNotifications)
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

          // Get filtered notifications
          final filteredNotifications = _getFilteredNotifications(
            provider.notifications,
            userId,
          );

          // Notification list with filter button
          return Column(
            children: [
              // Filter chips - horizontal scrollable
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _getAvailableFilters(userRole).map((filter) {
                    final isSelected = _selectedFilters.contains(filter);
                    final count = provider.notifications
                        .where((n) => _matchesFilter(n, filter, userId))
                        .length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleFilter(filter),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected &&
                                    filter != NotificationFilter.all)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                Text(
                                  _getFilterLabel(filter, l10n),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Active filters summary
              if (_selectedFilters.length > 1 ||
                  !_selectedFilters.contains(NotificationFilter.all))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_selectedFilters.length} ${_selectedFilters.length == 1 ? l10n.notification_filterActive : l10n.notification_filtersActive} • ${filteredNotifications.length} ${l10n.notification_results}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedFilters = {NotificationFilter.all};
                          });
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: Text(
                          l10n.notification_clearFilter,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              // Notification list
              Expanded(
                child: filteredNotifications.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () async {
                          if (userId != null) {
                            await provider.refresh(userId, userRole: userRole);
                          }
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 80,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedFilters.contains(
                                          NotificationFilter.all,
                                        )
                                        ? l10n.notification_empty
                                        : l10n.notification_filterEmpty,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                    ),
                                    child: Text(
                                      _selectedFilters.contains(
                                            NotificationFilter.all,
                                          )
                                          ? l10n.notification_emptyMessage
                                          : l10n.notification_filterEmptyMessage,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (!_selectedFilters.contains(
                                    NotificationFilter.all,
                                  ))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedFilters = {
                                              NotificationFilter.all,
                                            };
                                          });
                                        },
                                        icon: const Icon(Icons.clear_all),
                                        label: Text(
                                          l10n.notification_clearFilter,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (userId != null) {
                            await provider.refresh(userId, userRole: userRole);
                          }
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            final canDelete = _canDeleteNotification(
                              notification,
                            );

                            return NotificationItemWidget(
                              notification: notification,
                              onTap: () => _handleNotificationTap(notification),
                              onEdit: canDelete
                                  ? () => _handleEdit(notification)
                                  : null,
                              onDelete: canDelete
                                  ? () => _handleDelete(notification.id)
                                  : null,
                              canDelete: canDelete,
                            );
                          },
                        ),
                      ),
              ),
            ],
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

  /// Handle notification delete (called after Dismissible confirmation)
  Future<void> _handleDelete(String notificationId) async {
    // Capture context values before any async operation
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);
    final provider = context.read<NotificationProvider>();

    // No need to show dialog here - Dismissible already confirmed
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

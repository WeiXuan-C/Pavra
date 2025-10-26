import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../l10n/app_localizations.dart';
import 'notification_provider.dart';

/// Screen for creating or editing notifications
class NotificationFormScreen extends StatefulWidget {
  final NotificationModel? notification;

  const NotificationFormScreen({super.key, this.notification});

  @override
  State<NotificationFormScreen> createState() => _NotificationFormScreenState();
}

class _NotificationFormScreenState extends State<NotificationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = NotificationRepository(); // 使用 Repository
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late TextEditingController _dataController;
  String? _selectedActionLogId;
  late String _selectedType;
  late String _selectedStatus;
  late String _selectedTargetType;
  DateTime? _scheduledDateTime;
  List<String> _selectedRoles = [];
  List<String> _selectedUserIds = [];
  bool _isSubmitting = false;
  // bool _isLoadingActionLogs = false;
  bool _isLoadingUsers = false;
  // List<Map<String, dynamic>> _actionLogs = [];
  List<Map<String, dynamic>> _users = [];

  // Search and UI state
  String _userSearchQuery = '';
  bool _isUserListExpanded = false;

  final List<String> _notificationTypes = [
    'info',
    'success',
    'warning',
    'alert',
    'system',
    'user',
    'report',
    'location_alert',
    'submission_status',
    'promotion',
    'reminder',
  ];

  final List<String> _statusOptions = ['draft', 'sent'];

  final List<String> _targetTypeOptions = ['all', 'custom'];

  final List<String> _roleOptions = ['user', 'authority', 'developer'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.notification?.title);
    _messageController = TextEditingController(
      text: widget.notification?.message,
    );
    _dataController = TextEditingController(
      text: widget.notification?.data != null
          ? _formatJsonForDisplay(widget.notification!.data!)
          : '',
    );
    _selectedActionLogId = widget.notification?.relatedAction;
    _selectedType = widget.notification?.type ?? 'info';
    _selectedStatus = widget.notification?.status ?? 'sent';
    _selectedTargetType = widget.notification?.targetType ?? 'all';
    _selectedRoles = widget.notification?.targetRoles ?? [];
    _selectedUserIds = widget.notification?.targetUserIds ?? [];
    _scheduledDateTime = widget.notification?.scheduledAt;

    // 如果是 single 或 custom，默认展开用户列表
    _isUserListExpanded =
        _selectedTargetType == 'single' || _selectedTargetType == 'custom';

    // _loadActionLogs();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      // 通过 Repository 加载用户
      final users = await _repository.getUsers();
      debugPrint('Loaded ${users.length} users from profiles table');

      setState(() {
        _users = users;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  String _formatJsonForDisplay(Map<String, dynamic> json) {
    // Format JSON for display in text field
    return json.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  Map<String, dynamic>? _parseDataInput(String input) {
    if (input.trim().isEmpty) return null;

    try {
      // Parse simple key:value format
      final Map<String, dynamic> data = {};
      final lines = input.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          data[key] = value;
        }
      }
      return data.isEmpty ? null : data;
    } catch (e) {
      return null;
    }
  }

  // Future<void> _loadActionLogs() async {
  //   setState(() {
  //     _isLoadingActionLogs = true;
  //   });

  //   try {
  //     // 通过 Repository 加载 action logs
  //     final logs = await _repository.getActionLogs(limit: 50);
  //     debugPrint('Loaded ${logs.length} action logs from action_log table');

  //     setState(() {
  //       _actionLogs = logs;
  //     });
  //   } catch (e) {
  //     debugPrint('Error loading action logs: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to load action logs: $e'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //     }
  //   } finally {
  //     setState(() {
  //       _isLoadingActionLogs = false;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.notification != null;

  // 过滤 users
  List<Map<String, dynamic>> get _filteredUsers {
    if (_userSearchQuery.isEmpty) return _users;

    final query = _userSearchQuery.toLowerCase();
    return _users.where((user) {
      final username = (user['username'] as String? ?? '').toLowerCase();
      final email = (user['email'] as String? ?? '').toLowerCase();
      final role = (user['role'] as String? ?? '').toLowerCase();

      return username.contains(query) ||
          email.contains(query) ||
          role.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.notification_edit : l10n.notification_create,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== BASIC INFORMATION =====
            _buildSectionHeader('Basic Information', Icons.info_outline),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.notification_titleLabel,
                hintText: l10n.notification_titleHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.notification_titleRequired;
                }
                if (value.length > 100) {
                  return l10n.notification_titleTooLong;
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Message field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l10n.notification_messageLabel,
                hintText: l10n.notification_messageHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.notification_messageRequired;
                }
                if (value.length > 500) {
                  return l10n.notification_messageTooLong;
                }
                return null;
              },
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 24),

            // ===== NOTIFICATION TYPE =====
            _buildSectionHeader('Notification Type', Icons.category),

            // Type dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.notification_typeLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _notificationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getTypeLabel(type, l10n)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // ===== ADDITIONAL OPTIONS =====
            _buildSectionHeader('Additional Options', Icons.settings_outlined),

            // Related action dropdown (optional) with search
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     // Dropdown with search info
            //     DropdownButtonFormField<String>(
            //       initialValue: _selectedActionLogId,
            //       decoration: InputDecoration(
            //         labelText: l10n.notification_relatedActionLabel,
            //         hintText: _actionLogs.isEmpty
            //             ? 'No action logs available'
            //             : 'Select an action log (optional)',
            //         border: const OutlineInputBorder(),
            //         prefixIcon: const Icon(Icons.link),

            //         suffixIcon: _isLoadingActionLogs
            //             ? const Padding(
            //                 padding: EdgeInsets.all(12),
            //                 child: SizedBox(
            //                   width: 20,
            //                   height: 20,
            //                   child: CircularProgressIndicator(strokeWidth: 2),
            //                 ),
            //               )
            //             : null,
            //       ),
            //       isExpanded: true,
            //       menuMaxHeight: 400,
            //       // 自定义选中项的显示（只显示 action type）
            //       selectedItemBuilder: (BuildContext context) {
            //         return [
            //           const Text('None'),
            //           ..._actionLogs.map((log) {
            //             final actionType =
            //                 log['action_type'] as String? ?? 'Unknown';
            //             return Text(
            //               actionType,
            //               overflow: TextOverflow.ellipsis,
            //               style: const TextStyle(fontSize: 14),
            //             );
            //           }),
            //         ];
            //       },
            //       items: [
            //         const DropdownMenuItem<String>(
            //           value: null,
            //           child: Text('None'),
            //         ),
            //         ..._actionLogs.map((log) {
            //           final actionType =
            //               log['action_type'] as String? ?? 'Unknown';
            //           final profiles = log['profiles'] as Map<String, dynamic>?;
            //           final username =
            //               profiles?['username'] as String? ?? 'Unknown User';
            //           final email = profiles?['email'] as String? ?? '';

            //           return DropdownMenuItem<String>(
            //             value: log['id'] as String,
            //             child: Padding(
            //               padding: const EdgeInsets.symmetric(vertical: 4),
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Text(
            //                     actionType,
            //                     style: const TextStyle(
            //                       fontWeight: FontWeight.w600,
            //                       fontSize: 13,
            //                     ),
            //                     overflow: TextOverflow.ellipsis,
            //                     maxLines: 1,
            //                   ),
            //                   const SizedBox(height: 2),
            //                   Text(
            //                     '$username${email.isNotEmpty ? " • $email" : ""}',
            //                     style: const TextStyle(
            //                       fontSize: 10,
            //                       color: Colors.grey,
            //                     ),
            //                     maxLines: 1,
            //                     overflow: TextOverflow.ellipsis,
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           );
            //         }),
            //       ],
            //       onChanged: (value) {
            //         setState(() {
            //           _selectedActionLogId = value;
            //         });
            //       },
            //     ),
            //   ],
            // ),

            // Data field (optional JSON data)
            TextFormField(
              controller: _dataController,
              decoration: InputDecoration(
                labelText: 'Additional Data (Optional)',
                hintText: 'key1: value1\nkey2: value2',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.data_object),
                alignLabelWithHint: true,
                helperText: 'Enter key-value pairs, one per line',
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 24),

            // ===== DELIVERY SETTINGS =====
            _buildSectionHeader('Delivery Settings', Icons.send_outlined),

            // Status dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Notification Status',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.schedule_send),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(status), size: 20),
                      const SizedBox(width: 8),
                      Text(_getStatusLabel(status)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Scheduled date/time picker (only show if status is scheduled)
            if (_selectedStatus == 'scheduled') ...[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _scheduledDateTime == null
                      ? 'Select Schedule Time'
                      : 'Scheduled: ${_scheduledDateTime!.toString().substring(0, 16)}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () async {
                  final currentContext = context;
                  final date = await showDatePicker(
                    context: currentContext,
                    initialDate: _scheduledDateTime ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    if (!currentContext.mounted) return;
                    final time = await showTimePicker(
                      context: currentContext,
                      initialTime: TimeOfDay.fromDateTime(
                        _scheduledDateTime ?? DateTime.now(),
                      ),
                    );
                    if (time != null) {
                      if (!currentContext.mounted) return;
                      setState(() {
                        _scheduledDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Target type dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedTargetType,
              decoration: InputDecoration(
                labelText: 'Send To',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.people),
              ),
              items: _targetTypeOptions.map((targetType) {
                return DropdownMenuItem(
                  value: targetType,
                  child: Row(
                    children: [
                      Icon(_getTargetTypeIcon(targetType), size: 20),
                      const SizedBox(width: 8),
                      Text(_getTargetTypeLabel(targetType)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTargetType = value;
                    _selectedRoles = [];
                    // 自动展开用户列表（如果是 single 或 custom）
                    _isUserListExpanded =
                        value == 'single' || value == 'custom';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Role selection (only show if target type is role)
            if (_selectedTargetType == 'role') ...[
              Text(
                'Select Roles',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roleOptions.map((role) {
                  final isSelected = _selectedRoles.contains(role);
                  final theme = Theme.of(context);
                  final primaryColor = theme.colorScheme.primary;

                  return FilterChip(
                    label: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add(role);
                        } else {
                          _selectedRoles.remove(role);
                        }
                      });
                    },
                    selectedColor: primaryColor,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : theme.colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // User selection (show for both single and custom)
            if (_selectedTargetType == 'single' ||
                _selectedTargetType == 'custom') ...[
              // Header with expand/collapse button
              InkWell(
                onTap: () {
                  setState(() {
                    _isUserListExpanded = !_isUserListExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isUserListExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTargetType == 'single'
                                ? 'Select User'
                                : 'Select Users',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (_selectedUserIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedTargetType == 'single'
                                ? '1 selected'
                                : '${_selectedUserIds.length} selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Expandable user list
              if (_isUserListExpanded) ...[
                // Search field
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Users',
                    hintText: 'Search by username, email, or role',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _userSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _userSearchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _userSearchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // User list
                if (_isLoadingUsers)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_filteredUsers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No users found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final userId = user['id'] as String;
                        final username =
                            user['username'] as String? ?? 'Unknown';
                        final email = user['email'] as String? ?? '';
                        final role = user['role'] as String? ?? 'user';
                        final isSelected = _selectedUserIds.contains(userId);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                if (_selectedTargetType == 'single') {
                                  // For single user, replace the selection
                                  _selectedUserIds = [userId];
                                } else {
                                  // For custom list, add to selection
                                  _selectedUserIds.add(userId);
                                }
                              } else {
                                _selectedUserIds.remove(userId);
                              }
                            });
                          },
                          title: Text(username),
                          subtitle: Text('$email • $role'),
                          secondary: CircleAvatar(
                            child: Text(username[0].toUpperCase()),
                          ),
                        );
                      },
                    ),
                  ),
              ],
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),

            // Preview card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notification_preview,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildPreview(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing
                          ? l10n.notification_update
                          : l10n.notification_create,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(_selectedType),
        child: Icon(_getTypeIcon(_selectedType), color: Colors.white),
      ),
      title: Text(
        _titleController.text.isEmpty
            ? 'Notification Title'
            : _titleController.text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        _messageController.text.isEmpty
            ? 'Notification message will appear here'
            : _messageController.text,
      ),
      trailing: const Icon(Icons.circle, size: 12, color: Colors.blue),
    );
  }

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

  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'success':
        return l10n.notification_type_success;
      case 'warning':
        return l10n.notification_type_warning;
      case 'alert':
        return l10n.notification_type_alert;
      case 'system':
        return l10n.notification_type_system;
      case 'user':
        return l10n.notification_type_user;
      case 'report':
        return l10n.notification_type_report;
      case 'location_alert':
        return l10n.notification_type_location_alert;
      case 'submission_status':
        return l10n.notification_type_submission_status;
      case 'promotion':
        return l10n.notification_type_promotion;
      case 'reminder':
        return l10n.notification_type_reminder;
      default:
        return l10n.notification_type_info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.drafts;
      case 'scheduled':
        return Icons.schedule;
      case 'sent':
        return Icons.send;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'scheduled':
        return 'Scheduled';
      case 'sent':
        return 'Send Now';
      default:
        return status;
    }
  }

  IconData _getTargetTypeIcon(String targetType) {
    switch (targetType) {
      case 'single':
        return Icons.person;
      case 'all':
        return Icons.groups;
      case 'role':
        return Icons.badge;
      case 'custom':
        return Icons.people_outline;
      default:
        return Icons.person;
    }
  }

  String _getTargetTypeLabel(String targetType) {
    switch (targetType) {
      case 'single':
        return 'Single User';
      case 'all':
        return 'All Users';
      case 'role':
        return 'By Role';
      case 'custom':
        return 'Custom List';
      default:
        return targetType;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture context-dependent values before async gap
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<NotificationProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final parsedData = _parseDataInput(_dataController.text);

      if (isEditing) {
        // Update existing notification（传递所有字段）
        await provider.updateNotification(
          notificationId: widget.notification!.id,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          relatedAction: _selectedActionLogId,
          data: parsedData,
          status: _selectedStatus,
          scheduledAt: _selectedStatus == 'scheduled'
              ? _scheduledDateTime
              : null,
          targetType: _selectedTargetType,
          targetRoles: _selectedRoles.isNotEmpty ? _selectedRoles : null,
          targetUserIds: _selectedUserIds.isNotEmpty ? _selectedUserIds : null,
        );
      } else {
        // Create new notification
        await provider.createNotification(
          createdBy: userId, // 记录创建者
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          status: _selectedStatus,
          scheduledAt: _selectedStatus == 'scheduled'
              ? _scheduledDateTime
              : null,
          relatedAction: _selectedActionLogId,
          data: parsedData,
          targetType: _selectedTargetType,
          targetRoles: _selectedRoles.isNotEmpty ? _selectedRoles : null,
          targetUserIds: _selectedUserIds.isNotEmpty ? _selectedUserIds : null,
        );
      }

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? l10n.notification_updateSuccess
                  : l10n.notification_createSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? l10n.notification_updateError
                  : l10n.notification_createError,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/supabase/supabase_client.dart';
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
  bool _isLoadingActionLogs = false;
  bool _isLoadingUsers = false;
  List<Map<String, dynamic>> _actionLogs = [];
  List<Map<String, dynamic>> _users = [];

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

  final List<String> _statusOptions = ['draft', 'scheduled', 'sent'];

  final List<String> _targetTypeOptions = ['single', 'all', 'role', 'custom'];

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
    _selectedStatus = 'sent'; // Default to sent for immediate notifications
    _selectedTargetType = 'single'; // Default to single user
    _loadActionLogs();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      // Load users from Supabase
      final response = await supabase
          .from('profiles')
          .select('id, username, email, role')
          .order('username', ascending: true);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
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

  Future<void> _loadActionLogs() async {
    setState(() {
      _isLoadingActionLogs = true;
    });

    try {
      // Load action logs with user information
      final response = await supabase
          .from('action_log')
          .select('''
            id, 
            action_type, 
            description, 
            created_at,
            user_id,
            profiles!action_log_user_id_fkey (
              username,
              email
            )
          ''')
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _actionLogs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Handle error silently or show a message
      debugPrint('Error loading action logs: $e');
    } finally {
      setState(() {
        _isLoadingActionLogs = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.notification != null;

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

            // Related action dropdown (optional)
            DropdownButtonFormField<String>(
              initialValue: _selectedActionLogId,
              decoration: InputDecoration(
                labelText: l10n.notification_relatedActionLabel,
                hintText: 'Select an action log (optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _isLoadingActionLogs
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._actionLogs.map((log) {
                  final actionType = log['action_type'] as String? ?? 'Unknown';
                  final description = log['description'] as String?;
                  final profiles = log['profiles'] as Map<String, dynamic>?;
                  final username =
                      profiles?['username'] as String? ?? 'Unknown User';
                  final email = profiles?['email'] as String? ?? '';

                  return DropdownMenuItem<String>(
                    value: log['id'] as String,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getActionTypeIcon(actionType),
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                actionType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$username${email.isNotEmpty ? " • $email" : ""}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedActionLogId = value;
                });
              },
            ),
            const SizedBox(height: 16),

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
                children: _roleOptions.map((role) {
                  final isSelected = _selectedRoles.contains(role);
                  return FilterChip(
                    label: Text(role.toUpperCase()),
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
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(51),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // User selection (show for both single and custom)
            if (_selectedTargetType == 'single' ||
                _selectedTargetType == 'custom') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTargetType == 'single'
                        ? 'Select User'
                        : 'Select Users',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_selectedUserIds.isNotEmpty)
                    Text(
                      _selectedTargetType == 'single'
                          ? '1 selected'
                          : '${_selectedUserIds.length} selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoadingUsers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
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
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final userId = user['id'] as String;
                      final username = user['username'] as String? ?? 'Unknown';
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

  IconData _getActionTypeIcon(String actionType) {
    final type = actionType.toLowerCase();
    if (type.contains('report')) return Icons.report;
    if (type.contains('login')) return Icons.login;
    if (type.contains('logout')) return Icons.logout;
    if (type.contains('create')) return Icons.add_circle;
    if (type.contains('update')) return Icons.edit;
    if (type.contains('delete')) return Icons.delete;
    if (type.contains('submit')) return Icons.send;
    if (type.contains('approve')) return Icons.check_circle;
    if (type.contains('reject')) return Icons.cancel;
    if (type.contains('comment')) return Icons.comment;
    if (type.contains('like')) return Icons.favorite;
    if (type.contains('share')) return Icons.share;
    if (type.contains('view')) return Icons.visibility;
    if (type.contains('download')) return Icons.download;
    if (type.contains('upload')) return Icons.upload;
    if (type.contains('achievement')) return Icons.emoji_events;
    if (type.contains('reward')) return Icons.card_giftcard;
    if (type.contains('point')) return Icons.stars;
    return Icons.history;
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
        // Update existing notification
        await provider.updateNotification(
          notificationId: widget.notification!.id,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          relatedAction: _selectedActionLogId,
          data: parsedData,
        );
      } else {
        // Create new notification
        await provider.createNotification(
          userId: userId,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          relatedAction: _selectedActionLogId,
          data: parsedData,
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

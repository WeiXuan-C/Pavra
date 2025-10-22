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
  bool _isSubmitting = false;
  bool _isLoadingActionLogs = false;
  List<Map<String, dynamic>> _actionLogs = [];

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
    _loadActionLogs();
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
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        // Load action logs from Supabase
        final response = await supabase
            .from('action_log')
            .select('id, action_type, description, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(50);

        setState(() {
          _actionLogs = List<Map<String, dynamic>>.from(response);
        });
      }
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
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

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
                  return DropdownMenuItem<String>(
                    value: log['id'] as String,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          log['action_type'] as String? ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (log['description'] != null)
                          Text(
                            log['description'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final provider = context.read<NotificationProvider>();

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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? l10n.notification_updateSuccess
                  : l10n.notification_createSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
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

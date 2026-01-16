import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/supabase/database_service.dart';
import '../../../l10n/app_localizations.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentUsername;
  final String currentUserId;
  final Function(String) onSave;

  const EditProfileDialog({
    super.key,
    required this.currentUsername,
    required this.currentUserId,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isChecking = false;
  bool _isAvailable = true;
  String? _errorMessage;
  List<String> _suggestions = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername);
    _controller.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final username = _controller.text.trim();

    setState(() {
      _hasChanges = username != widget.currentUsername;
      _errorMessage = null;
      _suggestions.clear();
    });

    // Validate format first
    if (username.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).profile_usernameEmpty;
        _isAvailable = false;
      });
      return;
    }

    // Check format: only lowercase letters, numbers, underscore, and dot
    final validFormat = RegExp(r'^[a-z0-9_.]+$');
    if (!validFormat.hasMatch(username)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).profile_usernameFormat;
        _isAvailable = false;
      });
      return;
    }

    // Check length
    if (username.length < 3) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).profile_usernameMinLength;
        _isAvailable = false;
      });
      return;
    }

    if (username.length > 20) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).profile_usernameMaxLength;
        _isAvailable = false;
      });
      return;
    }

    // If it's the same as current username, it's available
    if (username == widget.currentUsername) {
      setState(() {
        _isAvailable = true;
        _errorMessage = null;
      });
      return;
    }

    // Debounce the database check
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Checking username availability: $username');
      final isAvailable = await DatabaseService().isUsernameAvailable(username);
      debugPrint('Username $username is available: $isAvailable');

      if (!mounted) return;

      setState(() {
        _isAvailable = isAvailable;
        _isChecking = false;

        if (!isAvailable) {
          _errorMessage = AppLocalizations.of(context).profile_usernameTaken;
          _generateSuggestions(username);
        }
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error checking username availability: $e');
      setState(() {
        _isChecking = false;
        _errorMessage = AppLocalizations.of(context).profile_usernameVerifyError;
        _isAvailable = false;
      });
    }
  }

  void _generateSuggestions(String username) {
    _suggestions = [
      '${username}_${DateTime.now().year}',
      '$username.${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
      '${username}_user',
    ];
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave =
        _hasChanges && _isAvailable && !_isChecking && _errorMessage == null;

    return AlertDialog(
      title: Text(l10n.profile_editUsername),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.profile_username,
                  hintText: l10n.profile_usernameHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: _isChecking
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _hasChanges && _isAvailable && _errorMessage == null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _errorMessage != null
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                  errorText: _errorMessage,
                  errorMaxLines: 3,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profile_usernameFormatHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.profile_suggestions,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((suggestion) {
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _applySuggestion(suggestion),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        ElevatedButton(
          onPressed: canSave
              ? () {
                  widget.onSave(_controller.text.trim());
                  Navigator.pop(context);
                }
              : null,
          child: Text(l10n.profile_saveChanges),
        ),
      ],
    );
  }
}

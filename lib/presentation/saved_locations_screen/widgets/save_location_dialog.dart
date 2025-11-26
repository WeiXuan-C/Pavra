import 'package:flutter/material.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/services/saved_location_service.dart';

/// Save Location Dialog
/// Allows saving a new location with custom label and icon
/// Displays location name and address (read-only)
/// Validates label uniqueness before saving
class SaveLocationDialog extends StatefulWidget {
  final String locationName;
  final String? address;
  final double latitude;
  final double longitude;
  final SavedLocationService locationService;

  const SaveLocationDialog({
    super.key,
    required this.locationName,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.locationService,
  });

  @override
  State<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  late TextEditingController _labelController;
  String _selectedIcon = 'place';
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;
  String? _labelError;

  // Common location icons
  final List<String> _commonIcons = [
    'home',
    'work',
    'school',
    'restaurant',
    'shopping',
    'hospital',
    'gym',
    'park',
    'place',
    'star',
    'favorite',
    'bookmark',
    'location',
    'map',
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// Validate label uniqueness
  Future<bool> _validateLabel(String label) async {
    if (label.trim().isEmpty) {
      return false;
    }

    setState(() {
      _isValidating = true;
      _labelError = null;
    });

    try {
      final exists = await widget.locationService.labelExists(label.trim());
      
      setState(() {
        _isValidating = false;
        if (exists) {
          _labelError = 'A location with label "$label" already exists';
        }
      });

      return !exists;
    } catch (e) {
      setState(() {
        _isValidating = false;
        _labelError = 'Error validating label';
      });
      return false;
    }
  }

  /// Handle save button press
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final label = _labelController.text.trim();
    
    // Validate label uniqueness
    final isValid = await _validateLabel(label);
    if (!isValid) {
      return;
    }

    // Return the data to save
    if (mounted) {
      Navigator.pop(context, {
        'label': label,
        'icon': _selectedIcon,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Location'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location name (read-only)
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.locationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Address (read-only)
              if (widget.address != null && widget.address!.isNotEmpty) ...[
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    widget.address!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Label input
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Label *',
                  hintText: 'e.g., Home, Work, School',
                  border: const OutlineInputBorder(),
                  errorText: _labelError,
                  suffixIcon: _isValidating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Clear error when user types
                  if (_labelError != null) {
                    setState(() {
                      _labelError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Icon picker
              Text(
                'Icon',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Icon grid
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonIcons.map((iconName) {
                    final isSelected = _selectedIcon == iconName;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconName;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          IconMapper.getIcon(iconName),
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValidating ? null : _handleSave,
          child: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

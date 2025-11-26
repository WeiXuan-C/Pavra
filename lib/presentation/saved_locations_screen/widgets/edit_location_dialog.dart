import 'package:flutter/material.dart';
import '../../../core/utils/icon_mapper.dart';

/// Edit Location Dialog
/// Allows editing label and icon of a saved location
class EditLocationDialog extends StatefulWidget {
  final String currentLabel;
  final String currentIcon;
  final String locationId;

  const EditLocationDialog({
    super.key,
    required this.currentLabel,
    required this.currentIcon,
    required this.locationId,
  });

  @override
  State<EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends State<EditLocationDialog> {
  late TextEditingController _labelController;
  late String _selectedIcon;
  final _formKey = GlobalKey<FormState>();

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
    _labelController = TextEditingController(text: widget.currentLabel);
    _selectedIcon = widget.currentIcon;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Location'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label input
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g., Home, Work, School',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'label': _labelController.text.trim(),
                'icon': _selectedIcon,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

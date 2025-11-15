import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/saved_route_model.dart';
import '../../../l10n/app_localizations.dart';
import 'location_picker_widget.dart';

class SavedRouteFormDialog extends StatefulWidget {
  final SavedRouteModel? route; // null for create, non-null for edit

  const SavedRouteFormDialog({super.key, this.route});

  @override
  State<SavedRouteFormDialog> createState() => _SavedRouteFormDialogState();
}

class _SavedRouteFormDialogState extends State<SavedRouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _fromNameController;
  late TextEditingController _fromAddressController;
  late TextEditingController _toNameController;
  late TextEditingController _toAddressController;
  
  double? _fromLat;
  double? _fromLng;
  double? _toLat;
  double? _toLng;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.name ?? '');
    _fromNameController = TextEditingController(
      text: widget.route?.fromLocationName ?? '',
    );
    _fromAddressController = TextEditingController(
      text: widget.route?.fromAddress ?? '',
    );
    _toNameController = TextEditingController(
      text: widget.route?.toLocationName ?? '',
    );
    _toAddressController = TextEditingController(
      text: widget.route?.toAddress ?? '',
    );
    _isMonitoring = widget.route?.isMonitoring ?? false;
    
    if (widget.route != null) {
      _fromLat = widget.route!.fromLatitude;
      _fromLng = widget.route!.fromLongitude;
      _toLat = widget.route!.toLatitude;
      _toLng = widget.route!.toLongitude;
    }
  }

  Future<void> _pickLocation(bool isFrom) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPickerWidget(
        initialLocationName: isFrom
            ? _fromNameController.text
            : _toNameController.text,
        initialLatitude: isFrom ? _fromLat : _toLat,
        initialLongitude: isFrom ? _fromLng : _toLng,
        initialAddress: isFrom
            ? _fromAddressController.text
            : _toAddressController.text,
      ),
    );

    if (result != null) {
      setState(() {
        if (isFrom) {
          _fromNameController.text = result['locationName'];
          _fromLat = result['latitude'];
          _fromLng = result['longitude'];
          _fromAddressController.text = result['address'] ?? '';
        } else {
          _toNameController.text = result['locationName'];
          _toLat = result['latitude'];
          _toLng = result['longitude'];
          _toAddressController.text = result['address'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromNameController.dispose();
    _fromAddressController.dispose();
    _toNameController.dispose();
    _toAddressController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate locations are set
    if (_fromLat == null || _fromLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.savedRoute_from}: ${l10n.common_locationRequired}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_toLat == null || _toLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.savedRoute_to}: ${l10n.common_locationRequired}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = {
      'name': _nameController.text,
      'fromLocationName': _fromNameController.text,
      'fromLatitude': _fromLat!,
      'fromLongitude': _fromLng!,
      'fromAddress': _fromAddressController.text.isEmpty
          ? null
          : _fromAddressController.text,
      'toLocationName': _toNameController.text,
      'toLatitude': _toLat!,
      'toLongitude': _toLng!,
      'toAddress': _toAddressController.text.isEmpty
          ? null
          : _toAddressController.text,
      'isMonitoring': _isMonitoring,
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEdit = widget.route != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.route,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    isEdit ? l10n.savedRoute_editRoute : l10n.savedRoute_addRoute,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.savedRoute_routeName,
                          hintText: l10n.savedRoute_routeNameHint,
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.common_nameRequired;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 3.h),

                      // From Location Section
                      Row(
                        children: [
                          Text(
                            l10n.savedRoute_from,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _pickLocation(true),
                            icon: const Icon(Icons.location_searching, size: 18),
                            label: Text(l10n.savedRoute_selectLocation),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      
                      // From Location Display
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: _fromLat != null && _fromLng != null
                              ? Colors.blue.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _fromLat != null && _fromLng != null
                                ? Colors.blue.withValues(alpha: 0.3)
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trip_origin,
                                  size: 20,
                                  color: _fromLat != null && _fromLng != null
                                      ? Colors.blue
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    _fromNameController.text.isEmpty
                                        ? l10n.savedRoute_selectLocation
                                        : _fromNameController.text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: _fromNameController.text.isEmpty
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                      color: _fromNameController.text.isEmpty
                                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_fromAddressController.text.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                _fromAddressController.text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                            if (_fromLat != null && _fromLng != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                '${_fromLat!.toStringAsFixed(6)}, ${_fromLng!.toStringAsFixed(6)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.blue.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // To Location Section
                      Row(
                        children: [
                          Text(
                            l10n.savedRoute_to,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _pickLocation(false),
                            icon: const Icon(Icons.location_searching, size: 18),
                            label: Text(l10n.savedRoute_selectLocation),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      
                      // To Location Display
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: _toLat != null && _toLng != null
                              ? Colors.orange.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _toLat != null && _toLng != null
                                ? Colors.orange.withValues(alpha: 0.3)
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: _toLat != null && _toLng != null
                                      ? Colors.orange
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    _toNameController.text.isEmpty
                                        ? l10n.savedRoute_selectLocation
                                        : _toNameController.text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: _toNameController.text.isEmpty
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                      color: _toNameController.text.isEmpty
                                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_toAddressController.text.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                _toAddressController.text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                            if (_toLat != null && _toLng != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                '${_toLat!.toStringAsFixed(6)}, ${_toLng!.toStringAsFixed(6)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.orange.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Monitoring Toggle
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: _isMonitoring
                              ? Colors.green.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isMonitoring
                                ? Colors.green.withValues(alpha: 0.3)
                                : theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: _isMonitoring
                                  ? Colors.green.shade700
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.savedRoute_monitoring,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    l10n.savedRoute_monitoringDesc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isMonitoring,
                              onChanged: (value) {
                                setState(() {
                                  _isMonitoring = value;
                                });
                              },
                              activeTrackColor: Colors.green.shade300,
                              activeThumbColor: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: Text(l10n.common_save),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api/report_issue/report_issue_api.dart';
import '../../core/api/report_issue/issue_type_api.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/icon_mapper.dart';
import '../../data/models/issue_photo_model.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import './manual_report_provider.dart';
import './widgets/description_input_widget.dart';
import './widgets/location_input_widget.dart';
import './widgets/manual_report_skeleton.dart';
import './widgets/photo_gallery_widget.dart';
import './widgets/severity_slider_widget.dart';
import './widgets/submission_actions_widget.dart';

/// Manual Report Screen
/// Allows users to manually create and submit reports
/// Automatically manages draft state
class ManualReportScreen extends StatefulWidget {
  const ManualReportScreen({super.key});

  @override
  State<ManualReportScreen> createState() => _ManualReportScreenState();
}

class _ManualReportScreenState extends State<ManualReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final LocationService _locationService = LocationService();

  final List<String> _selectedIssueTypeIds = [];
  double _severity = 3.0;
  bool _isSubmitting = false;
  bool _isIssueTypeSectionExpanded = true;
  bool _isDraftLoaded = false;
  bool _isLoadingLocation = false;

  // Location data
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  String _address = '';

  @override
  void initState() {
    super.initState();
    // Get location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Get current GPS location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        // Permission denied or service disabled
        if (!mounted) return;
        await _showLocationPermissionDialog();
        return;
      }

      // Get address from coordinates
      final addressData = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _address = addressData['fullAddress'] ?? '';
        _locationController.text = _address;
        _isLoadingLocation = false;
      });

      debugPrint('=== Location updated ===');
      debugPrint('Latitude: $_latitude');
      debugPrint('Longitude: $_longitude');
      debugPrint('Accuracy: $_accuracy');
      debugPrint('Address: $_address');
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
      Fluttertoast.showToast(
        msg: 'Failed to get location: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Show location permission dialog
  Future<void> _showLocationPermissionDialog() async {
    final l10n = AppLocalizations.of(context);

    // Check if service is disabled
    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.report_locationServiceDisabled),
          content: Text(l10n.report_locationServiceDisabledMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _locationService.openLocationSettings();
              },
              child: Text(l10n.report_openSettings),
            ),
          ],
        ),
      );
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    // Check permission
    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.report_locationPermissionDenied),
          content: Text(l10n.report_locationPermissionDeniedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _locationService.openAppSettings();
              },
              child: Text(l10n.report_openSettings),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.report_locationPermissionDenied),
          content: Text(l10n.report_locationPermissionDeniedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _getCurrentLocation();
              },
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  /// Show address edit dialog
  Future<void> _showAddressEditDialog() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final TextEditingController addressController = TextEditingController(
      text: _address,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.report_editAddress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: l10n.report_address,
                hintText: l10n.report_enterAddress,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.report_addressSearchHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAddress = addressController.text.trim();
              if (newAddress.isEmpty) {
                Fluttertoast.showToast(
                  msg: l10n.report_invalidAddress,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
                return;
              }

              Navigator.pop(context);

              // Geocode the address
              setState(() {
                _isLoadingLocation = true;
              });

              try {
                final position = await _locationService
                    .getCoordinatesFromAddress(newAddress);

                if (position == null) {
                  if (!mounted) return;
                  Fluttertoast.showToast(
                    msg: l10n.report_addressNotFound,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  setState(() {
                    _isLoadingLocation = false;
                  });
                  return;
                }

                // Get formatted address from coordinates
                final addressData = await _locationService
                    .getAddressFromCoordinates(
                      position.latitude,
                      position.longitude,
                    );

                if (!mounted) return;

                setState(() {
                  _latitude = position.latitude;
                  _longitude = position.longitude;
                  _accuracy = null; // Manual address has no accuracy
                  _address = addressData['fullAddress'] ?? newAddress;
                  _locationController.text = _address;
                  _isLoadingLocation = false;
                });

                Fluttertoast.showToast(
                  msg: l10n.report_locationUpdated,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              } catch (e) {
                debugPrint('Error geocoding address: $e');
                if (!mounted) return;
                setState(() {
                  _isLoadingLocation = false;
                });
                Fluttertoast.showToast(
                  msg: '${l10n.report_addressNotFound}: $e',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );

    addressController.dispose();
  }

  /// Load draft data into form fields
  void _loadDraftData(ManualReportProvider provider) {
    final draft = provider.draftReport;
    if (draft == null) return;

    debugPrint('=== Loading draft data into form ===');
    debugPrint('Draft: ${draft.toJson()}');

    // Load description
    final description = draft.description;
    if (description != null && description.isNotEmpty) {
      _descriptionController.text = description;
      debugPrint('Loaded description: $description');
    }

    // Load address and coordinates
    final address = draft.address;
    if (address != null && address.isNotEmpty) {
      _address = address;
      _locationController.text = address;
      debugPrint('Loaded address: $address');
    }

    if (draft.latitude != null) {
      _latitude = draft.latitude;
      debugPrint('Loaded latitude: $_latitude');
    }

    if (draft.longitude != null) {
      _longitude = draft.longitude;
      debugPrint('Loaded longitude: $_longitude');
    }

    // Load issue type IDs
    if (draft.issueTypeIds.isNotEmpty) {
      _selectedIssueTypeIds.clear();
      _selectedIssueTypeIds.addAll(draft.issueTypeIds);
      debugPrint('Loaded issue types: ${draft.issueTypeIds}');
    }

    // Load severity
    _severity = _getSeverityValue(draft.severity);
    debugPrint('Loaded severity: ${draft.severity} -> $_severity');

    debugPrint('=== Draft data loaded ===');
  }

  /// Convert severity string to slider value
  double _getSeverityValue(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return 1.0;
      case 'low':
        return 2.0;
      case 'moderate':
        return 3.0;
      case 'high':
        return 4.0;
      case 'critical':
        return 5.0;
      default:
        return 3.0;
    }
  }

  bool _isFormValid(ManualReportProvider provider) {
    // Check if at least one main photo is uploaded
    final hasMainPhoto = provider.uploadedPhotos.any(
      (p) => p.photoType == 'main',
    );

    // Check if at least one issue type is selected
    final hasIssueType = _selectedIssueTypeIds.isNotEmpty;

    // Check if location is filled
    final hasLocation = _locationController.text.isNotEmpty;

    // Severity always has a default value (3.0 = moderate)

    return hasMainPhoto && hasIssueType && hasLocation;
  }

  /// Add photo from camera or gallery with source selection
  Future<void> _addPhoto(
    BuildContext context,
    ManualReportProvider provider, {
    required String photoType,
  }) async {
    final l10n = AppLocalizations.of(context);

    // Check if can add more photos
    final validationError = provider.canAddPhoto(photoType);

    if (validationError != null) {
      Fluttertoast.showToast(
        msg: validationError,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // Show bottom sheet to choose camera or gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.report_takePhoto),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.report_chooseFromGallery),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                SizedBox(height: 1.h),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 6.h),
                  ),
                  child: Text(l10n.common_cancel),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        // Read file bytes
        final file = File(image.path);
        final bytes = await file.readAsBytes();

        // Determine MIME type
        String? mimeType;
        if (image.name.toLowerCase().endsWith('.jpg') ||
            image.name.toLowerCase().endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (image.name.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (image.name.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        // Upload to storage
        final uploadedPhoto = await provider.uploadPhoto(
          fileName: image.name,
          fileBytes: bytes,
          mimeType: mimeType,
          photoType: photoType,
          isPrimary: photoType == 'main',
        );

        HapticFeedback.lightImpact();
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: l10n.report_photoAdded,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Trigger AI analysis for main photo
        if (photoType == 'main' && mounted) {
          _analyzeMainPhoto(context, provider, uploadedPhoto.photoUrl);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '${l10n.report_photoAddFailed}: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Analyze main photo with AI
  Future<void> _analyzeMainPhoto(
    BuildContext context,
    ManualReportProvider provider,
    String photoUrl,
  ) async {
    // Show analyzing toast
    Fluttertoast.showToast(
      msg: 'Analyzing image with AI...',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    try {
      final result = await provider.analyzePhotoWithAI(photoUrl);

      if (result == null || !mounted) return;

      // Show AI analysis result dialog
      _showAiAnalysisDialog(context, provider, result);
    } catch (e) {
      debugPrint('AI analysis error: $e');
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'AI analysis failed: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Show AI analysis result dialog
  void _showAiAnalysisDialog(
    BuildContext context,
    ManualReportProvider provider,
    Map<String, dynamic> analysis,
  ) {
    final theme = Theme.of(context);

    final description = analysis['description'] as String? ?? '';
    final issueTypes =
        (analysis['issueTypes'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    final severity = analysis['severity'] as String? ?? 'moderate';
    final confidence = analysis['confidence'] as String? ?? 'medium';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            const Text('AI Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(
                    confidence,
                    theme,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Confidence: ${confidence.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getConfidenceColor(confidence, theme),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Description
              Text(
                'Description:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                description.isNotEmpty
                    ? description
                    : 'No description provided',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),

              // Suggested issue types
              if (issueTypes.isNotEmpty) ...[
                Text(
                  'Suggested Issue Types:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 1.w,
                  runSpacing: 1.h,
                  children: issueTypes.map((type) {
                    return Chip(
                      label: Text(type),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 2.h),
              ],

              // Suggested severity
              Text(
                'Suggested Severity:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getSeverityColor(
                    severity,
                    theme,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSeverityIcon(severity),
                      color: _getSeverityColor(severity, theme),
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      severity.toUpperCase(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getSeverityColor(severity, theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _applyAiSuggestions(provider, analysis);
            },
            child: const Text('Apply Suggestions'),
          ),
        ],
      ),
    );
  }

  /// Apply AI suggestions to the form
  void _applyAiSuggestions(
    ManualReportProvider provider,
    Map<String, dynamic> analysis,
  ) {
    final description = analysis['description'] as String? ?? '';
    final severity = analysis['severity'] as String? ?? 'moderate';

    // Update description if empty
    if (_descriptionController.text.isEmpty && description.isNotEmpty) {
      setState(() {
        _descriptionController.text = description;
      });
    }

    // Update severity
    setState(() {
      _severity = _getSeverityValue(severity);
    });

    Fluttertoast.showToast(
      msg: 'AI suggestions applied',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  /// Get confidence color
  Color _getConfidenceColor(String confidence, ThemeData theme) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Get severity color
  Color _getSeverityColor(String severity, ThemeData theme) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return Colors.blue;
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Get severity icon
  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return Icons.info_outline;
      case 'low':
        return Icons.warning_amber_outlined;
      case 'moderate':
        return Icons.warning;
      case 'high':
        return Icons.error_outline;
      case 'critical':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }

  /// Remove photo
  Future<void> _removePhoto(
    BuildContext context,
    ManualReportProvider provider,
    IssuePhotoModel photo,
  ) async {
    try {
      await provider.deletePhoto(photo);

      HapticFeedback.lightImpact();
      if (!context.mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_photoRemoved,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      if (!context.mounted) return;
      Fluttertoast.showToast(
        msg: 'Failed to remove photo: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Toggle issue type selection
  void _toggleIssueType(String issueTypeId) {
    setState(() {
      if (_selectedIssueTypeIds.contains(issueTypeId)) {
        _selectedIssueTypeIds.remove(issueTypeId);
      } else {
        _selectedIssueTypeIds.add(issueTypeId);
      }
    });

    HapticFeedback.selectionClick();
  }

  /// Update severity
  void _updateSeverity(double value) {
    setState(() {
      _severity = value;
    });

    HapticFeedback.selectionClick();
  }

  /// Save draft
  Future<void> _saveDraft(ManualReportProvider provider) async {
    try {
      // Use actual location or default
      final latitude = _latitude ?? 3.1390;
      final longitude = _longitude ?? 101.6869;

      debugPrint('=== Saving draft ===');
      debugPrint('Description: ${_descriptionController.text}');
      debugPrint('Issue Types: $_selectedIssueTypeIds');
      debugPrint('Severity: ${_getSeverityString(_severity)}');
      debugPrint('Address: ${_locationController.text}');
      debugPrint('Latitude: $latitude');
      debugPrint('Longitude: $longitude');
      debugPrint('Draft ID: ${provider.draftReport?.id}');

      await provider.updateDraft(
        description: _descriptionController.text,
        issueTypeIds: _selectedIssueTypeIds,
        severity: _getSeverityString(_severity),
        address: _locationController.text,
        latitude: latitude,
        longitude: longitude,
      );

      debugPrint('=== Draft saved successfully ===');
      HapticFeedback.lightImpact();
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_draftSaved,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e, stackTrace) {
      debugPrint('=== Error saving draft ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Failed to save draft: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Submit report
  Future<void> _submitReport(ManualReportProvider provider) async {
    if (!_isFormValid(provider)) {
      Fluttertoast.showToast(
        msg: 'Please fill in all required fields',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Use actual location or default
      final latitude = _latitude ?? 3.1390;
      final longitude = _longitude ?? 101.6869;

      debugPrint('=== Submitting report ===');
      debugPrint('Description: ${_descriptionController.text}');
      debugPrint('Issue Types: $_selectedIssueTypeIds');
      debugPrint('Severity: ${_getSeverityString(_severity)}');
      debugPrint('Address: ${_locationController.text}');
      debugPrint('Coordinates: $latitude, $longitude');

      // Update draft with final data including coordinates
      await provider.updateDraft(
        description: _descriptionController.text.isEmpty
            ? 'No description provided'
            : _descriptionController.text,
        issueTypeIds: _selectedIssueTypeIds,
        severity: _getSeverityString(_severity),
        address: _locationController.text,
        latitude: latitude,
        longitude: longitude,
      );

      // Submit the draft (changes status from 'draft' to 'submitted')
      final reportId = provider.draftReport?.id ?? 'Unknown';
      debugPrint('Submitting draft with ID: $reportId');
      await provider.submitDraft();

      debugPrint('=== Report submitted successfully ===');
      HapticFeedback.heavyImpact();

      if (!mounted) return;
      _showSuccessDialog(reportId);
    } catch (e, stackTrace) {
      debugPrint('=== Error submitting report ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '${AppLocalizations.of(context).report_submitFailed}: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Get severity string from slider value
  String _getSeverityString(double value) {
    if (value <= 1) return 'minor';
    if (value <= 2) return 'low';
    if (value <= 3) return 'moderate';
    if (value <= 4) return 'high';
    return 'critical';
  }

  /// Show success dialog
  void _showSuccessDialog(String reportId) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.brightness == Brightness.light
                    ? const Color(0xFF388E3C)
                    : const Color(0xFF66BB6A),
                size: 28,
              ),
              SizedBox(width: 2.w),
              Text(
                l10n.report_reportSubmitted,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.report_reportSubmittedMessage,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.report_reportId}: $reportId',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      l10n.report_estimatedResponse,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/map-view-screen');
              },
              child: Text(l10n.report_viewOnMap),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(l10n.report_done),
            ),
          ],
        );
      },
    );
  }

  /// Handle back navigation
  void _handlePopInvoked(
    bool didPop,
    Object? result,
    ManualReportProvider provider,
  ) async {
    if (didPop) return;

    final hasChanges =
        _descriptionController.text.isNotEmpty ||
        _selectedIssueTypeIds.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        provider.uploadedPhotos.isNotEmpty;

    if (hasChanges) {
      final navigator = Navigator.of(context);
      final bool? shouldPop = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.report_unsavedChanges),
            content: Text(l10n.report_unsavedChangesMessage),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop(false);
                  // Discard: Update status to 'discarded'
                  try {
                    debugPrint('=== Discarding draft ===');
                    debugPrint('Draft ID: ${provider.draftReport?.id}');
                    await provider.discardDraft();
                    debugPrint('=== Draft discarded successfully ===');
                  } catch (e, stackTrace) {
                    debugPrint('=== Error discarding draft ===');
                    debugPrint('Error: $e');
                    debugPrint('Stack trace: $stackTrace');
                    // Ignore error, just navigate back
                  }
                  if (!mounted) return;
                  navigator.pop();
                },
                child: Text(l10n.report_discard),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop(false);
                  await _saveDraft(provider);
                  if (!mounted) return;
                  navigator.pop();
                },
                child: Text(l10n.report_saveDraft),
              ),
            ],
          );
        },
      );

      if (shouldPop == true && mounted) {
        navigator.pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => ManualReportProvider(
        reportApi: ReportIssueApi(Supabase.instance.client),
        issueTypeApi: IssueTypeApi(),
        supabase: Supabase.instance.client,
      )..initialize(),
      child: Consumer<ManualReportProvider>(
        builder: (context, provider, _) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) =>
              _handlePopInvoked(didPop, result, provider),
          child: Scaffold(
            appBar: HeaderLayout(title: l10n.report_manualReport),
            body: Builder(
              builder: (context) {
                final provider = context.watch<ManualReportProvider>();
                if (provider.isLoading) {
                  return const ManualReportSkeleton();
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        SizedBox(height: 2.h),
                        Text(provider.error!),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: () => provider.initialize(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Load draft data into form fields (only once)
                if (!_isDraftLoaded && provider.draftReport != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadDraftData(provider);
                    setState(() {
                      _isDraftLoaded = true;
                    });
                  });
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Draft info
                            if (provider.draftReport != null)
                              _buildDraftInfo(
                                theme,
                                provider.draftReport!.title ?? 'Draft',
                              ),

                            SizedBox(height: 3.h),

                            // 1. Main Photo (Required - Only 1)
                            _buildMainPhotoSection(
                              context,
                              theme,
                              l10n,
                              provider,
                            ),

                            SizedBox(height: 3.h),

                            // 2. Location input (Latitude, Longitude, Address)
                            _buildLocationInput(theme, l10n),

                            SizedBox(height: 3.h),

                            // 3. Issue type selector (with name, description, icon)
                            _buildIssueTypeSelector(theme, l10n, provider),

                            SizedBox(height: 3.h),

                            // 4. Severity slider
                            SeveritySliderWidget(
                              severity: _severity,
                              onSeverityChanged: _updateSeverity,
                            ),

                            SizedBox(height: 3.h),

                            // 5. Description input
                            DescriptionInputWidget(
                              controller: _descriptionController,
                              suggestions: const [],
                            ),

                            SizedBox(height: 3.h),

                            // 6. Additional Photos (Optional - Up to 5)
                            _buildAdditionalPhotosSection(
                              context,
                              theme,
                              l10n,
                              provider,
                            ),

                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),
                    ),

                    // Bottom actions
                    SubmissionActionsWidget(
                      isFormValid: _isFormValid(provider),
                      isSubmitting: _isSubmitting || provider.isUploadingPhoto,
                      uploadProgress: provider.uploadProgress,
                      onSubmit: () => _submitReport(provider),
                      onSaveDraft: () => _saveDraft(provider),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftInfo(ThemeData theme, String title) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.drafts, color: theme.colorScheme.primary, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Draft: $title',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPhotoSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ManualReportProvider provider,
  ) {
    final mainPhotos = provider.uploadedPhotos
        .where((p) => p.photoType == 'main')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Row(
          children: [
            Icon(
              Icons.photo_camera,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                '${l10n.report_photos} *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: mainPhotos.isNotEmpty
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mainPhotos.isNotEmpty ? '1/1' : '0/1',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mainPhotos.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Show upload progress
        if (provider.isUploadingPhoto && mainPhotos.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Column(
              children: [
                LinearProgressIndicator(value: provider.uploadProgress),
                SizedBox(height: 1.h),
                Text(
                  'Uploading photo...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

        // Main photo display
        if (mainPhotos.isNotEmpty)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mainPhotos.first.photoUrl,
                  width: double.infinity,
                  height: 40.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 40.h,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () =>
                      _removePhoto(context, provider, mainPhotos.first),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: 0.9,
                    ),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          )
        else
          // Add photo button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: provider.isUploadingPhoto
                  ? null
                  : () => _addPhoto(context, provider, photoType: 'main'),
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(l10n.report_addPhoto),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdditionalPhotosSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ManualReportProvider provider,
  ) {
    final additionalPhotos = provider.uploadedPhotos
        .where((p) => p.photoType == 'additional')
        .toList();

    return PhotoGalleryWidget(
      imageUrls: additionalPhotos.map((p) => p.photoUrl).toList(),
      onAddPhoto: () => _addPhoto(context, provider, photoType: 'additional'),
      onRemovePhoto: (index) {
        final photo = additionalPhotos[index];
        _removePhoto(context, provider, photo);
      },
    );
  }

  Widget _buildLocationInput(ThemeData theme, AppLocalizations l10n) {
    return LocationInputWidget(
      streetAddress: _address,
      latitude: _latitude,
      longitude: _longitude,
      accuracy: _accuracy,
      isLoading: _isLoadingLocation,
      onRefreshLocation: _getCurrentLocation,
      onEditAddress: _showAddressEditDialog,
    );
  }

  Widget _buildIssueTypeSelector(
    ThemeData theme,
    AppLocalizations l10n,
    ManualReportProvider provider,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse/expand button
          InkWell(
            onTap: () {
              setState(() {
                _isIssueTypeSectionExpanded = !_isIssueTypeSectionExpanded;
              });
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      '${l10n.report_issueType} *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Selected count badge
                  if (_selectedIssueTypeIds.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(right: 2.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedIssueTypeIds.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Expand/collapse icon
                  Icon(
                    _isIssueTypeSectionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isIssueTypeSectionExpanded) ...[
            SizedBox(height: 2.h),

            // Issue type cards
            ...provider.availableIssueTypes.map((issueType) {
              final isSelected = _selectedIssueTypeIds.contains(issueType.id);

              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: InkWell(
                  onTap: () => _toggleIssueType(issueType.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon with better error handling
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  )
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            IconMapper.getIcon(issueType.iconUrl),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 3.w),

                        // Name and description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issueType.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (issueType.description != null &&
                                  issueType.description!.isNotEmpty) ...[
                                SizedBox(height: 0.5.h),
                                Text(
                                  issueType.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Checkbox
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import './widgets/description_input_widget.dart';
import './widgets/image_preview_widget.dart';
import './widgets/issue_type_selector_widget.dart';
import './widgets/location_info_widget.dart';
import './widgets/photo_gallery_widget.dart';
import './widgets/severity_slider_widget.dart';
import './widgets/submission_actions_widget.dart';

class ReportSubmissionScreen extends StatefulWidget {
  const ReportSubmissionScreen({super.key});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  // Controllers
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // Form state
  String? _capturedImageUrl;
  final List<String> _additionalPhotos = [];
  List<String> _selectedIssues = [];
  double _severity = 3.0;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  // Location data
  final String _streetAddress =
      "1234 Main Street, Downtown District, Springfield, IL 62701";
  final double _latitude = 39.7817;
  final double _longitude = -89.6501;
  final double _accuracy = 8.5;

  // Mock AI detected issues
  final List<Map<String, dynamic>> _detectedIssues = [
    {
      "type": "pothole",
      "confidence": 0.92,
      "x": 0.3,
      "y": 0.4,
      "width": 0.15,
      "height": 0.12,
    },
    {
      "type": "crack",
      "confidence": 0.78,
      "x": 0.6,
      "y": 0.2,
      "width": 0.25,
      "height": 0.08,
    },
    {
      "type": "obstacle",
      "confidence": 0.85,
      "x": 0.1,
      "y": 0.7,
      "width": 0.12,
      "height": 0.15,
    },
  ];

  // Suggestion texts for description
  final List<String> _descriptionSuggestions = [
    "Heavy traffic area with frequent vehicle damage",
    "Water accumulates here during rain",
    "Pedestrians have to walk around this area",
    "Multiple vehicles have been affected",
    "Issue has been present for several weeks",
    "Creates safety hazard during night time",
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    // Simulate captured image from camera detection
    _capturedImageUrl =
        "https://images.pexels.com/photos/1563356/pexels-photo-1563356.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1";

    // Pre-select detected issues with high confidence
    _selectedIssues = _detectedIssues
        .where((issue) => (issue['confidence'] as double) > 0.8)
        .map((issue) => issue['type'] as String)
        .toList();

    setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _capturedImageUrl != null && _selectedIssues.isNotEmpty;
  }

  /// Retake the main photo using camera
  Future<void> _retakePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImageUrl = image.path;
        });

        HapticFeedback.lightImpact();
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: AppLocalizations.of(context).report_photoUpdated,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_photoCaptureFailed,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Refresh location data
  Future<void> _refreshLocation() async {
    HapticFeedback.lightImpact();

    // Simulate location refresh
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context).report_locationUpdated,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _toggleIssueSelection(String issueType) {
    setState(() {
      if (_selectedIssues.contains(issueType)) {
        _selectedIssues.remove(issueType);
      } else {
        _selectedIssues.add(issueType);
      }
    });

    HapticFeedback.selectionClick();
  }

  void _updateSeverity(double value) {
    setState(() {
      _severity = value;
    });

    HapticFeedback.selectionClick();
  }

  /// Add additional photo from camera
  Future<void> _addPhoto() async {
    if (_additionalPhotos.length >= 5) {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_maxPhotos,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _additionalPhotos.add(image.path);
        });

        HapticFeedback.lightImpact();
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: AppLocalizations.of(context).report_photoAdded,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_photoAddFailed,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Remove photo from additional photos list
  void _removePhoto(int index) {
    setState(() {
      _additionalPhotos.removeAt(index);
    });

    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context).report_photoRemoved,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  /// Submit the report to the server
  Future<void> _submitReport() async {
    if (!_isFormValid) return;

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        setState(() {
          _uploadProgress = i / 100;
        });
      }

      // Generate report ID
      final String reportId =
          "RPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      HapticFeedback.heavyImpact();

      // Show success dialog
      if (!mounted) return;
      _showSuccessDialog(reportId);
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_submitFailed,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// Show success dialog after report submission
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
                    ? const Color(0xFF388E3C) // Success green from theme
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

  /// Save current report as draft
  Future<void> _saveDraft() async {
    HapticFeedback.lightImpact();

    // Simulate saving draft
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context).report_draftSaved,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      return;
    }

    if (_descriptionController.text.isNotEmpty || _selectedIssues.isNotEmpty) {
      final navigator = Navigator.of(context);
      final bool shouldPop =
          await showDialog(
            context: context,
            builder: (dialogContext) {
              final l10n = AppLocalizations.of(context);
              return AlertDialog(
                title: Text(l10n.report_unsavedChanges),
                content: Text(l10n.report_unsavedChangesMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.report_discard),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop(false);
                      await _saveDraft();
                      if (!mounted) return;
                      navigator.pop();
                    },
                    child: Text(l10n.report_saveDraft),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (shouldPop && mounted) {
        navigator.pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: HeaderLayout(
          title: l10n.report_title,
          // leading: IconButton(
          //   onPressed: () {
          //     Navigator.of(context).pop();
          //   },
          //   icon: Icon(Icons.arrow_back, size: 24),
          // ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/safety-alerts-screen');
              },
              icon: Icon(Icons.notifications, size: 24),
            ),
          ],
        ),
        body: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview with AI detection
                    ImagePreviewWidget(
                      imageUrl: _capturedImageUrl,
                      detectedIssues: _detectedIssues,
                      onRetakePhoto: _retakePhoto,
                    ),

                    SizedBox(height: 3.h),

                    // Location information
                    LocationInfoWidget(
                      streetAddress: _streetAddress,
                      latitude: _latitude,
                      longitude: _longitude,
                      accuracy: _accuracy,
                      onRefreshLocation: _refreshLocation,
                    ),

                    SizedBox(height: 3.h),

                    // Issue type selector
                    IssueTypeSelectorWidget(
                      detectedIssues: _detectedIssues,
                      selectedIssues: _selectedIssues,
                      onIssueToggle: _toggleIssueSelection,
                    ),

                    SizedBox(height: 3.h),

                    // Severity slider
                    SeveritySliderWidget(
                      severity: _severity,
                      onSeverityChanged: _updateSeverity,
                    ),

                    SizedBox(height: 3.h),

                    // Description input
                    DescriptionInputWidget(
                      controller: _descriptionController,
                      suggestions: _descriptionSuggestions,
                    ),

                    SizedBox(height: 3.h),

                    // Additional photos
                    PhotoGalleryWidget(
                      imageUrls: _additionalPhotos,
                      onAddPhoto: _addPhoto,
                      onRemovePhoto: _removePhoto,
                    ),

                    SizedBox(height: 10.h), // Space for bottom actions
                  ],
                ),
              ),
            ),

            // Bottom actions
            SubmissionActionsWidget(
              isFormValid: _isFormValid,
              isSubmitting: _isSubmitting,
              uploadProgress: _uploadProgress,
              onSubmit: _submitReport,
              onSaveDraft: _saveDraft,
            ),
          ],
        ),
      ),
    );
  }
}

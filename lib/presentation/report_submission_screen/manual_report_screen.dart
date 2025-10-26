import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api/report_issue/report_issue_api.dart';
import '../../core/api/report_issue/issue_type_api.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import './manual_report_provider.dart';
import './widgets/description_input_widget.dart';
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

  final List<String> _selectedIssueTypeIds = [];
  double _severity = 3.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool _isFormValid(ManualReportProvider provider) {
    return provider.uploadedPhotos.isNotEmpty &&
        _selectedIssueTypeIds.isNotEmpty &&
        _locationController.text.isNotEmpty;
  }

  /// Add photo from camera or gallery
  Future<void> _addPhoto({bool fromCamera = true}) async {
    final provider = context.read<ManualReportProvider>();

    // Check if can add more photos
    final photoType = provider.mainPhotoCount == 0 ? 'main' : 'additional';
    final validationError = provider.canAddPhoto(photoType);

    if (validationError != null) {
      Fluttertoast.showToast(
        msg: validationError,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
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
        await provider.uploadPhoto(
          fileName: image.name,
          fileBytes: bytes,
          mimeType: mimeType,
          photoType: photoType,
          isPrimary: provider.photoCount == 0,
        );

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
        msg: '${AppLocalizations.of(context).report_photoAddFailed}: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Remove photo
  Future<void> _removePhoto(int index) async {
    final provider = context.read<ManualReportProvider>();

    if (index >= provider.uploadedPhotos.length) return;

    final photo = provider.uploadedPhotos[index];

    try {
      await provider.deletePhoto(photo);

      HapticFeedback.lightImpact();
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_photoRemoved,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      if (!mounted) return;
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
  Future<void> _saveDraft() async {
    final provider = context.read<ManualReportProvider>();

    try {
      await provider.updateDraft(
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        issueTypeIds: _selectedIssueTypeIds.isEmpty
            ? null
            : _selectedIssueTypeIds,
        severity: _getSeverityString(_severity),
        address: _locationController.text.isEmpty
            ? null
            : _locationController.text,
      );

      HapticFeedback.lightImpact();
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_draftSaved,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Failed to save draft: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Submit report
  Future<void> _submitReport() async {
    final provider = context.read<ManualReportProvider>();

    if (!_isFormValid(provider)) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update draft with final data
      await provider.updateDraft(
        description: _descriptionController.text,
        issueTypeIds: _selectedIssueTypeIds,
        severity: _getSeverityString(_severity),
        address: _locationController.text,
      );

      // Submit the draft
      final reportId = provider.draftReport?.id ?? 'Unknown';
      await provider.submitDraft();

      HapticFeedback.heavyImpact();

      if (!mounted) return;
      _showSuccessDialog(reportId);
    } catch (e) {
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
  void _handlePopInvoked(bool didPop, Object? result) async {
    if (didPop) return;

    final provider = context.read<ManualReportProvider>();

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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _handlePopInvoked,
        child: Scaffold(
          appBar: HeaderLayout(title: l10n.report_manualReport),
          body: Consumer<ManualReportProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
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

                          // Photo section
                          _buildPhotoSection(theme, l10n, provider),

                          SizedBox(height: 3.h),

                          // Location input
                          _buildLocationInput(theme, l10n),

                          SizedBox(height: 3.h),

                          // Issue type selector
                          _buildIssueTypeSelector(theme, l10n, provider),

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
                            suggestions: const [],
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
                    onSubmit: _submitReport,
                    onSaveDraft: _saveDraft,
                  ),
                ],
              );
            },
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

  Widget _buildPhotoSection(
    ThemeData theme,
    AppLocalizations l10n,
    ManualReportProvider provider,
  ) {
    // Convert uploaded photos to URLs for display
    final photoUrls = provider.uploadedPhotos.map((p) => p.photoUrl).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.report_photos,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${provider.photoCount}/10',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Show upload progress
        if (provider.isUploadingPhoto)
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Column(
              children: [
                LinearProgressIndicator(value: provider.uploadProgress),
                SizedBox(height: 1.h),
                Text('Uploading photo...', style: theme.textTheme.bodySmall),
              ],
            ),
          ),

        PhotoGalleryWidget(
          imageUrls: photoUrls,
          onAddPhoto: _addPhoto,
          onRemovePhoto: _removePhoto,
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.isUploadingPhoto
                    ? null
                    : () => _addPhoto(fromCamera: true),
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.report_takePhoto),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.isUploadingPhoto
                    ? null
                    : () => _addPhoto(fromCamera: false),
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.report_chooseFromGallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInput(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.report_location,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: l10n.report_enterLocation,
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildIssueTypeSelector(
    ThemeData theme,
    AppLocalizations l10n,
    ManualReportProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.report_issueType,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: provider.availableIssueTypes.map((issueType) {
            final isSelected = _selectedIssueTypeIds.contains(issueType.id);
            return FilterChip(
              label: Text(issueType.name),
              selected: isSelected,
              onSelected: (_) => _toggleIssueType(issueType.id),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/api/report_issue/report_issue_api.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/report_management_service.dart';
import '../../data/models/report_issue_model.dart';
import '../../data/models/issue_type_model.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';

class ReportEditScreen extends StatefulWidget {
  final ReportIssueModel report;

  const ReportEditScreen({super.key, required this.report});

  @override
  State<ReportEditScreen> createState() => _ReportEditScreenState();
}

class _ReportEditScreenState extends State<ReportEditScreen> {
  late final ReportManagementService _managementService;
  late final ReportIssueApi _reportApi;
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  
  String _selectedSeverity = 'moderate';
  List<IssueTypeModel> _availableTypes = [];
  List<String> _selectedTypeIds = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _descriptionController = TextEditingController(text: widget.report.description);
    _addressController = TextEditingController(text: widget.report.address);
    _selectedSeverity = widget.report.severity;
    _selectedTypeIds = List.from(widget.report.issueTypeIds);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = context.read<AuthProvider>();
      _reportApi = ReportIssueApi(authProvider.supabaseClient);
      _managementService = ReportManagementService(_reportApi);
      _loadIssueTypes();
      _isInitialized = true;
    }
  }

  bool _isInitialized = false;

  Future<void> _loadIssueTypes() async {
    setState(() => _isLoading = true);
    
    try {
      final types = await _reportApi.getIssueTypes();
      if (mounted) {
        setState(() {
          _availableTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading issue types: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeIds.isEmpty) {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).report_editSelectIssueType,
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _managementService.updateReport(
        reportId: widget.report.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        issueTypeIds: _selectedTypeIds,
        severity: _selectedSeverity,
        address: _addressController.text.trim(),
        latitude: widget.report.latitude,
        longitude: widget.report.longitude,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n.report_editUpdated,
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n.report_editFailed(e.toString()),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally{
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.report_editReport,
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                l10n.common_save,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      l10n.report_editTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: l10n.report_editTitleHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.report_editTitleRequired;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Description
                    Text(
                      l10n.report_description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: l10n.report_descriptionHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.report_editDescriptionRequired;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Address
                    Text(
                      l10n.report_address,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: l10n.report_editAddressHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Severity
                    Text(
                      l10n.report_editSeverity,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildSeveritySelector(theme),

                    SizedBox(height: 3.h),

                    // Issue Types
                    Text(
                      l10n.report_editIssueTypes,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildIssueTypeSelector(theme, l10n),

                    SizedBox(height: 4.h),

                    // Info card
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              l10n.report_editSaveInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeveritySelector(ThemeData theme) {
    final severities = ['minor', 'low', 'moderate', 'high', 'critical'];
    final colors = {
      'minor': Colors.yellow.shade600,
      'low': Colors.yellow.shade700,
      'moderate': Colors.orange.shade600,
      'high': Colors.red.shade500,
      'critical': Colors.red.shade700,
    };

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: severities.map((severity) {
        final isSelected = _selectedSeverity == severity;
        final color = colors[severity]!;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedSeverity = severity;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              severity.toUpperCase(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIssueTypeSelector(ThemeData theme, AppLocalizations l10n) {
    if (_availableTypes.isEmpty) {
      return Text(
        l10n.report_editNoIssueTypes,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _availableTypes.map((type) {
        final isSelected = _selectedTypeIds.contains(type.id);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTypeIds.remove(type.id);
              } else {
                _selectedTypeIds.add(type.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                if (isSelected) SizedBox(width: 1.w),
                Text(
                  type.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

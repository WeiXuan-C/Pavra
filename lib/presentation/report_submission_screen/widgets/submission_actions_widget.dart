import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class SubmissionActionsWidget extends StatelessWidget {
  final bool isFormValid;
  final bool isSubmitting;
  final VoidCallback? onSubmit;
  final VoidCallback? onSaveDraft;
  final double uploadProgress;

  const SubmissionActionsWidget({
    super.key,
    required this.isFormValid,
    required this.isSubmitting,
    this.onSubmit,
    this.onSaveDraft,
    this.uploadProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upload progress indicator
            if (isSubmitting) ...[
              _buildUploadProgress(l10n),
              SizedBox(height: 2.h),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: isFormValid && !isSubmitting ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                  foregroundColor: Colors.white,
                  elevation: isFormValid ? 2.0 : 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            l10n.report_submittingReport,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'send',
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            l10n.report_submitReport,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 2.h),

            // Save draft button
            SizedBox(
              width: double.infinity,
              height: 5.h,
              child: OutlinedButton(
                onPressed: !isSubmitting ? onSaveDraft : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.lightTheme.primaryColor,
                  side: BorderSide(
                    color: AppTheme.lightTheme.primaryColor.withValues(
                      alpha: isSubmitting ? 0.3 : 1.0,
                    ),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'save',
                      color: AppTheme.lightTheme.primaryColor.withValues(
                        alpha: isSubmitting ? 0.3 : 1.0,
                      ),
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      l10n.report_saveDraft,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor.withValues(
                          alpha: isSubmitting ? 0.3 : 1.0,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form validation message
            if (!isFormValid && !isSubmitting) ...[
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.error.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.error.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.lightTheme.colorScheme.error,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        l10n.report_selectIssueTypeWarning,
                        style: AppTheme.lightTheme.textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.report_uploadingReport,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            Text(
              '${(uploadProgress * 100).toInt()}%',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        LinearProgressIndicator(
          value: uploadProgress,
          backgroundColor: AppTheme.lightTheme.dividerColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.primaryColor,
          ),
          minHeight: 4,
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'cloud_upload',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              size: 14,
            ),
            SizedBox(width: 1.w),
            Text(
              l10n.report_syncingCloud,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

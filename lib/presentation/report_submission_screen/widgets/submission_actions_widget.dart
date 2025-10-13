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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                      ? theme.primaryColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
                            style: theme.textTheme.titleMedium?.copyWith(
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
                            style: theme.textTheme.titleMedium?.copyWith(
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
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(
                    color: theme.primaryColor.withValues(
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
                      color: theme.primaryColor.withValues(
                        alpha: isSubmitting ? 0.3 : 1.0,
                      ),
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      l10n.report_saveDraft,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.primaryColor.withValues(
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
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        l10n.report_selectIssueTypeWarning,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
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
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.report_uploadingReport,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${(uploadProgress * 100).toInt()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              minHeight: 4,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'cloud_upload',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Text(
                  l10n.report_syncingCloud,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

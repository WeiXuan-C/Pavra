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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
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
              height: 56,
              child: ElevatedButton(
                onPressed: isFormValid && !isSubmitting ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  foregroundColor: isFormValid
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  disabledBackgroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.12),
                  disabledForegroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.38),
                  elevation: isFormValid ? 2.0 : 0.0,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 16),
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
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.report_submittingReport,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send,
                            color: isFormValid
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.38,
                                  ),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.report_submitReport,
                            style: theme.textTheme.titleMedium?.copyWith(
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
              height: 48,
              child: OutlinedButton(
                onPressed: !isSubmitting ? onSaveDraft : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  disabledForegroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.38),
                  side: BorderSide(
                    color: isSubmitting
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                        : theme.colorScheme.primary,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save_outlined,
                      color: isSubmitting
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                          : theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.report_saveDraft,
                      style: theme.textTheme.titleSmall?.copyWith(
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

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class DescriptionInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final List<String> suggestions;

  const DescriptionInputWidget({
    super.key,
    required this.controller,
    this.maxLength = 500,
    this.suggestions = const [],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'description',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                l10n.report_description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                l10n.common_cancel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            l10n.report_descriptionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 2.h),

          // Text input field
          TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe the road condition, traffic impact, or any other relevant details...',
              hintStyle: theme.inputDecorationTheme.hintStyle,
              border: theme.inputDecorationTheme.border,
              enabledBorder: theme.inputDecorationTheme.enabledBorder,
              focusedBorder: theme.inputDecorationTheme.focusedBorder,
              fillColor: theme.inputDecorationTheme.fillColor,
              filled: true,
              contentPadding: EdgeInsets.all(3.w),
              counterStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            style: theme.textTheme.bodyMedium,
          ),

          // Suggestions
          if (suggestions.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              l10n.report_description,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: suggestions
                  .map((suggestion) => _buildSuggestionChip(suggestion))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: () {
            final currentText = controller.text;
            final newText = currentText.isEmpty
                ? suggestion
                : '$currentText ${currentText.endsWith('.') ? '' : '.'} $suggestion';

            if (newText.length <= maxLength) {
              controller.text = newText;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'add',
                  color: theme.primaryColor,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Text(
                  suggestion,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

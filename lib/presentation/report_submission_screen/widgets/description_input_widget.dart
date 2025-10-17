import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
              Icon(
                Icons.description_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.report_description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.report_optional,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
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
              hintText: l10n.report_descriptionPlaceholder,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              fillColor: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface,
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
              l10n.report_suggestions,
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
                  .map(
                    (suggestion) => _buildSuggestionChip(context, suggestion),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String suggestion) {
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
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              suggestion,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

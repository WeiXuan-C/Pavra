import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class SeveritySliderWidget extends StatelessWidget {
  final double severity;
  final Function(double) onSeverityChanged;

  const SeveritySliderWidget({
    super.key,
    required this.severity,
    required this.onSeverityChanged,
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
                iconName: 'priority_high',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                l10n.report_severityLevel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            l10n.report_rateSeverity,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 3.h),

          // Current severity display
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getSeverityColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getSeverityColor(context), width: 2),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: _getSeverityIcon(),
                    color: _getSeverityColor(context),
                    size: 32,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _getSeverityLabel(context),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getSeverityColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _getSeverityDescription(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getSeverityColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getSeverityColor(context),
              inactiveTrackColor: theme.dividerColor,
              thumbColor: _getSeverityColor(context),
              overlayColor: _getSeverityColor(context).withValues(alpha: 0.2),
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: Slider(
              value: severity,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              onChanged: onSeverityChanged,
            ),
          ),

          SizedBox(height: 1.h),

          // Severity labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSeverityLabel(context, 'Minor', 1.0),
              _buildSeverityLabel(context, 'Low', 2.0),
              _buildSeverityLabel(context, 'Moderate', 3.0),
              _buildSeverityLabel(context, 'High', 4.0),
              _buildSeverityLabel(context, 'Critical', 5.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityLabel(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isSelected = severity == value;
    final Color color = isSelected
        ? _getSeverityColor(context)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    // Get translated label
    String translatedLabel;
    if (value == 1.0) {
      translatedLabel = l10n.severity_minor;
    } else if (value == 2.0) {
      translatedLabel = l10n.severity_low;
    } else if (value == 3.0) {
      translatedLabel = l10n.severity_moderate;
    } else if (value == 4.0) {
      translatedLabel = l10n.severity_high;
    } else {
      translatedLabel = l10n.severity_critical;
    }

    return Text(
      translatedLabel,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Color _getSeverityColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (severity <= 1.5) {
      return isDark
          ? const Color(0xFF66BB6A)
          : const Color(0xFF4CAF50); // Green - Minor
    } else if (severity <= 2.5) {
      return isDark
          ? const Color(0xFF9CCC65)
          : const Color(0xFF8BC34A); // Light Green - Low
    } else if (severity <= 3.5) {
      return isDark
          ? const Color(0xFFFFB74D)
          : const Color(0xFFFF9800); // Orange - Moderate
    } else if (severity <= 4.5) {
      return isDark
          ? const Color(0xFFFF8A65)
          : const Color(0xFFFF5722); // Deep Orange - High
    } else {
      return isDark
          ? const Color(0xFFEF5350)
          : const Color(0xFFF44336); // Red - Critical
    }
  }

  String _getSeverityIcon() {
    if (severity <= 1.5) {
      return 'info';
    } else if (severity <= 2.5) {
      return 'warning_amber';
    } else if (severity <= 3.5) {
      return 'warning';
    } else if (severity <= 4.5) {
      return 'error';
    } else {
      return 'dangerous';
    }
  }

  String _getSeverityLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (severity <= 1.5) {
      return l10n.severity_minor;
    } else if (severity <= 2.5) {
      return l10n.severity_low;
    } else if (severity <= 3.5) {
      return l10n.severity_moderate;
    } else if (severity <= 4.5) {
      return l10n.severity_high;
    } else {
      return l10n.severity_critical;
    }
  }

  String _getSeverityDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (severity <= 1.5) {
      return l10n.severity_minorDesc;
    } else if (severity <= 2.5) {
      return l10n.severity_lowDesc;
    } else if (severity <= 3.5) {
      return l10n.severity_moderateDesc;
    } else if (severity <= 4.5) {
      return l10n.severity_highDesc;
    } else {
      return l10n.severity_criticalDesc;
    }
  }
}

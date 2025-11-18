import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../ai_detection_provider.dart';

/// Sensitivity Settings Panel
/// 
/// Allows users to adjust AI detection sensitivity from 1 (low) to 5 (high)
/// Settings are persisted using shared_preferences
class SensitivitySettingsPanel extends StatefulWidget {
  final VoidCallback onClose;

  const SensitivitySettingsPanel({
    super.key,
    required this.onClose,
  });

  @override
  State<SensitivitySettingsPanel> createState() => _SensitivitySettingsPanelState();
}

class _SensitivitySettingsPanelState extends State<SensitivitySettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiProvider = context.watch<AiDetectionProvider>();
    final currentSensitivity = aiProvider.sensitivity;

    return Container(
      width: 85.w,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sensitivity Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.close,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      'Adjust how sensitive the AI detection is. Higher sensitivity detects more issues but may have more false positives.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Current Level Display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Current Level',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '$currentSensitivity',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            _getSensitivityLabel(currentSensitivity),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Slider
                    Slider(
                      value: currentSensitivity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$currentSensitivity',
                      onChanged: (value) {
                        aiProvider.setSensitivity(value.toInt());
                      },
                    ),
                    SizedBox(height: 1.h),

                    // Level Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '2',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '3',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '4',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '5',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Level Descriptions
                    _buildLevelCard(
                      context,
                      1,
                      'Low Sensitivity',
                      'Only report high-confidence detections (>90%). Fewer false positives.',
                      currentSensitivity == 1,
                    ),
                    SizedBox(height: 2.h),
                    _buildLevelCard(
                      context,
                      2,
                      'Medium-Low Sensitivity',
                      'Report detections with >80% confidence. Conservative approach.',
                      currentSensitivity == 2,
                    ),
                    SizedBox(height: 2.h),
                    _buildLevelCard(
                      context,
                      3,
                      'Medium Sensitivity (Recommended)',
                      'Balanced detection with >70% confidence. Good for most situations.',
                      currentSensitivity == 3,
                    ),
                    SizedBox(height: 2.h),
                    _buildLevelCard(
                      context,
                      4,
                      'Medium-High Sensitivity',
                      'More detections with >60% confidence. May have some false positives.',
                      currentSensitivity == 4,
                    ),
                    SizedBox(height: 2.h),
                    _buildLevelCard(
                      context,
                      5,
                      'High Sensitivity',
                      'Report all potential issues (>50% confidence). Maximum detection.',
                      currentSensitivity == 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSensitivityLabel(int level) {
    switch (level) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium-Low';
      case 3:
        return 'Medium';
      case 4:
        return 'Medium-High';
      case 5:
        return 'High';
      default:
        return 'Medium';
    }
  }

  Widget _buildLevelCard(
    BuildContext context,
    int level,
    String title,
    String description,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final aiProvider = context.read<AiDetectionProvider>();

    return GestureDetector(
      onTap: () {
        aiProvider.setSensitivity(level);
      },
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
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Level Number
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Selected Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

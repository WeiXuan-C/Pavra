import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'priority_high',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Severity Level',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            'Rate the severity of the road issue',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Current severity display
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getSeverityColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getSeverityColor(), width: 2),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: _getSeverityIcon(),
                    color: _getSeverityColor(),
                    size: 32,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _getSeverityLabel(),
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: _getSeverityColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _getSeverityDescription(),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _getSeverityColor().withValues(alpha: 0.8),
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
              activeTrackColor: _getSeverityColor(),
              inactiveTrackColor: AppTheme.lightTheme.dividerColor,
              thumbColor: _getSeverityColor(),
              overlayColor: _getSeverityColor().withValues(alpha: 0.2),
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
              _buildSeverityLabel('Minor', 1.0),
              _buildSeverityLabel('Low', 2.0),
              _buildSeverityLabel('Moderate', 3.0),
              _buildSeverityLabel('High', 4.0),
              _buildSeverityLabel('Critical', 5.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityLabel(String label, double value) {
    final bool isSelected = severity == value;
    final Color color = isSelected
        ? _getSeverityColor()
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Text(
      label,
      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Color _getSeverityColor() {
    if (severity <= 1.5) {
      return const Color(0xFF4CAF50); // Green - Minor
    } else if (severity <= 2.5) {
      return const Color(0xFF8BC34A); // Light Green - Low
    } else if (severity <= 3.5) {
      return const Color(0xFFFF9800); // Orange - Moderate
    } else if (severity <= 4.5) {
      return const Color(0xFFFF5722); // Deep Orange - High
    } else {
      return const Color(0xFFF44336); // Red - Critical
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

  String _getSeverityLabel() {
    if (severity <= 1.5) {
      return 'Minor';
    } else if (severity <= 2.5) {
      return 'Low';
    } else if (severity <= 3.5) {
      return 'Moderate';
    } else if (severity <= 4.5) {
      return 'High';
    } else {
      return 'Critical';
    }
  }

  String _getSeverityDescription() {
    if (severity <= 1.5) {
      return 'Minor inconvenience, no immediate danger';
    } else if (severity <= 2.5) {
      return 'Slight discomfort, minimal impact';
    } else if (severity <= 3.5) {
      return 'Noticeable issue, requires attention';
    } else if (severity <= 4.5) {
      return 'Significant hazard, needs urgent repair';
    } else {
      return 'Extreme danger, immediate action required';
    }
  }
}

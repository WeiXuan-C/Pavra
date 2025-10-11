import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';

class LocationInfoWidget extends StatelessWidget {
  final String streetAddress;
  final double latitude;
  final double longitude;
  final double accuracy;
  final VoidCallback? onRefreshLocation;

  const LocationInfoWidget({
    super.key,
    required this.streetAddress,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                iconName: 'location_on',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  l10n.report_locationDetails,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRefreshLocation,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomIconWidget(
                    iconName: 'refresh',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Street Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomIconWidget(
                iconName: 'place',
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.report_address,
                      style: AppTheme.lightTheme.textTheme.labelMedium
                          ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      streetAddress,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Coordinates
          Row(
            children: [
              Expanded(
                child: _buildCoordinateItem(
                  'Latitude',
                  latitude.toStringAsFixed(6),
                  'my_location',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildCoordinateItem(
                  'Longitude',
                  longitude.toStringAsFixed(6),
                  'my_location',
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Accuracy indicator
          Row(
            children: [
              CustomIconWidget(
                iconName: 'gps_fixed',
                color: _getAccuracyColor(),
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'GPS Accuracy: ${accuracy.toStringAsFixed(1)}m',
                style: AppTheme.dataTextStyle(isLight: true, fontSize: 12.sp),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getAccuracyColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getAccuracyLabel(),
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: _getAccuracyColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value, String iconName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              size: 14,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.dataTextStyle(isLight: true, fontSize: 12.sp),
        ),
      ],
    );
  }

  Color _getAccuracyColor() {
    if (accuracy <= 5) {
      return const Color(0xFF4CAF50); // Green - Excellent
    } else if (accuracy <= 10) {
      return const Color(0xFF8BC34A); // Light Green - Good
    } else if (accuracy <= 20) {
      return const Color(0xFFFF9800); // Orange - Fair
    } else {
      return const Color(0xFFF44336); // Red - Poor
    }
  }

  String _getAccuracyLabel() {
    if (accuracy <= 5) {
      return 'Excellent';
    } else if (accuracy <= 10) {
      return 'Good';
    } else if (accuracy <= 20) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }
}

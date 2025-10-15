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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  l10n.report_locationDetails,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRefreshLocation,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(26), // 0.1 * 255 ≈ 26
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomIconWidget(
                    iconName: 'refresh',
                    color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.report_address,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      streetAddress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  context,
                  'Latitude',
                  latitude.toStringAsFixed(6),
                  'my_location',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildCoordinateItem(
                  context,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getAccuracyColor().withAlpha(26), // 0.1 * 255 ≈ 26
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getAccuracyLabel(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  Widget _buildCoordinateItem(BuildContext context, String label, String value, String iconName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
              size: 14,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'JetBrains Mono',
            fontSize: 12.sp,
          ),
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

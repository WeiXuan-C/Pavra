import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

/// Widget to display and edit location information
/// Shows address, coordinates, and GPS accuracy
/// Allows manual address editing with geocoding
class LocationInputWidget extends StatelessWidget {
  final String streetAddress;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool isLoading;
  final VoidCallback? onRefreshLocation;
  final ValueChanged<String>? onAddressChanged;
  final VoidCallback? onEditAddress;

  const LocationInputWidget({
    super.key,
    required this.streetAddress,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.isLoading = false,
    this.onRefreshLocation,
    this.onAddressChanged,
    this.onEditAddress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  '${l10n.report_location} *',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Refresh button
              if (onRefreshLocation != null)
                IconButton(
                  onPressed: isLoading ? null : onRefreshLocation,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          color: theme.colorScheme.primary,
                        ),
                  tooltip: l10n.report_useCurrentLocation,
                ),
            ],
          ),
          SizedBox(height: 2.h),

          // Address display/edit
          InkWell(
            onTap: onEditAddress,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.report_address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          streetAddress.isEmpty
                              ? l10n.report_locationNotSet
                              : streetAddress,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: streetAddress.isEmpty
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEditAddress != null)
                    Icon(
                      Icons.edit,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Coordinates and accuracy
          Row(
            children: [
              // Latitude
              Expanded(
                child: _buildInfoCard(
                  context,
                  label: l10n.report_latitude,
                  value: latitude != null ? latitude!.toStringAsFixed(6) : '--',
                  icon: Icons.explore,
                ),
              ),
              SizedBox(width: 2.w),
              // Longitude
              Expanded(
                child: _buildInfoCard(
                  context,
                  label: l10n.report_longitude,
                  value: longitude != null
                      ? longitude!.toStringAsFixed(6)
                      : '--',
                  icon: Icons.explore,
                ),
              ),
            ],
          ),

          if (accuracy != null) ...[
            SizedBox(height: 2.h),
            _buildAccuracyIndicator(context, accuracy!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              SizedBox(width: 1.w),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyIndicator(BuildContext context, double accuracy) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Determine accuracy quality
    Color accuracyColor;
    String accuracyText;
    IconData accuracyIcon;

    if (accuracy <= 10) {
      accuracyColor = const Color(0xFF388E3C); // Excellent
      accuracyText = l10n.report_accuracyExcellent;
      accuracyIcon = Icons.gps_fixed;
    } else if (accuracy <= 30) {
      accuracyColor = const Color(0xFF66BB6A); // Good
      accuracyText = l10n.report_accuracyGood;
      accuracyIcon = Icons.gps_fixed;
    } else if (accuracy <= 50) {
      accuracyColor = const Color(0xFFFFA726); // Fair
      accuracyText = l10n.report_accuracyFair;
      accuracyIcon = Icons.gps_not_fixed;
    } else {
      accuracyColor = const Color(0xFFEF5350); // Poor
      accuracyText = l10n.report_accuracyPoor;
      accuracyIcon = Icons.gps_off;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: accuracyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accuracyColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(accuracyIcon, size: 16, color: accuracyColor),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              '${l10n.report_gpsAccuracy}: $accuracyText (±${accuracy.toStringAsFixed(1)}m)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accuracyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

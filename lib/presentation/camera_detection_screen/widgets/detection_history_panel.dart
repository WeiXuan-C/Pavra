import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/detection_model.dart';
import '../../../data/models/detection_type.dart';
import '../../../l10n/app_localizations.dart';
import '../ai_detection_provider.dart';
import 'detection_filter_sheet.dart';
import 'detection_map_widget.dart';

class DetectionHistoryPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(DetectionModel) onDetectionTap;

  const DetectionHistoryPanel({
    super.key,
    required this.onClose,
    required this.onDetectionTap,
  });

  @override
  State<DetectionHistoryPanel> createState() => _DetectionHistoryPanelState();
}

class _DetectionHistoryPanelState extends State<DetectionHistoryPanel> {
  bool _isRefreshing = false;
  bool _isMapView = false;
  DetectionType? _filterType;
  int? _filterSeverity;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  Future<void> _refreshHistory() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        final aiProvider = context.read<AiDetectionProvider>();
        await aiProvider.loadHistory(
          userId,
          filterType: _filterType,
          filterSeverity: _filterSeverity,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetectionFilterSheet(
        selectedType: _filterType,
        selectedSeverity: _filterSeverity,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        onTypeChanged: (type) {
          setState(() {
            _filterType = type;
          });
        },
        onSeverityChanged: (severity) {
          setState(() {
            _filterSeverity = severity;
          });
        },
        onDateRangeChanged: (start, end) {
          setState(() {
            _filterStartDate = start;
            _filterEndDate = end;
          });
        },
        onApply: () {
          _refreshHistory();
        },
        onClear: () {
          setState(() {
            _filterType = null;
            _filterSeverity = null;
            _filterStartDate = null;
            _filterEndDate = null;
          });
          _refreshHistory();
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _filterType != null ||
      _filterSeverity != null ||
      _filterStartDate != null ||
      _filterEndDate != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final aiProvider = context.watch<AiDetectionProvider>();
    final detections = aiProvider.detectionHistory;

    return Container(
      width: 80.w,
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
                    l10n.camera_recentDetections,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Map/List toggle button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMapView = !_isMapView;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _isMapView ? Icons.list : Icons.map,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                // Filter button
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasActiveFilters
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    child: Stack(
                      children: [
                        CustomIconWidget(
                          iconName: 'filter_list',
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
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
            child: detections.isEmpty
                ? _buildEmptyState(context, l10n)
                : _isMapView
                    ? DetectionMapWidget(
                        detections: detections,
                        aiProvider: aiProvider,
                        onDetectionTap: widget.onDetectionTap,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshHistory,
                        child: ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: detections.length,
                          separatorBuilder: (context, index) => SizedBox(height: 2.h),
                          itemBuilder: (context, index) {
                            final detection = detections[index];
                            return _buildDetectionCard(context, detection);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.camera_noDetectionsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.camera_startScanning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(
    BuildContext context,
    DetectionModel detection,
  ) {
    final theme = Theme.of(context);
    final aiProvider = context.read<AiDetectionProvider>();

    // Get alert color from provider
    final alertColor = aiProvider.getAlertColor(detection);

    // Get icon based on detection type
    IconData typeIcon;
    switch (detection.type.value) {
      case 'pothole':
        typeIcon = Icons.warning;
        break;
      case 'road_crack':
        typeIcon = Icons.linear_scale;
        break;
      case 'obstacle':
      case 'debris':
        typeIcon = Icons.block;
        break;
      case 'accident':
        typeIcon = Icons.car_crash;
        break;
      case 'flood':
        typeIcon = Icons.water;
        break;
      case 'uneven_surface':
        typeIcon = Icons.terrain;
        break;
      default:
        typeIcon = Icons.info;
    }

    // Format location
    String location = 'Unknown Location';
    if (detection.latitude != null && detection.longitude != null) {
      location = '${detection.latitude!.toStringAsFixed(4)}, ${detection.longitude!.toStringAsFixed(4)}';
    }

    return GestureDetector(
      onTap: () => widget.onDetectionTap(detection),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: alertColor.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: detection.imageUrl,
                  width: 15.w,
                  height: 15.w,
                  fit: BoxFit.cover,
                  errorWidget: Center(
                    child: Icon(typeIcon, color: alertColor, size: 6.w),
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: alertColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          detection.type.displayName.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${(detection.confidence * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      // Severity indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'L${detection.severity}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    detection.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 9.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _formatTimestamp(detection.createdAt, context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return l10n.time_justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.time_minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.time_hoursAgo(difference.inHours);
    } else {
      return l10n.time_daysAgo(difference.inDays);
    }
  }
}

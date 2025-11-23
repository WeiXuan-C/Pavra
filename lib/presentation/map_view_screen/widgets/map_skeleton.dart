import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

/// Skeleton loading widget for map view
///
/// Displays a shimmer effect while map and issues are loading
class MapSkeleton extends StatelessWidget {
  const MapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Stack(
      children: [
        // Map placeholder with gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [Colors.grey[200]!, Colors.grey[100]!],
            ),
          ),
        ),

        // Shimmer overlay for UI elements
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Stack(
            children: [
              // Search bar skeleton
              SafeArea(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(4.w),
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    
                    // Alert radius indicator skeleton
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      height: 4.h,
                      width: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating action buttons skeleton
              Positioned(
                right: 4.w,
                bottom: 25.h,
                child: Column(
                  children: [
                    _buildFabSkeleton(),
                    SizedBox(height: 2.h),
                    _buildFabSkeleton(),
                    SizedBox(height: 2.h),
                    _buildFabSkeleton(),
                  ],
                ),
              ),

              // Bottom buttons skeleton - card + icon layout
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 2.h,
                child: SafeArea(
                  child: Row(
                    children: [
                      // Main card skeleton (Nearby Issues)
                      Expanded(
                        child: Container(
                          height: 56,
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Circle skeleton
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 2.5.w),
                              // Text skeleton
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 13,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(6.5),
                                      ),
                                    ),
                                    SizedBox(height: 0.4.h),
                                    Container(
                                      height: 9,
                                      width: 60.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(4.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      // Alert icon button skeleton - subtle bottom shadow only
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mock map markers
              _buildMarkerSkeleton(context, top: 30.h, left: 20.w),
              _buildMarkerSkeleton(context, top: 45.h, right: 25.w),
              _buildMarkerSkeleton(context, top: 55.h, left: 60.w),
              _buildMarkerSkeleton(context, top: 35.h, right: 15.w),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a floating action button skeleton
  Widget _buildFabSkeleton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  /// Build a map marker skeleton
  Widget _buildMarkerSkeleton(
    BuildContext context, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
                width: 2,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(8, 12),
            painter: _MarkerTailPainter(),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for marker tail
class _MarkerTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

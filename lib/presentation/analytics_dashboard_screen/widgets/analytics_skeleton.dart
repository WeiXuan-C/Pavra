import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

/// Skeleton loading widget for analytics dashboard
///
/// Displays a shimmer effect while analytics data is loading
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: 3.w),
                Expanded(child: _buildStatCardSkeleton()),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(child: _buildStatCardSkeleton()),
                SizedBox(width: 3.w),
                Expanded(child: _buildStatCardSkeleton()),
              ],
            ),
            
            SizedBox(height: 3.h),
            
            // Doughnut Chart Card
            _buildChartCardSkeleton(height: 350),
            
            SizedBox(height: 3.h),
            
            // Another Doughnut Chart Card
            _buildChartCardSkeleton(height: 350),
            
            SizedBox(height: 3.h),
            
            // Issue Types Card
            _buildChartCardSkeleton(height: 300),
            
            SizedBox(height: 3.h),
            
            // Trend Chart Card
            _buildChartCardSkeleton(height: 280),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 28,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 0.5.h),
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCardSkeleton({required double height}) {
    return Container(
      height: height,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

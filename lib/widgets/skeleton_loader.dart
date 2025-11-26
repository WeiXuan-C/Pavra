import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Skeleton loader widget for showing loading placeholders
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for location list items
class LocationSkeletonLoader extends StatelessWidget {
  const LocationSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon placeholder
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: 16),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 40.w,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 60.w,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  SkeletonLoader(
                    width: 50.w,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            // Action buttons placeholder
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for route list items
class RouteSkeletonLoader extends StatelessWidget {
  const RouteSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and icon
            Row(
              children: [
                Expanded(
                  child: SkeletonLoader(
                    width: 50.w,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SkeletonLoader(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Info rows
            SkeletonLoader(
              width: 30.w,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 0.5.h),
            SkeletonLoader(
              width: 25.w,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 0.5.h),
            SkeletonLoader(
              width: 35.w,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 1.h),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SkeletonLoader(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                SizedBox(width: 2.w),
                SkeletonLoader(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                SizedBox(width: 2.w),
                SkeletonLoader(
                  width: 40,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading overlay widget for inline use
class LoadingOverlay extends StatelessWidget {
  final String message;
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.message,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

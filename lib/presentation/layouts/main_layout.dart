import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../l10n/app_localizations.dart';
import '../camera_detection_screen/camera_detection_screen.dart';
import '../map_view_screen/map_view_screen.dart';
import '../report_submission_screen/report_submission_screen.dart';
import '../safety_alerts_screen/safety_alerts_screen.dart';
import '../notification_screen/notification_screen.dart';
import '../profile_screen/profile_screen.dart';

/// Main Layout
/// Provides centralized navigation bar for all main app screens (except authentication)
/// Displays a bottom navigation bar with access to Camera, Map, Report, Alerts, and Profile
class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late PageController _pageController;

  // List of main screens
  final List<Widget> _screens = [
    const CameraDetectionScreen(),
    const MapViewScreen(),
    const ReportSubmissionScreen(),
    const SafetyAlertsScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle navigation bar tap
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  /// Handle page change
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe navigation
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: [
          // Camera
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'camera_alt',
              color: _currentIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.nav_camera,
          ),
          // Map
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'map',
              color: _currentIndex == 1
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.nav_map,
          ),
          // Report
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'report',
              color: _currentIndex == 2
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.nav_report,
          ),
          // Alerts
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: _currentIndex == 3
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.nav_alerts,
          ),
          // Notifications
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'notifications_active',
              color: _currentIndex == 4
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.notification_title,
          ),
          // Profile
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 5
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.nav_profile,
          ),
        ],
      ),
    );
  }
}

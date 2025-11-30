import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../core/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../map_view_screen/map_view_screen.dart';
import '../report_screen/report_screen.dart';
import '../notification_screen/notification_screen.dart';
import '../notification_screen/notification_provider.dart';
import '../profile_screen/profile_screen.dart';
import '../admin_panel_screen/admin_panel_screen.dart';

/// Main Layout
/// Provides centralized navigation bar for all main app screens
/// Displays a bottom navigation bar with access to Map, Report, Notification, and Profile
class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late PageController _pageController;

  // Report screen filter type: 0 = Home, 1 = My Reports, 2 = All Reports
  int _reportFilterType = 0;

  // Profile screen type: 0 = Profile, 1 = Admin
  int _profileScreenType = 0;

  // List of main screens
  List<Widget> _getScreens() => [
    const MapViewScreen(),
    ReportScreen(filterType: _reportFilterType),
    const NotificationScreen(),
    _getProfileScreen(),
  ];

  Widget _getProfileScreen() {
    switch (_profileScreenType) {
      case 1:
        return const AdminPanelScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Load notifications early to show badge count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationCount();
    });
  }
  
  /// Load notification count for badge display
  void _loadNotificationCount() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final userRole = authProvider.userProfile?.role;
      
      if (userId != null) {
        context.read<NotificationProvider>().loadNotifications(
          userId,
          userRole: userRole,
        );
      }
    } catch (e) {
      // Silently fail if auth provider is not available
      debugPrint('Failed to load notification count: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle navigation bar tap
  void _onNavBarTap(int index) {
    // If tapping on Report tab (index 1), show dropdown menu
    if (index == 1 && _currentIndex == 1) {
      _showReportFilterMenu();
      return;
    }

    // If tapping on Profile tab (index 3), show dropdown menu for developers
    if (index == 3 && _currentIndex == 3) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userRole = authProvider.userProfile?.role;
      if (userRole == 'developer') {
        _showProfileFilterMenu();
        return;
      }
    }

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

  /// Show profile filter dropdown menu (for developers)
  void _showProfileFilterMenu() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 2.h),
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 2.h),
            _buildFilterOption(
              icon: Icons.person_outline,
              title: l10n.nav_profile,
              subtitle: 'View your profile and settings',
              isSelected: _profileScreenType == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _profileScreenType = 0);
              },
            ),
            Divider(height: 1),
            _buildFilterOption(
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              subtitle: 'Manage reports and users',
              isSelected: _profileScreenType == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() => _profileScreenType = 1);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  /// Show report filter dropdown menu
  void _showReportFilterMenu() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 2.h),
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 2.h),
            _buildFilterOption(
              icon: Icons.home_outlined,
              title: l10n.report_title,
              subtitle: l10n.report_filterMenuSubtitleHome,
              isSelected: _reportFilterType == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _reportFilterType = 0);
              },
            ),
            Divider(height: 1),
            _buildFilterOption(
              icon: Icons.person_outline,
              title: l10n.report_myReports,
              subtitle: l10n.report_filterMenuSubtitleMy,
              isSelected: _reportFilterType == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() => _reportFilterType = 1);
              },
            ),
            Divider(height: 1),
            _buildFilterOption(
              icon: Icons.public,
              title: l10n.report_allReports,
              subtitle: l10n.report_filterMenuSubtitleAll,
              isSelected: _reportFilterType == 2,
              onTap: () {
                Navigator.pop(context);
                setState(() => _reportFilterType = 2);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  /// Build filter option item
  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 6.w,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
          ],
        ),
      ),
    );
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
        children: _getScreens(),
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
          // Map
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'map',
              color: _currentIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: l10n.nav_map,
          ),
          // Report (with dropdown indicator)
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomIconWidget(
                  iconName: 'report',
                  color: _currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 6.w,
                ),
                if (_currentIndex == 1)
                  Positioned(
                    right: -2.w,
                    top: -1.h,
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 4.w,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            label: l10n.nav_report,
          ),
          // Notifications
          BottomNavigationBarItem(
            icon: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final unreadCount = provider.unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomIconWidget(
                      iconName: 'notifications_active',
                      color: _currentIndex == 2
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 6.w,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -1.w,
                        top: -0.5.h,
                        child: Container(
                          padding: EdgeInsets.all(
                            unreadCount > 99 ? 0.3.w : 0.8.w,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).cardColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 4.w,
                            minHeight: 4.w,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: l10n.notification_title,
          ),
          // Profile (with dropdown indicator for developers)
          BottomNavigationBarItem(
            icon: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isDeveloper = authProvider.userProfile?.role == 'developer';
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomIconWidget(
                      iconName: 'person',
                      color: _currentIndex == 3
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 6.w,
                    ),
                    if (_currentIndex == 3 && isDeveloper)
                      Positioned(
                        right: -2.w,
                        top: -1.h,
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 4.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                );
              },
            ),
            label: l10n.nav_profile,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/alert_card_widget.dart';
import './widgets/alert_toggle_widget.dart';
import './widgets/mini_map_widget.dart';
import './widgets/radius_slider_widget.dart';
import './widgets/route_monitoring_widget.dart';

class SafetyAlertsScreen extends StatefulWidget {
  const SafetyAlertsScreen({super.key});

  @override
  State<SafetyAlertsScreen> createState() => _SafetyAlertsScreenState();
}

class _SafetyAlertsScreenState extends State<SafetyAlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  double _alertRadius = 5.0;
  bool _roadDamageEnabled = true;
  bool _constructionEnabled = true;
  bool _weatherEnabled = false;
  bool _trafficEnabled = true;
  bool _isRefreshing = false;

  // Mock data for safety alerts
  final List<Map<String, dynamic>> _alerts = [
    {
      "id": 1,
      "severity": "Critical",
      "hazardType": "Road Damage",
      "location": "Main Street & 5th Avenue intersection",
      "distance": "0.3 miles",
      "timeReported": "2 hours ago",
      "photo":
          "https://images.pexels.com/photos/416978/pexels-photo-416978.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "description":
          "Large pothole causing vehicle damage. Multiple reports of tire punctures. Road surface severely compromised with debris scattered.",
      "alternateRoute": "Use Oak Street parallel route",
      "isExpanded": false,
    },
    {
      "id": 2,
      "severity": "High",
      "hazardType": "Construction Zones",
      "location": "Highway 101 Northbound, Mile Marker 45",
      "distance": "1.2 miles",
      "timeReported": "4 hours ago",
      "photo":
          "https://images.pexels.com/photos/162539/architecture-building-construction-work-162539.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "description":
          "Lane closure for bridge repair work. Single lane traffic with 15-minute delays expected during peak hours.",
      "alternateRoute": "Exit at Maple Ave, rejoin at Pine St",
      "isExpanded": false,
    },
    {
      "id": 3,
      "severity": "Medium",
      "hazardType": "Weather Hazards",
      "location": "Mountain View Road, Sections 12-18",
      "distance": "2.8 miles",
      "timeReported": "1 hour ago",
      "description":
          "Fog reducing visibility to less than 100 feet. Wet road conditions from recent rainfall creating slippery surfaces.",
      "alternateRoute": "Valley Route via Sunset Boulevard",
      "isExpanded": false,
    },
    {
      "id": 4,
      "severity": "High",
      "hazardType": "Traffic Incidents",
      "location": "Interstate 95 Southbound, Exit 23",
      "distance": "3.5 miles",
      "timeReported": "30 minutes ago",
      "photo":
          "https://images.pexels.com/photos/13861/IMG_3496bfree.jpg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "description":
          "Multi-vehicle accident blocking two right lanes. Emergency services on scene. Expect significant delays.",
      "alternateRoute": "Use Route 1 coastal highway",
      "isExpanded": false,
    },
    {
      "id": 5,
      "severity": "Medium",
      "hazardType": "Road Damage",
      "location": "Cedar Avenue near Shopping Center",
      "distance": "4.1 miles",
      "timeReported": "6 hours ago",
      "description":
          "Uneven road surface and loose gravel. Recent utility work left road in poor condition affecting vehicle alignment.",
      "isExpanded": false,
    },
  ];

  // Mock data for saved routes
  final List<Map<String, dynamic>> _savedRoutes = [
    {
      "id": 1,
      "name": "Home to Work",
      "from": "123 Residential Ave",
      "to": "456 Business District",
      "distance": "12.3 miles",
      "isMonitoring": true,
    },
    {
      "id": 2,
      "name": "School Route",
      "from": "Home",
      "to": "Lincoln Elementary",
      "distance": "3.7 miles",
      "isMonitoring": true,
    },
    {
      "id": 3,
      "name": "Weekend Shopping",
      "from": "Home",
      "to": "Westfield Mall",
      "distance": "8.9 miles",
      "isMonitoring": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAlerts() async {
    setState(() => _isRefreshing = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Safety alerts updated',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _toggleAlertExpansion(int alertId) {
    setState(() {
      final alertIndex = _alerts.indexWhere((alert) => alert['id'] == alertId);
      if (alertIndex != -1) {
        _alerts[alertIndex]['isExpanded'] =
            !(_alerts[alertIndex]['isExpanded'] as bool);
      }
    });
  }

  void _dismissAlert(int alertId) {
    setState(() {
      _alerts.removeWhere((alert) => alert['id'] == alertId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alert marked as acknowledged',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // In a real app, restore the dismissed alert
          },
        ),
      ),
    );
  }

  void _toggleRouteMonitoring(int routeIndex, bool isMonitoring) {
    setState(() {
      _savedRoutes[routeIndex]['isMonitoring'] = isMonitoring;
    });
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationSettingsSheet(),
    );
  }

  Widget _buildNotificationSettingsSheet() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Notification Settings',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                    size: 6.w,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  _buildSettingsTile(
                    'Sound Alerts',
                    'Play notification sounds for critical alerts',
                    'volume_up',
                    true,
                    (value) {},
                  ),
                  _buildSettingsTile(
                    'Vibration',
                    'Vibrate device for high priority alerts',
                    'vibration',
                    true,
                    (value) {},
                  ),
                  _buildSettingsTile(
                    'Do Not Disturb',
                    'Respect system do not disturb settings',
                    'do_not_disturb',
                    false,
                    (value) {},
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'schedule',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Quiet Hours',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Only critical safety alerts will be shown during quiet hours',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: Text('10:00 PM'),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text('to'),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                child: Text('7:00 AM'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    String iconName,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    )
                  : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: value
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.5,
                    ),
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    return _alerts.where((alert) {
      final hazardType = (alert['hazardType'] as String).toLowerCase();

      if (hazardType.contains('road damage') && !_roadDamageEnabled) {
        return false;
      }
      if (hazardType.contains('construction') && !_constructionEnabled) {
        return false;
      }
      if (hazardType.contains('weather') && !_weatherEnabled) return false;
      if (hazardType.contains('traffic') && !_trafficEnabled) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Safety Alerts',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showNotificationSettings,
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 6.w,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.lightTheme.colorScheme.onPrimary,
          unselectedLabelColor: AppTheme.lightTheme.colorScheme.onPrimary
              .withValues(alpha: 0.7),
          indicatorColor: AppTheme.lightTheme.colorScheme.onPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Active Alerts'),
            Tab(text: 'Settings'),
            Tab(text: 'Routes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Alerts Tab
          RefreshIndicator(
            onRefresh: _refreshAlerts,
            color: AppTheme.lightTheme.colorScheme.primary,
            child: _filteredAlerts.isEmpty
                ? _buildEmptyAlertsState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    itemCount: _filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _filteredAlerts[index];
                      return AlertCardWidget(
                        alert: alert,
                        onTap: () => _toggleAlertExpansion(alert['id'] as int),
                        onDismiss: () => _dismissAlert(alert['id'] as int),
                      );
                    },
                  ),
          ),

          // Settings Tab
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    'Alert Types',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AlertToggleWidget(
                  title: 'Road Damage',
                  iconName: 'construction',
                  isEnabled: _roadDamageEnabled,
                  onChanged: (value) =>
                      setState(() => _roadDamageEnabled = value),
                ),
                AlertToggleWidget(
                  title: 'Construction Zones',
                  iconName: 'engineering',
                  isEnabled: _constructionEnabled,
                  onChanged: (value) =>
                      setState(() => _constructionEnabled = value),
                ),
                AlertToggleWidget(
                  title: 'Weather Hazards',
                  iconName: 'cloud',
                  isEnabled: _weatherEnabled,
                  onChanged: (value) => setState(() => _weatherEnabled = value),
                ),
                AlertToggleWidget(
                  title: 'Traffic Incidents',
                  iconName: 'traffic',
                  isEnabled: _trafficEnabled,
                  onChanged: (value) => setState(() => _trafficEnabled = value),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    'Location Settings',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RadiusSliderWidget(
                  currentRadius: _alertRadius,
                  onChanged: (value) => setState(() => _alertRadius = value),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    'Coverage Preview',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                MiniMapWidget(radius: _alertRadius),
              ],
            ),
          ),

          // Routes Tab
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    children: [
                      Text(
                        'Saved Routes',
                        style: AppTheme.lightTheme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to add route screen
                        },
                        icon: CustomIconWidget(
                          iconName: 'add',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 5.w,
                        ),
                        label: Text(
                          'Add Route',
                          style: AppTheme.lightTheme.textTheme.labelLarge
                              ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                RouteMonitoringWidget(
                  savedRoutes: _savedRoutes,
                  onRouteToggle: _toggleRouteMonitoring,
                ),
                SizedBox(height: 2.h),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Route Monitoring',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Enable monitoring for your frequent routes to receive proactive alerts about road conditions, construction, and incidents along your path.',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.cardColor,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurface
            .withValues(alpha: 0.6),
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/camera-detection-screen');
              break;
            case 1:
              Navigator.pushNamed(context, '/report-submission-screen');
              break;
            case 2:
              Navigator.pushNamed(context, '/map-view-screen');
              break;
            case 3:
              // Current screen - Safety Alerts
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'camera_alt',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              size: 6.w,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'camera_alt',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'report',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              size: 6.w,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'report',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'map',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              size: 6.w,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'map',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              size: 6.w,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'notifications',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAlertsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'shield',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 15.w,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'All Clear!',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'No safety alerts in your area right now. We\'ll notify you immediately if any road hazards are reported nearby.',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _refreshAlerts,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'refresh',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 5.w,
                    ),
              label: Text(_isRefreshing ? 'Checking...' : 'Check for Updates'),
            ),
          ],
        ),
      ),
    );
  }
}

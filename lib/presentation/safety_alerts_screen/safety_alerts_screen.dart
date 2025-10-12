import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
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
          content: Text(AppLocalizations.of(context).alerts_updated),
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
        content: Text(AppLocalizations.of(context).alerts_acknowledged),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: AppLocalizations.of(context).alerts_undo,
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
    // Navigate to settings screen
    Navigator.pushNamed(context, '/settings');
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.alerts_title,
        actions: [
          IconButton(
            onPressed: _showNotificationSettings,
            icon: Icon(Icons.settings, size: 24),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.alerts_activeAlerts),
            Tab(text: l10n.alerts_settings),
            Tab(text: l10n.alerts_routes),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Alerts Tab
          RefreshIndicator(
            onRefresh: _refreshAlerts,
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
                    l10n.alerts_alertTypes,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AlertToggleWidget(
                  title: l10n.alerts_roadDamage,
                  iconName: 'construction',
                  isEnabled: _roadDamageEnabled,
                  onChanged: (value) =>
                      setState(() => _roadDamageEnabled = value),
                ),
                AlertToggleWidget(
                  title: l10n.alerts_constructionZones,
                  iconName: 'engineering',
                  isEnabled: _constructionEnabled,
                  onChanged: (value) =>
                      setState(() => _constructionEnabled = value),
                ),
                AlertToggleWidget(
                  title: l10n.alerts_weatherHazards,
                  iconName: 'cloud',
                  isEnabled: _weatherEnabled,
                  onChanged: (value) => setState(() => _weatherEnabled = value),
                ),
                AlertToggleWidget(
                  title: l10n.alerts_trafficIncidents,
                  iconName: 'traffic',
                  isEnabled: _trafficEnabled,
                  onChanged: (value) => setState(() => _trafficEnabled = value),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Text(
                    l10n.alerts_locationSettings,
                    style: theme.textTheme.titleLarge?.copyWith(
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
                    l10n.alerts_coveragePreview,
                    style: theme.textTheme.titleLarge?.copyWith(
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
                        l10n.alerts_savedRoutes,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to add route screen
                        },
                        icon: Icon(Icons.add, size: 20),
                        label: Text(l10n.alerts_addRoute),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            l10n.alerts_routeMonitoring,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        l10n.alerts_routeMonitoringInfo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
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
    );
  }

  Widget _buildEmptyAlertsState() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.primary,
                size: 60,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.alerts_allClear,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.alerts_noAlertsMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _refreshAlerts,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh, size: 20),
              label: Text(
                _isRefreshing
                    ? l10n.alerts_checking
                    : l10n.alerts_checkForUpdates,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

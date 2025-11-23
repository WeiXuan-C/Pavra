import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/api/alert_preferences/alert_preferences_api.dart';
import '../../core/api/saved_route/saved_route_api.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/models/saved_route_model.dart';
import '../../data/repositories/alert_preferences_repository.dart';
import '../../data/repositories/saved_route_repository.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import './widgets/alert_card_widget.dart';
import './widgets/alert_toggle_widget.dart';
import './widgets/empty_routes_widget.dart';
import './widgets/mini_map_widget.dart';
import './widgets/radius_slider_widget.dart';
import './widgets/saved_route_card_widget.dart';
import './widgets/saved_route_form_dialog.dart';

class SafetyAlertsScreen extends StatefulWidget {
  const SafetyAlertsScreen({super.key});

  @override
  State<SafetyAlertsScreen> createState() => _SafetyAlertsScreenState();
}

class _SafetyAlertsScreenState extends State<SafetyAlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late SavedRouteRepository _routeRepository;
  late AlertPreferencesRepository _preferencesRepository;
  
  double _alertRadius = 5.0;
  bool _roadDamageEnabled = true;
  bool _constructionEnabled = true;
  bool _weatherEnabled = false;
  bool _trafficEnabled = true;
  bool _isRefreshing = false;
  bool _isLoadingRoutes = true;
  bool _isLoadingPreferences = true;
  
  List<SavedRouteModel> _savedRoutes = [];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initRepository();
      _loadPreferences();
      _loadRoutes();
      _isInitialized = true;
    }
  }

  bool _isInitialized = false;

  void _initRepository() {
    final authProvider = context.read<AuthProvider>();
    final supabaseClient = authProvider.supabaseClient;
    
    _routeRepository = SavedRouteRepository(
      SavedRouteApi(supabaseClient),
    );
    
    _preferencesRepository = AlertPreferencesRepository(
      AlertPreferencesApi(supabaseClient),
    );
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoadingPreferences = true);

    try {
      final preferences = await _preferencesRepository.getPreferences();
      if (mounted) {
        setState(() {
          _alertRadius = preferences.alertRadiusMiles;
          _roadDamageEnabled = preferences.roadDamageEnabled;
          _constructionEnabled = preferences.constructionZonesEnabled;
          _weatherEnabled = preferences.weatherHazardsEnabled;
          _trafficEnabled = preferences.trafficIncidentsEnabled;
          _isLoadingPreferences = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      if (mounted) {
        setState(() => _isLoadingPreferences = false);
      }
    }
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoadingRoutes = true);

    try {
      final routes = await _routeRepository.getSavedRoutes();
      if (mounted) {
        setState(() {
          _savedRoutes = routes;
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
      if (mounted) {
        setState(() => _isLoadingRoutes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load routes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _toggleRouteMonitoring(String routeId, bool isMonitoring) async {
    try {
      await _routeRepository.toggleRouteMonitoring(routeId, isMonitoring);
      await _loadRoutes();
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMonitoring
                  ? l10n.savedRoute_monitoringEnabled
                  : l10n.savedRoute_monitoringDisabled,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update monitoring: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRouteForm([SavedRouteModel? route]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SavedRouteFormDialog(route: route),
    );

    if (result != null) {
      try {
        if (route == null) {
          // Create new route
          await _routeRepository.createRoute(
            name: result['name'],
            fromLocationName: result['fromLocationName'],
            fromLatitude: result['fromLatitude'],
            fromLongitude: result['fromLongitude'],
            fromAddress: result['fromAddress'],
            toLocationName: result['toLocationName'],
            toLatitude: result['toLatitude'],
            toLongitude: result['toLongitude'],
            toAddress: result['toAddress'],
            isMonitoring: result['isMonitoring'],
          );
          
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.savedRoute_routeCreated)),
            );
          }
        } else {
          // Update existing route
          await _routeRepository.updateRoute(route.id, result);
          
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.savedRoute_routeUpdated)),
            );
          }
        }
        
        await _loadRoutes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save route: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteRoute(SavedRouteModel route) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.savedRoute_deleteRoute),
        content: Text(l10n.savedRoute_deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routeRepository.deleteRoute(route.id);
        await _loadRoutes();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.savedRoute_routeDeleted),
              action: SnackBarAction(
                label: l10n.alerts_undo,
                onPressed: () {
                  // TODO: Implement undo
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete route: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
        centerTitle: false,
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
          _isLoadingPreferences
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                  onChanged: (value) async {
                    setState(() => _roadDamageEnabled = value);
                    try {
                      await _preferencesRepository.updateAlertTypes(
                        roadDamageEnabled: value,
                      );
                    } catch (e) {
                      debugPrint('Error updating alert type: $e');
                    }
                  },
                ),
                AlertToggleWidget(
                  title: l10n.alerts_constructionZones,
                  iconName: 'engineering',
                  isEnabled: _constructionEnabled,
                  onChanged: (value) async {
                    setState(() => _constructionEnabled = value);
                    try {
                      await _preferencesRepository.updateAlertTypes(
                        constructionZonesEnabled: value,
                      );
                    } catch (e) {
                      debugPrint('Error updating alert type: $e');
                    }
                  },
                ),
                AlertToggleWidget(
                  title: l10n.alerts_weatherHazards,
                  iconName: 'cloud',
                  isEnabled: _weatherEnabled,
                  onChanged: (value) async {
                    setState(() => _weatherEnabled = value);
                    try {
                      await _preferencesRepository.updateAlertTypes(
                        weatherHazardsEnabled: value,
                      );
                    } catch (e) {
                      debugPrint('Error updating alert type: $e');
                    }
                  },
                ),
                AlertToggleWidget(
                  title: l10n.alerts_trafficIncidents,
                  iconName: 'traffic',
                  isEnabled: _trafficEnabled,
                  onChanged: (value) async {
                    setState(() => _trafficEnabled = value);
                    try {
                      await _preferencesRepository.updateAlertTypes(
                        trafficIncidentsEnabled: value,
                      );
                    } catch (e) {
                      debugPrint('Error updating alert type: $e');
                    }
                  },
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
                  onChanged: (value) async {
                    setState(() => _alertRadius = value);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _preferencesRepository.updateAlertRadius(value);
                    } catch (e) {
                      debugPrint('Error updating alert radius: $e');
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to save radius: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
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
          _isLoadingRoutes
              ? const Center(child: CircularProgressIndicator())
              : _savedRoutes.isEmpty
                  ? EmptyRoutesWidget(
                      onAddRoute: () => _showRouteForm(),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRoutes,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        itemCount: _savedRoutes.length + 2, // +2 for header and info
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Header
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.h,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    l10n.savedRoute_title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _showRouteForm(),
                                    icon: const Icon(Icons.add, size: 20),
                                    label: Text(l10n.savedRoute_addRoute),
                                  ),
                                ],
                              ),
                            );
                          } else if (index <= _savedRoutes.length) {
                            // Route cards
                            final route = _savedRoutes[index - 1];
                            return SavedRouteCardWidget(
                              route: route,
                              onMonitoringToggle: (isMonitoring) =>
                                  _toggleRouteMonitoring(route.id, isMonitoring),
                              onEdit: () => _showRouteForm(route),
                              onDelete: () => _deleteRoute(route),
                            );
                          } else {
                            // Info card at bottom
                            return Container(
                              margin: EdgeInsets.all(4.w),
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
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
                            );
                          }
                        },
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
                color: theme.colorScheme.primary.withAlpha(26),
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
                color: theme.colorScheme.onSurface.withAlpha(179),
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

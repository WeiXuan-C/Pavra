# 位置警报通知解决方案

## 问题描述

当前系统无法在用户开启GPS移动到附近有严重issue时发送通知。

## 根本原因

1. **缺少用户位置跟踪**：`profiles` 表没有存储用户当前位置
2. **`get_nearby_users` 函数不完整**：只返回启用警报的用户，没有地理过滤
3. **缺少位置监控机制**：没有后台服务监控用户位置变化

## 解决方案

### 方案A：实时位置跟踪 + 后台监控（推荐）

#### 1. 数据库改造

**添加位置字段到 profiles 表：**

```sql
-- 在 profiles 表添加位置跟踪字段
ALTER TABLE public.profiles
ADD COLUMN current_latitude DOUBLE PRECISION,
ADD COLUMN current_longitude DOUBLE PRECISION,
ADD COLUMN location_updated_at TIMESTAMPTZ,
ADD COLUMN location_tracking_enabled BOOLEAN DEFAULT FALSE;

-- 创建空间索引（如果使用 PostGIS）
CREATE INDEX idx_profiles_location ON public.profiles 
USING GIST (ST_MakePoint(current_longitude, current_latitude));
```

**更新 get_nearby_users 函数：**

```sql
CREATE OR REPLACE FUNCTION public.get_nearby_users(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (id UUID, distance_km DOUBLE PRECISION)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    -- Haversine formula for distance calculation
    (
      6371 * acos(
        cos(radians(lat)) * 
        cos(radians(p.current_latitude)) * 
        cos(radians(p.current_longitude) - radians(lng)) + 
        sin(radians(lat)) * 
        sin(radians(p.current_latitude))
      )
    ) AS distance_km
  FROM public.profiles p
  LEFT JOIN public.user_alert_preferences uap ON p.id = uap.user_id
  WHERE 
    -- User has location tracking enabled
    p.location_tracking_enabled = true
    -- User has current location data
    AND p.current_latitude IS NOT NULL
    AND p.current_longitude IS NOT NULL
    -- Location data is recent (within last 30 minutes)
    AND p.location_updated_at > NOW() - INTERVAL '30 minutes'
    -- User has notifications enabled
    AND p.notifications_enabled = true
    -- User has location alerts enabled
    AND (
      uap.id IS NULL
      OR uap.road_damage_enabled = true
      OR uap.construction_zones_enabled = true
      OR uap.weather_hazards_enabled = true
      OR uap.traffic_incidents_enabled = true
    )
    -- Don't notify the current user
    AND p.id != COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)
  HAVING
    -- Filter by distance
    (
      6371 * acos(
        cos(radians(lat)) * 
        cos(radians(p.current_latitude)) * 
        cos(radians(p.current_longitude) - radians(lng)) + 
        sin(radians(lat)) * 
        sin(radians(p.current_latitude))
      )
    ) <= radius_km
  ORDER BY distance_km;
END;
$$;
```

#### 2. Flutter 位置服务实现

**创建 LocationTrackingService：**

```dart
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;
  
  // Minimum distance (meters) before updating server
  static const double _minDistanceThreshold = 100.0; // 100 meters
  
  // Minimum time (seconds) between server updates
  static const int _minUpdateInterval = 60; // 1 minute

  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;

  /// Start location tracking
  Future<void> startTracking({
    required Function(Position) onLocationUpdate,
    required Function(double lat, double lng) onServerUpdate,
  }) async {
    if (_isTracking) {
      developer.log('Location tracking already active');
      return;
    }

    // Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || 
          requested == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    // Start listening to position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen(
      (Position position) async {
        _lastPosition = position;
        
        // Notify local listeners
        onLocationUpdate(position);
        
        // Check if we should update server
        if (_shouldUpdateServer(position)) {
          try {
            await onServerUpdate(position.latitude, position.longitude);
            _lastUpdateTime = DateTime.now();
            developer.log('Location updated on server: ${position.latitude}, ${position.longitude}');
          } catch (e) {
            developer.log('Failed to update location on server: $e');
          }
        }
      },
      onError: (error) {
        developer.log('Location tracking error: $error');
      },
    );

    _isTracking = true;
    developer.log('Location tracking started');
  }

  /// Check if we should update server based on distance and time thresholds
  bool _shouldUpdateServer(Position newPosition) {
    // Always update if this is the first position
    if (_lastUpdateTime == null) {
      return true;
    }

    // Check time threshold
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!).inSeconds;
    if (timeSinceLastUpdate < _minUpdateInterval) {
      return false;
    }

    // Check distance threshold
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      
      if (distance < _minDistanceThreshold) {
        return false;
      }
    }

    return true;
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    developer.log('Location tracking stopped');
  }

  /// Get current position once
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
```

**更新 UserApi 添加位置更新方法：**

```dart
/// Update user's current location
Future<void> updateCurrentLocation({
  required String userId,
  required double latitude,
  required double longitude,
}) async {
  try {
    await _db.update(
      table: _tableName,
      data: {
        'current_latitude': latitude,
        'current_longitude': longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
      },
      matchColumn: 'id',
      matchValue: userId,
    );
    
    developer.log(
      'Location updated: ($latitude, $longitude)',
      name: 'UserApi',
    );
  } catch (e, stackTrace) {
    developer.log(
      'Failed to update location',
      name: 'UserApi',
      error: e,
      stackTrace: stackTrace,
    );
    // Don't throw - location update failures shouldn't disrupt app
  }
}

/// Enable/disable location tracking for user
Future<void> setLocationTrackingEnabled({
  required String userId,
  required bool enabled,
}) async {
  await _db.update(
    table: _tableName,
    data: {'location_tracking_enabled': enabled},
    matchColumn: 'id',
    matchValue: userId,
  );
}
```

#### 3. 后台位置监控服务

**创建 NearbyIssueMonitorService：**

```dart
import 'dart:async';
import 'dart:developer' as developer;
import '../api/report_issue/report_issue_api.dart';
import '../services/notification_helper_service.dart';
import 'location_tracking_service.dart';

class NearbyIssueMonitorService {
  static final NearbyIssueMonitorService _instance = NearbyIssueMonitorService._internal();
  factory NearbyIssueMonitorService() => _instance;
  NearbyIssueMonitorService._internal();

  final LocationTrackingService _locationService = LocationTrackingService();
  ReportIssueApi? _reportApi;
  NotificationHelperService? _notificationHelper;
  
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  
  // Check for nearby issues every 2 minutes
  static const Duration _checkInterval = Duration(minutes: 2);
  
  // Alert radius in km
  static const double _alertRadiusKm = 5.0;
  
  // Track notified issues to avoid duplicate notifications
  final Set<String> _notifiedIssueIds = {};

  void initialize({
    required ReportIssueApi reportApi,
    required NotificationHelperService notificationHelper,
  }) {
    _reportApi = reportApi;
    _notificationHelper = notificationHelper;
  }

  /// Start monitoring for nearby issues
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      developer.log('Already monitoring nearby issues');
      return;
    }

    if (_reportApi == null || _notificationHelper == null) {
      throw Exception('NearbyIssueMonitorService not initialized');
    }

    _isMonitoring = true;
    
    // Start periodic checks
    _monitorTimer = Timer.periodic(_checkInterval, (_) => _checkNearbyIssues());
    
    // Do initial check
    await _checkNearbyIssues();
    
    developer.log('Started monitoring nearby issues');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    _notifiedIssueIds.clear();
    developer.log('Stopped monitoring nearby issues');
  }

  /// Check for nearby issues and send notifications
  Future<void> _checkNearbyIssues() async {
    try {
      final position = _locationService.lastPosition;
      if (position == null) {
        developer.log('No location available for nearby issue check');
        return;
      }

      developer.log('Checking for nearby issues at (${position.latitude}, ${position.longitude})');

      // Search for nearby issues
      final nearbyIssues = await _reportApi!.searchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _alertRadiusKm,
        limit: 20,
      );

      // Filter for high severity issues that haven't been notified
      final criticalIssues = nearbyIssues.where((issue) {
        return (issue.severity == 'high' || issue.severity == 'critical') &&
               !_notifiedIssueIds.contains(issue.id);
      }).toList();

      if (criticalIssues.isEmpty) {
        developer.log('No new critical issues nearby');
        return;
      }

      developer.log('Found ${criticalIssues.length} new critical issues nearby');

      // Send notifications for each critical issue
      for (final issue in criticalIssues) {
        try {
          await _notificationHelper!.notifyNearbyUsers(
            reportId: issue.id,
            title: issue.title ?? 'Road Issue',
            latitude: issue.latitude!,
            longitude: issue.longitude!,
            severity: issue.severity,
            nearbyUserIds: [_reportApi!.getCurrentUserId()!],
          );
          
          // Mark as notified
          _notifiedIssueIds.add(issue.id);
          
          developer.log('Sent notification for issue: ${issue.id}');
        } catch (e) {
          developer.log('Failed to send notification for issue ${issue.id}: $e');
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error checking nearby issues',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear notified issues cache (call when user moves significantly)
  void clearNotifiedCache() {
    _notifiedIssueIds.clear();
    developer.log('Cleared notified issues cache');
  }
}
```

#### 4. 集成到应用

**在 main.dart 或 app 初始化时：**

```dart
// Initialize services
final locationService = LocationTrackingService();
final nearbyIssueMonitor = NearbyIssueMonitorService();
final userApi = UserApi(notificationHelper: notificationHelper);

// Initialize monitor
nearbyIssueMonitor.initialize(
  reportApi: reportApi,
  notificationHelper: notificationHelper,
);

// Start location tracking when user enables it
Future<void> enableLocationTracking() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  // Enable in database
  await userApi.setLocationTrackingEnabled(
    userId: userId,
    enabled: true,
  );

  // Start tracking
  await locationService.startTracking(
    onLocationUpdate: (position) {
      // Handle local location updates (e.g., update map)
      print('Location: ${position.latitude}, ${position.longitude}');
    },
    onServerUpdate: (lat, lng) async {
      // Update server with new location
      await userApi.updateCurrentLocation(
        userId: userId,
        latitude: lat,
        longitude: lng,
      );
    },
  );

  // Start monitoring for nearby issues
  await nearbyIssueMonitor.startMonitoring();
}

// Stop tracking when user disables it
Future<void> disableLocationTracking() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  await userApi.setLocationTrackingEnabled(
    userId: userId,
    enabled: false,
  );

  await locationService.stopTracking();
  nearbyIssueMonitor.stopMonitoring();
}
```

### 方案B：简化方案 - 仅在地图页面检查

如果不想实现完整的后台位置跟踪，可以简化为：

1. 只在用户打开地图页面时检查附近issue
2. 当用户移动地图时检查新区域的issue
3. 显示本地通知/警告横幅

```dart
class MapScreen extends StatefulWidget {
  // ... existing code

  void _checkNearbyIssues(LatLng center) async {
    final nearbyIssues = await reportApi.searchNearby(
      latitude: center.latitude,
      longitude: center.longitude,
      radiusKm: 5.0,
    );

    final criticalIssues = nearbyIssues.where((issue) =>
      issue.severity == 'high' || issue.severity == 'critical'
    ).toList();

    if (criticalIssues.isNotEmpty) {
      // Show local alert
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${criticalIssues.length} critical issues nearby!'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to issue list
            },
          ),
        ),
      );
    }
  }
}
```

## 推荐实施步骤

1. **Phase 1：数据库改造**
   - 添加位置字段到 profiles 表
   - 更新 get_nearby_users 函数
   - 测试数据库函数

2. **Phase 2：位置服务**
   - 实现 LocationTrackingService
   - 添加位置更新 API
   - 测试位置跟踪

3. **Phase 3：监控服务**
   - 实现 NearbyIssueMonitorService
   - 集成到应用
   - 测试通知触发

4. **Phase 4：优化**
   - 添加电池优化
   - 实现后台位置更新
   - 添加用户设置界面

## 注意事项

1. **电池消耗**：持续位置跟踪会消耗电池，需要优化
2. **隐私**：需要明确告知用户位置跟踪用途
3. **权限**：需要请求位置权限（前台和后台）
4. **性能**：避免频繁的数据库更新和通知
5. **成本**：考虑数据库查询和存储成本

## 依赖包

```yaml
dependencies:
  geolocator: ^10.1.0  # 位置服务
  permission_handler: ^11.0.1  # 权限管理
```

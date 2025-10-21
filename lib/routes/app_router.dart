import 'package:flutter/material.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/camera_detection_screen/camera_detection_screen.dart';
import '../presentation/map_view_screen/map_view_screen.dart';
import '../presentation/report_submission_screen/report_submission_screen.dart';
import '../presentation/safety_alerts_screen/safety_alerts_screen.dart';
import '../presentation/notification_screen/notification_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import 'app_routes.dart';

/// Configures the app's routing by mapping route names to screen widgets
class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.authentication: (context) => const AuthenticationScreen(),
    AppRoutes.home: (context) => const HomeScreen(),
    AppRoutes.cameraDetection: (context) => const CameraDetectionScreen(),
    AppRoutes.mapView: (context) => const MapViewScreen(),
    AppRoutes.reportSubmission: (context) => const ReportSubmissionScreen(),
    AppRoutes.safetyAlerts: (context) => const SafetyAlertsScreen(),
    AppRoutes.notifications: (context) => const NotificationScreen(),
    AppRoutes.profile: (context) => const ProfileScreen(),
    AppRoutes.settings: (context) => const SettingsScreen(),
  };
}

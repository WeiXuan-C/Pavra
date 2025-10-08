import 'package:flutter/material.dart';
import '../presentation/report_submission_screen/report_submission_screen.dart';
import '../presentation/safety_alerts_screen/safety_alerts_screen.dart';
import '../presentation/map_view_screen/map_view_screen.dart';
import '../presentation/camera_detection_screen/camera_detection_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String reportSubmission = '/report-submission-screen';
  static const String safetyAlerts = '/safety-alerts-screen';
  static const String mapView = '/map-view-screen';
  static const String cameraDetection = '/camera-detection-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const CameraDetectionScreen(),
    reportSubmission: (context) => const ReportSubmissionScreen(),
    safetyAlerts: (context) => const SafetyAlertsScreen(),
    mapView: (context) => const MapViewScreen(),
    cameraDetection: (context) => const CameraDetectionScreen(),
    // TODO: Add your other routes here
  };
}

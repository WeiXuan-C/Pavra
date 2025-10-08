import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/detection_history_panel.dart';
import './widgets/detection_metrics_sheet.dart';
import './widgets/status_bar_widget.dart';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen>
    with TickerProviderStateMixin {
  // Camera related
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _isBurstMode = false;

  // Detection related
  bool _isDetectionActive = true;
  Timer? _detectionTimer;
  final List<Map<String, dynamic>> _detectedIssues = [];
  final List<Map<String, dynamic>> _recentDetections = [];
  final Map<String, int> _detectionStats = {
    'pothole': 0,
    'crack': 0,
    'obstacle': 0,
  };

  // GPS related
  final bool _isGpsActive = true;
  final String _gpsAccuracy = 'High (±3m)';

  // UI related
  bool _isHistoryPanelOpen = false;
  int _currentTabIndex = 0;
  TabController? _tabController;

  // Animation controllers
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeCamera();
    _startDetectionSimulation();
    _generateMockDetections();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _pulseController!.repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await _requestCameraPermission()) {
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      }
    } catch (e) {
      debugPrint('Settings error: $e');
    }
  }

  void _startDetectionSimulation() {
    _detectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_isDetectionActive && mounted) {
        _simulateDetection();
      }
    });
  }

  void _simulateDetection() {
    final random = Random();
    if (random.nextDouble() < 0.3) {
      // 30% chance of detection
      final types = ['pothole', 'crack', 'obstacle'];
      final type = types[random.nextInt(types.length)];
      final confidence = 0.6 + (random.nextDouble() * 0.4);

      final detection = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'confidence': confidence,
        'x': random.nextDouble() * 0.6 + 0.2,
        'y': random.nextDouble() * 0.6 + 0.2,
        'width': 0.1 + random.nextDouble() * 0.1,
        'height': 0.1 + random.nextDouble() * 0.1,
        'timestamp': DateTime.now(),
        'location': _generateMockLocation(),
        'imageUrl': _generateMockImageUrl(),
      };

      setState(() {
        _detectedIssues.add(detection);
        _recentDetections.insert(0, detection);
        if (_recentDetections.length > 10) {
          _recentDetections.removeLast();
        }
        _detectionStats[type] = (_detectionStats[type] ?? 0) + 1;
      });

      // Remove detection after 5 seconds
      Timer(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _detectedIssues.removeWhere((d) => d['id'] == detection['id']);
          });
        }
      });

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _generateMockDetections() {
    final mockDetections = [
      {
        'id': '1',
        'type': 'pothole',
        'confidence': 0.89,
        'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
        'location': 'Main Street & 5th Avenue',
        'imageUrl':
            'https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg',
      },
      {
        'id': '2',
        'type': 'crack',
        'confidence': 0.76,
        'timestamp': DateTime.now().subtract(Duration(minutes: 12)),
        'location': 'Highway 101, Mile 23',
        'imageUrl':
            'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg',
      },
      {
        'id': '3',
        'type': 'obstacle',
        'confidence': 0.92,
        'timestamp': DateTime.now().subtract(Duration(minutes: 18)),
        'location': 'Oak Street Bridge',
        'imageUrl':
            'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg',
      },
    ];

    setState(() {
      _recentDetections.addAll(mockDetections);
      _detectionStats['pothole'] = 3;
      _detectionStats['crack'] = 2;
      _detectionStats['obstacle'] = 1;
    });
  }

  String _generateMockLocation() {
    final locations = [
      'Main Street & 1st Ave',
      'Highway 101, Mile 15',
      'Oak Street Bridge',
      'Downtown Plaza',
      'Industrial Blvd',
      'Riverside Drive',
    ];
    return locations[Random().nextInt(locations.length)];
  }

  String _generateMockImageUrl() {
    final urls = [
      'https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg',
      'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg',
      'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg',
      'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg',
    ];
    return urls[Random().nextInt(urls.length)];
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();

      // Simulate processing time
      await Future.delayed(Duration(milliseconds: 500));

      // Add to recent detections with current detected issues
      if (_detectedIssues.isNotEmpty) {
        final captureDetection = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'captured',
          'confidence': 1.0,
          'timestamp': DateTime.now(),
          'location': _generateMockLocation(),
          'imageUrl': photo.path,
          'detectedIssues': List.from(_detectedIssues),
        };

        setState(() {
          _recentDetections.insert(0, captureDetection);
          if (_recentDetections.length > 10) {
            _recentDetections.removeLast();
          }
        });
      }

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured successfully'),
            backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _openGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Simulate AI processing
        await Future.delayed(Duration(milliseconds: 1000));

        final galleryDetection = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'pothole',
          'confidence': 0.85,
          'timestamp': DateTime.now(),
          'location': 'Gallery Image',
          'imageUrl': image.path,
        };

        setState(() {
          _recentDetections.insert(0, galleryDetection);
          _detectionStats['pothole'] = (_detectionStats['pothole'] ?? 0) + 1;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image processed successfully'),
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

  void _toggleFlash() {
    if (kIsWeb) return; // Flash not supported on web

    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    try {
      _cameraController?.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  void _toggleDetection() {
    setState(() {
      _isDetectionActive = !_isDetectionActive;
    });

    if (_isDetectionActive) {
      _startDetectionSimulation();
    } else {
      _detectionTimer?.cancel();
      setState(() {
        _detectedIssues.clear();
      });
    }
  }

  void _toggleBurstMode() {
    setState(() {
      _isBurstMode = !_isBurstMode;
    });

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBurstMode ? 'Burst mode activated' : 'Burst mode deactivated',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onCrosshairTap() {
    HapticFeedback.selectionClick();
    // Could trigger manual focus or detection
  }

  void _onDetectionTap(Map<String, dynamic> detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detection Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${detection['type']}'),
            Text('Confidence: ${(detection['confidence'] * 100).toInt()}%'),
            Text('Location: ${detection['location']}'),
            Text('Time: ${detection['timestamp']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/report-submission-screen');
            },
            child: Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detectionTimer?.cancel();
    _tabController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: AppTheme.lightTheme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });

                  // Navigate to other screens
                  switch (index) {
                    case 1:
                      Navigator.pushNamed(context, '/map-view-screen');
                      break;
                    case 2:
                      Navigator.pushNamed(context, '/report-submission-screen');
                      break;
                    case 3:
                      Navigator.pushNamed(context, '/safety-alerts-screen');
                      break;
                  }
                },
                tabs: [
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: _currentTabIndex == 0
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      size: 24,
                    ),
                    text: 'Camera',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'map',
                      color: _currentTabIndex == 1
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      size: 24,
                    ),
                    text: 'Map',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'report',
                      color: _currentTabIndex == 2
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      size: 24,
                    ),
                    text: 'Reports',
                  ),
                  Tab(
                    icon: CustomIconWidget(
                      iconName: 'person',
                      color: _currentTabIndex == 3
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      size: 24,
                    ),
                    text: 'Profile',
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Status Bar
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: StatusBarWidget(
                          isGpsActive: _isGpsActive,
                          gpsAccuracy: _gpsAccuracy,
                          isDetectionActive: _isDetectionActive,
                          onDetectionToggle: _toggleDetection,
                        ),
                      ),

                      // Camera Preview
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: CameraPreviewWidget(
                            cameraController: _cameraController,
                            isDetectionActive: _isDetectionActive,
                            detectedIssues: _detectedIssues,
                            onCrosshairTap: _onCrosshairTap,
                          ),
                        ),
                      ),

                      // Camera Controls
                      CameraControlsWidget(
                        onCapturePressed: _capturePhoto,
                        onGalleryPressed: _openGallery,
                        onFlashToggle: _toggleFlash,
                        isFlashOn: _isFlashOn,
                        isCapturing: _isCapturing,
                        isBurstMode: _isBurstMode,
                        onBurstModeToggle: _toggleBurstMode,
                      ),
                    ],
                  ),

                  // History Panel Button
                  Positioned(
                    right: 4.w,
                    top: 20.h,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isHistoryPanelOpen = !_isHistoryPanelOpen;
                        });
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnimation!,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _recentDetections.isNotEmpty
                                ? _pulseAnimation!.value
                                : 1.0,
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.lightTheme.colorScheme.shadow,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'history',
                                    color: AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onPrimary,
                                    size: 24,
                                  ),
                                  if (_recentDetections.isNotEmpty)
                                    Positioned(
                                      top: -1,
                                      right: -1,
                                      child: Container(
                                        width: 5.w,
                                        height: 5.w,
                                        decoration: BoxDecoration(
                                          color: AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${_recentDetections.length > 9 ? '9+' : _recentDetections.length}',
                                            style: AppTheme
                                                .lightTheme
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 8.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Metrics Button
                  Positioned(
                    right: 4.w,
                    top: 30.h,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DetectionMetricsSheet(
                            detectionHistory: _recentDetections,
                            detectionStats: _detectionStats,
                            onClose: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.shadow,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomIconWidget(
                          iconName: 'analytics',
                          color: AppTheme.lightTheme.colorScheme.onSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // History Panel
                  if (_isHistoryPanelOpen)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: DetectionHistoryPanel(
                        recentDetections: _recentDetections,
                        onClose: () {
                          setState(() {
                            _isHistoryPanelOpen = false;
                          });
                        },
                        onDetectionTap: _onDetectionTap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

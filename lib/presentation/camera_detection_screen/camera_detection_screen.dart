import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/audio_alert_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/network_status_service.dart';
import '../../data/models/detection_exception.dart';
import '../../data/models/detection_model.dart';
import '../../data/models/detection_type.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import './ai_detection_provider.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/detection_alert_widget.dart';
import './widgets/detection_history_panel.dart';
import './widgets/queue_status_widget.dart';
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

  // GPS related
  bool _isGpsActive = false;
  String _gpsAccuracy = 'Searching...';
  double? _latitude;
  double? _longitude;

  // Services
  final LocationService _locationService = LocationService();
  final AudioAlertService _audioAlertService = AudioAlertService();
  final NetworkStatusService _networkStatusService = NetworkStatusService();

  // UI related
  bool _isHistoryPanelOpen = false;
  DetectionModel? _currentAlert;

  // Animation controllers
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeCamera();
    _initializeGPS();
    _initializeAudioService();
    _initializeNetworkMonitoring();
    _startAutoDetection();
  }

  Future<void> _initializeAudioService() async {
    await _audioAlertService.initialize();
  }

  Future<void> _initializeNetworkMonitoring() async {
    try {
      await _networkStatusService.initialize();
      
      // Listen to network status changes
      _networkStatusService.statusStream.listen((isConnected) {
        if (isConnected && mounted) {
          // Auto-retry queued detections when network is restored
          _autoRetryQueue();
        }
      });
    } catch (e) {
      debugPrint('Error initializing network monitoring: $e');
    }
  }

  Future<void> _autoRetryQueue() async {
    try {
      final aiProvider = context.read<AiDetectionProvider>();
      final successCount = await aiProvider.retryQueuedDetections();
      
      if (successCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully processed $successCount queued detection(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-retrying queue: $e');
    }
  }

  Future<void> _initializeGPS() async {
    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null && mounted) {
        setState(() {
          _isGpsActive = true;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _gpsAccuracy = 'High (±${position.accuracy.toInt()}m)';
        });
      } else if (mounted) {
        setState(() {
          _isGpsActive = false;
          _gpsAccuracy = 'Unavailable';
        });
      }
    } catch (e) {
      debugPrint('GPS error: $e');
      if (mounted) {
        setState(() {
          _isGpsActive = false;
          _gpsAccuracy = 'Unavailable';
        });
      }
    }
  }

  void _initializeControllers() {
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

  void _startAutoDetection() {
    // Cancel existing timer if any
    _detectionTimer?.cancel();
    
    // Auto-detect every 10 seconds when detection is active (increased from 5s)
    // Only trigger if not already processing
    _detectionTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_isDetectionActive && mounted && !_isCapturing) {
        final aiProvider = context.read<AiDetectionProvider>();
        // Don't trigger if already processing
        if (!aiProvider.isProcessing) {
          _captureAndProcessFrame(isManual: false);
        } else {
          debugPrint('Skipping auto-detection: previous detection still processing');
        }
      }
    });
  }

  Future<void> _capturePhoto() async {
    await _captureAndProcessFrame(isManual: true);
  }

  Future<void> _captureAndProcessFrame({bool isManual = false}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture photo
      final XFile photo = await _cameraController!.takePicture();
      
      // Store the photo for potential report submission
      _lastCapturedPhoto = photo;

      if (!mounted) return;

      // Get user ID
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get GPS coordinates
      if (_latitude == null || _longitude == null) {
        await _initializeGPS();
      }

      if (!mounted) return;

      final latitude = _latitude ?? 0.0;
      final longitude = _longitude ?? 0.0;

      // Process with AI with timeout protection
      final aiProvider = context.read<AiDetectionProvider>();
      
      // Add a timeout wrapper to prevent indefinite waiting
      await aiProvider.processFrame(photo, latitude, longitude, userId).timeout(
        Duration(seconds: 35), // Slightly longer than API timeout
        onTimeout: () {
          throw DetectionException.timeout(
            'Detection is taking too long. Please try again.',
          );
        },
      );

      // Get latest detection
      final latestDetection = aiProvider.latestDetection;

      if (latestDetection != null) {
        // Play audio alert for high severity
        if (aiProvider.shouldPlaySound(latestDetection)) {
          _audioAlertService.playAlertSound();
        }

        // Haptic feedback
        if (latestDetection.issueDetected) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }

        // Only show alert if issue is detected
        if (latestDetection.issueDetected && latestDetection.type != DetectionType.normal) {
          setState(() {
            _currentAlert = latestDetection;
          });

          // Auto-dismiss alert after 15 seconds
          Timer(Duration(seconds: 15), () {
            if (mounted && _currentAlert?.id == latestDetection.id) {
              setState(() {
                _currentAlert = null;
              });
            }
          });
        }
      }
    } on DetectionException catch (e) {
      debugPrint('Detection exception: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error during detection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      if (image != null && mounted) {
        // Get user ID
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.user?.id;

        if (userId == null) {
          throw Exception('User not authenticated');
        }

        // Get GPS coordinates
        if (_latitude == null || _longitude == null) {
          await _initializeGPS();
        }

        if (!mounted) return;

        final latitude = _latitude ?? 0.0;
        final longitude = _longitude ?? 0.0;

        // Process with AI
        final aiProvider = context.read<AiDetectionProvider>();
        await aiProvider.processFrame(image, latitude, longitude, userId);

        // Get latest detection
        final latestDetection = aiProvider.latestDetection;

        if (latestDetection != null && latestDetection.issueDetected) {
          setState(() {
            _currentAlert = latestDetection;
          });

          // Auto-dismiss after 15 seconds
          Timer(Duration(seconds: 15), () {
            if (mounted && _currentAlert?.id == latestDetection.id) {
              setState(() {
                _currentAlert = null;
              });
            }
          });
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.camera_imageProcessed)),
          );
        }
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing gallery image'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      _startAutoDetection();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-detection enabled (every 10s)'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _detectionTimer?.cancel();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-detection disabled. Use capture button for manual detection.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _toggleBurstMode() {
    setState(() {
      _isBurstMode = !_isBurstMode;
    });

    HapticFeedback.mediumImpact();

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBurstMode
              ? l10n.camera_burstModeActivated
              : l10n.camera_burstModeDeactivated,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onCrosshairTap() {
    HapticFeedback.selectionClick();
    // Could trigger manual focus or detection
  }

  void _onDetectionTap(DetectionModel detection) {
    // Show detection details and allow submitting report
    setState(() {
      _currentAlert = detection;
    });
  }

  void _dismissAlert() {
    setState(() {
      _currentAlert = null;
    });
  }

  // Store the last captured photo for report submission
  XFile? _lastCapturedPhoto;

  void _submitReportFromAlert() {
    if (_currentAlert == null) return;

    // Navigate to manual report screen with detection data
    Navigator.pushNamed(
      context,
      '/manual-report-screen',
      arguments: {
        'detectionData': _currentAlert,
        'latitude': _latitude,
        'longitude': _longitude,
        'fromAiDetection': true,
        'capturedPhoto': _lastCapturedPhoto, // Pass the photo file
      },
    ).then((_) {
      // Dismiss the alert after returning from manual report screen
      if (mounted) {
        _dismissAlert();
      }
    });
  }

  @override
  void dispose() {
    // Dispose camera controller with error handling
    try {
      _cameraController?.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }

    _detectionTimer?.cancel();
    _pulseController?.dispose();
    _audioAlertService.dispose();
    _networkStatusService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.camera_title,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Status Bar
                    Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        children: [
                          StatusBarWidget(
                            isGpsActive: _isGpsActive,
                            gpsAccuracy: _gpsAccuracy,
                            isDetectionActive: _isDetectionActive,
                            onDetectionToggle: _toggleDetection,
                          ),

                          // Processing indicator (non-blocking)
                          Consumer<AiDetectionProvider>(
                            builder: (context, aiProvider, child) {
                              if (!aiProvider.isProcessing) {
                                return SizedBox.shrink();
                              }

                              return Container(
                                margin: EdgeInsets.only(top: 1.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 0.8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Analyzing... (max 30s)',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Queue Status Widget
                    Consumer<AiDetectionProvider>(
                      builder: (context, aiProvider, child) {
                        if (aiProvider.queueSize == 0) {
                          return SizedBox.shrink();
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: QueueStatusWidget(
                            queueSize: aiProvider.queueSize,
                            onRetry: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              try {
                                final successCount =
                                    await aiProvider.retryQueuedDetections();
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Successfully processed $successCount detection(s)',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to retry queue'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),

                    // Camera Preview
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: CameraPreviewWidget(
                          cameraController: _cameraController,
                          isDetectionActive: _isDetectionActive,
                          detectedIssues: [],
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
                  child: Consumer<AiDetectionProvider>(
                    builder: (context, aiProvider, child) {
                      final historyCount = aiProvider.detectionHistory.length;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _isHistoryPanelOpen = !_isHistoryPanelOpen;
                          });
                        },
                        child: AnimatedBuilder(
                          animation: _pulseAnimation!,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: historyCount > 0
                                  ? _pulseAnimation!.value
                                  : 1.0,
                              child: Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.shadow,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'history',
                                      color: theme.colorScheme.onPrimary,
                                      size: 24,
                                    ),
                                    if (historyCount > 0)
                                      Positioned(
                                        top: -1,
                                        right: -1,
                                        child: Container(
                                          width: 5.w,
                                          height: 5.w,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${historyCount > 9 ? '9+' : historyCount}',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.onError,
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
                      );
                    },
                  ),
                ),

                // Detection Alert Widget
                if (_currentAlert != null)
                  Positioned(
                    top: 12.h,
                    left: 4.w,
                    right: 4.w,
                    child: Consumer<AiDetectionProvider>(
                      builder: (context, aiProvider, child) {
                        if (_currentAlert == null) return SizedBox.shrink();

                        return DetectionAlertWidget(
                          detection: _currentAlert!,
                          alertColor: aiProvider.getAlertColor(_currentAlert!),
                          onDismiss: _dismissAlert,
                          onSubmitReport: _submitReportFromAlert,
                        );
                      },
                    ),
                  ),

                // History Panel
                if (_isHistoryPanelOpen)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: DetectionHistoryPanel(
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
    );
  }
}

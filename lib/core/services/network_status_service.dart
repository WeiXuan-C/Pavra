import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network Status Service
/// Monitors network connectivity changes and provides status updates
///
/// Features:
/// - Real-time connectivity monitoring
/// - Stream of connectivity status changes
/// - Check current connectivity status
class NetworkStatusService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  bool _isInitialized = false;

  /// Stream of network status changes
  /// Emits true when connected, false when disconnected
  Stream<bool> get statusStream => _statusController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log(
        'NetworkStatusService already initialized',
        name: 'NetworkStatusService',
      );
      return;
    }

    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isConnected = _isConnectionAvailable(result);
      
      developer.log(
        'Initial network status: ${_isConnected ? "connected" : "disconnected"}',
        name: 'NetworkStatusService',
      );

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          developer.log(
            'Error listening to connectivity changes: $error',
            name: 'NetworkStatusService',
            error: error,
          );
        },
      );

      _isInitialized = true;
    } catch (e) {
      developer.log(
        'Error initializing NetworkStatusService: $e',
        name: 'NetworkStatusService',
        error: e,
      );
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _isConnectionAvailable(results);

    developer.log(
      'Connectivity changed: ${_isConnected ? "connected" : "disconnected"} (results: $results)',
      name: 'NetworkStatusService',
    );

    // Only emit if status actually changed
    if (wasConnected != _isConnected) {
      _statusController.add(_isConnected);
      
      developer.log(
        'Network status changed: ${wasConnected ? "connected" : "disconnected"} -> ${_isConnected ? "connected" : "disconnected"}',
        name: 'NetworkStatusService',
      );
    }
  }

  /// Check if any connection is available
  bool _isConnectionAvailable(List<ConnectivityResult> results) {
    // Consider connected if any result is not 'none'
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Manually check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = _isConnectionAvailable(result);
      return _isConnected;
    } catch (e) {
      developer.log(
        'Error checking connectivity: $e',
        name: 'NetworkStatusService',
        error: e,
      );
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _isInitialized = false;
    
    developer.log(
      'NetworkStatusService disposed',
      name: 'NetworkStatusService',
    );
  }
}

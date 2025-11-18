import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Audio Alert Service
/// Handles audio playback for detection alerts
///
/// Plays warning sounds for high-severity detections (red alerts)
class AudioAlertService {
  static final AudioAlertService _instance = AudioAlertService._internal();
  factory AudioAlertService() => _instance;
  AudioAlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio mode for alerts
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      
      _isInitialized = true;
      developer.log(
        'AudioAlertService initialized',
        name: 'AudioAlertService',
      );
    } catch (e) {
      developer.log(
        'Error initializing audio service: $e',
        name: 'AudioAlertService',
        error: e,
      );
    }
  }

  /// Play alert sound for high-severity detections
  /// 
  /// Uses system notification sound as a fallback since we don't have
  /// a custom sound asset yet. In production, this should play a custom
  /// alert sound from assets.
  Future<void> playAlertSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Play system notification sound
      // Note: In production, replace this with a custom sound asset:
      // await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
      
      // For now, use haptic feedback as an alternative
      await HapticFeedback.heavyImpact();
      
      // Wait a bit and do another haptic for emphasis
      await Future.delayed(Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();

      developer.log(
        'Alert sound played (haptic feedback)',
        name: 'AudioAlertService',
      );
    } catch (e) {
      developer.log(
        'Error playing alert sound: $e',
        name: 'AudioAlertService',
        error: e,
      );
    }
  }

  /// Play alert sound from asset
  /// 
  /// Use this method when a custom sound asset is available
  /// 
  /// Parameters:
  /// - [assetPath]: Path to the sound asset (e.g., 'sounds/alert.mp3')
  Future<void> playAlertSoundFromAsset(String assetPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Play the sound from assets
      await _audioPlayer.play(AssetSource(assetPath));

      developer.log(
        'Alert sound played from asset: $assetPath',
        name: 'AudioAlertService',
      );
    } catch (e) {
      developer.log(
        'Error playing alert sound from asset: $e',
        name: 'AudioAlertService',
        error: e,
      );
      
      // Fallback to haptic feedback
      await HapticFeedback.heavyImpact();
    }
  }

  /// Stop any currently playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      developer.log(
        'Error stopping sound: $e',
        name: 'AudioAlertService',
        error: e,
      );
    }
  }

  /// Dispose of the audio player
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}

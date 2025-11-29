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
  /// Tries to play custom sound from assets/sounds/alert.mp3
  /// Falls back to haptic feedback if sound file is not available
  Future<void> playAlertSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Try to play custom alert sound
      try {
        await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
        
        developer.log(
          'Alert sound played from asset',
          name: 'AudioAlertService',
        );
      } catch (assetError) {
        // Sound file not found, use haptic feedback as fallback
        developer.log(
          'Alert sound file not found, using haptic feedback: $assetError',
          name: 'AudioAlertService',
        );
        
        await HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        
        developer.log(
          'Alert played (haptic feedback fallback)',
          name: 'AudioAlertService',
        );
      }
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

  /// Play notification sound (lighter than alert sound)
  /// 
  /// Used for general notifications, less urgent than alerts
  /// Tries to play custom notification sound, falls back to light haptic
  Future<void> playNotificationSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Try to play custom notification sound
      try {
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
        
        developer.log(
          'Notification sound played from asset',
          name: 'AudioAlertService',
        );
      } catch (assetError) {
        // Sound file not found, use light haptic feedback as fallback
        developer.log(
          'Notification sound file not found, using haptic feedback: $assetError',
          name: 'AudioAlertService',
        );
        
        // Single light haptic for notifications (less intense than alerts)
        await HapticFeedback.lightImpact();
        
        developer.log(
          'Notification played (haptic feedback fallback)',
          name: 'AudioAlertService',
        );
      }
    } catch (e) {
      developer.log(
        'Error playing notification sound: $e',
        name: 'AudioAlertService',
        error: e,
      );
    }
  }

  /// Stop any currently playing sound
  Future<void> stopSound() async {
    if (!_isInitialized) return;
    
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
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      // Stop any playing sound first
      await _audioPlayer.stop();
      
      // Small delay to ensure stop completes
      await Future.delayed(Duration(milliseconds: 100));
      
      // Release and dispose the player
      await _audioPlayer.release();
      await _audioPlayer.dispose();
      
      _isInitialized = false;
      
      developer.log(
        'AudioAlertService disposed successfully',
        name: 'AudioAlertService',
      );
    } catch (e) {
      developer.log(
        'Error disposing audio service: $e',
        name: 'AudioAlertService',
        error: e,
      );
      // Mark as not initialized even if disposal fails
      _isInitialized = false;
    }
  }
}

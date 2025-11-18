# Alert Sounds

This directory should contain audio files for detection alerts.

## Required Sound Files

### alert.mp3
- **Purpose**: High-severity detection alert sound
- **Duration**: 1-2 seconds
- **Format**: MP3 or WAV
- **Volume**: Moderate (will be played at system volume)
- **Characteristics**: Clear, attention-grabbing but not jarring

## Usage

To add a custom alert sound:

1. Add your sound file to this directory (e.g., `alert.mp3`)
2. Update `lib/core/services/audio_alert_service.dart` to use the asset:
   ```dart
   await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
   ```

## Current Implementation

Currently, the app uses haptic feedback (vibration) as a fallback since no custom sound asset is provided. This works well for mobile devices and provides immediate tactile feedback for high-severity alerts.

## Recommended Sound Sources

- Free sound libraries: Freesound.org, Zapsplat.com
- Create custom sounds using audio editing software
- Use system notification sounds as reference

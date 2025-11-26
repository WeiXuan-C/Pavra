# Notification Sound Files

This directory contains custom notification sound files for the OneSignal notification system.

## Required Files

The following .wav audio files should be placed in this directory:

1. **alert.wav** - Critical alert sound (high priority notifications)
   - Used for: Alert-type notifications
   - Characteristics: Urgent, attention-grabbing tone
   - Duration: 1-2 seconds recommended

2. **warning.wav** - Warning sound (medium priority notifications)
   - Used for: Warning-type notifications
   - Characteristics: Noticeable but less urgent than alert
   - Duration: 1-2 seconds recommended

3. **success.wav** - Success sound (normal priority notifications)
   - Used for: Success-type notifications
   - Characteristics: Pleasant, positive tone
   - Duration: 0.5-1 second recommended

4. **default.wav** - Default notification sound
   - Used for: Info and general notifications
   - Characteristics: Standard notification tone
   - Duration: 1 second recommended

## Audio Specifications

- Format: WAV (Waveform Audio File Format)
- Sample Rate: 44.1 kHz or 48 kHz
- Bit Depth: 16-bit
- Channels: Mono or Stereo
- File Size: Keep under 100KB for optimal performance

## Usage

These sound files are referenced in the OneSignal notification payload:

```dart
// Example usage in notification creation
await notificationAPI.createNotification(
  title: 'Alert',
  message: 'Critical issue detected',
  type: 'alert',
  sound: 'alert', // References alert.wav
);
```

## Android Resource Naming

Android requires resource files to use lowercase letters, numbers, and underscores only. The .wav extension is automatically handled by the Android resource system.

## Testing

To test the sounds:
1. Send a test notification with each sound type
2. Verify the correct sound plays on the device
3. Test with device in different states (silent, vibrate, normal)

## Fallback Behavior

If a specified sound file is missing, the system will fall back to the device's default notification sound.

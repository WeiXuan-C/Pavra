# iOS Notification Sound Files

This directory contains custom notification sound files for the OneSignal notification system on iOS.

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

## iOS Audio Specifications

- Format: WAV (Linear PCM) or CAF (Core Audio Format)
- Sample Rate: 44.1 kHz or 48 kHz
- Bit Depth: 16-bit
- Channels: Mono or Stereo
- Duration: Maximum 30 seconds (iOS limitation)
- File Size: Keep under 100KB for optimal performance

## Adding to Xcode Project

After placing the sound files in this directory, you must add them to the Xcode project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on the `Runner` folder in the project navigator
3. Select "Add Files to Runner..."
4. Navigate to `ios/Runner/Resources/`
5. Select all .wav files
6. Ensure "Copy items if needed" is checked
7. Ensure "Runner" target is selected
8. Click "Add"

## Info.plist Configuration

No additional Info.plist configuration is required for custom notification sounds. iOS automatically recognizes sound files in the app bundle.

## Usage

These sound files are referenced in the OneSignal notification payload:

```dart
// Example usage in notification creation
await notificationAPI.createNotification(
  title: 'Alert',
  message: 'Critical issue detected',
  type: 'alert',
  sound: 'alert.wav', // iOS requires .wav extension
);
```

## iOS Sound Naming

- iOS requires the full filename including extension (e.g., "alert.wav")
- File names are case-sensitive
- Use only alphanumeric characters, hyphens, and underscores

## Testing

To test the sounds:
1. Send a test notification with each sound type
2. Verify the correct sound plays on the device
3. Test with device in different states (silent mode, Do Not Disturb, normal)
4. Note: Silent mode will prevent sounds from playing (expected behavior)

## Fallback Behavior

If a specified sound file is missing or invalid, iOS will use the default system notification sound.

## Converting Audio Formats

If you need to convert audio files to iOS-compatible format:

```bash
# Using ffmpeg to convert to Linear PCM WAV
ffmpeg -i input.mp3 -acodec pcm_s16le -ar 44100 -ac 2 output.wav

# Using afconvert (macOS built-in tool)
afconvert -f WAVE -d LEI16 input.mp3 output.wav
```

# Accessibility Features Documentation

This document describes the accessibility features implemented in the Pavra application to ensure the app is usable by all users, including those with disabilities.

## Overview

The application implements comprehensive accessibility features following WCAG 2.1 AA standards, including:

1. **Semantic Labels** - All interactive elements have descriptive labels for screen readers
2. **Haptic Feedback** - Tactile feedback for important actions and state changes
3. **Sufficient Contrast** - Color combinations meet WCAG AA contrast ratios (4.5:1)
4. **Dynamic Font Sizes** - Support for system font size settings
5. **Visual Feedback** - Alternative visual indicators for audio/haptic feedback (for deaf users)

## Implementation

### 1. Semantic Labels

All interactive elements include semantic labels that describe their purpose and state:

#### Route Planning
- **Route Point Markers**: "Starting point, stop 1 of N" / "Waypoint X, stop X of N" / "Destination, stop N of N"
- **Travel Mode Buttons**: "driving travel mode, selected/not selected. Tap to select."
- **Optimize Button**: "Optimize route with N waypoints. Tap to reorder for shortest distance."
- **Navigation Button**: "Start navigation. Tap to begin turn-by-turn directions."

#### Saved Locations
- **Saved Location Items**: "Saved location: [label], [name]. Tap to select."
- **Quick Access Buttons**: "Navigate to Home/Work. Tap to start navigation to your saved location."

#### Issue Markers
- **Issue Markers**: "[severity] severity road issue: [title]. Tap for details."
- **Issue Count Badges**: "N [severity] issues along route"

#### Voice Search
- **Voice Button**: "Voice search. Tap to start voice input." / "Voice search active, listening for input. Tap to stop."
- **Visual Indicators**: Real-time transcription display and status indicators for deaf users

### 2. Haptic Feedback

Haptic feedback is provided for the following actions:

#### Voice Search
- `voiceSearchActivated()` - Medium impact when voice search starts
- `voiceSearchSuccess()` - Light impact when speech is recognized successfully
- `voiceSearchError()` - Heavy impact when an error occurs

#### Route Optimization
- `optimizationStarted()` - Medium impact when optimization begins
- `optimizationComplete()` - Double light impact (success pattern) when optimization completes

#### General Actions
- `buttonPressed()` - Selection click for all button presses
- `successAction()` - Light impact for successful operations
- `errorOccurred()` - Heavy impact for errors
- `waypointReached()` - Double medium impact when reaching a waypoint during navigation

### 3. Color Contrast

All colors are validated to meet WCAG AA standards (4.5:1 contrast ratio):

#### Severity Colors (Dark Mode / Light Mode)
- **Critical**: Red 300 / Red 700
- **High**: Orange 300 / Red 600
- **Moderate**: Yellow 300 / Orange 700
- **Low**: Blue 300 / Blue 700
- **Minor**: Green 300 / Green 700

#### Route Point Colors (Dark Mode / Light Mode)
- **Start**: Green 300 / Green 700
- **Destination**: Red 300 / Red 700
- **Waypoint**: Orange 300 / Orange 700

#### Contrast Checking Functions
```dart
// Check if colors meet WCAG AA standards (4.5:1)
AccessibilityUtils.hasSufficientContrast(foreground, background)

// Check if colors meet WCAG AAA standards (7:1)
AccessibilityUtils.hasEnhancedContrast(foreground, background)
```

### 4. Dynamic Font Sizes

The app supports system font size settings:

```dart
// Get scaled font size based on accessibility settings
double scaledSize = AccessibilityUtils.getScaledFontSize(context, baseSize);

// Check if large text is enabled
bool isLargeText = AccessibilityUtils.isLargeTextEnabled(context);

// Get responsive padding that scales with text
EdgeInsets padding = AccessibilityUtils.getResponsivePadding(context, basePadding);
```

All text elements automatically scale with system font size settings through Flutter's `MediaQuery.textScaler`.

### 5. Visual Feedback for Voice Search

For users who are deaf or hard of hearing, visual indicators are provided:

#### Listening State
- Green border with pulsing animation
- "Listening..." text
- Real-time transcription display

#### Processing State
- Circular progress indicator
- "Processing..." text

#### Error State
- Red border
- Error icon
- Error message text

#### Success State
- Recognized text displayed
- Edit option provided

## Usage Examples

### Adding Semantic Labels to Buttons

```dart
Semantics(
  label: AccessibilityUtils.navigationButtonLabel(isNavigating),
  button: true,
  child: IconButton(
    icon: Icon(Icons.navigation),
    onPressed: () async {
      await AccessibilityUtils.buttonPressed();
      _startNavigation();
    },
  ),
)
```

### Adding Haptic Feedback to Actions

```dart
ElevatedButton(
  onPressed: () async {
    await AccessibilityUtils.optimizationStarted();
    await _optimizeRoute();
    await AccessibilityUtils.optimizationComplete();
  },
  child: Text('Optimize Route'),
)
```

### Checking Color Contrast

```dart
final foreground = Colors.white;
final background = theme.colorScheme.primary;

if (!AccessibilityUtils.hasSufficientContrast(foreground, background)) {
  // Use alternative color combination
}
```

### Using Severity Colors with Proper Contrast

```dart
final isDarkMode = Theme.of(context).brightness == Brightness.dark;
final markerColor = AccessibilityUtils.getSeverityMarkerColor(
  'critical',
  isDarkMode: isDarkMode,
);
```

## Testing Accessibility

### Screen Reader Testing
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate through the app using swipe gestures
3. Verify all interactive elements have descriptive labels
4. Verify labels accurately describe element state and purpose

### Contrast Testing
1. Use the built-in contrast checking functions
2. Test in both light and dark modes
3. Verify all text is readable against backgrounds

### Font Size Testing
1. Go to device Settings → Display → Font Size
2. Set to largest size
3. Verify all text is visible and doesn't overflow
4. Verify layouts adapt appropriately

### Haptic Feedback Testing
1. Enable haptic feedback in device settings
2. Perform various actions (voice search, optimization, navigation)
3. Verify appropriate haptic patterns are triggered

### Visual Feedback Testing (for Deaf Users)
1. Mute device audio
2. Use voice search feature
3. Verify visual indicators clearly show listening/processing/error states
4. Verify transcription is displayed in real-time

## Accessibility Checklist

- [x] All interactive elements have semantic labels
- [x] Buttons include `button: true` in Semantics
- [x] Selected states are indicated with `selected: true`
- [x] Haptic feedback for voice search (activate, success, error)
- [x] Haptic feedback for route optimization (start, complete)
- [x] Haptic feedback for button presses
- [x] Haptic feedback for waypoint reached during navigation
- [x] Color contrast meets WCAG AA standards (4.5:1)
- [x] Severity colors optimized for dark/light modes
- [x] Route point colors optimized for dark/light modes
- [x] Dynamic font size support via MediaQuery
- [x] Responsive padding for large text
- [x] Visual indicators for voice search states
- [x] Real-time transcription display
- [x] Error states clearly indicated visually
- [x] Success states clearly indicated visually

## Future Enhancements

### Potential Improvements
1. **Voice Announcements**: Add TTS announcements for critical events
2. **Gesture Alternatives**: Provide alternative gestures for drag-and-drop operations
3. **High Contrast Mode**: Add dedicated high contrast theme
4. **Reduced Motion**: Respect system reduced motion settings
5. **Focus Management**: Improve keyboard navigation and focus indicators

### Additional Testing
1. Automated accessibility testing with tools like Accessibility Scanner
2. User testing with people who have disabilities
3. Compliance audit against WCAG 2.1 AA standards

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [iOS Accessibility](https://developer.apple.com/accessibility/)
- [Android Accessibility](https://developer.android.com/guide/topics/ui/accessibility)

## Contact

For accessibility issues or suggestions, please contact the development team or file an issue in the project repository.

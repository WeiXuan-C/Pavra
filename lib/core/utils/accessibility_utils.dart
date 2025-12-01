import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';

/// Accessibility Utilities
/// 
/// Provides helper functions and constants for implementing accessibility features
/// across the application, including semantic labels, haptic feedback, and
/// contrast checking.
/// 
/// Requirements: Accessibility from design
class AccessibilityUtils {
  AccessibilityUtils._();

  // ============================================================================
  // SEMANTIC LABELS
  // ============================================================================

  /// Generate semantic label for route point markers
  static String routePointLabel(int index, int total, String type) {
    if (type == 'start') {
      return 'Starting point, stop 1 of $total';
    } else if (type == 'destination') {
      return 'Destination, stop $total of $total';
    } else {
      return 'Waypoint ${index + 1}, stop ${index + 1} of $total';
    }
  }

  /// Generate semantic label for issue markers
  static String issueMarkerLabel(String title, String severity) {
    return '$severity severity road issue: $title. Tap for details.';
  }

  /// Generate semantic label for saved location
  static String savedLocationLabel(String label, String locationName) {
    return 'Saved location: $label, $locationName. Tap to select.';
  }

  /// Generate semantic label for travel mode button
  static String travelModeLabel(String mode, bool isSelected) {
    final status = isSelected ? 'selected' : 'not selected';
    return '$mode travel mode, $status. Tap to select.';
  }

  /// Generate semantic label for voice search button
  static String voiceSearchButtonLabel(bool isListening) {
    if (isListening) {
      return 'Voice search active, listening for input. Tap to stop.';
    }
    return 'Voice search. Tap to start voice input.';
  }

  /// Generate semantic label for optimize route button
  static String optimizeRouteLabel(int waypointCount) {
    return 'Optimize route with $waypointCount waypoints. Tap to reorder for shortest distance.';
  }

  /// Generate semantic label for navigation button
  static String navigationButtonLabel(bool isNavigating) {
    if (isNavigating) {
      return 'Cancel navigation. Tap to stop current navigation.';
    }
    return 'Start navigation. Tap to begin turn-by-turn directions.';
  }

  /// Generate semantic label for route info display
  static String routeInfoLabel(String distance, String duration, int stops) {
    return 'Route summary: $distance distance, $duration duration, $stops stops';
  }

  /// Generate semantic label for issue count badge
  static String issueCountLabel(int count, String severity) {
    final plural = count == 1 ? 'issue' : 'issues';
    return '$count $severity $plural along route';
  }

  /// Generate semantic label for quick access button
  static String quickAccessLabel(String locationType) {
    return 'Navigate to $locationType. Tap to start navigation to your saved $locationType location.';
  }

  // ============================================================================
  // HAPTIC FEEDBACK
  // ============================================================================

  /// Provide haptic feedback for voice search activation
  static Future<void> voiceSearchActivated() async {
    await HapticFeedback.mediumImpact();
  }

  /// Provide haptic feedback for voice search success
  static Future<void> voiceSearchSuccess() async {
    await HapticFeedback.lightImpact();
  }

  /// Provide haptic feedback for voice search error
  static Future<void> voiceSearchError() async {
    await HapticFeedback.heavyImpact();
  }

  /// Provide haptic feedback for route optimization start
  static Future<void> optimizationStarted() async {
    await HapticFeedback.mediumImpact();
  }

  /// Provide haptic feedback for route optimization complete
  static Future<void> optimizationComplete() async {
    await HapticFeedback.lightImpact();
    // Double tap for success
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Provide haptic feedback for button press
  static Future<void> buttonPressed() async {
    await HapticFeedback.selectionClick();
  }

  /// Provide haptic feedback for error or warning
  static Future<void> errorOccurred() async {
    await HapticFeedback.heavyImpact();
  }

  /// Provide haptic feedback for success action
  static Future<void> successAction() async {
    await HapticFeedback.lightImpact();
  }

  /// Provide haptic feedback for navigation waypoint reached
  static Future<void> waypointReached() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.mediumImpact();
  }

  // ============================================================================
  // CONTRAST CHECKING
  // ============================================================================

  /// Check if color contrast meets WCAG AA standards (4.5:1 for normal text)
  static bool hassufficientContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 4.5;
  }

  /// Check if color contrast meets WCAG AAA standards (7:1 for normal text)
  static bool hasEnhancedContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 7.0;
  }

  /// Calculate contrast ratio between two colors
  static double _calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _calculateRelativeLuminance(foreground);
    final bgLuminance = _calculateRelativeLuminance(background);

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return _pow((component + 0.055) / 1.055, 2.4);
  }
  
  /// Calculate power (x^y) using logarithms
  static double _pow(double base, double exponent) {
    if (base == 0) return 0;
    if (base < 0) return 0; // Handle negative base
    // Using logarithms: x^y = e^(y * ln(x))
    return _exp(exponent * _ln(base));
  }
  
  /// Natural logarithm approximation
  static double _ln(double x) {
    if (x <= 0) return 0;
    // Taylor series approximation for ln(x) around x=1
    // ln(x) ≈ (x-1) - (x-1)²/2 + (x-1)³/3 - ...
    final z = (x - 1) / (x + 1);
    final z2 = z * z;
    return 2 * z * (1 + z2 / 3 + z2 * z2 / 5 + z2 * z2 * z2 / 7);
  }
  
  /// Exponential function approximation
  static double _exp(double x) {
    // Taylor series: e^x = 1 + x + x²/2! + x³/3! + ...
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i < 20; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-10) break;
    }
    return result;
  }

  // ============================================================================
  // MARKER COLORS WITH SUFFICIENT CONTRAST
  // ============================================================================

  /// Get marker color for severity with sufficient contrast
  static Color getSeverityMarkerColor(String severity, {required bool isDarkMode}) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
      case 'high':
        return isDarkMode ? Colors.orange.shade300 : Colors.red.shade600;
      case 'moderate':
        return isDarkMode ? Colors.yellow.shade300 : Colors.orange.shade700;
      case 'low':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
      case 'minor':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
      default:
        return isDarkMode ? Colors.yellow.shade300 : Colors.orange.shade700;
    }
  }

  /// Get route point marker color with sufficient contrast
  static Color getRoutePointColor(String type, {required bool isDarkMode}) {
    switch (type) {
      case 'start':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
      case 'destination':
        return isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
      case 'waypoint':
        return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
      default:
        return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
    }
  }

  // ============================================================================
  // VISUAL FEEDBACK FOR VOICE SEARCH (FOR DEAF USERS)
  // ============================================================================

  /// Show visual indicator for voice search listening state
  static Widget buildVoiceSearchVisualIndicator({
    required BuildContext context,
    required bool isListening,
    required bool hasError,
    required String transcription,
  }) {
    final l10n = AppLocalizations.of(context);
    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.accessibility_voiceSearchError,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isListening) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              transcription.isEmpty ? l10n.accessibility_listening : transcription,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================================
  // FONT SIZE SUPPORT
  // ============================================================================

  /// Get scaled font size based on accessibility settings
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    return baseSize * textScaleFactor;
  }

  /// Check if large text is enabled
  static bool isLargeTextEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.textScaler.scale(1.0) > 1.3;
  }

  /// Get responsive padding based on text scale
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    if (textScaleFactor > 1.3) {
      // Increase padding for large text
      return basePadding * 1.2;
    }
    return basePadding;
  }
}

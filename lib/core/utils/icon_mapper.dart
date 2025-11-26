import 'package:flutter/material.dart';

/// Icon Mapper Utility
/// Maps icon names to Material Icons
class IconMapper {
  /// Map of icon names to IconData
  static final Map<String, IconData> _iconMap = {
    // Road Issues
    'pothole': Icons.warning,
    'crack': Icons.broken_image,
    'construction': Icons.construction,
    'flooding': Icons.water_damage,
    'lighting': Icons.lightbulb_outline,
    'obstacle': Icons.block,
    'damage': Icons.report_problem,
    'sign': Icons.sign_language,
    'traffic': Icons.traffic,

    // General
    'warning': Icons.warning,
    'error': Icons.error_outline,
    'info': Icons.info_outline,
    'alert': Icons.notification_important,
    'report': Icons.report,
    'location': Icons.location_on,
    'map': Icons.map,
    'camera': Icons.camera_alt,
    'photo': Icons.photo_camera,

    // Categories
    'category': Icons.category,
    'label': Icons.label,
    'tag': Icons.local_offer,

    // Status
    'check': Icons.check_circle,
    'pending': Icons.pending,
    'done': Icons.done_all,
    'close': Icons.cancel,

    // Saved Locations
    'home': Icons.home,
    'work': Icons.work,
    'school': Icons.school,
    'restaurant': Icons.restaurant,
    'shopping': Icons.shopping_cart,
    'hospital': Icons.local_hospital,
    'gym': Icons.fitness_center,
    'park': Icons.park,
    'place': Icons.place,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'bookmark': Icons.bookmark,

    // Default
    'default': Icons.help_outline,
  };

  /// Get IconData from icon name
  /// Returns default icon if name not found
  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return _iconMap['default']!;
    }
    return _iconMap[iconName.toLowerCase()] ?? _iconMap['default']!;
  }

  /// Get all available icon names
  static List<String> getAvailableIcons() {
    return _iconMap.keys.toList()..sort();
  }

  /// Check if icon name exists
  static bool hasIcon(String iconName) {
    return _iconMap.containsKey(iconName.toLowerCase());
  }

  /// Get icon preview widget
  static Widget getIconPreview(
    String? iconName, {
    double size = 24,
    Color? color,
  }) {
    return Icon(getIcon(iconName), size: size, color: color);
  }
}

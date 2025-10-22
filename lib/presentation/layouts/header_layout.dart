import 'package:flutter/material.dart';

/// Unified Header Layout
/// Provides a consistent AppBar design across all screens that need it
/// Used by Report Submission, Safety Alerts, Profile, Settings screens
class HeaderLayout extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final bool centerTitle;

  const HeaderLayout({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.elevation = 0,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      leading: leading,
      actions: actions,
      bottom: bottom,
      // Add subtle bottom border in dark mode for better separation
      shape: isDark
          ? Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 0.5,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

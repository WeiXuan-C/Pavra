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

  const HeaderLayout({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      elevation: elevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: leading,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

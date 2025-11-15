import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';

class EmptyRoutesWidget extends StatelessWidget {
  final VoidCallback onAddRoute;

  const EmptyRoutesWidget({
    super.key,
    required this.onAddRoute,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                color: theme.colorScheme.primary,
                size: 60,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.savedRoute_noRoutes,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.savedRoute_noRoutesDesc,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: onAddRoute,
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.savedRoute_addRoute),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

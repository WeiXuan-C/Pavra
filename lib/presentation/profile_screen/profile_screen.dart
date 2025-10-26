import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../layouts/header_layout.dart';

/// Profile Screen
/// Displays user profile information and app settings
class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Force reload profile if it's null
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userProfile == null && authProvider.user != null) {
        authProvider.reloadUserProfile();
      } else {
        debugPrint(
          '✅ UserProfile loaded: ${authProvider.userProfile?.username}',
        );
        debugPrint('✅ Role: ${authProvider.userProfile?.role}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.nav_profile,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Consumer3<AuthProvider, LocaleProvider, ThemeProvider>(
        builder: (context, authProvider, localeProvider, themeProvider, child) {
          final user = authProvider.user;
          final profile = authProvider.userProfile;

          if (user == null) {
            return Center(child: Text(l10n.home_noUserLoggedIn));
          }

          // Show warning if profile is null
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile not loaded',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('User ID: ${user.id}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.reloadUserProfile();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload Profile'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Direct Supabase query test
                      final userId = user.id;

                      try {
                        await Supabase.instance.client
                            .from('profiles')
                            .select()
                            .eq('id', userId)
                            .maybeSingle();
                      } catch (e) {
                        debugPrint('❌ Direct query error: $e');
                      }
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Test Direct Query'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage:
                              profile.avatarUrl != null &&
                                  profile.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                          child:
                              profile.avatarUrl == null ||
                                  profile.avatarUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Username
                        Text(
                          profile.username,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        // Email
                        Text(
                          user.email ?? l10n.home_noEmail,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 16),

                        // User ID
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${l10n.home_userId}: ${user.id}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Account Info Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.home_accountInfo,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: l10n.profile_username,
                          value: profile.username,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: l10n.home_email,
                          value: user.email ?? 'N/A',
                        ),
                        const Divider(height: 24),
                        _RoleRow(role: profile.role),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.language,
                          label: l10n.profile_language,
                          value: _getLanguageName(profile.language),
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.update,
                          label: l10n.home_lastUpdated,
                          value: _formatDate(profile.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Statistics Section (if user has reports)
                if (profile.reportsCount > 0)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profile_statistics,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.report_outlined,
                                  label: l10n.profile_totalReports,
                                  value: profile.reportsCount.toString(),
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.star_outline,
                                  label: l10n.profile_reputation,
                                  value: profile.reputationScore.toString(),
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () => _handleLogout(context, authProvider),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(
                    l10n.home_logout,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Handle logout
  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.home_confirmLogout),
        content: Text(l10n.home_confirmLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.home_logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.signOut();
    }
  }

  /// Format DateTime to readable string
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get language display name
  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return languageCode;
    }
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Role Row Widget with badge
class _RoleRow extends StatelessWidget {
  final String role;

  const _RoleRow({required this.role});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Get role display info
    final roleInfo = _getRoleInfo(role, l10n);

    return Row(
      children: [
        Icon(Icons.badge_outlined, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profile_role,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleInfo['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleInfo['icon'], size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          roleInfo['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getRoleInfo(String role, AppLocalizations l10n) {
    switch (role.toLowerCase()) {
      case 'developer':
        return {
          'label': l10n.profile_roleDeveloper,
          'icon': Icons.code,
          'color': Colors.purple,
        };
      case 'authority':
        return {
          'label': l10n.profile_roleAuthority,
          'icon': Icons.admin_panel_settings,
          'color': Colors.blue,
        };
      case 'user':
      default:
        return {
          'label': l10n.profile_roleUser,
          'icon': Icons.person,
          'color': Colors.green,
        };
    }
  }
}

/// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

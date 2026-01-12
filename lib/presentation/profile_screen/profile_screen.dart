import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/supabase/storage_service.dart';
import '../layouts/header_layout.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/statistics_analysis_widget.dart';
import 'widgets/reputation_history_widget.dart';

/// Profile Screen
/// Displays user profile information and app settings
class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAccountInfoExpanded = true;
  final _imagePicker = ImagePicker();
  bool _isUploading = false;

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

    return Consumer3<AuthProvider, LocaleProvider, ThemeProvider>(
      builder: (context, authProvider, localeProvider, themeProvider, child) {
        final user = authProvider.user;
        final profile = authProvider.userProfile;

        return Scaffold(
          appBar: HeaderLayout(
            title: l10n.nav_profile,
            actions: [
              // Show developer badge in header if user is developer
              if (profile?.role == 'developer')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            l10n.profile_roleDeveloper,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          body: _buildBody(context, user, profile, l10n, authProvider),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic user,
    dynamic profile,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) {

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
            Text(
              'Try reloading the profile or restarting the app',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
                        // Avatar with edit button
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                              backgroundImage:
                                  profile.avatarUrl != null &&
                                      profile.avatarUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      profile.avatarUrl!,
                                    )
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
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    )
                                  : null,
                            ),
                            if (_isUploading)
                              Positioned.fill(
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.black54,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 16),
                                  color: Colors.white,
                                  padding: EdgeInsets.zero,
                                  onPressed: _isUploading
                                      ? null
                                      : () => _changeAvatar(authProvider),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Username with edit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                profile.username,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: profile.username.length > 15
                                          ? 20
                                          : profile.username.length > 12
                                          ? 22
                                          : 24,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  _editUsername(authProvider, profile.username),
                              tooltip: l10n.profile_editUsername,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Email
                        Text(
                          user.email ?? l10n.home_noEmail,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Account Info Section (Collapsible)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isAccountInfoExpanded = !_isAccountInfoExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_circle_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.home_accountInfo,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(
                                _isAccountInfoExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0,
                            16.0,
                            16.0,
                          ),
                          child: Column(
                            children: [
                              const Divider(height: 8),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.fingerprint,
                                label: l10n.home_userId,
                                value: user.id,
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
                        secondChild: const SizedBox.shrink(),
                        crossFadeState: _isAccountInfoExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Reputation History Section (only for regular users)
                if (profile.role == 'user') ...[
                  ReputationHistoryWidget(userId: user.id),
                  const SizedBox(height: 24),
                ],

                // Statistics Analysis Section
                const StatisticsAnalysisWidget(),

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

  /// Edit username
  Future<void> _editUsername(
    AuthProvider authProvider,
    String currentUsername,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => EditProfileDialog(
        currentUsername: currentUsername,
        currentUserId: authProvider.user!.id,
        onSave: (newUsername) async {
          try {
            await authProvider.updateProfile(username: newUsername);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).profile_usernameUpdated)),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update username: $e')),
            );
          }
        },
      ),
    );
  }

  /// Change avatar
  Future<void> _changeAvatar(AuthProvider authProvider) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).profile_chooseAvatarSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).profile_gallery),
              onTap: () => Navigator.pop(dialogContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(dialogContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() => _isUploading = true);

      // Upload to Supabase storage
      final userId = authProvider.user!.id;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      final avatarUrl = await StorageService().uploadAvatar(
        filePath: filePath,
        fileBytes: bytes,
      );

      // Update profile with new avatar URL
      await authProvider.updateProfile(avatarUrl: avatarUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).profile_avatarUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update avatar: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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



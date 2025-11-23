import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../layouts/header_layout.dart';

class AboutScreen extends StatelessWidget {
  static const String routeName = '/about';

  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(title: 'About Pavra'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 2.h),

            // App Logo
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5.w),
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),

            SizedBox(height: 3.h),

            // App Name & Version
            Text(
              'Pavra',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Version 1.1.0',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            SizedBox(height: 1.h),

            // Tagline
            Text(
              'AI-Powered Road Safety Platform',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Mission Statement
            _buildSection(
              context,
              icon: Icons.flag,
              title: 'Our Mission',
              content:
                  'Pavra is dedicated to making roads safer for everyone through community-driven reporting and AI-powered detection. We empower users to identify and report road hazards, helping authorities respond faster and prevent accidents.',
            ),

            SizedBox(height: 3.h),

            // Features
            _buildSection(
              context,
              icon: Icons.star,
              title: 'Key Features',
              content: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(context, '🤖 AI-powered road hazard detection'),
                  _buildFeatureItem(context, '🗺️ Interactive map with real-time updates'),
                  _buildFeatureItem(context, '🧭 Multi-stop route planning'),
                  _buildFeatureItem(context, '🔔 Smart safety alerts'),
                  _buildFeatureItem(context, '🎯 Gamification & reputation system'),
                  _buildFeatureItem(context, '🚗 Smart Drive Mode with voice alerts'),
                  _buildFeatureItem(context, '🌍 Community-driven reporting'),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Technology
            _buildSection(
              context,
              icon: Icons.computer,
              title: 'Technology',
              content:
                  'Built with Flutter for cross-platform compatibility. Powered by advanced AI models including NVIDIA Nemotron and Google Gemini for accurate road hazard detection. Backend infrastructure uses Supabase, Serverpod, and Upstash for reliable, scalable performance.',
            ),

            SizedBox(height: 3.h),

            // Team
            _buildSection(
              context,
              icon: Icons.people,
              title: 'Our Team',
              content:
                  'Pavra is developed by a passionate team of engineers, designers, and road safety advocates committed to leveraging technology for public good.',
            ),

            SizedBox(height: 3.h),

            // Links
            Card(
              child: Column(
                children: [
                  _buildLinkTile(
                    context,
                    icon: Icons.language,
                    title: 'Website',
                    subtitle: 'www.pavra.app',
                    onTap: () => _launchURL('https://www.pavra.app'),
                  ),
                  Divider(height: 1),
                  _buildLinkTile(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () => _launchURL('https://www.pavra.app/privacy'),
                  ),
                  Divider(height: 1),
                  _buildLinkTile(
                    context,
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'Terms and conditions',
                    onTap: () => _launchURL('https://www.pavra.app/terms'),
                  ),
                  Divider(height: 1),
                  _buildLinkTile(
                    context,
                    icon: Icons.code,
                    title: 'Open Source Licenses',
                    subtitle: 'Third-party software',
                    onTap: () => _showLicenses(context),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Social Media
            Text(
              'Follow Us',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  context,
                  icon: Icons.facebook,
                  onTap: () => _launchURL('https://facebook.com/pavra'),
                ),
                SizedBox(width: 3.w),
                _buildSocialButton(
                  context,
                  icon: Icons.camera_alt, // Twitter/X
                  onTap: () => _launchURL('https://twitter.com/pavra'),
                ),
                SizedBox(width: 3.w),
                _buildSocialButton(
                  context,
                  icon: Icons.photo_camera, // Instagram
                  onTap: () => _launchURL('https://instagram.com/pavra'),
                ),
                SizedBox(width: 3.w),
                _buildSocialButton(
                  context,
                  icon: Icons.work, // LinkedIn
                  onTap: () => _launchURL('https://linkedin.com/company/pavra'),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            // Contact
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.email,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Contact Us',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'support@pavra.app',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton.icon(
                    onPressed: () => _launchURL('mailto:support@pavra.app'),
                    icon: Icon(Icons.send),
                    label: Text('Send Email'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            // Copyright
            Text(
              '© 2025 Pavra. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            Text(
              'Made with ❤️ for safer roads',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? content,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (content != null)
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Text(
        feature,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3.w),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(3.w),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 28,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Pavra',
      applicationVersion: '1.1.0',
      applicationIcon: Icon(
        Icons.warning_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

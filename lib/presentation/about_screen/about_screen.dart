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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Column(
                children: [
                  _buildLinkTile(
                    context,
                    icon: Icons.language,
                    title: 'Website',
                    subtitle: 'pavra.vercel.app',
                    onTap: () => _launchURL('https://pavra.vercel.app'),
                  ),
                  Divider(height: 1),
                  _buildLinkTile(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () => Navigator.pushNamed(context, '/privacy-policy-screen'),
                  ),
                  Divider(height: 1),
                  _buildLinkTile(
                    context,
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'Terms and conditions',
                    onTap: () => Navigator.pushNamed(context, '/terms-of-service-screen'),
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

            SizedBox(height: 4.h),

            // Contact
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.contact_support,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Contact Us',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    
                    // Email
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  'pavra.noreply@gmail.com',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _launchURL('mailto:pavra.noreply@gmail.com'),
                            icon: Icon(Icons.send, color: theme.colorScheme.primary),
                            tooltip: 'Send Email',
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Phone
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  '+60 11-6520 0275',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _launchURL('tel:+601165200275'),
                            icon: Icon(Icons.call, color: theme.colorScheme.primary),
                            tooltip: 'Call',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

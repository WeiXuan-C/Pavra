import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = '/privacy-policy';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: HeaderLayout(title: l10n.privacy_policy_title),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        ]
                      : [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.privacy_policy_title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          l10n.privacy_policy_last_updated,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            _buildSection(
              context,
              title: '1. Introduction',
              content:
                  'Welcome to Pavra. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),

            _buildSection(
              context,
              title: '2. Information We Collect',
              content: 'We collect information that you provide directly to us, including:',
              bulletPoints: [
                'Account information (email, username, profile picture)',
                'Location data when you report road issues',
                'Photos and descriptions of reported road hazards',
                'Device information and usage data',
                'Communication preferences and settings',
              ],
            ),

            _buildSection(
              context,
              title: '3. How We Use Your Information',
              content: 'We use the information we collect to:',
              bulletPoints: [
                'Provide, maintain, and improve our services',
                'Process and display your road hazard reports',
                'Send you safety alerts and notifications',
                'Analyze usage patterns and optimize user experience',
                'Communicate with you about updates and features',
                'Ensure the security and integrity of our platform',
              ],
            ),

            _buildSection(
              context,
              title: '4. Location Data',
              content:
                  'Pavra collects location data to enable core features such as reporting road hazards, displaying nearby issues, and providing navigation assistance. You can control location permissions through your device settings. Location data is only collected when you actively use the app.',
            ),

            _buildSection(
              context,
              title: '5. Data Sharing and Disclosure',
              content: 'We may share your information with:',
              bulletPoints: [
                'Government authorities and road maintenance agencies (anonymized reports)',
                'Service providers who assist in operating our platform',
                'Other users (only public information like reports and reputation)',
                'Law enforcement when required by law',
              ],
              additionalContent:
                  'We do not sell your personal information to third parties.',
            ),

            _buildSection(
              context,
              title: '6. Data Security',
              content:
                  'We implement appropriate technical and organizational measures to protect your personal information. However, no method of transmission over the internet is 100% secure. We use encryption, secure servers, and regular security audits to safeguard your data.',
            ),

            _buildSection(
              context,
              title: '7. Your Rights',
              content: 'You have the right to:',
              bulletPoints: [
                'Access your personal information',
                'Correct inaccurate data',
                'Request deletion of your account and data',
                'Opt-out of marketing communications',
                'Export your data in a portable format',
                'Withdraw consent for data processing',
              ],
            ),

            _buildSection(
              context,
              title: '8. Children\'s Privacy',
              content:
                  'Pavra is not intended for children under 13 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
            ),

            _buildSection(
              context,
              title: '9. Third-Party Services',
              content:
                  'Our app uses third-party services including Google Maps, Supabase, and OneSignal. These services have their own privacy policies. We encourage you to review their policies.',
            ),

            _buildSection(
              context,
              title: '10. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),

            _buildSection(
              context,
              title: '11. Contact Us',
              content:
                  'If you have questions about this Privacy Policy or our data practices, please contact us:',
              bulletPoints: [
                'Email: pavra.noreply@gmail.com',
                'Phone: +60 11-6520 0275',
              ],
            ),

            SizedBox(height: 3.h),

            // Footer
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Your Privacy Matters',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'We are committed to protecting your personal information and being transparent about our data practices.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    List<String>? bulletPoints,
    String? additionalContent,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (bulletPoints != null) ...[
            SizedBox(height: 1.h),
            ...bulletPoints.map((point) => Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 0.5.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: isDark
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (additionalContent != null) ...[
            SizedBox(height: 1.h),
            Text(
              additionalContent,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

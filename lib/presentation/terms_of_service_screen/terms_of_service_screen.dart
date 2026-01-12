import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';

class TermsOfServiceScreen extends StatelessWidget {
  static const String routeName = '/terms-of-service';

  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: HeaderLayout(title: l10n.terms_of_service_title),
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
                    Icons.description,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.terms_of_service_title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          l10n.terms_of_service_last_updated,
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
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using Pavra ("the App"), you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App. We reserve the right to modify these terms at any time, and your continued use constitutes acceptance of any changes.',
            ),

            _buildSection(
              context,
              title: '2. Description of Service',
              content:
                  'Pavra is a road safety platform that enables users to report and view road hazards using AI-powered detection and community-driven reporting. The service includes:',
              bulletPoints: [
                'AI-powered road hazard detection',
                'Interactive map with real-time updates',
                'Route planning and navigation',
                'Safety alerts and notifications',
                'Gamification and reputation system',
                'Community reporting features',
              ],
            ),

            _buildSection(
              context,
              title: '3. User Accounts',
              content: 'To use certain features, you must create an account. You agree to:',
              bulletPoints: [
                'Provide accurate and complete information',
                'Maintain the security of your account credentials',
                'Notify us immediately of any unauthorized access',
                'Be responsible for all activities under your account',
                'Not share your account with others',
              ],
              additionalContent:
                  'We reserve the right to suspend or terminate accounts that violate these terms.',
            ),

            _buildSection(
              context,
              title: '4. User Conduct',
              content: 'You agree NOT to:',
              bulletPoints: [
                'Submit false, misleading, or spam reports',
                'Harass, abuse, or harm other users',
                'Violate any applicable laws or regulations',
                'Attempt to gain unauthorized access to the system',
                'Use the App for any commercial purpose without permission',
                'Upload malicious code or viruses',
                'Interfere with the proper functioning of the App',
              ],
            ),

            _buildSection(
              context,
              title: '5. Content and Intellectual Property',
              content:
                  'You retain ownership of content you submit (reports, photos, descriptions). By submitting content, you grant Pavra a worldwide, non-exclusive, royalty-free license to use, display, and distribute your content for the purpose of operating and improving the service.',
              additionalContent:
                  'All App content, features, and functionality are owned by Pavra and protected by copyright, trademark, and other intellectual property laws.',
            ),

            _buildSection(
              context,
              title: '6. Report Accuracy',
              content:
                  'While we strive for accuracy, Pavra does not guarantee the accuracy, completeness, or reliability of user-submitted reports. Road hazard information is provided "as is" for informational purposes only. Users should always exercise caution and follow official road signs and regulations.',
            ),

            _buildSection(
              context,
              title: '7. Location Services',
              content:
                  'The App uses location services to provide core functionality. By using the App, you consent to the collection and use of location data as described in our Privacy Policy. You can disable location services, but this may limit App functionality.',
            ),

            _buildSection(
              context,
              title: '8. Third-Party Services',
              content:
                  'The App integrates with third-party services (Google Maps, Supabase, OneSignal, etc.). Your use of these services is subject to their respective terms and conditions. We are not responsible for third-party service availability or performance.',
            ),

            _buildSection(
              context,
              title: '9. Disclaimer of Warranties',
              content:
                  'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. We do not warrant that:',
              bulletPoints: [
                'The App will be uninterrupted or error-free',
                'Defects will be corrected',
                'The App is free of viruses or harmful components',
                'Results from using the App will be accurate or reliable',
              ],
            ),

            _buildSection(
              context,
              title: '10. Limitation of Liability',
              content:
                  'TO THE MAXIMUM EXTENT PERMITTED BY LAW, PAVRA SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS, DATA, OR USE, ARISING FROM YOUR USE OF THE APP.',
              additionalContent:
                  'Some jurisdictions do not allow the exclusion of certain warranties or limitations of liability, so some of the above may not apply to you.',
            ),

            _buildSection(
              context,
              title: '11. Indemnification',
              content:
                  'You agree to indemnify and hold harmless Pavra, its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:',
              bulletPoints: [
                'Your use of the App',
                'Your violation of these Terms',
                'Your violation of any rights of another party',
                'Content you submit to the App',
              ],
            ),

            _buildSection(
              context,
              title: '12. Termination',
              content:
                  'We reserve the right to suspend or terminate your access to the App at any time, with or without notice, for any reason, including violation of these Terms. Upon termination, your right to use the App will immediately cease.',
            ),

            _buildSection(
              context,
              title: '13. Governing Law',
              content:
                  'These Terms shall be governed by and construed in accordance with the laws of Malaysia, without regard to its conflict of law provisions. Any disputes arising from these Terms or your use of the App shall be subject to the exclusive jurisdiction of the courts of Malaysia.',
            ),

            _buildSection(
              context,
              title: '14. Changes to Terms',
              content:
                  'We reserve the right to modify these Terms at any time. We will notify users of material changes via email or in-app notification. Your continued use of the App after changes constitutes acceptance of the modified Terms.',
            ),

            _buildSection(
              context,
              title: '15. Contact Information',
              content:
                  'If you have questions about these Terms of Service, please contact us:',
              bulletPoints: [
                'Email: pavra.noreply@gmail.com',
                'Phone: +60 11-6520 0275',
              ],
            ),

            _buildSection(
              context,
              title: '16. Severability',
              content:
                  'If any provision of these Terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary, and the remaining provisions will remain in full force and effect.',
            ),

            _buildSection(
              context,
              title: '17. Entire Agreement',
              content:
                  'These Terms, together with our Privacy Policy, constitute the entire agreement between you and Pavra regarding the use of the App and supersede all prior agreements and understandings.',
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
                    Icons.gavel,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Agreement Acknowledgment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'By using Pavra, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
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

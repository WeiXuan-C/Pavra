import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';

class HelpScreen extends StatefulWidget {
  static const String routeName = '/help';

  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: HeaderLayout(title: l10n.help_title),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: l10n.help_searchPlaceholder,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),

            SizedBox(height: 3.h),

            // Quick Links
            Text(
              l10n.help_quickLinks,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            _buildQuickLinkCard(
              icon: Icons.map,
              title: l10n.help_mapGuideTitle,
              subtitle: l10n.help_mapGuideSubtitle,
              onTap: () => _showGuide(context, 'map'),
            ),
            SizedBox(height: 1.h),
            _buildQuickLinkCard(
              icon: Icons.camera_alt,
              title: l10n.help_aiGuideTitle,
              subtitle: l10n.help_aiGuideSubtitle,
              onTap: () => _showGuide(context, 'detection'),
            ),
            SizedBox(height: 1.h),
            _buildQuickLinkCard(
              icon: Icons.report,
              title: l10n.help_reportGuideTitle,
              subtitle: l10n.help_reportGuideSubtitle,
              onTap: () => _showGuide(context, 'report'),
            ),

            SizedBox(height: 3.h),

            // FAQ Categories
            Text(
              l10n.help_faqTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            _buildFAQCategory(
              l10n.help_gettingStarted,
              [
                FAQItem(
                  question: l10n.help_q1,
                  answer: l10n.help_a1,
                ),
                FAQItem(
                  question: l10n.help_q2,
                  answer: l10n.help_a2,
                ),
                FAQItem(
                  question: l10n.help_q3,
                  answer: l10n.help_a3,
                ),
              ],
            ),

            _buildFAQCategory(
              l10n.help_mapNavigation,
              [
                FAQItem(
                  question: l10n.help_q4,
                  answer: l10n.help_a4,
                ),
                FAQItem(
                  question: l10n.help_q5,
                  answer: l10n.help_a5,
                ),
                FAQItem(
                  question: l10n.help_q6,
                  answer: l10n.help_a6,
                ),
                FAQItem(
                  question: l10n.help_q7,
                  answer: l10n.help_a7,
                ),
              ],
            ),

            _buildFAQCategory(
              l10n.help_aiDetection,
              [
                FAQItem(
                  question: l10n.help_q8,
                  answer: l10n.help_a8,
                ),
                FAQItem(
                  question: l10n.help_q9,
                  answer: l10n.help_a9,
                ),
                FAQItem(
                  question: l10n.help_q10,
                  answer: l10n.help_a10,
                ),
                FAQItem(
                  question: l10n.help_q11,
                  answer: l10n.help_a11,
                ),
              ],
            ),

            _buildFAQCategory(
              l10n.help_reportsIssues,
              [
                FAQItem(
                  question: l10n.help_q12,
                  answer: l10n.help_a12,
                ),
                FAQItem(
                  question: l10n.help_q13,
                  answer: l10n.help_a13,
                ),
                FAQItem(
                  question: l10n.help_q14,
                  answer: l10n.help_a14,
                ),
                FAQItem(
                  question: l10n.help_q15,
                  answer: l10n.help_a15,
                ),
              ],
            ),

            _buildFAQCategory(
              l10n.help_safetyAlerts,
              [
                FAQItem(
                  question: l10n.help_q16,
                  answer: l10n.help_a16,
                ),
                FAQItem(
                  question: l10n.help_q17,
                  answer: l10n.help_a17,
                ),
                FAQItem(
                  question: l10n.help_q18,
                  answer: l10n.help_a18,
                ),
              ],
            ),

            _buildFAQCategory(
              l10n.help_accountPrivacy,
              [
                FAQItem(
                  question: l10n.help_q19,
                  answer: l10n.help_a19,
                ),
                FAQItem(
                  question: l10n.help_q20,
                  answer: l10n.help_a20,
                ),
                FAQItem(
                  question: l10n.help_q21,
                  answer: l10n.help_a21,
                ),
              ],
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQCategory(String category, List<FAQItem> items) {
    final theme = Theme.of(context);
    final isExpanded = _expandedCategory == category;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        children: [
          ListTile(
            title: Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : category;
              });
            },
          ),
          if (isExpanded)
            ...items.map((item) => _buildFAQItem(item)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        item.question,
        style: theme.textTheme.bodyLarge,
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            item.answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  void _showGuide(BuildContext context, String guideType) {
    final l10n = AppLocalizations.of(context);
    // Show detailed guide in a dialog or new screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.help_guide),
        content: Text(l10n.help_guideContent(guideType)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

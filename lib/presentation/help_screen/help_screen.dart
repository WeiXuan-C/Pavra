import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

    return Scaffold(
      appBar: HeaderLayout(title: 'Help & FAQ'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
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
              'Quick Links',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            _buildQuickLinkCard(
              icon: Icons.map,
              title: 'Map & Navigation Guide',
              subtitle: 'Learn how to use map features',
              onTap: () => _showGuide(context, 'map'),
            ),
            SizedBox(height: 1.h),
            _buildQuickLinkCard(
              icon: Icons.camera_alt,
              title: 'AI Detection Guide',
              subtitle: 'How to detect road issues',
              onTap: () => _showGuide(context, 'detection'),
            ),
            SizedBox(height: 1.h),
            _buildQuickLinkCard(
              icon: Icons.report,
              title: 'Report Submission Guide',
              subtitle: 'How to submit reports',
              onTap: () => _showGuide(context, 'report'),
            ),

            SizedBox(height: 3.h),

            // FAQ Categories
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            _buildFAQCategory(
              'Getting Started',
              [
                FAQItem(
                  question: 'How do I create an account?',
                  answer: 'Tap on "Sign Up" on the login screen, enter your email and password, then verify your email address.',
                ),
                FAQItem(
                  question: 'How do I enable location services?',
                  answer: 'Go to your device Settings > Apps > Pavra > Permissions > Location, and select "Allow all the time" or "Allow only while using the app".',
                ),
                FAQItem(
                  question: 'What is the reputation system?',
                  answer: 'The reputation system rewards users for submitting accurate reports. Higher reputation unlocks more features and increases your trust level.',
                ),
              ],
            ),

            _buildFAQCategory(
              'Map & Navigation',
              [
                FAQItem(
                  question: 'How do I search for locations?',
                  answer: 'Tap the search bar at the top of the map, type any address, place name, or road issue. You can also search for specific issues by title or description.',
                ),
                FAQItem(
                  question: 'How do I get directions?',
                  answer: 'Search for a location, tap on the result, then tap "Directions". Choose your travel mode (driving, walking, transit, or bicycling) and start navigation.',
                ),
                FAQItem(
                  question: 'How do I plan a multi-stop route?',
                  answer: 'Tap the route planning icon (🔀) next to the search bar, add your stops, reorder them as needed, select travel mode, and start navigation.',
                ),
                FAQItem(
                  question: 'What do the marker colors mean?',
                  answer: 'Red markers = Critical/High severity issues, Orange = Moderate severity, Yellow = Low/Minor severity, Cyan = Your search result.',
                ),
              ],
            ),

            _buildFAQCategory(
              'AI Detection',
              [
                FAQItem(
                  question: 'How does AI detection work?',
                  answer: 'Take a photo of a road issue, and our AI analyzes it to identify the type and severity. The AI uses advanced vision models to detect potholes, cracks, debris, and other hazards.',
                ),
                FAQItem(
                  question: 'What can the AI detect?',
                  answer: 'The AI can detect potholes, road cracks, debris, flooding, damaged signs, missing lane markings, and other road safety issues.',
                ),
                FAQItem(
                  question: 'How accurate is the AI?',
                  answer: 'Our AI has high accuracy, but all detections are reviewed by the community. You can adjust the sensitivity level in settings.',
                ),
                FAQItem(
                  question: 'Can I use photos from my gallery?',
                  answer: 'Yes! Tap the gallery icon when submitting a report to select existing photos.',
                ),
              ],
            ),

            _buildFAQCategory(
              'Reports & Issues',
              [
                FAQItem(
                  question: 'How do I submit a report?',
                  answer: 'Use AI detection or tap "Report Issue" on the map. Add photos, description, and location details, then submit.',
                ),
                FAQItem(
                  question: 'Can I edit my reports?',
                  answer: 'You can edit draft reports. Once submitted, reports can only be updated by moderators.',
                ),
                FAQItem(
                  question: 'How long does review take?',
                  answer: 'Most reports are reviewed within 24-48 hours. High-severity issues are prioritized.',
                ),
                FAQItem(
                  question: 'What happens to spam reports?',
                  answer: 'Spam reports are flagged and removed. Repeated spam submissions may result in account restrictions.',
                ),
              ],
            ),

            _buildFAQCategory(
              'Safety Alerts',
              [
                FAQItem(
                  question: 'How do I set up alerts?',
                  answer: 'Go to Safety Alerts screen, enable notifications, and set your alert radius. You\'ll receive notifications for issues within your radius.',
                ),
                FAQItem(
                  question: 'Can I customize alert types?',
                  answer: 'Yes! In Safety Alerts settings, you can choose which severity levels trigger notifications.',
                ),
                FAQItem(
                  question: 'What is Smart Drive Mode?',
                  answer: 'Smart Drive Mode provides voice alerts while driving, warning you about nearby road hazards in real-time.',
                ),
              ],
            ),

            _buildFAQCategory(
              'Account & Privacy',
              [
                FAQItem(
                  question: 'How do I change my password?',
                  answer: 'Go to Profile > Settings > Account Settings > Change Password.',
                ),
                FAQItem(
                  question: 'Is my location data private?',
                  answer: 'Yes. Location data is only used for map features and alerts. We never share your personal location with third parties.',
                ),
                FAQItem(
                  question: 'How do I delete my account?',
                  answer: 'Contact support at support@pavra.app to request account deletion. All your data will be permanently removed.',
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Contact Support
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Still need help?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Contact our support team',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Open email or support form
                    },
                    icon: Icon(Icons.email),
                    label: Text('Contact Support'),
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
    // Show detailed guide in a dialog or new screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Guide'),
        content: Text('Detailed guide for $guideType will be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
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

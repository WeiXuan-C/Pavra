import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/repositories/report_issue_repository.dart';
import '../../../data/sources/remote/report_issue_remote_source.dart';
import '../../../data/sources/remote/issue_type_remote_source.dart';
import '../../../data/sources/remote/issue_vote_remote_source.dart';

/// Statistics Analysis Widget
/// Displays analysis of reports_count and reputation_score
class StatisticsAnalysisWidget extends StatefulWidget {
  const StatisticsAnalysisWidget({super.key});

  @override
  State<StatisticsAnalysisWidget> createState() =>
      _StatisticsAnalysisWidgetState();
}

class _StatisticsAnalysisWidgetState extends State<StatisticsAnalysisWidget> {
  bool _isExpanded = true;
  bool _isGenerating = false;
  bool _hasGenerated = false;
  int _actualReportsCount = 0;
  int _reputationScore = 0;
  String? _errorMessage;

  /// Generate statistics by counting actual reports
  Future<void> _generateStatistics() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('📊 Starting statistics generation for user: $userId');

      // Create report repository instance
      final supabase = Supabase.instance.client;
      final reportRepository = ReportIssueRepository(
        reportRemoteSource: ReportIssueRemoteSource(supabase),
        typeRemoteSource: IssueTypeRemoteSource(supabase),
        voteRemoteSource: IssueVoteRemoteSource(supabase),
      );

      debugPrint('📊 Fetching user reports...');
      // Count reports where status != 'discard' and status != 'spam'
      List<dynamic> allReports = [];
      try {
        // Fetch reports for the current user
        allReports = await reportRepository.getReportIssues(createdBy: userId);
        debugPrint('📊 Total reports fetched: ${allReports.length}');
      } catch (e) {
        debugPrint('⚠️ Error fetching reports: $e');
        // If error is due to no reports, continue with empty list
        allReports = [];
      }

      final validReports = allReports.where((report) {
        final isValid = report.status != 'discard' && report.status != 'spam';
        debugPrint(
          '📊 Report ${report.id}: status=${report.status}, valid=$isValid',
        );
        return isValid;
      }).toList();

      final actualCount = validReports.length;
      debugPrint('📊 Valid reports count: $actualCount');

      // Update the reports_count in the profiles table
      debugPrint('📊 Updating profile with reports_count: $actualCount');
      await supabase
          .from('profiles')
          .update({
            'reports_count': actualCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      debugPrint('✅ Profile updated successfully');

      // Reload user profile to get latest data
      debugPrint('📊 Reloading user profile...');
      await authProvider.reloadUserProfile();

      // Get updated profile data
      final profile = authProvider.userProfile;
      if (profile != null) {
        debugPrint(
          '📊 Profile loaded: reports_count=${profile.reportsCount}, reputation=${profile.reputationScore}',
        );
        setState(() {
          _actualReportsCount = actualCount;
          _reputationScore = profile.reputationScore;
          _hasGenerated = true;
          _isGenerating = false;
        });
        debugPrint('✅ Statistics generation completed successfully');
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating statistics: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });

      // Show error in snackbar for better user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header with collapse/expand
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.profile_statisticsAnalysis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 8),
                  const SizedBox(height: 8),

                  // Generate Button
                  if (!_hasGenerated)
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateStatistics,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_graph),
                      label: Text(
                        _isGenerating
                            ? l10n.profile_generating
                            : l10n.profile_generateAnalysis,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.profile_analysisError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Analysis Results
                  if (_hasGenerated) ...[
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _AnalysisCard(
                            icon: Icons.report_outlined,
                            label: l10n.profile_validReports,
                            value: _actualReportsCount.toString(),
                            color: isDark ? Colors.blue.shade300 : Colors.blue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnalysisCard(
                            icon: Icons.star_outline,
                            label: l10n.profile_reputation,
                            value: _reputationScore.toString(),
                            color: isDark
                                ? Colors.orange.shade300
                                : Colors.orange,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Analysis Insights
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? theme.colorScheme.outline.withValues(alpha: 0.3)
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.insights,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.profile_insights,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _InsightRow(
                            icon: Icons.check_circle_outline,
                            text: l10n.profile_insightReports(
                              _actualReportsCount,
                            ),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 6),
                          _InsightRow(
                            icon: Icons.trending_up,
                            text: _getReputationInsight(l10n),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 6),
                          _InsightRow(
                            icon: Icons.emoji_events_outlined,
                            text: _getContributionLevel(l10n),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Refresh Button
                    TextButton.icon(
                      onPressed: _isGenerating ? null : _generateStatistics,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.profile_refreshAnalysis),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  String _getReputationInsight(AppLocalizations l10n) {
    if (_reputationScore >= 100) {
      return l10n.profile_insightReputationHigh;
    } else if (_reputationScore >= 50) {
      return l10n.profile_insightReputationMedium;
    } else {
      return l10n.profile_insightReputationLow;
    }
  }

  String _getContributionLevel(AppLocalizations l10n) {
    if (_actualReportsCount >= 20) {
      return l10n.profile_contributionExcellent;
    } else if (_actualReportsCount >= 10) {
      return l10n.profile_contributionGood;
    } else if (_actualReportsCount >= 5) {
      return l10n.profile_contributionActive;
    } else {
      return l10n.profile_contributionBeginner;
    }
  }
}

/// Analysis Card Widget
class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _AnalysisCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)]
              : [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Insight Row Widget
class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InsightRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

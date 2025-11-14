import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/models/reputation_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/repositories/reputation_repository.dart';

/// Reputation History Widget
/// Displays reputation score, status, and recent changes for the user
class ReputationHistoryWidget extends StatefulWidget {
  final String userId;

  const ReputationHistoryWidget({super.key, required this.userId});

  @override
  State<ReputationHistoryWidget> createState() =>
      _ReputationHistoryWidgetState();
}

class _ReputationHistoryWidgetState extends State<ReputationHistoryWidget> {
  final _reputationRepository = ReputationRepository();
  List<ReputationModel>? _reputationHistory;
  bool _isLoading = true;
  bool _isExpanded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReputationHistory();
  }

  Future<void> _loadReputationHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _reputationRepository.getReputationHistory(
        userId: widget.userId,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _reputationHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final currentScore = authProvider.userProfile?.reputationScore ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header with expand/collapse
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
                    Icons.stars_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.reputation_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 8),
                  const SizedBox(height: 16),

                  // Current Score Display
                  _ReputationScoreCard(score: currentScore),

                  const SizedBox(height: 16),

                  // Status and Advice
                  _ReputationStatusCard(
                    score: currentScore,
                    history: _reputationHistory,
                  ),

                  const SizedBox(height: 16),

                  // History Header
                  Row(
                    children: [
                      Text(
                        l10n.reputation_recentActivity,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _loadReputationHistory,
                        tooltip: l10n.common_retry,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // History List
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.reputation_loadError,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_reputationHistory == null ||
                      _reputationHistory!.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.reputation_noHistory,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reputationHistory!.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final record = _reputationHistory![index];
                        return _ReputationHistoryItem(record: record);
                      },
                    ),
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
}

/// Reputation Score Card
class _ReputationScoreCard extends StatelessWidget {
  final int score;

  const _ReputationScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _getStatusColor(score);
    final statusText = _getStatusText(score, l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(score), color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reputation_currentScore,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$score',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                    ),
                    Text(
                      ' / 100',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(int score) {
    if (score >= 70) return Icons.verified;
    if (score >= 40) return Icons.warning_amber_rounded;
    return Icons.error;
  }

  String _getStatusText(int score, AppLocalizations l10n) {
    if (score >= 70) return l10n.reputation_statusExcellent;
    if (score >= 40) return l10n.reputation_statusGood;
    return l10n.reputation_statusLow;
  }
}

/// Reputation Status and Advice Card
class _ReputationStatusCard extends StatelessWidget {
  final int score;
  final List<ReputationModel>? history;

  const _ReputationStatusCard({required this.score, required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.reputation_advice,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status message
          _buildAdviceItem(
            context,
            _getStatusAdvice(score, l10n),
            _getStatusColor(score),
          ),

          // Max score notice
          if (score == 100) ...[
            const SizedBox(height: 12),
            _buildMaxScoreNotice(context),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // How to increase score
          Text(
            l10n.reputation_howToIncrease,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildAdviceItem(
            context,
            l10n.reputation_increaseUpload,
            Colors.green,
            icon: Icons.add_circle_outline,
          ),
          _buildAdviceItem(
            context,
            l10n.reputation_increaseReviewed,
            Colors.green,
            icon: Icons.add_circle_outline,
          ),

          const SizedBox(height: 12),

          // How score decreases
          Text(
            l10n.reputation_howToDecrease,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildAdviceItem(
            context,
            l10n.reputation_decreaseRejected,
            Colors.red,
            icon: Icons.remove_circle_outline,
          ),
          _buildAdviceItem(
            context,
            l10n.reputation_decreaseSpam,
            Colors.red,
            icon: Icons.remove_circle_outline,
          ),

          // Recent trend
          if (history != null && history!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildRecentTrend(context, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildAdviceItem(
    BuildContext context,
    String text,
    Color color, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrend(BuildContext context, AppLocalizations l10n) {
    final recentChanges = history!.take(5).toList();
    final totalChange = recentChanges.fold<int>(
      0,
      (sum, record) => sum + record.changeAmount,
    );

    final trendIcon = totalChange > 0
        ? Icons.trending_up
        : totalChange < 0
        ? Icons.trending_down
        : Icons.trending_flat;

    final trendColor = totalChange > 0
        ? Colors.green
        : totalChange < 0
        ? Colors.red
        : Colors.grey;

    return Row(
      children: [
        Icon(trendIcon, size: 16, color: trendColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.reputation_recentTrend(totalChange),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaxScoreNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[700]!, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.stars, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).reputation_maxReached,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.amber[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getStatusAdvice(int score, AppLocalizations l10n) {
    if (score >= 70) return l10n.reputation_adviceExcellent;
    if (score >= 40) return l10n.reputation_adviceGood;
    return l10n.reputation_adviceLow;
  }
}

/// Reputation History Item
class _ReputationHistoryItem extends StatelessWidget {
  final ReputationModel record;

  const _ReputationHistoryItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actionInfo = _getActionInfo(record.actionType, l10n);
    final isPositive = record.changeAmount > 0;
    final isAtMax = record.scoreBefore == 100 && record.scoreAfter == 100;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: actionInfo['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(actionInfo['icon'], color: actionInfo['color'], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                actionInfo['label'],
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(record.createdAt, l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Tooltip(
          message: isAtMax
              ? 'Already at maximum score (100/100)'
              : isPositive
              ? 'Gained ${record.changeAmount} point${record.changeAmount > 1 ? 's' : ''}'
              : 'Lost ${record.changeAmount.abs()} point${record.changeAmount.abs() > 1 ? 's' : ''}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAtMax
                  ? Colors.amber.withValues(alpha: 0.1)
                  : isPositive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: isAtMax
                  ? Border.all(color: Colors.amber[700]!, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAtMax) ...[
                  Icon(
                    Icons.stars,
                    size: 14,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  isAtMax
                      ? 'MAX'
                      : '${isPositive ? '+' : ''}${record.changeAmount}',
                  style: TextStyle(
                    color: isAtMax
                        ? Colors.amber[700]
                        : isPositive
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getActionInfo(
    String actionType,
    AppLocalizations l10n,
  ) {
    switch (actionType) {
      // Positive actions
      case 'UPLOAD_ISSUE':
        return {
          'label': l10n.reputation_actionUploadIssue,
          'icon': Icons.upload_file,
          'color': Colors.green,
        };
      case 'ISSUE_VERIFIED':
        return {
          'label': 'Report Verified',
          'icon': Icons.verified,
          'color': Colors.blue,
        };
      case 'HELPFUL_VOTE':
        return {
          'label': 'Helpful Vote',
          'icon': Icons.thumb_up,
          'color': Colors.green,
        };
      case 'ISSUE_RESOLVED':
        return {
          'label': 'Issue Resolved',
          'icon': Icons.check_circle,
          'color': Colors.green[700]!,
        };
      case 'QUALITY_REPORT':
        return {
          'label': 'Quality Report Bonus',
          'icon': Icons.star,
          'color': Colors.amber,
        };
      case 'CONSECUTIVE_REPORTS':
        return {
          'label': 'Consistency Bonus',
          'icon': Icons.trending_up,
          'color': Colors.green,
        };
      case 'FIRST_REPORTER':
        return {
          'label': l10n.reputation_actionFirstReporter,
          'icon': Icons.emoji_events,
          'color': Colors.orange,
        };
      case 'COMMUNITY_CONTRIBUTION':
        return {
          'label': 'Community Contribution',
          'icon': Icons.volunteer_activism,
          'color': Colors.purple,
        };
      
      // Negative actions
      case 'ISSUE_SPAM':
        return {
          'label': l10n.reputation_issueSpam,
          'icon': Icons.report,
          'color': Colors.red,
        };
      case 'ISSUE_REJECTED':
        return {
          'label': 'Report Rejected',
          'icon': Icons.block,
          'color': Colors.orange,
        };
      case 'DUPLICATE_REPORT':
        return {
          'label': l10n.reputation_actionDuplicateReport,
          'icon': Icons.content_copy,
          'color': Colors.orange[700]!,
        };
      case 'FALSE_INFORMATION':
        return {
          'label': 'False Information',
          'icon': Icons.warning,
          'color': Colors.red[700]!,
        };
      case 'ABUSE_REPORT':
        return {
          'label': l10n.reputation_actionAbuseReport,
          'icon': Icons.gavel,
          'color': Colors.red[900]!,
        };
      case 'INACTIVE_PENALTY':
        return {
          'label': 'Inactivity Penalty',
          'icon': Icons.schedule,
          'color': Colors.grey,
        };
      
      // Special actions
      case 'MANUAL_ADJUSTMENT':
        return {
          'label': l10n.reputation_actionManualAdjustment,
          'icon': Icons.admin_panel_settings,
          'color': Colors.blue[700]!,
        };
      case 'APPEAL_APPROVED':
        return {
          'label': 'Appeal Approved',
          'icon': Icons.how_to_reg,
          'color': Colors.green,
        };
      
      // Legacy/deprecated
      case 'ISSUE_REVIEWED':
        return {
          'label': l10n.reputation_issueReviewed,
          'icon': Icons.verified,
          'color': Colors.blue,
        };
      case 'AUTHORITY_REJECTED':
        return {
          'label': l10n.reputation_authorityRejected,
          'icon': Icons.block,
          'color': Colors.orange,
        };
      
      case 'OTHERS':
        return {
          'label': l10n.reputation_actionOthers,
          'icon': Icons.info,
          'color': Colors.grey,
        };
      
      default:
        return {'label': actionType, 'icon': Icons.info, 'color': Colors.grey};
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return l10n.time_justNow;
    } else if (difference.inHours < 1) {
      return l10n.time_minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.time_hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.time_daysAgo(difference.inDays);
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

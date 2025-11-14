import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/ai_service.dart';
import '../../../l10n/app_localizations.dart';
import '../manual_report_provider.dart';

class AiAnalysisDialog extends StatefulWidget {
  final Map<String, dynamic> analysis;
  final ManualReportProvider provider;
  final Function(Map<String, dynamic>) onApplySuggestions;

  const AiAnalysisDialog({
    super.key,
    required this.analysis,
    required this.provider,
    required this.onApplySuggestions,
  });

  @override
  State<AiAnalysisDialog> createState() => _AiAnalysisDialogState();
}

class _AiAnalysisDialogState extends State<AiAnalysisDialog> {
  String? _translatedDescription;
  bool _isTranslating = false;
  bool _showTranslation = false;

  String get _currentLanguage {
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }

  bool get _isChineseUser => _currentLanguage == 'zh';

  Future<void> _translateDescription() async {
    if (_translatedDescription != null) {
      setState(() {
        _showTranslation = !_showTranslation;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final aiService = AiService();
      final description = widget.analysis['description'] as String? ?? '';
      final translated = await aiService.translateToZh(description);

      setState(() {
        _translatedDescription = translated;
        _showTranslation = true;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final description = widget.analysis['description'] as String? ?? '';
    final issueTypes =
        (widget.analysis['issueTypes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final severity = widget.analysis['severity'] as String? ?? 'moderate';
    final confidence = widget.analysis['confidence'] as String? ?? 'medium';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          SizedBox(width: 2.w),
          Text(l10n.report_aiAnalysis),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: _getConfidenceColor(
                  confidence,
                  theme,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${l10n.report_confidence}: ${_getConfidenceText(confidence, l10n)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getConfidenceColor(confidence, theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Description with translate button
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.report_description,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isChineseUser)
                  _isTranslating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: _translateDescription,
                          icon: Icon(
                            _showTranslation
                                ? Icons.translate_outlined
                                : Icons.translate,
                            size: 16,
                          ),
                          label: Text(
                            _showTranslation ? 'English' : '中文',
                            style: theme.textTheme.bodySmall,
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 2.w),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              _showTranslation && _translatedDescription != null
                  ? _translatedDescription!
                  : (description.isNotEmpty
                        ? description
                        : l10n.report_noDescription),
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),

            // Suggested issue types
            if (issueTypes.isNotEmpty) ...[
              Text(
                l10n.report_suggestedIssueTypes,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: issueTypes.map((type) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.label,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          type,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 2.h),
            ],

            // Suggested severity
            Text(
              l10n.report_suggestedSeverity,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _getSeverityColor(
                  severity,
                  theme,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getSeverityIcon(severity),
                    color: _getSeverityColor(severity, theme),
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _getSeverityText(severity, l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getSeverityColor(severity, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onApplySuggestions(widget.analysis);
          },
          child: Text(l10n.report_applySuggestions),
        ),
      ],
    );
  }

  String _getConfidenceText(String confidence, AppLocalizations l10n) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return l10n.report_confidenceHigh;
      case 'medium':
        return l10n.report_confidenceMedium;
      case 'low':
        return l10n.report_confidenceLow;
      default:
        return confidence;
    }
  }

  Color _getConfidenceColor(String confidence, ThemeData theme) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getSeverityText(String severity, AppLocalizations l10n) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return l10n.report_severityMinor;
      case 'low':
        return l10n.report_severityLow;
      case 'moderate':
        return l10n.report_severityModerate;
      case 'high':
        return l10n.report_severityHigh;
      case 'critical':
        return l10n.report_severityCritical;
      default:
        return severity;
    }
  }

  Color _getSeverityColor(String severity, ThemeData theme) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return Colors.blue;
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return Icons.info_outline;
      case 'low':
        return Icons.warning_amber_outlined;
      case 'moderate':
        return Icons.warning;
      case 'high':
        return Icons.error_outline;
      case 'critical':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }
}

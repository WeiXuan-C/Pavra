import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/issue_type_model.dart';

class IssueTypeCard extends StatefulWidget {
  final IssueTypeModel issueType;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showTranslateButton;

  const IssueTypeCard({
    super.key,
    required this.issueType,
    required this.isSelected,
    required this.onTap,
    this.showTranslateButton = false,
  });

  @override
  State<IssueTypeCard> createState() => _IssueTypeCardState();
}

class _IssueTypeCardState extends State<IssueTypeCard> {
  String? _translatedName;
  String? _translatedDescription;
  bool _isTranslating = false;
  bool _showTranslation = false;

  Future<void> _toggleTranslation() async {
    // If already translated, just toggle display
    if (_translatedName != null) {
      setState(() {
        _showTranslation = !_showTranslation;
      });
      return;
    }

    // Otherwise, translate
    setState(() {
      _isTranslating = true;
    });

    try {
      final aiService = AiService();

      // Translate name
      final translatedName = await aiService.translateToZh(
        widget.issueType.name,
      );

      // Translate description if exists
      String? translatedDesc;
      if (widget.issueType.description != null &&
          widget.issueType.description!.isNotEmpty) {
        translatedDesc = await aiService.translateToZh(
          widget.issueType.description!,
        );
      }

      setState(() {
        _translatedName = translatedName;
        _translatedDescription = translatedDesc;
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

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconMapper.getIcon(widget.issueType.iconUrl),
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 28,
              ),
            ),
            SizedBox(width: 3.w),

            // Name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with translate button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // English name
                            Text(
                              widget.issueType.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            // Chinese name (if translated and showing)
                            if (_showTranslation &&
                                _translatedName != null) ...[
                              SizedBox(height: 0.3.h),
                              Text(
                                _translatedName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: widget.isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.8,
                                        )
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Translate button (only for Chinese users)
                      if (widget.showTranslateButton)
                        _isTranslating
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: _toggleTranslation,
                                icon: Icon(
                                  _showTranslation
                                      ? Icons.translate_outlined
                                      : Icons.translate,
                                  size: 18,
                                ),
                                color: theme.colorScheme.primary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                    ],
                  ),

                  // Description
                  if (widget.issueType.description != null &&
                      widget.issueType.description!.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    // English description
                    Text(
                      widget.issueType.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Chinese description (if translated and showing)
                    if (_showTranslation && _translatedDescription != null) ...[
                      SizedBox(height: 0.3.h),
                      Text(
                        _translatedDescription!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            SizedBox(width: 2.w),

            // Checkbox
            Icon(
              widget.isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/api/report_issue/report_issue_api.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/models/report_issue_model.dart';
import '../../data/models/issue_type_model.dart';
import '../../data/models/issue_photo_model.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';

/// Report Detail Screen - Read-only preview of a report
class ReportDetailScreen extends StatefulWidget {
  final ReportIssueModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isProcessing = false;
  List<IssueTypeModel> _issueTypes = [];
  List<IssuePhotoModel> _photos = [];
  bool _isLoadingTypes = true;
  bool _isLoadingPhotos = true;

  // Voting state
  late final ReportIssueApi _reportApi;
  String? _userVote; // 'verify' or 'spam' or null
  int _verifiedVotes = 0;
  int _spamVotes = 0;
  bool _isLoadingVotes = true;

  @override
  void initState() {
    super.initState();
    // Initialize API in didChangeDependencies where we have context
    _verifiedVotes = widget.report.verifiedVotes;
    _spamVotes = widget.report.spamVotes;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = context.read<AuthProvider>();
      _reportApi = ReportIssueApi(authProvider.supabaseClient);
      _loadIssueTypes();
      _loadPhotos();
      _loadVotingData();
      _isInitialized = true;
    }
  }

  bool _isInitialized = false;

  Future<void> _loadIssueTypes() async {
    try {
      if (widget.report.issueTypeIds.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingTypes = false;
          });
        }
        return;
      }

      final types = await _reportApi.getIssueTypesByIds(
        widget.report.issueTypeIds,
      );

      if (mounted) {
        debugPrint('=== Loaded issue types ===');
        for (var type in types) {
          debugPrint('Type: ${type.name}, Icon URL: ${type.iconUrl}');
        }

        setState(() {
          _issueTypes = types;
          _isLoadingTypes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading issue types: $e');
      if (mounted) {
        setState(() {
          _isLoadingTypes = false;
        });
      }
    }
  }

  Future<void> _loadPhotos() async {
    try {
      debugPrint('=== Loading photos for report: ${widget.report.id} ===');

      final photos = await _reportApi.getReportPhotos(widget.report.id);

      if (mounted) {
        // Ensure photo URLs are complete
        final processedPhotos = photos.map((photo) {
          String photoUrl = photo.photoUrl;
          if (!photoUrl.startsWith('http')) {
            // If it's a relative path, get the full URL from storage
            try {
              photoUrl = _reportApi.getStoragePublicUrl(
                'issue-photos',
                photoUrl,
              );
              debugPrint('Converted relative path to full URL: $photoUrl');
            } catch (e) {
              debugPrint('Error converting photo URL: $e');
            }
          }
          return IssuePhotoModel(
            id: photo.id,
            issueId: photo.issueId,
            photoUrl: photoUrl,
            photoType: photo.photoType,
            isPrimary: photo.isPrimary,
            createdAt: photo.createdAt,
            updatedAt: photo.updatedAt,
            deletedAt: photo.deletedAt,
            isDeleted: photo.isDeleted,
          );
        }).toList();

        debugPrint('Parsed photos:');
        for (var photo in processedPhotos) {
          debugPrint('  - ${photo.photoType}: ${photo.photoUrl}');
        }

        setState(() {
          _photos = processedPhotos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading photos: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingPhotos = false;
        });
      }
    }
  }

  Future<void> _loadVotingData() async {
    try {
      // Load user's vote
      final userVote = await _reportApi.getMyVote(widget.report.id);

      // Load vote counts
      final voteCounts = await _reportApi.getVoteCounts(widget.report.id);

      if (mounted) {
        setState(() {
          _userVote = userVote;
          _verifiedVotes = voteCounts['verified'] ?? 0;
          _spamVotes = voteCounts['spam'] ?? 0;
          _isLoadingVotes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading voting data: $e');
      if (mounted) {
        setState(() {
          _isLoadingVotes = false;
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_userVote == 'verify') {
        // Remove verify vote (toggle off)
        await _reportApi.removeVote(widget.report.id);

        HapticFeedback.lightImpact();
        if (!mounted) return;

        setState(() {
          _userVote = null;
          _verifiedVotes = (_verifiedVotes - 1).clamp(0, 999999);
        });

        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n.reportDetail_verificationRemoved,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        // Cast verify vote (will update if user had spam vote)
        await _reportApi.voteVerify(widget.report.id);

        HapticFeedback.heavyImpact();
        if (!mounted) return;

        setState(() {
          // If user had spam vote, decrement spam count
          if (_userVote == 'spam') {
            _spamVotes = (_spamVotes - 1).clamp(0, 999999);
          }
          _userVote = 'verify';
          _verifiedVotes++;
        });

        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n.reportDetail_reportVerified,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error voting: $e');
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: l10n.reportDetail_failedToVote(e.toString()),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleSpam() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_userVote == 'spam') {
        // Remove spam vote (toggle off)
        await _reportApi.removeVote(widget.report.id);

        HapticFeedback.lightImpact();
        if (!mounted) return;

        setState(() {
          _userVote = null;
          _spamVotes = (_spamVotes - 1).clamp(0, 999999);
        });

        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n.reportDetail_spamVoteRemoved,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        // Cast spam vote (will update if user had verify vote)
        await _reportApi.voteSpam(widget.report.id);

        HapticFeedback.heavyImpact();
        if (!mounted) return;

        setState(() {
          // If user had verify vote, decrement verify count
          if (_userVote == 'verify') {
            _verifiedVotes = (_verifiedVotes - 1).clamp(0, 999999);
          }
          _userVote = 'spam';
          _spamVotes++;
        });

        final l10n = AppLocalizations.of(context);
        Fluttertoast.showToast(
          msg: l10n.reportDetail_markedAsSpam,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error voting: $e');
      if (!mounted) return;

      Fluttertoast.showToast(
        msg: 'Failed to vote: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ========== Authority Actions ==========

  Future<void> _handleAuthorityVerify() async {
    if (_isProcessing) return;

    // Show confirmation dialog
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportDetail_verifyReport),
        content: Text(l10n.reportDetail_verifyReportConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('🔄 Authority verifying report: ${widget.report.id}');

      await _reportApi.markAsReviewed(widget.report.id);

      HapticFeedback.heavyImpact();
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: l10n.reportDetail_reportVerifiedSuccess,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
      );

      // Pop back to refresh the list
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ Error verifying report: $e');
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: l10n.reportDetail_failedToVerify(e.toString()),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleAuthorityMarkSpam() async {
    if (_isProcessing) return;

    // Show confirmation dialog
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportDetail_markAsSpam),
        content: Text(l10n.reportDetail_markAsSpamConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark as Spam'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('🔄 Authority marking report as spam: ${widget.report.id}');

      await _reportApi.markAsSpam(widget.report.id);

      HapticFeedback.heavyImpact();
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: l10n.reportDetail_reportMarkedSpam,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );

      // Pop back to refresh the list
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ Error marking report as spam: $e');
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      Fluttertoast.showToast(
        msg: l10n.reportDetail_failedToMarkSpam(e.toString()),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Successfully popped, return true to indicate changes were made
          // This helps refresh the previous screen if needed
          return;
        }
        // If processing, show a message
        if (_isProcessing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.common_pleaseWait),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: HeaderLayout(title: l10n.reportDetail_title),
        body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(theme, l10n),
                  SizedBox(height: 3.h),
                  _buildPhotoCarousel(theme, l10n),
                  SizedBox(height: 3.h),
                  _buildInfoSection(theme, l10n),
                  SizedBox(height: 3.h),
                  _buildIssueTypesSection(theme, l10n),
                  SizedBox(height: 3.h),
                  _buildSeveritySection(theme, l10n),
                  SizedBox(height: 3.h),
                  _buildDescriptionSection(theme, l10n),
                  SizedBox(height: 3.h),
                  _buildVoteCountsSection(theme, l10n),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          _buildActionButtons(theme, l10n),
        ],
      ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, AppLocalizations l10n) {
    final statusColor = _getStatusColor(widget.report.status);
    final statusLabel = _getStatusLabel(widget.report.status, l10n);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.reportDetail_reportId(widget.report.id),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeago.format(widget.report.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(ThemeData theme, AppLocalizations l10n) {
    if (_isLoadingPhotos) {
      return Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_photos.isEmpty) {
      return Container(
        width: double.infinity,
        height: 45.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.reportDetail_noPhotos,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Sort photos: main photos first, then additional photos
    final sortedPhotos = List<IssuePhotoModel>.from(_photos);
    sortedPhotos.sort((a, b) {
      if (a.photoType == 'main' && b.photoType != 'main') return -1;
      if (a.photoType != 'main' && b.photoType == 'main') return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              l10n.reportDetail_photos,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${sortedPhotos.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 45.h,
          child: PageView.builder(
            itemCount: sortedPhotos.length,
            itemBuilder: (context, index) {
              final photo = sortedPhotos[index];
              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photo.photoUrl,
                        width: double.infinity,
                        height: 45.h,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 45.h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    l10n.reportDetail_loadingPhoto(index + 1, sortedPhotos.length),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            'Error loading photo ${index + 1}: $error',
                          );
                          return Container(
                            width: double.infinity,
                            height: 45.h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  l10n.reportDetail_failedToLoad,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Photo counter overlay
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1}/${sortedPhotos.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 1.h),
        Center(
          child: Text(
            l10n.reportDetail_swipePhotos,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              l10n.report_location,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Address
              _buildLocationItem(
                theme,
                l10n,
                icon: Icons.place,
                label: l10n.report_address,
                value: widget.report.address ?? l10n.reportDetail_noLocation,
                color: theme.colorScheme.primary,
              ),
              
              // Coordinates (if available)
              if (widget.report.latitude != null &&
                  widget.report.longitude != null) ...[
                SizedBox(height: 2.h),
                Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  height: 1,
                ),
                SizedBox(height: 2.h),
                _buildLocationItem(
                  theme,
                  l10n,
                  icon: Icons.my_location,
                  label: l10n.reportDetail_coordinates,
                  value: '${widget.report.latitude!.toStringAsFixed(6)}, ${widget.report.longitude!.toStringAsFixed(6)}',
                  color: Colors.blue,
                  isCopyable: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem(
    ThemeData theme,
    AppLocalizations l10n, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        
        SizedBox(width: 3.w),
        
        // Label and value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Copy button for coordinates
        if (isCopyable)
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.common_copied),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Copy coordinates',
          ),
      ],
    );
  }

  Widget _buildIssueTypesSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: theme.colorScheme.primary, size: 24),
            SizedBox(width: 2.w),
            Text(
              l10n.report_issueType,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_isLoadingTypes)
          const Center(child: CircularProgressIndicator())
        else if (_issueTypes.isEmpty)
          Text(
            l10n.reportDetail_noIssueTypes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _issueTypes.map((type) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type.iconUrl != null && type.iconUrl!.isNotEmpty) ...[
                      Icon(
                        _getIconFromName(type.iconUrl!),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                    ],
                    Text(
                      type.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSeveritySection(ThemeData theme, AppLocalizations l10n) {
    final severityColor = _getSeverityColor(widget.report.severity);
    final severityLabel = _getSeverityLabel(widget.report.severity, l10n);
    final severityIcon = _getSeverityIcon(widget.report.severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              l10n.reportDetail_severity,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                severityColor.withValues(alpha: 0.15),
                severityColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(severityIcon, color: severityColor, size: 36),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      severityLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _getSeverityDescription(widget.report.severity),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        return Icons.warning;
    }
  }

  String _getSeverityDescription(String severity) {
    final l10n = AppLocalizations.of(context);
    switch (severity.toLowerCase()) {
      case 'minor':
        return l10n.reportDetail_severityMinor;
      case 'low':
        return l10n.reportDetail_severityLow;
      case 'moderate':
        return l10n.reportDetail_severityModerate;
      case 'high':
        return l10n.reportDetail_severityHigh;
      case 'critical':
        return l10n.reportDetail_severityCritical;
      default:
        return l10n.reportDetail_severityUnspecified;
    }
  }

  Widget _buildDescriptionSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, color: theme.colorScheme.primary, size: 24),
            SizedBox(width: 2.w),
            Text(
              l10n.report_description,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            widget.report.description ?? l10n.reportDetail_noDescription,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteCountsSection(ThemeData theme, AppLocalizations l10n) {
    if (_isLoadingVotes) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine which side is winning
    final isVerifiedWinning = _verifiedVotes > _spamVotes;
    final isSpamWinning = _spamVotes > _verifiedVotes;
    final isTied = _verifiedVotes == _spamVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.how_to_vote,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              l10n.reportDetail_communityVotes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        
        // Vote counts in a modern card layout
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Verified votes
              _buildVoteRow(
                theme,
                l10n,
                icon: Icons.verified,
                label: l10n.reportDetail_verified,
                count: _verifiedVotes,
                color: Colors.green,
                isWinning: isVerifiedWinning,
                total: _verifiedVotes + _spamVotes,
              ),
              
              SizedBox(height: 2.h),
              
              // Divider with VS
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),
              
              // Spam votes
              _buildVoteRow(
                theme,
                l10n,
                icon: Icons.report,
                label: l10n.reportDetail_spam,
                count: _spamVotes,
                color: Colors.red,
                isWinning: isSpamWinning,
                total: _verifiedVotes + _spamVotes,
              ),
              
              // Result indicator
              if (!isTied && (_verifiedVotes + _spamVotes) > 0) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: (isVerifiedWinning ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isVerifiedWinning ? Colors.green : Colors.red)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVerifiedWinning ? Icons.trending_up : Icons.trending_down,
                        size: 18,
                        color: isVerifiedWinning ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          isVerifiedWinning
                              ? l10n.reportDetail_communityBelievesLegit
                              : l10n.reportDetail_communitySuspectsSpam,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoteRow(
    ThemeData theme,
    AppLocalizations l10n, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isWinning,
    required int total,
  }) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    
    return Row(
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(2.5.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        
        SizedBox(width: 3.w),
        
        // Label and count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isWinning) ...[
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 0.5.h),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? count / total : 0,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(width: 3.w),
        
        // Count and percentage
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, AppLocalizations l10n) {
    // Check if current user is the creator of this report
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final userRole = authProvider.userProfile?.role ?? 'user';
    final isOwnReport =
        currentUserId != null && widget.report.createdBy == currentUserId;

    // Don't show action buttons if it's the user's own report
    if (isOwnReport) {
      return const SizedBox.shrink();
    }

    // Authority users see different buttons
    if (userRole == 'authority') {
      return _buildAuthorityActionButtons(theme, l10n);
    }

    // Regular users see voting buttons
    return _buildUserVotingButtons(theme, l10n);
  }

  Widget _buildUserVotingButtons(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _handleSpam,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  side: BorderSide(
                    color: _userVote == 'spam' ? Colors.red : Colors.grey,
                    width: _userVote == 'spam' ? 2.5 : 2,
                  ),
                  foregroundColor: _userVote == 'spam'
                      ? Colors.red
                      : Colors.grey,
                  backgroundColor: _userVote == 'spam'
                      ? Colors.red.withValues(alpha: 0.1)
                      : null,
                ),
                icon: Icon(
                  _userVote == 'spam' ? Icons.report : Icons.report_outlined,
                  size: 20,
                ),
                label: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : Text(
                        _userVote == 'spam' ? l10n.reportDetail_spam : l10n.reportDetail_markSpam,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  backgroundColor: _userVote == 'verify'
                      ? Colors.green
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: _userVote == 'verify' ? 4 : 2,
                ),
                icon: Icon(
                  _userVote == 'verify'
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: 20,
                ),
                label: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _userVote == 'verify' ? l10n.reportDetail_verified : l10n.reportDetail_verify,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorityActionButtons(ThemeData theme, AppLocalizations l10n) {
    final isReviewed = widget.report.status == 'reviewed';
    final isSpam = widget.report.status == 'spam';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing || isSpam
                    ? null
                    : _handleAuthorityMarkSpam,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  side: BorderSide(
                    color: isSpam ? Colors.red : Colors.grey,
                    width: isSpam ? 2.5 : 2,
                  ),
                  foregroundColor: isSpam ? Colors.red : Colors.grey,
                  backgroundColor: isSpam
                      ? Colors.red.withValues(alpha: 0.1)
                      : null,
                ),
                icon: Icon(
                  isSpam ? Icons.report : Icons.report_outlined,
                  size: 20,
                ),
                label: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : Text(
                        isSpam ? l10n.reportDetail_markedAsSpamButton : l10n.reportDetail_markAsSpam,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing || isReviewed
                    ? null
                    : _handleAuthorityVerify,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  backgroundColor: isReviewed
                      ? Colors.green
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: isReviewed ? 4 : 2,
                ),
                icon: Icon(
                  isReviewed ? Icons.verified : Icons.verified_outlined,
                  size: 20,
                ),
                label: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isReviewed ? l10n.reportDetail_verified : l10n.reportDetail_verifyReportButton,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'reviewed':
        return Colors.green;
      case 'spam':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'draft':
        return l10n.status_draft;
      case 'submitted':
        return l10n.status_submitted;
      case 'reviewed':
        return l10n.status_reviewed;
      case 'spam':
        return l10n.status_spam;
      default:
        return status;
    }
  }

  Color _getSeverityColor(String severity) {
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
        return Colors.grey;
    }
  }

  String _getSeverityLabel(String severity, AppLocalizations l10n) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return l10n.severity_minor;
      case 'low':
        return l10n.severity_low;
      case 'moderate':
        return l10n.severity_moderate;
      case 'high':
        return l10n.severity_high;
      case 'critical':
        return l10n.severity_critical;
      default:
        return severity;
    }
  }

  IconData _getIconFromName(String iconName) {
    // Map icon names to Material Icons
    final iconMap = {
      'pothole': Icons.warning,
      'crack': Icons.broken_image,
      'construction': Icons.construction,
      'flooding': Icons.water_damage,
      'lighting': Icons.lightbulb_outline,
      'obstacle': Icons.block,
      'damage': Icons.report_problem,
      'sign': Icons.sign_language,
      'traffic': Icons.traffic,
      'warning': Icons.warning,
      'error': Icons.error_outline,
      'info': Icons.info_outline,
      'alert': Icons.notification_important,
      'report': Icons.report,
      'location': Icons.location_on,
      'map': Icons.map,
      'camera': Icons.camera_alt,
      'photo': Icons.photo_camera,
      'category': Icons.category,
      'label': Icons.label,
      'tag': Icons.local_offer,
      'check': Icons.check_circle,
      'pending': Icons.pending,
      'done': Icons.done_all,
      'close': Icons.cancel,
    };

    return iconMap[iconName.toLowerCase()] ?? Icons.category;
  }
}

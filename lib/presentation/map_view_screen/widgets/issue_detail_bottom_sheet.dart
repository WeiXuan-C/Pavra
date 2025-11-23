import 'dart:math' show sin, cos, asin, sqrt;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/api/report_issue/report_issue_api.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../l10n/app_localizations.dart';

class IssueDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> issue;
  final double? userLatitude;
  final double? userLongitude;

  const IssueDetailBottomSheet({
    super.key, 
    required this.issue,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<IssueDetailBottomSheet> createState() => _IssueDetailBottomSheetState();
}

class _IssueDetailBottomSheetState extends State<IssueDetailBottomSheet> {
  late final ReportIssueApi _reportIssueApi;
  String? _userVote;
  int _verifyCount = 0;
  int _spamCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reportIssueApi = ReportIssueApi(supabase);
    _loadVoteData();
  }

  Future<void> _loadVoteData() async {
    try {
      final issueId = widget.issue['id'] as String;
      
      // Load vote counts
      final counts = await _reportIssueApi.getVoteCounts(issueId);
      
      // Load user's vote
      final userVote = await _reportIssueApi.getMyVote(issueId);
      
      if (mounted) {
        setState(() {
          _verifyCount = counts['verified'] ?? 0;
          _spamCount = counts['spam'] ?? 0;
          _userVote = userVote;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vote data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isUserNearIssue() {
    if (widget.userLatitude == null || widget.userLongitude == null) {
      return false;
    }
    
    final issueLat = widget.issue['latitude'];
    final issueLng = widget.issue['longitude'];
    
    if (issueLat == null || issueLng == null) {
      return false;
    }
    
    // Calculate distance in meters using Haversine formula
    const earthRadius = 6371000; // meters
    final issueLatDouble = (issueLat as num).toDouble();
    final issueLngDouble = (issueLng as num).toDouble();
    final dLat = _toRadians(issueLatDouble - widget.userLatitude!);
    final dLng = _toRadians(issueLngDouble - widget.userLongitude!);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(widget.userLatitude!)) *
        cos(_toRadians(issueLatDouble)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * asin(sqrt(a));
    final distance = earthRadius * c;
    
    // User must be within 100 meters (about 328 feet) to vote
    return distance <= 100;
  }
  
  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180.0;
  }

  Future<void> _handleVote(String voteType) async {
    // Check if user is trying to vote on their own report
    final currentUserId = supabase.auth.currentUser?.id;
    final issueCreatorId = widget.issue['created_by'];
    
    if (currentUserId != null && issueCreatorId == currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You cannot vote on your own report'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Check if user is near the issue location
    if (!_isUserNearIssue()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You must be at the issue location to vote'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      final issueId = widget.issue['id'] as String;
      
      if (_userVote == voteType) {
        // Remove vote if clicking the same button
        await _reportIssueApi.removeVote(issueId);
        setState(() {
          if (voteType == 'verify') {
            _verifyCount--;
          } else {
            _spamCount--;
          }
          _userVote = null;
        });
      } else {
        // Cast new vote
        if (voteType == 'verify') {
          await _reportIssueApi.voteVerify(issueId);
          setState(() {
            if (_userVote == 'spam') _spamCount--;
            _verifyCount++;
            _userVote = 'verify';
          });
        } else {
          await _reportIssueApi.voteSpam(issueId);
          setState(() {
            if (_userVote == 'verify') _verifyCount--;
            _spamCount++;
            _userVote = 'spam';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openDirections() {
    final lat = widget.issue['latitude'];
    final lng = widget.issue['longitude'];
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }
    
    // Close bottom sheet and navigate to location on map
    Navigator.pop(context, {
      'action': 'navigate',
      'latitude': lat,
      'longitude': lng,
      'title': widget.issue['title'],
    });
  }

  void _showImageZoom(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageZoomView(imageUrl: imageUrl),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final issue = widget.issue;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 2.h, bottom: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Issue images - compact with zoom
                  if (issue['issue_photos'] != null && (issue['issue_photos'] as List).isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageZoom(
                        context,
                        (issue['issue_photos'] as List).first['photo_url'] as String,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 20.h,
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomImageWidget(
                                imageUrl: (issue['issue_photos'] as List).first['photo_url'] as String,
                                width: double.infinity,
                                height: 20.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Zoom indicator overlay
                            Positioned(
                              top: 1.h,
                              right: 2.w,
                              child: Container(
                                padding: EdgeInsets.all(1.5.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Title and Severity in one row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue['title'] as String? ?? 'Road Issue',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      _buildCompactSeverityBadge(
                        issue['severity'] as String? ?? 'moderate',
                        theme,
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Compact info row
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          issue['address'] as String? ?? 'Location not available',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
                      SizedBox(width: 1.w),
                      Text(
                        _formatDate(_parseDate(issue['created_at'])),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (issue['distance_miles'] != null) ...[
                        SizedBox(width: 4.w),
                        Icon(Icons.near_me, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 1.w),
                        Text(
                          '${(issue['distance_miles'] as double).toStringAsFixed(1)} mi',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Community Votes - compact
                  _buildCommunityVotes(theme, l10n),

                  SizedBox(height: 2.h),

                  // Directions button - compact
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: Icon(Icons.directions, color: Colors.white, size: 20),
                      label: Text(l10n.map_directions),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 1.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSeverityBadge(String severity, ThemeData theme) {
    final severityData = _getSeverityData(severity);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: severityData['color'].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: severityData['color'],
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            severityData['icon'],
            color: severityData['color'],
            size: 16,
          ),
          SizedBox(width: 1.w),
          Text(
            severity.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: severityData['color'],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityVotes(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return SizedBox(
        height: 8.h,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final totalVotes = _verifyCount + _spamCount;
    final canVote = _isUserNearIssue();
    final currentUserId = supabase.auth.currentUser?.id;
    final issueCreatorId = widget.issue['created_by'];
    final isOwnReport = currentUserId != null && issueCreatorId == currentUserId;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Own report notice
          if (isOwnReport)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'You cannot vote on your own report',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[800],
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Location requirement notice
          if (!canVote && !isOwnReport)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off, size: 20, color: Colors.orange),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'You must be at the location to vote',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[800],
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Vote buttons - compact
          Row(
            children: [
              Expanded(
                child: _buildCompactVoteButton(
                  icon: Icons.verified,
                  count: _verifyCount,
                  color: Colors.green,
                  isSelected: _userVote == 'verify',
                  onTap: () => _handleVote('verify'),
                  theme: theme,
                  enabled: canVote && !isOwnReport,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildCompactVoteButton(
                  icon: Icons.report,
                  count: _spamCount,
                  color: Colors.red,
                  isSelected: _userVote == 'spam',
                  onTap: () => _handleVote('spam'),
                  theme: theme,
                  enabled: canVote && !isOwnReport,
                ),
              ),
            ],
          ),

          if (totalVotes > 0) ...[
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _verifyCount / totalVotes,
                minHeight: 4,
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactVoteButton({
    required IconData icon,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : theme.dividerColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.5), 
                size: 18
              ),
              SizedBox(width: 1.w),
              Text(
                count.toString(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected ? color : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getSeverityData(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return {
          'color': Colors.red[700]!,
          'icon': Icons.dangerous,
          'description': 'Extreme danger - Immediate action required',
        };
      case 'high':
        return {
          'color': Colors.red,
          'icon': Icons.warning,
          'description': 'Significant hazard - Needs urgent repair',
        };
      case 'moderate':
        return {
          'color': Colors.orange,
          'icon': Icons.error_outline,
          'description': 'Noticeable issue - Requires attention',
        };
      case 'low':
        return {
          'color': Colors.amber,
          'icon': Icons.info_outline,
          'description': 'Slight discomfort - Minimal impact',
        };
      case 'minor':
        return {
          'color': Colors.yellow[700]!,
          'icon': Icons.report_problem_outlined,
          'description': 'Minor inconvenience - No immediate danger',
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'description': 'Severity not specified',
        };
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Full-screen zoomable image viewer
class _ImageZoomView extends StatefulWidget {
  final String imageUrl;

  const _ImageZoomView({required this.imageUrl});

  @override
  State<_ImageZoomView> createState() => _ImageZoomViewState();
}

class _ImageZoomViewState extends State<_ImageZoomView> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Reset zoom
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in to 2x at tap position
      final position = _doubleTapDetails!.localPosition;
      final double scale = 2.0;
      final double dx = (1 - scale) * position.dx;
      final double dy = (1 - scale) * position.dy;
      
      _transformationController.value = Matrix4(
        scale, 0, 0, 0,
        0, scale, 0, 0,
        0, 0, 1, 0,
        dx, dy, 0, 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: CustomImageWidget(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

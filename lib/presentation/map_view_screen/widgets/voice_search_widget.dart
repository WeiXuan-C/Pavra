import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/voice_search_service.dart';
import '../../../core/utils/accessibility_utils.dart';

/// Voice Search Widget
/// 
/// Displays a voice search interface with:
/// - Pulsing microphone icon during listening
/// - Real-time speech-to-text transcription
/// - Processing indicator
/// - Recognized text with edit option
/// - Audio/haptic feedback for different states
/// - Permission denied handling
/// - Voice command handling for navigation actions
/// 
/// Requirements: 6.1, 6.2, 6.4, 6.5, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 8.1, 8.2, 8.3, 8.4, 8.5
class VoiceSearchWidget extends StatefulWidget {
  final VoiceSearchService voiceSearchService;
  final Function(String) onSearchResult;
  final Function(VoiceCommand)? onCommandRecognized;
  final VoidCallback? onClose;

  const VoiceSearchWidget({
    super.key,
    required this.voiceSearchService,
    required this.onSearchResult,
    this.onCommandRecognized,
    this.onClose,
  });

  @override
  State<VoiceSearchWidget> createState() => _VoiceSearchWidgetState();
}

class _VoiceSearchWidgetState extends State<VoiceSearchWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _transcription = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showEditOption = false;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation for microphone icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseController.repeat(reverse: true);
    
    // Start listening immediately
    _startListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _editController.dispose();
    super.dispose();
  }

  /// Start listening for voice input
  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _hasError = false;
      _errorMessage = '';
      _transcription = '';
      _showEditOption = false;
    });

    // Play listening sound (haptic feedback)
    await AccessibilityUtils.voiceSearchActivated();

    try {
      await widget.voiceSearchService.startListening(
        onResult: (text) {
          setState(() {
            _transcription = text;
            _isListening = false;
            _isProcessing = true;
          });
          
          // Process the result after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleSearchResult(text);
          });
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _hasError = true;
            _errorMessage = error;
          });
          
          // Play error sound (haptic feedback)
          AccessibilityUtils.voiceSearchError();
        },
        onPartialResult: (text) {
          // Update transcription in real-time
          setState(() {
            _transcription = text;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _hasError = true;
        _errorMessage = 'Failed to start voice recognition';
      });
      
      // Play error sound (haptic feedback)
      await AccessibilityUtils.voiceSearchError();
    }
  }

  /// Handle the search result
  void _handleSearchResult(String text) {
    if (text.isEmpty) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = 'No speech detected';
      });
      return;
    }

    // Parse the voice command
    final command = widget.voiceSearchService.parseCommand(text);
    
    // Play success sound (haptic feedback)
    AccessibilityUtils.voiceSearchSuccess();

    // Check if this is a navigation command or a search
    if (command.type != VoiceCommandType.search && 
        command.type != VoiceCommandType.unknown) {
      // This is a navigation command - execute it immediately
      if (widget.onCommandRecognized != null) {
        widget.onCommandRecognized!(command);
        widget.onClose?.call();
      } else {
        // Fallback to showing edit option if no command handler
        setState(() {
          _isProcessing = false;
          _showEditOption = true;
          _editController.text = text;
        });
      }
    } else {
      // This is a search query - show edit option
      setState(() {
        _isProcessing = false;
        _showEditOption = true;
        _editController.text = text;
      });
    }
  }

  /// Confirm and execute the search
  void _confirmSearch() {
    final searchText = _editController.text.trim();
    if (searchText.isNotEmpty) {
      widget.onSearchResult(searchText);
      widget.onClose?.call();
    }
  }

  /// Retry voice search
  void _retry() {
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Voice Search',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Microphone icon with pulse animation
          if (_isListening) ...[
            Semantics(
              label: 'Voice search is listening for your input',
              liveRegion: true,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 40,
                        color: colorScheme.primary,
                        semanticLabel: 'Microphone active',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Listening...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Visual feedback for deaf users
            const SizedBox(height: 8),
            AccessibilityUtils.buildVoiceSearchVisualIndicator(
              isListening: true,
              hasError: false,
              transcription: _transcription,
            ),
          ],

          // Processing indicator
          if (_isProcessing) ...[
            Semantics(
              label: 'Processing your voice input',
              liveRegion: true,
              child: const CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing...',
              style: theme.textTheme.bodyLarge,
            ),
          ],

          // Error state
          if (_hasError) ...[
            Semantics(
              label: 'Voice search error: $_errorMessage',
              liveRegion: true,
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: colorScheme.error,
                semanticLabel: 'Error icon',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            // Visual feedback for deaf users
            const SizedBox(height: 8),
            AccessibilityUtils.buildVoiceSearchVisualIndicator(
              isListening: false,
              hasError: true,
              transcription: '',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Semantics(
                  button: true,
                  label: 'Cancel voice search',
                  child: TextButton(
                    onPressed: () => widget.onClose?.call(),
                    child: const Text('Cancel'),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Retry voice search',
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ],

          // Transcription display with edit option
          if (_showEditOption) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recognized:',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _editController,
                    decoration: InputDecoration(
                      hintText: 'Edit search text',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 2,
                    autofocus: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _retry,
                  child: const Text('Try Again'),
                ),
                ElevatedButton.icon(
                  onPressed: _confirmSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
          ],

          // Real-time transcription during listening
          if (_isListening && _transcription.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _transcription,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

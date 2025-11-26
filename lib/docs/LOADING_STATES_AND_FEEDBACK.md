# Loading States and Feedback Guide

This document describes the loading states and feedback mechanisms implemented throughout the Pavra application.

## Overview

The application provides consistent loading states and user feedback through:
1. **FeedbackUtils** - Centralized toast/snackbar messages
2. **Skeleton Loaders** - Animated placeholders for loading content
3. **Loading Overlays** - Full-screen or inline loading indicators
4. **Inline Loading States** - Component-specific loading indicators

## FeedbackUtils

Located in `lib/core/utils/feedback_utils.dart`, this utility provides consistent feedback messages.

### Success Messages

```dart
FeedbackUtils.showSuccess(
  context,
  'Route saved successfully',
  duration: const Duration(seconds: 3), // Optional
  action: SnackBarAction( // Optional
    label: 'View',
    onPressed: () { /* ... */ },
  ),
);
```

### Error Messages

```dart
FeedbackUtils.showError(
  context,
  'Failed to calculate route',
  duration: const Duration(seconds: 4), // Optional
);
```

### Warning Messages

```dart
FeedbackUtils.showWarning(
  context,
  'Critical issues found along route',
  duration: const Duration(seconds: 4), // Optional
  action: SnackBarAction(
    label: 'View',
    onPressed: () { /* ... */ },
  ),
);
```

### Info Messages

```dart
FeedbackUtils.showInfo(
  context,
  'Please calculate a route first',
  duration: const Duration(seconds: 3), // Optional
);
```

### Loading Overlay Dialog

For operations that block the entire UI:

```dart
// Show loading
FeedbackUtils.showLoadingOverlay(
  context,
  'Optimizing route...',
  barrierDismissible: false, // Optional, default is false
);

// Hide loading
FeedbackUtils.hideLoadingOverlay(context);
```

## Skeleton Loaders

Located in `lib/widgets/skeleton_loader.dart`, these provide animated placeholders.

### Basic Skeleton Loader

```dart
SkeletonLoader(
  width: 200,
  height: 20,
  borderRadius: BorderRadius.circular(4),
)
```

### Location List Skeleton

Pre-built skeleton for location list items:

```dart
ListView.builder(
  itemCount: 5, // Show 5 skeleton items
  itemBuilder: (context, index) {
    return const LocationSkeletonLoader();
  },
)
```

### Route List Skeleton

Pre-built skeleton for route list items:

```dart
ListView.builder(
  itemCount: 4, // Show 4 skeleton items
  itemBuilder: (context, index) {
    return const RouteSkeletonLoader();
  },
)
```

### Custom Skeleton Patterns

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SkeletonLoader(
      width: 150,
      height: 18,
      borderRadius: BorderRadius.circular(4),
    ),
    const SizedBox(height: 8),
    SkeletonLoader(
      width: 200,
      height: 14,
      borderRadius: BorderRadius.circular(4),
    ),
    const SizedBox(height: 8),
    SkeletonLoader(
      width: 180,
      height: 14,
      borderRadius: BorderRadius.circular(4),
    ),
  ],
)
```

## Loading Overlay Widget

For inline loading states that overlay content:

```dart
LoadingOverlay(
  isLoading: _isCalculating,
  message: 'Calculating route...',
  child: GoogleMap(
    // Map widget
  ),
)
```

## Inline Loading States

### Pattern 1: Boolean Flag with Conditional Rendering

```dart
class MyScreen extends StatefulWidget {
  // ...
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoading = false;
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load data
      final data = await service.getData();
      
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to load data: $e',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const LocationSkeletonLoader(),
          )
        : ListView.builder(
            itemCount: _data.length,
            itemBuilder: (context, index) => _buildItem(_data[index]),
          );
  }
}
```

### Pattern 2: Loading Overlay on Map

```dart
Stack(
  children: [
    GoogleMap(
      // Map configuration
    ),
    
    // Loading overlay
    if (_isCalculating || _isOptimizing)
      Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isOptimizing ? 'Optimizing route...' : 'Calculating route...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
  ],
)
```

### Pattern 3: Button Loading State

```dart
ElevatedButton(
  onPressed: _isLoading ? null : _handleAction,
  child: _isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : const Text('Submit'),
)
```

## Implementation Examples

### Multi-Stop Route Planner

The route planner screen demonstrates comprehensive loading states:

1. **Route Calculation**: Shows loading overlay on map with "Calculating route..." message
2. **Route Optimization**: Shows loading overlay with "Optimizing route..." message
3. **Issue Loading**: Uses `_isLoadingIssues` flag (internal state)
4. **Success Feedback**: Uses `FeedbackUtils.showSuccess()` for route saved
5. **Error Feedback**: Uses `FeedbackUtils.showError()` for calculation failures
6. **Warning Feedback**: Uses `FeedbackUtils.showWarning()` for critical issues

### Saved Locations Screen

The saved locations screen demonstrates list loading:

1. **Initial Load**: Shows 5 `LocationSkeletonLoader` widgets
2. **Success Feedback**: Uses `FeedbackUtils.showSuccess()` for updates/deletes
3. **Error Feedback**: Uses `FeedbackUtils.showError()` for failures
4. **Pull to Refresh**: Uses `RefreshIndicator` for manual refresh

### Saved Routes Screen

The saved routes screen demonstrates split-view loading:

1. **Initial Load**: Shows 4 `RouteSkeletonLoader` widgets in list
2. **Map Placeholder**: Shows placeholder when no route selected
3. **Success Feedback**: Uses `FeedbackUtils.showSuccess()` for share/delete
4. **Error Feedback**: Uses `FeedbackUtils.showError()` for failures

### Voice Search Widget

The voice search widget demonstrates state-based UI:

1. **Listening State**: Pulsing microphone icon with "Listening..." text
2. **Processing State**: Circular progress indicator with "Processing..." text
3. **Error State**: Error icon with retry button
4. **Edit State**: Text field with recognized text
5. **Real-time Transcription**: Shows partial results during listening

## Best Practices

### 1. Always Use try-catch with Loading States

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final data = await service.getData();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    
    if (mounted) {
      FeedbackUtils.showError(context, 'Failed to load data');
    }
  }
}
```

### 2. Check mounted Before Showing Feedback

```dart
if (mounted) {
  FeedbackUtils.showSuccess(context, 'Operation completed');
}
```

### 3. Use Appropriate Feedback Types

- **Success**: For completed operations (save, delete, update)
- **Error**: For failures (network errors, validation errors)
- **Warning**: For important notices (critical issues, data loss warnings)
- **Info**: For informational messages (empty states, requirements)

### 4. Provide Actionable Feedback

```dart
FeedbackUtils.showWarning(
  context,
  'Critical issues found along route',
  action: SnackBarAction(
    label: 'View',
    onPressed: () => _showIssuesSummaryDialog(),
  ),
);
```

### 5. Use Skeleton Loaders for Lists

Instead of showing a single loading spinner, use skeleton loaders to maintain layout:

```dart
// ❌ Don't do this
_isLoading ? const Center(child: CircularProgressIndicator()) : ListView(...)

// ✅ Do this
_isLoading
    ? ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const LocationSkeletonLoader(),
      )
    : ListView.builder(...)
```

### 6. Disable Interactions During Loading

```dart
ElevatedButton(
  onPressed: _isLoading ? null : _handleAction,
  child: const Text('Submit'),
)
```

### 7. Use Appropriate Loading Messages

Be specific about what's happening:

```dart
// ❌ Generic
'Loading...'

// ✅ Specific
'Calculating route...'
'Optimizing waypoints...'
'Saving location...'
```

## Accessibility Considerations

1. **Semantic Labels**: Loading indicators should have semantic labels for screen readers
2. **Haptic Feedback**: Voice search uses haptic feedback for different states
3. **Visual Feedback**: Always provide visual feedback in addition to audio/haptic
4. **Timeout Handling**: Long operations should have timeout handling with user feedback

## Performance Considerations

1. **Skeleton Animation**: Uses efficient `AnimationController` with `SingleTickerProviderStateMixin`
2. **Conditional Rendering**: Only renders loading states when needed
3. **Dispose Controllers**: Always dispose animation controllers in `dispose()`
4. **Debouncing**: Consider debouncing rapid state changes to avoid UI flicker

## Testing

When testing components with loading states:

1. Test initial loading state
2. Test success state transition
3. Test error state transition
4. Test loading state during operation
5. Test feedback message display
6. Test skeleton loader rendering
7. Test interaction disabling during loading

## Migration Guide

To migrate existing screens to use the new loading system:

1. Import `FeedbackUtils` and `skeleton_loader.dart`
2. Replace `ScaffoldMessenger.of(context).showSnackBar()` with `FeedbackUtils` methods
3. Replace `CircularProgressIndicator()` in lists with skeleton loaders
4. Add loading overlays for map-based operations
5. Ensure all async operations have proper loading states

Example migration:

```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Route saved successfully'),
    backgroundColor: Colors.green,
  ),
);

// After
FeedbackUtils.showSuccess(
  context,
  'Route saved successfully',
);
```

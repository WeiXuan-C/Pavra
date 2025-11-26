# Error Handling Guide

This document describes the comprehensive error handling implementation for the advanced map features in the Pavra application.

## Overview

The error handling system provides:
- Custom exception classes for different error scenarios
- User-friendly error messages
- Consistent error logging
- Proper error propagation and handling

## Custom Exception Classes

### Base Exception
- `AppException`: Base class for all app-specific errors

### Voice Search Exceptions
- `VoiceSearchException`: Base for voice search errors
- `SpeechRecognitionUnavailableException`: Speech recognition not available on device
- `MicrophonePermissionDeniedException`: Microphone permission denied
- `SpeechRecognitionTimeoutException`: No speech detected within timeout
- `NetworkErrorDuringRecognitionException`: Network error during voice recognition

### Route Calculation Exceptions
- `RouteCalculationException`: Base for route calculation errors
- `NoRouteFoundException`: No route available for selected travel mode
- `ApiRateLimitExceededException`: Too many API requests
- `InvalidWaypointCoordinatesException`: Invalid latitude/longitude coordinates
- `RouteOptimizationFailedException`: Route optimization failed

### Database Exceptions
- `DatabaseException`: Base for database errors
- `DuplicateLabelException`: Duplicate location label
- `DatabaseConnectionFailedException`: Database connection failed
- `RecordNotFoundException`: Record not found in database

### Network Exceptions
- `NetworkException`: Base for network errors
- `NetworkTimeoutException`: Request timed out
- `NoInternetConnectionException`: No internet connection

## Error Handler Utility

The `ErrorHandler` class provides utility methods for error handling:

### Methods

#### `getUserFriendlyMessage(dynamic error)`
Converts any error into a user-friendly message.

```dart
try {
  // Some operation
} catch (e) {
  final message = ErrorHandler.getUserFriendlyMessage(e);
  showSnackBar(message);
}
```

#### `logError(String context, dynamic error, {StackTrace? stackTrace, Map<String, dynamic>? additionalInfo})`
Logs errors with context and additional information.

```dart
try {
  // Some operation
} catch (e, stackTrace) {
  ErrorHandler.logError(
    'MyService.myMethod',
    e,
    stackTrace: stackTrace,
    additionalInfo: {'userId': userId, 'action': 'save'},
  );
}
```

#### `validateCoordinates(double latitude, double longitude)`
Validates latitude and longitude coordinates.

```dart
ErrorHandler.validateCoordinates(latitude, longitude);
// Throws InvalidWaypointCoordinatesException if invalid
```

#### `isNetworkError(dynamic error)`
Checks if an error is network-related.

```dart
if (ErrorHandler.isNetworkError(e)) {
  // Handle network error
}
```

#### `isPermissionError(dynamic error)`
Checks if an error is permission-related.

```dart
if (ErrorHandler.isPermissionError(e)) {
  // Handle permission error
}
```

#### `isRateLimitError(dynamic error)`
Checks if an error is rate limit-related.

```dart
if (ErrorHandler.isRateLimitError(e)) {
  // Handle rate limit error
}
```

## Service-Level Error Handling

### VoiceSearchService

**Errors Handled:**
1. Speech recognition unavailable
2. Microphone permission denied
3. Speech recognition timeout
4. Network errors during recognition

**Example Usage:**
```dart
final voiceService = VoiceSearchService();

try {
  await voiceService.initialize();
} on SpeechRecognitionUnavailableException catch (e) {
  showError(e.message);
} on MicrophonePermissionDeniedException catch (e) {
  showPermissionDialog(e.message);
}

await voiceService.startListening(
  onResult: (text) {
    // Handle result
  },
  onError: (error) {
    // Error is already user-friendly
    showError(error);
  },
);
```

### MultiStopRouteService

**Errors Handled:**
1. Invalid waypoint coordinates
2. No route found for travel mode
3. API rate limit exceeded
4. Network timeout

**Example Usage:**
```dart
try {
  final route = await multiStopRouteService.calculateRoute(
    start: start,
    waypoints: waypoints,
    destination: destination,
    travelMode: travelMode,
  );
} on InvalidWaypointCoordinatesException catch (e) {
  showError(e.message);
} on NoRouteFoundException catch (e) {
  showError(e.message);
} on ApiRateLimitExceededException catch (e) {
  showError(e.message);
} on NetworkTimeoutException catch (e) {
  showError(e.message);
}
```

### SavedLocationService

**Errors Handled:**
1. Duplicate label errors
2. Invalid coordinates
3. Database connection failures
4. Record not found

**Example Usage:**
```dart
try {
  await savedLocationService.saveLocation(
    label: label,
    locationName: name,
    latitude: lat,
    longitude: lng,
  );
} on DuplicateLabelException catch (e) {
  showError(e.message);
} on InvalidWaypointCoordinatesException catch (e) {
  showError(e.message);
} on DatabaseConnectionFailedException catch (e) {
  showError(e.message);
}
```

### RouteOptimizer

**Errors Handled:**
1. Invalid coordinates
2. Optimization failures (returns original waypoints)

**Example Usage:**
```dart
try {
  final result = await routeOptimizer.optimizeNearestNeighbor(
    start: start,
    waypoints: waypoints,
    destination: destination,
  );
  
  // Check if optimization actually improved the route
  if (result.savingsPercent > 0) {
    showSuccess('Route optimized: ${result.savingsPercent.toStringAsFixed(1)}% savings');
  }
} on InvalidWaypointCoordinatesException catch (e) {
  showError(e.message);
} on RouteOptimizationFailedException catch (e) {
  showError(e.message);
}
```

### SavedRouteService

**Errors Handled:**
1. Invalid coordinates
2. Database connection failures
3. Record not found
4. Import/export errors

**Example Usage:**
```dart
try {
  await savedRouteService.saveRoute(
    name: name,
    start: start,
    waypoints: waypoints,
    destination: destination,
    travelMode: travelMode,
  );
} on InvalidWaypointCoordinatesException catch (e) {
  showError(e.message);
} on DatabaseConnectionFailedException catch (e) {
  showError(e.message);
}
```

## UI Integration

### Displaying Errors to Users

```dart
void handleError(dynamic error) {
  final message = ErrorHandler.getUserFriendlyMessage(error);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: error is NetworkException
          ? SnackBarAction(
              label: 'Retry',
              onPressed: () => retryOperation(),
            )
          : null,
    ),
  );
}
```

### Permission Handling

```dart
void handlePermissionError(MicrophonePermissionDeniedException error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permission Required'),
      content: Text(error.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            openAppSettings();
          },
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

### Network Error Handling

```dart
void handleNetworkError(NetworkException error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Connection Error'),
      content: Text(error.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            retryOperation();
          },
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

## Best Practices

1. **Always catch specific exceptions first**: Catch custom exceptions before generic ones
2. **Log errors with context**: Use `ErrorHandler.logError()` with meaningful context
3. **Provide user-friendly messages**: Use `ErrorHandler.getUserFriendlyMessage()` for display
4. **Validate early**: Validate coordinates and inputs before making API calls
5. **Handle network errors gracefully**: Provide retry options for network failures
6. **Don't swallow errors**: Always log or handle errors appropriately
7. **Use appropriate exception types**: Choose the most specific exception type
8. **Include original errors**: Pass `originalError` parameter for debugging

## Testing Error Handling

```dart
test('should throw DuplicateLabelException for duplicate labels', () async {
  // Setup
  when(repository.getLocationByLabel('Home')).thenAnswer((_) async => mockLocation);
  
  // Execute & Verify
  expect(
    () => service.saveLocation(label: 'Home', ...),
    throwsA(isA<DuplicateLabelException>()),
  );
});

test('should throw InvalidWaypointCoordinatesException for invalid coordinates', () {
  expect(
    () => ErrorHandler.validateCoordinates(91, 0),
    throwsA(isA<InvalidWaypointCoordinatesException>()),
  );
});
```

## Error Codes

Each exception has an optional error code for tracking and analytics:

- `SPEECH_UNAVAILABLE`: Speech recognition unavailable
- `MICROPHONE_PERMISSION_DENIED`: Microphone permission denied
- `SPEECH_TIMEOUT`: Speech recognition timeout
- `NETWORK_ERROR_RECOGNITION`: Network error during recognition
- `NO_ROUTE_FOUND`: No route found
- `API_RATE_LIMIT`: API rate limit exceeded
- `INVALID_COORDINATES`: Invalid coordinates
- `OPTIMIZATION_FAILED`: Route optimization failed
- `DUPLICATE_LABEL`: Duplicate location label
- `DATABASE_CONNECTION_FAILED`: Database connection failed
- `RECORD_NOT_FOUND`: Record not found
- `NETWORK_TIMEOUT`: Network timeout
- `NO_INTERNET`: No internet connection

## Summary

This comprehensive error handling system ensures:
- Consistent error handling across all services
- User-friendly error messages
- Proper error logging for debugging
- Graceful degradation when errors occur
- Clear error types for specific handling

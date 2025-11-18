# Requirements Document

## Introduction

This document defines the requirements for an AI-powered real-time road damage detection system. The system captures camera frames at 1 FPS, processes them through a Vision LLM via backend API, and automatically detects and classifies road hazards (potholes, cracks, accidents, debris, etc.) with structured output that auto-fills damage report forms in the Supabase database.

## Glossary

- **Camera Feed System**: The Flutter camera component that captures frames at 1 FPS intervals
- **Image Compressor**: Component that reduces image size to <150KB for efficient upload
- **Detection API**: Backend endpoint that receives images and returns AI analysis results
- **Vision LLM**: Large Language Model with vision capabilities (e.g., GPT-4o, Qwen-VL) accessed via OpenRouter
- **Structured Output**: Strictly formatted JSON response from AI containing detection results
- **Detection UI**: Real-time visual feedback system showing detection results with color-coded alerts
- **Detection History**: Persistent storage and retrieval of past detections from Supabase
- **Severity Level**: Integer scale 1-5 indicating urgency (1=very mild, 5=urgent danger)
- **Issue Type**: Classification category (pothole, crack, accident, debris, flood, obstacle, normal)

## Requirements

### Requirement 1

**User Story:** As a road inspector, I want the app to automatically capture and analyze road conditions in real-time, so that I can identify hazards without manual intervention

#### Acceptance Criteria

1. WHEN the user activates road inspection mode, THE Camera Feed System SHALL initialize the camera preview with back-facing camera
2. WHILE road inspection mode is active, THE Camera Feed System SHALL capture one frame every 1000 milliseconds
3. WHEN a frame is captured, THE Image Compressor SHALL reduce the image size to less than 150 kilobytes in JPEG format
4. WHEN image compression completes, THE Camera Feed System SHALL upload the compressed image to the Detection API with GPS coordinates, user ID, and timestamp
5. THE Camera Feed System SHALL maintain camera preview at minimum 24 frames per second for smooth user experience

### Requirement 2

**User Story:** As a road inspector, I want the system to automatically detect and classify road damage types, so that I can quickly understand the nature of hazards

#### Acceptance Criteria

1. WHEN the Detection API receives an image, THE Detection API SHALL send the image to Vision LLM with a structured prompt
2. THE Detection API SHALL enforce a response schema requiring fields: issue_detected (boolean), type (string), severity (integer 1-5), description (string), suggested_action (string), confidence (float 0-1)
3. WHEN Vision LLM returns a response, THE Detection API SHALL validate the response against the required schema
4. IF the response validation fails, THEN THE Detection API SHALL retry the request up to 2 additional times
5. THE Detection API SHALL classify detections into exactly one of these types: road_crack, pothole, uneven_surface, flood, accident, debris, obstacle, or normal
6. THE Detection API SHALL assign severity levels where 1 represents very mild issues and 5 represents urgent danger
7. THE Detection API SHALL include confidence scores between 0.0 and 1.0 for each detection

### Requirement 3

**User Story:** As a road inspector, I want to see immediate visual feedback when hazards are detected, so that I can respond quickly to dangerous situations

#### Acceptance Criteria

1. WHEN the Detection API returns a result with issue_detected as true and type as accident or severity greater than 3, THE Detection UI SHALL display a red alert card
2. WHEN the Detection API returns a result with issue_detected as true and severity between 2 and 3, THE Detection UI SHALL display a yellow warning card
3. WHEN the Detection API returns a result with issue_detected as false or type as normal, THE Detection UI SHALL display a green status message stating "No issues detected"
4. WHEN a red alert card is displayed, THE Detection UI SHALL play an audible warning sound
5. THE Detection UI SHALL display detection results within 2 seconds of receiving the API response
6. THE Detection UI SHALL show the detection type, severity level, description, and confidence score on the alert card
7. WHILE waiting for API response, THE Detection UI SHALL display a loading indicator on the camera preview

### Requirement 4

**User Story:** As a road inspector, I want detection results to automatically populate damage report forms, so that I can submit reports without manual data entry

#### Acceptance Criteria

1. WHEN the Detection API receives a valid structured output from Vision LLM, THE Detection API SHALL write a new record to the report_issues table in Supabase
2. THE Detection API SHALL map the AI type field to the appropriate issue_type_ids in the database
3. THE Detection API SHALL map the AI severity field to the database severity enum (minor, low, moderate, high, critical)
4. THE Detection API SHALL store the AI description in the description field
5. THE Detection API SHALL store the AI suggested_action in a designated field
6. THE Detection API SHALL store the uploaded image URL in the issue_photos table with photo_type as 'ai_reference'
7. THE Detection API SHALL store GPS coordinates in the latitude and longitude fields
8. THE Detection API SHALL set the status field to 'draft' for user review
9. THE Detection API SHALL store the confidence score in a metadata field

### Requirement 5

**User Story:** As a road inspector, I want to review my detection history with timestamps and locations, so that I can track patterns and revisit specific incidents

#### Acceptance Criteria

1. WHEN the user opens the detection history panel, THE Detection History SHALL retrieve the 50 most recent detections from Supabase ordered by created_at descending
2. THE Detection History SHALL display each detection with timestamp, GPS coordinates, thumbnail image, issue type, and severity level
3. WHEN the user taps on a detection in history, THE Detection History SHALL navigate to a detail view showing the full image, description, suggested action, and confidence score
4. THE Detection History SHALL support filtering by issue type and severity level
5. THE Detection History SHALL support date range filtering
6. THE Detection History SHALL display a map view showing all detection locations as pins color-coded by severity

### Requirement 6

**User Story:** As a road inspector, I want the system to handle network failures gracefully, so that I don't lose detection data during poor connectivity

#### Acceptance Criteria

1. WHEN image upload fails due to network error, THE Camera Feed System SHALL queue the image locally with metadata
2. WHEN network connectivity is restored, THE Camera Feed System SHALL automatically retry uploading queued images in chronological order
3. THE Camera Feed System SHALL display the number of queued detections in the UI
4. THE Camera Feed System SHALL limit the local queue to 100 images maximum
5. IF the queue reaches maximum capacity, THEN THE Camera Feed System SHALL discard the oldest queued image
6. THE Camera Feed System SHALL persist the queue across app restarts

### Requirement 7

**User Story:** As a system administrator, I want the backend to validate and sanitize all inputs, so that the system remains secure and stable

#### Acceptance Criteria

1. WHEN the Detection API receives a request, THE Detection API SHALL validate that the image size is less than 5 megabytes
2. THE Detection API SHALL validate that latitude is between -90 and 90 degrees
3. THE Detection API SHALL validate that longitude is between -180 and 180 degrees
4. THE Detection API SHALL validate that userId exists in the auth.users table
5. THE Detection API SHALL validate that timestamp is within 5 minutes of server time
6. IF any validation fails, THEN THE Detection API SHALL return a 400 error with a descriptive message
7. THE Detection API SHALL sanitize all text fields to prevent SQL injection and XSS attacks

### Requirement 8

**User Story:** As a road inspector, I want to manually trigger detection on specific frames, so that I can analyze particular road sections of interest

#### Acceptance Criteria

1. WHEN the user taps the manual capture button, THE Camera Feed System SHALL immediately capture the current frame
2. THE Camera Feed System SHALL process the manually captured frame with higher priority than automatic captures
3. THE Camera Feed System SHALL display a visual indicator that manual capture is processing
4. WHEN manual capture completes, THE Detection UI SHALL display the result in a modal dialog with options to save or discard
5. THE Camera Feed System SHALL allow manual captures even when automatic detection is paused

### Requirement 9

**User Story:** As a road inspector, I want to adjust detection sensitivity settings, so that I can optimize for different road conditions and inspection priorities

#### Acceptance Criteria

1. THE Camera Feed System SHALL provide a settings panel with a sensitivity slider ranging from 1 (low) to 5 (high)
2. WHEN sensitivity is set to 1, THE Detection API SHALL only report detections with confidence greater than 0.9
3. WHEN sensitivity is set to 5, THE Detection API SHALL report all detections with confidence greater than 0.5
4. THE Camera Feed System SHALL persist the sensitivity setting across app sessions
5. THE Detection UI SHALL display the current sensitivity level in the status bar

### Requirement 10

**User Story:** As a developer, I want comprehensive error logging and monitoring, so that I can diagnose and fix issues quickly

#### Acceptance Criteria

1. WHEN any error occurs in the Detection API, THE Detection API SHALL log the error with timestamp, user ID, request payload, and stack trace
2. THE Detection API SHALL track and log API response times for performance monitoring
3. THE Detection API SHALL log Vision LLM token usage and costs per request
4. THE Camera Feed System SHALL log camera initialization failures with device information
5. THE Camera Feed System SHALL log image compression failures with original image size and target size
6. THE Detection API SHALL expose a health check endpoint returning system status and error rates

# Implementation Plan

- [x] 1. Set up core data models and enums





  - Create DetectionType enum with all 8 types (road_crack, pothole, uneven_surface, flood, accident, debris, obstacle, normal)
  - Create DetectionModel class with fromJson/toJson methods
  - Create DetectionException class with error types enum
  - _Requirements: 2.5, 2.7_

- [x] 2. Implement image compression service








  - [x] 2.1 Create ImageCompressionService class in lib/core/services/


    - Implement compressImage() method using image package
    - Add adaptive quality reduction to meet <150KB target
    - Implement convertToBase64() method
    - _Requirements: 1.3_

- [x] 3. Implement detection API layer





  - [x] 3.1 Create AiDetectionApi class in lib/core/api/detection/


    - Implement detectRoadDamage() method with Dio HTTP client
    - Implement getDetectionHistory() method
    - Add request/response logging
    - _Requirements: 1.4, 5.1_

  - [x] 3.2 Add API constants and configuration


    - Create detection_api_constants.dart with endpoint URLs
    - Add environment-based configuration
    - _Requirements: 1.4_

- [x] 4. Implement detection repository layer




  - [x] 4.1 Create AiDetectionRepository in lib/data/repositories/


    - Implement detectFromCamera() method
    - Implement getHistory() method with filtering
    - Handle API response transformation to DetectionModel
    - _Requirements: 4.1, 5.1, 5.2_

- [x] 5. Implement offline queue management





  - [x] 5.1 Create DetectionQueueManager in lib/data/sources/local/


    - Implement enqueue() and dequeue() methods
    - Add queue persistence using shared_preferences
    - Implement processQueue() with retry logic
    - Add queueSizeStream for reactive updates
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 5.2 Create QueuedDetection model


    - Add fields for offline storage
    - Implement serialization methods
    - _Requirements: 6.1_

- [x] 6. Implement AI detection provider





  - [x] 6.1 Create AiDetectionProvider in lib/presentation/camera_detection_screen/


    - Add state properties (isProcessing, latestDetection, history, queueSize, sensitivity)
    - Implement processFrame() method
    - Implement loadHistory() method
    - Implement retryQueuedDetections() method
    - Implement setSensitivity() method
    - _Requirements: 1.1, 1.2, 3.1, 9.1, 9.2_

  - [x] 6.2 Add alert logic methods


    - Implement getAlertColor() based on severity and type
    - Implement shouldPlaySound() for red alerts
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 7. Enhance camera detection screen





  - [x] 7.1 Integrate AiDetectionProvider into CameraDetectionScreen


    - Add provider initialization in widget tree
    - Replace mock detection with real AI detection calls
    - _Requirements: 1.1, 1.2_

  - [x] 7.2 Implement 1 FPS frame capture logic

    - Modify _startDetectionSimulation() to capture real frames
    - Add frame extraction from camera stream
    - Implement 1000ms interval timer
    - _Requirements: 1.1, 1.2_

  - [x] 7.3 Add detection processing flow

    - Call ImageCompressionService on captured frame
    - Call AiDetectionProvider.processFrame()
    - Handle loading states during processing
    - _Requirements: 1.3, 1.4_

- [x] 8. Implement detection alert UI





  - [x] 8.1 Create DetectionAlertWidget


    - Display color-coded alert cards (red/yellow/green)
    - Show detection type, severity, confidence, description
    - Add dismiss and submit report actions
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6_

  - [x] 8.2 Add audio alert functionality


    - Implement sound playback for red alerts
    - Use audioplayers package
    - Add sound asset to project
    - _Requirements: 3.4_

  - [x] 8.3 Add loading indicator overlay


    - Show processing indicator during API calls
    - Display "Analyzing..." text
    - _Requirements: 3.7_

- [x] 9. Implement queue status UI






  - [x] 9.1 Create QueueStatusWidget

    - Display queue size badge
    - Show "X detections queued" message
    - Add retry button
    - _Requirements: 6.3_


  - [x] 9.2 Add network status monitoring

    - Listen to connectivity changes
    - Auto-trigger queue processing on reconnect
    - _Requirements: 6.2_

- [x] 10. Implement detection history enhancements





  - [x] 10.1 Update DetectionHistoryPanel to use real data


    - Replace mock data with AiDetectionProvider.detectionHistory
    - Add pull-to-refresh functionality
    - _Requirements: 5.1_

  - [x] 10.2 Add history filtering UI


    - Create filter bottom sheet
    - Add issue type filter chips
    - Add severity level filter
    - Add date range picker
    - _Requirements: 5.4, 5.5_

  - [x] 10.3 Add map view for detections


    - Create detection map widget
    - Plot detections as color-coded pins
    - Add pin tap to show details
    - _Requirements: 5.6_

- [x] 11. Implement manual capture enhancement





  - [x] 11.1 Add manual capture button to camera controls


    - Update CameraControlsWidget
    - Add priority processing for manual captures
    - _Requirements: 8.1, 8.2_


  - [x] 11.2 Create manual capture result dialog

    - Show detection result in modal
    - Add save/discard options
    - _Requirements: 8.4_

- [-] 12. Implement sensitivity settings


  - [-] 12.1 Create sensitivity settings panel

    - Add slider widget (1-5 scale)
    - Display current sensitivity level
    - Persist setting to shared_preferences
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ] 12.2 Add sensitivity indicator to status bar
    - Update StatusBarWidget
    - Show current sensitivity level
    - _Requirements: 9.5_

- [ ] 13. Implement backend detection endpoint
  - [ ] 13.1 Set up Node.js project structure
    - Initialize npm project
    - Install dependencies (express, @supabase/supabase-js, axios)
    - Create environment configuration
    - _Requirements: 1.4, 4.1_

  - [ ] 13.2 Create detection endpoint route
    - Implement POST /api/v1/detect handler
    - Add request validation middleware
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [ ] 13.3 Implement image upload to Supabase Storage
    - Create storage service module
    - Implement uploadImage() function
    - Generate unique file paths per user
    - _Requirements: 4.6_

  - [ ] 13.4 Implement Vision LLM integration
    - Create OpenRouter API client
    - Implement callVisionLLM() function with structured prompt
    - Add response parsing and validation
    - Implement retry logic (up to 2 retries)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ] 13.5 Implement AI response schema validation
    - Create validation function for all required fields
    - Add type checking for each field
    - Throw errors on validation failure
    - _Requirements: 2.3, 2.4_

  - [ ] 13.6 Implement database write operations
    - Create database service module
    - Implement writeToDatabase() function
    - Map AI types to issue_type_ids
    - Map AI severity to database severity enum
    - Write to report_issues, issue_photos, detection_logs tables
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9_

  - [ ] 13.7 Add error handling and logging
    - Implement error handler middleware
    - Add structured logging
    - Log API response times
    - Log LLM token usage
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 13.8 Implement rate limiting
    - Add rate limiting middleware
    - Configure per-user limits (60/min, 1000/day)
    - _Requirements: 7.5_

- [ ] 14. Create database migrations
  - [ ] 14.1 Add AI fields to report_issues table
    - Add ai_confidence column
    - Add ai_suggested_action column
    - Add detection_source column with enum
    - _Requirements: 4.9_

  - [ ] 14.2 Create detection_logs table
    - Create table with all required columns
    - Add indexes for performance
    - _Requirements: 10.2_

  - [ ] 14.3 Seed issue_types table
    - Insert 8 detection types
    - Add descriptions and icons
    - _Requirements: 2.5_

- [ ] 15. Add error handling to Flutter app
  - [ ] 15.1 Implement error handling in AiDetectionProvider
    - Add try-catch blocks in all async methods
    - Convert exceptions to DetectionException
    - Call error handler
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [ ] 15.2 Create error feedback UI
    - Implement handleDetectionError() method
    - Show appropriate SnackBar messages
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 16. Add localization strings
  - [ ] 16.1 Add detection-related strings to ARB files
    - Add alert messages
    - Add error messages
    - Add UI labels
    - Support English and Chinese
    - _Requirements: 3.1, 3.2, 3.3, 6.1, 6.2_

- [ ] 17. Configure environment and deployment
  - [ ] 17.1 Add environment configuration
    - Create .env.example with required variables
    - Add DETECTION_API_URL to Flutter environment
    - Document all environment variables
    - _Requirements: 1.4_

  - [ ] 17.2 Update pubspec.yaml dependencies
    - Add image package for compression
    - Add audioplayers for sound alerts
    - Add connectivity_plus for network monitoring
    - _Requirements: 1.3, 3.4, 6.2_

  - [ ] 17.3 Deploy backend to cloud platform
    - Choose platform (Vercel/Railway/Fly.io)
    - Configure environment variables
    - Deploy and test endpoint
    - _Requirements: 1.4_

- [ ] 18. Integration testing
  - [ ] 18.1 Test complete detection flow
    - Test camera capture → compression → API → response → UI update
    - Verify alert colors and sounds
    - Verify database writes
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.1, 3.2, 3.3, 3.4, 4.1_

  - [ ] 18.2 Test offline queue flow
    - Simulate network failure
    - Verify queue persistence
    - Verify retry on reconnect
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ] 18.3 Test sensitivity adjustment
    - Test different sensitivity levels
    - Verify confidence threshold changes
    - _Requirements: 9.1, 9.2, 9.3_

  - [ ] 18.4 Test error scenarios
    - Test invalid image
    - Test API timeout
    - Test invalid GPS coordinates
    - Verify error messages
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

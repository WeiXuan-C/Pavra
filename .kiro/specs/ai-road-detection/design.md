# Design Document

## Overview

This document outlines the technical design for implementing an AI-powered real-time road damage detection system in the Pavra Flutter application. The system captures camera frames at 1 FPS, compresses them, uploads to a backend API, processes through Vision LLM (via OpenRouter), receives structured JSON output, and automatically populates damage reports in Supabase.

### System Flow

```
Flutter Camera (1 FPS)
    ↓
Image Compression (<150KB)
    ↓
Upload to Backend API (with GPS, userId, timestamp)
    ↓
Backend → Vision LLM (OpenRouter)
    ↓
AI Structured JSON Output
    ↓
Backend → Supabase Database Write
    ↓
Response to Flutter App
    ↓
UI Update (Color-coded alerts + Audio)
```

### Key Technologies

- **Frontend**: Flutter (camera plugin, image compression, Provider state management)
- **Backend**: Node.js/Serverpod (detection endpoint, LLM integration)
- **AI**: Vision LLM via OpenRouter (GPT-4o, Qwen-VL, or similar)
- **Database**: Supabase (PostgreSQL with existing report_issues schema)
- **Storage**: Supabase Storage (compressed images)

## Architecture

### High-Level Architecture


```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Frontend)                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Presentation Layer                                     │ │
│  │  - CameraDetectionScreen (enhanced)                    │ │
│  │  - AiDetectionProvider (new)                           │ │
│  │  - Detection Alert Widgets (color-coded)               │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Data Layer                                             │ │
│  │  - AiDetectionRepository (new)                         │ │
│  │  - DetectionQueueManager (offline support)             │ │
│  │  - ImageCompressionService (new)                       │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Core Layer                                             │ │
│  │  - AiDetectionApi (new)                                │ │
│  │  - DetectionModel (new)                                │ │
│  │  - GPS Service (existing)                              │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓ HTTP POST
┌─────────────────────────────────────────────────────────────┐
│                    Backend API (Node.js)                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  POST /api/v1/detect                                   │ │
│  │  - Validate request (image, GPS, userId, timestamp)    │ │
│  │  - Upload image to Supabase Storage                    │ │
│  │  - Call Vision LLM with structured prompt              │ │
│  │  - Validate AI response schema                         │ │
│  │  - Write to Supabase (report_issues, issue_photos)     │ │
│  │  - Return detection result                             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Vision LLM (OpenRouter)                     │
│  - GPT-4o / Qwen-VL / Claude with vision                    │
│  - Structured output enforcement                            │
│  - Road damage classification                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Database                         │
│  - report_issues (enhanced with AI fields)                  │
│  - issue_photos (ai_reference type)                         │
│  - detection_logs (new table for analytics)                 │
└─────────────────────────────────────────────────────────────┘
```

### Three-Layer Architecture Integration

Following the existing project architecture:

**Presentation Layer** (`lib/presentation/camera_detection_screen/`)
- Enhanced `CameraDetectionScreen` with 1 FPS frame capture
- New `AiDetectionProvider` for AI detection state management
- Alert widgets for visual feedback

**Data Layer** (`lib/data/`)
- `AiDetectionRepository`: Bridges API and UI with type-safe models
- `DetectionQueueManager`: Handles offline queue persistence

**Core Layer** (`lib/core/`)
- `AiDetectionApi`: Business logic for detection API calls
- `ImageCompressionService`: Image processing utilities
- `DetectionModel`: Data models for AI responses

## Components and Interfaces

### 1. Flutter Components

#### 1.1 ImageCompressionService

**Location**: `lib/core/services/image_compression_service.dart`

**Purpose**: Compress camera frames to <150KB for efficient upload



**Interface**:
```dart
class ImageCompressionService {
  static const int maxSizeBytes = 150 * 1024; // 150KB
  static const int defaultQuality = 85;
  
  Future<Uint8List> compressImage({
    required XFile imageFile,
    int maxSize = maxSizeBytes,
    int quality = defaultQuality,
  });
  
  Future<String> convertToBase64(Uint8List bytes);
}
```

**Key Methods**:
- `compressImage()`: Uses `image` package to compress JPEG
- `convertToBase64()`: Converts bytes to Base64 for API upload
- Adaptive quality reduction if size exceeds limit

#### 1.2 AiDetectionApi

**Location**: `lib/core/api/detection/ai_detection_api.dart`

**Purpose**: Handle HTTP communication with backend detection endpoint

**Interface**:
```dart
class AiDetectionApi {
  final Dio _dio;
  static const String _endpoint = '/api/v1/detect';
  
  Future<Map<String, dynamic>> detectRoadDamage({
    required String imageBase64,
    required double latitude,
    required double longitude,
    required String userId,
    required DateTime timestamp,
    int sensitivity = 3,
  });
  
  Future<List<Map<String, dynamic>>> getDetectionHistory({
    required String userId,
    int limit = 50,
    String? issueType,
    DateTime? startDate,
    DateTime? endDate,
  });
}
```

**Request Payload**:
```json
{
  "image": "base64_encoded_string",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "userId": "uuid",
  "timestamp": "2025-11-18T10:30:00Z",
  "sensitivity": 3
}
```

**Response Payload**:
```json
{
  "success": true,
  "detection": {
    "id": "uuid",
    "issue_detected": true,
    "type": "pothole",
    "severity": 4,
    "description": "Large pothole on right lane, approximately 30cm diameter",
    "suggested_action": "Immediate repair required",
    "confidence": 0.94,
    "image_url": "https://storage.supabase.co/...",
    "created_at": "2025-11-18T10:30:05Z"
  }
}
```

#### 1.3 DetectionModel

**Location**: `lib/data/models/detection_model.dart`

**Purpose**: Type-safe model for AI detection results



**Interface**:
```dart
class DetectionModel {
  final String id;
  final bool issueDetected;
  final DetectionType type;
  final int severity; // 1-5
  final String description;
  final String suggestedAction;
  final double confidence; // 0.0-1.0
  final String imageUrl;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  
  factory DetectionModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

enum DetectionType {
  roadCrack,
  pothole,
  unevenSurface,
  flood,
  accident,
  debris,
  obstacle,
  normal
}
```

#### 1.4 AiDetectionRepository

**Location**: `lib/data/repositories/ai_detection_repository.dart`

**Purpose**: Bridge between API and UI, handle data transformation

**Interface**:
```dart
class AiDetectionRepository {
  final AiDetectionApi _api;
  final ImageCompressionService _compressionService;
  
  Future<DetectionModel> detectFromCamera({
    required XFile image,
    required double latitude,
    required double longitude,
    required String userId,
    int sensitivity = 3,
  });
  
  Future<List<DetectionModel>> getHistory({
    required String userId,
    int limit = 50,
    DetectionType? filterType,
    DateTime? startDate,
    DateTime? endDate,
  });
}
```

#### 1.5 DetectionQueueManager

**Location**: `lib/data/sources/local/detection_queue_manager.dart`

**Purpose**: Manage offline detection queue with persistence

**Interface**:
```dart
class DetectionQueueManager {
  static const int maxQueueSize = 100;
  
  Future<void> enqueue(QueuedDetection detection);
  Future<List<QueuedDetection>> getQueue();
  Future<void> dequeue(String id);
  Future<void> processQueue();
  Stream<int> get queueSizeStream;
}

class QueuedDetection {
  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String userId;
  final DateTime timestamp;
  final int retryCount;
}
```

**Storage**: Uses `shared_preferences` or `hive` for persistence

#### 1.6 AiDetectionProvider

**Location**: `lib/presentation/camera_detection_screen/ai_detection_provider.dart`

**Purpose**: Manage AI detection state for the camera screen



**Interface**:
```dart
class AiDetectionProvider extends ChangeNotifier {
  final AiDetectionRepository _repository;
  final DetectionQueueManager _queueManager;
  
  // State
  bool _isProcessing = false;
  DetectionModel? _latestDetection;
  List<DetectionModel> _detectionHistory = [];
  int _queueSize = 0;
  int _sensitivity = 3;
  
  // Getters
  bool get isProcessing => _isProcessing;
  DetectionModel? get latestDetection => _latestDetection;
  List<DetectionModel> get detectionHistory => _detectionHistory;
  int get queueSize => _queueSize;
  int get sensitivity => _sensitivity;
  
  // Methods
  Future<void> processFrame(XFile image, double lat, double lng, String userId);
  Future<void> loadHistory(String userId);
  Future<void> retryQueuedDetections();
  void setSensitivity(int level);
  Color getAlertColor(DetectionModel detection);
  bool shouldPlaySound(DetectionModel detection);
}
```

**Alert Logic**:
- Red alert: `severity >= 4` OR `type == accident`
- Yellow alert: `severity == 2 or 3`
- Green: `severity == 1` OR `type == normal`
- Audio: Play sound for red alerts only

### 2. Backend Components

#### 2.1 Detection Endpoint

**Route**: `POST /api/v1/detect`

**Technology**: Node.js with Express/Fastify

**Flow**:
1. Validate request payload
2. Upload image to Supabase Storage
3. Call Vision LLM with structured prompt
4. Validate AI response schema
5. Write to Supabase database
6. Return response to client

**Implementation Outline**:
```javascript
async function detectRoadDamage(req, res) {
  try {
    // 1. Validate input
    const { image, latitude, longitude, userId, timestamp, sensitivity } = req.body;
    validateInput(image, latitude, longitude, userId, timestamp);
    
    // 2. Upload to Supabase Storage
    const imageBuffer = Buffer.from(image, 'base64');
    const imageUrl = await uploadToStorage(imageBuffer, userId);
    
    // 3. Call Vision LLM
    const aiResponse = await callVisionLLM(imageUrl, sensitivity);
    
    // 4. Validate schema
    const validatedDetection = validateAIResponse(aiResponse);
    
    // 5. Write to database
    const detectionRecord = await writeToDatabase({
      ...validatedDetection,
      imageUrl,
      latitude,
      longitude,
      userId
    });
    
    // 6. Return response
    res.json({ success: true, detection: detectionRecord });
  } catch (error) {
    handleError(error, res);
  }
}
```

#### 2.2 Vision LLM Integration

**Provider**: OpenRouter (supports multiple models)

**Recommended Models**:
- GPT-4o (best accuracy, higher cost)
- Qwen-VL (good balance)
- Claude 3.5 Sonnet (vision capable)

**Structured Prompt**:


```javascript
const DETECTION_PROMPT = `You are an AI road safety inspector analyzing road conditions from camera images.

Analyze this image and detect any road hazards or damage. You must respond with ONLY a valid JSON object following this exact schema:

{
  "issue_detected": boolean,
  "type": "road_crack" | "pothole" | "uneven_surface" | "flood" | "accident" | "debris" | "obstacle" | "normal",
  "severity": 1-5 (1=very mild, 5=urgent danger),
  "description": "Detailed description of the issue including location (left/right/center lane), size, and characteristics",
  "suggested_action": "no_action" | "monitor" | "schedule_repair" | "immediate_repair" | "notify_authorities",
  "confidence": 0.0-1.0
}

Classification Guidelines:
- road_crack: Visible cracks in pavement (linear, alligator, etc.)
- pothole: Depression or hole in road surface
- uneven_surface: Bumps, dips, or uneven pavement
- flood: Standing water on road
- accident: Vehicle collision or incident
- debris: Objects blocking road (rocks, branches, trash)
- obstacle: Fixed obstacles (fallen tree, construction barrier)
- normal: No issues detected

Severity Scale:
1 = Very minor, cosmetic only
2 = Minor, monitor condition
3 = Moderate, schedule repair within weeks
4 = Serious, repair within days
5 = Critical, immediate danger to vehicles

Sensitivity Level: ${sensitivity}/5
${sensitivity >= 4 ? 'Report even minor issues with confidence > 0.5' : ''}
${sensitivity <= 2 ? 'Only report clear, significant issues with confidence > 0.8' : ''}

Respond with ONLY the JSON object, no additional text.`;
```

**API Call**:
```javascript
async function callVisionLLM(imageUrl, sensitivity = 3) {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'openai/gpt-4o',
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: DETECTION_PROMPT.replace('${sensitivity}', sensitivity) },
            { type: 'image_url', image_url: { url: imageUrl } }
          ]
        }
      ],
      response_format: { type: 'json_object' },
      max_tokens: 500,
      temperature: 0.3
    })
  });
  
  const data = await response.json();
  return JSON.parse(data.choices[0].message.content);
}
```

**Schema Validation**:
```javascript
function validateAIResponse(response) {
  const schema = {
    issue_detected: 'boolean',
    type: ['road_crack', 'pothole', 'uneven_surface', 'flood', 'accident', 'debris', 'obstacle', 'normal'],
    severity: (val) => Number.isInteger(val) && val >= 1 && val <= 5,
    description: 'string',
    suggested_action: ['no_action', 'monitor', 'schedule_repair', 'immediate_repair', 'notify_authorities'],
    confidence: (val) => typeof val === 'number' && val >= 0 && val <= 1
  };
  
  // Validate and throw if invalid
  // Retry up to 2 times if validation fails
}
```

#### 2.3 Database Operations

**Enhanced report_issues Table**:
```sql
ALTER TABLE public.report_issues ADD COLUMN IF NOT EXISTS ai_confidence DOUBLE PRECISION;
ALTER TABLE public.report_issues ADD COLUMN IF NOT EXISTS ai_suggested_action TEXT;
ALTER TABLE public.report_issues ADD COLUMN IF NOT EXISTS detection_source TEXT DEFAULT 'manual' 
  CHECK (detection_source IN ('manual', 'ai_realtime', 'ai_batch'));
```

**New detection_logs Table** (for analytics):


```sql
CREATE TABLE IF NOT EXISTS public.detection_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  issue_id UUID REFERENCES report_issues(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  ai_type TEXT NOT NULL,
  ai_severity INTEGER CHECK (ai_severity BETWEEN 1 AND 5),
  ai_confidence DOUBLE PRECISION,
  ai_description TEXT,
  ai_suggested_action TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  processing_time_ms INTEGER,
  model_used TEXT,
  token_count INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_detection_logs_user_id ON detection_logs(user_id);
CREATE INDEX idx_detection_logs_created_at ON detection_logs(created_at);
CREATE INDEX idx_detection_logs_ai_type ON detection_logs(ai_type);
```

**Database Write Function**:
```javascript
async function writeToDatabase(detection) {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  
  // Map AI type to issue_type_id
  const issueTypeId = await getIssueTypeId(detection.type);
  
  // Map AI severity to DB severity
  const severityMap = {
    1: 'minor',
    2: 'low',
    3: 'moderate',
    4: 'high',
    5: 'critical'
  };
  
  // Insert report_issue
  const { data: issue, error: issueError } = await supabase
    .from('report_issues')
    .insert({
      description: detection.description,
      issue_type_ids: [issueTypeId],
      severity: severityMap[detection.severity],
      latitude: detection.latitude,
      longitude: detection.longitude,
      status: 'draft',
      created_by: detection.userId,
      ai_confidence: detection.confidence,
      ai_suggested_action: detection.suggested_action,
      detection_source: 'ai_realtime'
    })
    .select()
    .single();
  
  // Insert issue_photo
  await supabase
    .from('issue_photos')
    .insert({
      issue_id: issue.id,
      photo_url: detection.imageUrl,
      photo_type: 'ai_reference',
      is_primary: true
    });
  
  // Insert detection_log
  await supabase
    .from('detection_logs')
    .insert({
      user_id: detection.userId,
      issue_id: issue.id,
      image_url: detection.imageUrl,
      ai_type: detection.type,
      ai_severity: detection.severity,
      ai_confidence: detection.confidence,
      ai_description: detection.description,
      ai_suggested_action: detection.suggested_action,
      latitude: detection.latitude,
      longitude: detection.longitude,
      processing_time_ms: detection.processingTime,
      model_used: 'gpt-4o',
      token_count: detection.tokenCount
    });
  
  return issue;
}
```

## Data Models

### DetectionModel (Flutter)

```dart
class DetectionModel {
  final String id;
  final bool issueDetected;
  final DetectionType type;
  final int severity;
  final String description;
  final String suggestedAction;
  final double confidence;
  final String imageUrl;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  
  DetectionModel({
    required this.id,
    required this.issueDetected,
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestedAction,
    required this.confidence,
    required this.imageUrl,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });
  
  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      id: json['id'] as String,
      issueDetected: json['issue_detected'] as bool,
      type: _parseDetectionType(json['type'] as String),
      severity: json['severity'] as int,
      description: json['description'] as String,
      suggestedAction: json['suggested_action'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }
  
  static DetectionType _parseDetectionType(String type) {
    switch (type) {
      case 'road_crack': return DetectionType.roadCrack;
      case 'pothole': return DetectionType.pothole;
      case 'uneven_surface': return DetectionType.unevenSurface;
      case 'flood': return DetectionType.flood;
      case 'accident': return DetectionType.accident;
      case 'debris': return DetectionType.debris;
      case 'obstacle': return DetectionType.obstacle;
      default: return DetectionType.normal;
    }
  }
}
```

## Error Handling

### Flutter Error Handling



**Error Types**:
```dart
class DetectionException implements Exception {
  final String message;
  final DetectionErrorType type;
  
  DetectionException(this.message, this.type);
}

enum DetectionErrorType {
  compressionFailed,
  networkError,
  apiError,
  invalidResponse,
  queueFull,
  permissionDenied
}
```

**Error Handling Strategy**:
1. **Compression Failure**: Show error toast, don't queue
2. **Network Error**: Queue detection for retry, show queued indicator
3. **API Error**: Log error, show user-friendly message
4. **Invalid Response**: Retry up to 2 times, then fail gracefully
5. **Queue Full**: Discard oldest, notify user
6. **Permission Denied**: Show permission request dialog

**User Feedback**:
```dart
void handleDetectionError(DetectionException error) {
  switch (error.type) {
    case DetectionErrorType.networkError:
      showSnackBar('Detection queued for retry when online');
      break;
    case DetectionErrorType.apiError:
      showSnackBar('Detection failed. Please try again.');
      break;
    case DetectionErrorType.queueFull:
      showSnackBar('Detection queue full. Oldest detection discarded.');
      break;
    default:
      showSnackBar('An error occurred: ${error.message}');
  }
}
```

### Backend Error Handling

**Validation Errors** (400):
- Invalid image format
- Missing required fields
- GPS coordinates out of range
- Timestamp too old/future

**Processing Errors** (500):
- LLM API failure
- Database write failure
- Storage upload failure

**Rate Limiting** (429):
- Max 60 requests per minute per user
- Max 1000 requests per day per user

**Error Response Format**:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_IMAGE",
    "message": "Image size exceeds 5MB limit",
    "details": {}
  }
}
```

## Testing Strategy

### Unit Tests

**Flutter Unit Tests**:
- `ImageCompressionService`: Test compression with various image sizes
- `DetectionModel`: Test JSON serialization/deserialization
- `DetectionQueueManager`: Test queue operations (enqueue, dequeue, persistence)
- `AiDetectionProvider`: Test state management logic

**Backend Unit Tests**:
- Input validation functions
- AI response schema validation
- Database mapping functions
- Error handling logic

### Integration Tests

**Flutter Integration Tests**:
- Camera frame capture → compression → API call flow
- Offline queue → network restore → retry flow
- Detection result → UI update flow

**Backend Integration Tests**:
- Full detection endpoint flow (mock LLM)
- Database write operations
- Storage upload operations

### E2E Tests

**Critical Flows**:
1. User opens camera → frame captured → AI detects pothole → red alert shown → report created
2. User offline → detection queued → network restored → detection processed
3. User adjusts sensitivity → detection threshold changes
4. User views history → detections loaded from database

### Performance Tests

**Metrics to Monitor**:
- Image compression time (target: <500ms)
- API response time (target: <3s)
- LLM processing time (target: <2s)
- Database write time (target: <200ms)
- Frame capture interval accuracy (target: 1000ms ±50ms)

## Security Considerations

### Authentication & Authorization

- All API requests require valid JWT token
- User can only access their own detection history
- Service role key used for backend database operations

### Input Validation

- Image size limit: 5MB (before compression)
- GPS coordinates validation: lat [-90, 90], lng [-180, 180]
- Timestamp validation: within 5 minutes of server time
- User ID validation: exists in auth.users table

### Data Privacy

- Images stored in user-specific folders in Supabase Storage
- Detection logs include user_id but can be anonymized for analytics
- RLS policies enforce user data isolation

### Rate Limiting

- Per-user rate limits to prevent abuse
- API key rotation for OpenRouter
- Cost monitoring for LLM usage

## Performance Optimization

### Image Compression

- Adaptive quality reduction algorithm
- Target size: <150KB
- Fallback to lower resolution if needed
- Cache compression settings per device

### API Optimization

- Connection pooling for database
- Image upload parallelized with LLM call (if possible)
- Response caching for identical images (optional)
- Batch processing for queued detections

### Database Optimization

- Indexes on frequently queried columns
- Partitioning detection_logs by date
- Archival strategy for old detections
- Materialized views for analytics

### Mobile Optimization

- Background processing for queue retry
- Battery-aware processing (pause when low battery)
- Data usage monitoring (warn on cellular)
- Memory management for image buffers

## Deployment Strategy

### Backend Deployment

**Environment Variables**:
```
OPENROUTER_API_KEY=sk-...
SUPABASE_URL=https://...
SUPABASE_SERVICE_KEY=...
NODE_ENV=production
PORT=3000
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_DAY=1000
```

**Deployment Steps**:
1. Deploy to cloud platform (Vercel, Railway, Fly.io)
2. Configure environment variables
3. Run database migrations
4. Test detection endpoint
5. Monitor logs and metrics

### Flutter Deployment

**Configuration**:
```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String detectionApiUrl = 
    String.fromEnvironment('DETECTION_API_URL', 
      defaultValue: 'https://api.pavra.com');
}
```

**Build Steps**:
1. Update API endpoint in environment config
2. Test on physical devices (iOS/Android)
3. Build release APK/IPA
4. Submit to app stores

## Monitoring & Analytics

### Metrics to Track

**Detection Metrics**:
- Total detections per day
- Detection types distribution
- Average confidence scores
- False positive rate (user feedback)

**Performance Metrics**:
- API response times (p50, p95, p99)
- LLM processing times
- Image compression times
- Queue size over time

**Cost Metrics**:
- LLM API costs per detection
- Storage costs
- Database query costs

**User Metrics**:
- Active users using AI detection
- Detections per user session
- Queue retry success rate

### Logging

**Backend Logs**:
- All API requests with user_id, timestamp
- LLM responses (for debugging)
- Errors with stack traces
- Performance metrics

**Flutter Logs**:
- Detection attempts (success/failure)
- Queue operations
- Compression times
- Network errors

## Future Enhancements

### Phase 2 Features

1. **Batch Processing**: Process multiple queued images in single API call
2. **Local AI Model**: On-device detection using TensorFlow Lite
3. **Video Analysis**: Continuous video stream processing
4. **Collaborative Detection**: Multiple users confirm same hazard
5. **Predictive Maintenance**: ML model predicts future road damage
6. **AR Overlay**: Show detected hazards in augmented reality view

### Scalability Improvements

1. **CDN for Images**: Use CDN for faster image delivery
2. **Edge Computing**: Process detections closer to users
3. **Model Fine-tuning**: Train custom model on road damage dataset
4. **Multi-region Deployment**: Deploy backend in multiple regions
5. **Caching Layer**: Redis cache for frequent queries

## Conclusion

This design provides a comprehensive architecture for implementing AI-powered real-time road damage detection in the Pavra app. The system follows the existing three-layer architecture, integrates seamlessly with Supabase, and provides a robust, scalable solution for automated road hazard detection.

Key design decisions:
- 1 FPS frame capture balances detection frequency with performance
- <150KB compression ensures fast uploads on mobile networks
- Structured LLM output guarantees consistent, parseable responses
- Offline queue ensures no detections are lost
- Color-coded alerts provide immediate visual feedback
- Comprehensive error handling and retry logic
- Monitoring and analytics for continuous improvement

The implementation will be done incrementally following the task list in tasks.md.

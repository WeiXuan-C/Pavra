# AI Image Analysis Flow Documentation

## Overview
The AI analysis feature uses OpenRouter's NVIDIA Nemotron Nano 12B V2 VL (Vision-Language) model to automatically analyze uploaded photos and extract issue information for manual reports.

## Architecture

### Components Involved

1. **Frontend (Flutter)**
   - `manual_report_screen.dart` - UI and user interaction
   - `manual_report_provider.dart` - State management
   - `ai_service.dart` - Client-side AI service wrapper

2. **Backend (Serverpod)**
   - `openrouter_endpoint.dart` - Server-side OpenRouter API integration

## Flow Diagram

```
User uploads photo
       ↓
Photo uploaded to Supabase Storage
       ↓
Get public photo URL
       ↓
Trigger AI analysis (manual_report_screen.dart)
       ↓
Call provider.analyzePhotoWithAI(photoUrl)
       ↓
AiService.analyzeImage() sends request to backend
       ↓
Backend (openrouter_endpoint.dart) calls OpenRouter API
       ↓
OpenRouter processes image with NVIDIA model
       ↓
Response parsed and returned to frontend
       ↓
Show AI analysis dialog with suggestions
       ↓
User can apply or dismiss suggestions
```

## Detailed Flow

### 1. Photo Upload Trigger
**Location:** `manual_report_screen.dart` → `_addPhoto()`

```dart
// After successful photo upload
if (photoType == 'main' && mounted) {
  _analyzeMainPhoto(context, provider, uploadedPhoto.photoUrl);
}
```

### 2. Analysis Initiation
**Location:** `manual_report_screen.dart` → `_analyzeMainPhoto()`

- Shows "Analyzing image with AI..." toast
- Calls `provider.analyzePhotoWithAI(photoUrl)`
- Handles errors gracefully
- Shows result dialog on success

### 3. Provider Layer
**Location:** `manual_report_provider.dart` → `analyzePhotoWithAI()`

```dart
Future<Map<String, dynamic>?> analyzePhotoWithAI(String photoUrl) async {
  _isAnalyzingImage = true;  // Set loading state
  _aiAnalysisResult = null;
  notifyListeners();
  
  try {
    final aiService = AiService();
    final result = await aiService.analyzeImage(
      imageUrl: photoUrl,
      additionalContext: 'This is a report about infrastructure or safety issues.',
    );
    
    _aiAnalysisResult = result;
    return result;
  } finally {
    _isAnalyzingImage = false;
    notifyListeners();
  }
}
```

### 4. AI Service Layer
**Location:** `ai_service.dart` → `analyzeImage()`

**Request Structure:**
```dart
{
  'prompt': '[Analysis prompt]\n\nImage URL: [photoUrl]',
  'model': 'nvidia/nemotron-nano-12b-v2-vl:free',
  'temperature': 0.3,  // Lower for factual analysis
  'maxTokens': 500
}
```

**Prompt Template:**
```
Analyze this image and identify any infrastructure or safety issues. 
Provide your response in the following JSON format:

{
  "description": "Brief description of what you see and the issue",
  "issueTypes": ["type1", "type2"],
  "severity": "minor|low|moderate|high|critical",
  "confidence": "low|medium|high"
}

Issue types: pothole, broken streetlight, damaged road, graffiti, 
illegal dumping, broken sidewalk, damaged signage, flooding, 
fallen tree, damaged fence, etc.

Severity levels:
- minor: Cosmetic issues, no immediate danger
- low: Minor inconvenience, no safety risk
- moderate: Noticeable issue, potential minor safety concern
- high: Significant issue, clear safety concern
- critical: Immediate danger, requires urgent attention
```

### 5. Backend Processing
**Location:** `openrouter_endpoint.dart` → `chat()`

**Key Features:**
- **Load Balancing:** Randomly selects from 20 available API keys
- **Error Handling:** Comprehensive logging and error responses
- **Headers:** Includes HTTP-Referer and X-Title for OpenRouter rankings

**Request to OpenRouter:**
```dart
POST https://openrouter.ai/api/v1/chat/completions
Headers:
  - Authorization: Bearer [API_KEY]
  - Content-Type: application/json
  - HTTP-Referer: [SERVERPOD_URL]
  - X-Title: Pavra App

Body:
{
  "model": "nvidia/nemotron-nano-12b-v2-vl:free",
  "messages": [
    {
      "role": "user",
      "content": "[prompt with image URL]"
    }
  ],
  "max_tokens": 500,
  "temperature": 0.3
}
```

### 6. Response Processing
**Location:** `ai_service.dart` → `_parseImageAnalysisResponse()`

**Expected Response Format:**
```json
{
  "description": "A pothole on the road surface, approximately 30cm wide",
  "issueTypes": ["pothole", "damaged road"],
  "severity": "moderate",
  "confidence": "high"
}
```

**Fallback Handling:**
- If JSON parsing fails, returns raw response as description
- Default values: severity="moderate", confidence="low"

### 7. UI Display
**Location:** `manual_report_screen.dart` → `_showAiAnalysisDialog()`

**Dialog Components:**
- Confidence badge (color-coded)
- Description text
- Suggested issue types (as chips)
- Suggested severity (with icon and color)
- Actions: "Dismiss" or "Apply Suggestions"

### 8. Apply Suggestions
**Location:** `manual_report_screen.dart` → `_applyAiSuggestions()`

**Applied Changes:**
- Updates description field (if empty)
- Updates severity slider
- Shows confirmation toast

## Recent Improvements (2024-11-28)

### ✅ Fixed: Detection History to Manual Report Flow

**Problem:** When users tapped on a detection from the history panel, they couldn't directly submit a report with pre-filled information.

**Solution Implemented:**

1. **Direct Navigation:** Modified `_onDetectionTap()` in `camera_detection_screen.dart` to navigate directly to manual report screen with detection data
2. **Image URL Support:** Updated `_loadAiDetectionData()` to accept both `capturedPhoto` (for live detections) and `imageUrl` (for historical detections)
3. **Photo Loading:** Added support for loading existing photos from URL using `provider.addPhotoFromUrl()` to avoid re-uploading
4. **Auto-fill Data:** Detection description, severity, type, and location are automatically pre-filled

**Code Changes:**
```dart
// camera_detection_screen.dart
void _onDetectionTap(DetectionModel detection) {
  Navigator.pushNamed(
    context,
    '/manual-report-screen',
    arguments: {
      'detectionData': detection,
      'latitude': detection.latitude,
      'longitude': detection.longitude,
      'fromAiDetection': true,
      'imageUrl': detection.imageUrl, // Pass stored image URL
    },
  );
}

// manual_report_screen.dart
Future<void> _loadAiDetectionData(
  DetectionModel detection,
  double? latitude,
  double? longitude, {
  XFile? capturedPhoto,
  String? imageUrl,  // New parameter
}) async {
  // ... existing code ...
  
  // Load from URL if available (detection history)
  if (imageUrl != null && imageUrl.isNotEmpty) {
    await provider.addPhotoFromUrl(
      photoUrl: imageUrl,
      photoType: 'main',
      isPrimary: true,
    );
  }
}
```

**User Flow Now:**
1. User opens detection history panel
2. User taps on a detection → **Directly navigates to manual report screen**
3. Photo, description, severity, and type are **pre-filled**
4. User reviews and confirms → Submits report

## Current Issues

### ❌ Problem: Image URL Not Sent Correctly to AI Model

The current implementation sends the image URL as **plain text** in the prompt, but OpenRouter's vision models require a **structured message format** with `image_url` type.

**Current (Incorrect):**
```dart
'prompt': '$prompt\n\nImage URL: $imageUrl'
```

**Required (Correct):**
```json
{
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "What is in this image?"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "https://example.com/image.jpg"
          }
        }
      ]
    }
  ]
}
```

## Required Fixes

### 1. Update Backend Endpoint
Add support for structured content with image URLs:

```dart
// openrouter_endpoint.dart
Future<Map<String, dynamic>> chatWithVision({
  required Session session,
  required String textPrompt,
  required String imageUrl,
  String? model,
  int? maxTokens,
  double? temperature,
}) async {
  // ... API key logic ...
  
  final response = await http.post(
    Uri.parse(_openRouterUrl),
    headers: { /* ... */ },
    body: jsonEncode({
      'model': selectedModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': textPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': imageUrl,
              }
            }
          ]
        }
      ],
      'max_tokens': maxTokens ?? 500,
      'temperature': temperature ?? 0.3,
    }),
  );
  
  // ... response handling ...
}
```

### 2. Update AI Service
Modify to use the new vision endpoint:

```dart
// ai_service.dart
Future<Map<String, dynamic>> analyzeImage({
  required String imageUrl,
  String? additionalContext,
}) async {
  final prompt = _buildImageAnalysisPrompt(additionalContext);
  
  final response = await http.post(
    Uri.parse('$serverUrl/openrouter/chatWithVision'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'textPrompt': prompt,
      'imageUrl': imageUrl,
      'model': 'nvidia/nemotron-nano-12b-v2-vl:free',
      'temperature': 0.3,
      'maxTokens': 500,
    }),
  );
  
  // ... rest of the code ...
}
```

## State Management

### Provider States
- `_isAnalyzingImage` - Boolean flag for loading state
- `_aiAnalysisResult` - Cached analysis result
- `_error` - Error message if analysis fails

### UI States
- Loading: Shows toast "Analyzing image with AI..."
- Success: Shows dialog with analysis results
- Error: Shows error toast

## Error Handling

### Network Errors
- Caught in `ai_service.dart`
- Wrapped in `AiException`
- Displayed as toast to user

### API Errors
- HTTP status codes handled in backend
- Error details logged to Serverpod
- Generic error message shown to user

### Parsing Errors
- Fallback to raw response text
- Default values used for missing fields
- Low confidence indicator shown

## Performance Considerations

1. **API Key Rotation:** 20 keys for load balancing
2. **Temperature:** 0.3 for consistent, factual responses
3. **Max Tokens:** 500 to limit response size
4. **Timeout:** Default HTTP timeout (no custom timeout set)

## Security

1. **API Keys:** Stored in environment variables
2. **Image URLs:** Must be publicly accessible
3. **HTTPS:** All requests use secure connections
4. **No PII:** Image analysis doesn't store personal data

## Future Improvements

1. ✅ Add progress indicator during analysis
2. ✅ Detection history to manual report flow with pre-filled data
3. ⚠️ Fix image URL format for vision model (structured content)
4. ⚠️ Add retry mechanism for failed requests
5. ⚠️ Cache analysis results to avoid duplicate calls
6. ⚠️ Add timeout handling (30s recommended)
7. ⚠️ Support batch image analysis
8. ⚠️ Add confidence threshold filtering
9. ⚠️ Implement rate limiting on client side

import 'dart:io';

/// API Configuration
class ApiConfig {
  /// OneSignal App ID
  static String get oneSignalAppId {
    final appId = Platform.environment['ONESIGNAL_APP_ID'];
    if (appId == null || appId.isEmpty) {
      throw Exception(
        'ONESIGNAL_APP_ID not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return appId;
  }

  /// OneSignal API Key
  static String get oneSignalApiKey {
    final apiKey = Platform.environment['ONESIGNAL_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'ONESIGNAL_API_KEY not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return apiKey;
  }
}

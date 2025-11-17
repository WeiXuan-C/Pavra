import 'dart:io';

/// API Configuration
class ApiConfig {
  /// Serverpod API base URL
  ///
  /// 在生产环境中，应该从环境变量或配置文件读取
  /// 开发环境：http://localhost:8080
  /// 生产环境：https://your-domain.com
  static String get serverpodUrl {
    // 优先使用环境变量
    final envUrl = Platform.environment['SERVERPOD_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // 开发环境默认值
    return 'http://localhost:8080';
  }

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

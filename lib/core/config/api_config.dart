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
    return Platform.environment['ONESIGNAL_APP_ID'] ??
        '2eebafba-17aa-49a6-91aa-f9f7f2f72aca';
  }

  /// OneSignal API Key
  static String get oneSignalApiKey {
    return Platform.environment['ONESIGNAL_API_KEY'] ??
        'os_v2_app_f3v27oqxvje2nenk7h37f5zkzlnemkqsxkuezzffpgs3ug34lfz4gluj5rzlhqysuixzw5yr6lp4t36yxkj3r7camutveielpkqx24i';
  }
}

import 'package:flutter/material.dart';
import 'package:hcaptcha/hcaptcha.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HCaptchaService {
  static final HCaptchaService _instance = HCaptchaService._internal();
  factory HCaptchaService() => _instance;
  HCaptchaService._internal();

  final String _siteKey = dotenv.get('HCAPTCHA_SITE_KEY');
  final String _apiUrl = 'https://hcaptcha.com/1/api.js';

  /// Initialize hCaptcha with site key and API URL
  void initialize() {
    HCaptcha.init(
      siteKey: _siteKey,
      initialUrl: _apiUrl,
    );
  }

  /// Verify hCaptcha and return the token
  ///
  /// Throws an exception if verification fails
  Future<String> verify(BuildContext context) async {
    try {
      initialize();
      final result = await HCaptcha.show(context);
      
      if (result == null || result['code'] == null) {
        throw Exception('Failed to verify hCaptcha');
      }

      return result['code'] as String;
    } catch (e) {
      debugPrint('hCaptcha verification error: $e');
      rethrow;
    }
  }
}

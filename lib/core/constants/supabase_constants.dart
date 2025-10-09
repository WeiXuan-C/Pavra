import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration constants
/// All values are loaded from .env file
class SupabaseConstants {
  // Core Supabase configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  
  // hCaptcha configuration (optional, for client-side captcha display)
  static String? get hCaptchaSiteKey => dotenv.env['HCAPTCHA_SITE_KEY'];
  
  // OAuth Redirect URIs (platform-specific)
  static String? get redirectUriAndroid => dotenv.env['REDIRECT_URI_ANDROID'];
  static String? get redirectUriIos => dotenv.env['REDIRECT_URI_IOS'];
  static String? get redirectUriWeb => dotenv.env['REDIRECT_URI_WEB'];
  
  SupabaseConstants._();
}

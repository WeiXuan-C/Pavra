import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../constants/supabase_constants.dart';
import '../services/hcaptcha_service.dart';

/// Authentication Service
/// Handles all authentication-related operations including:
/// - Passwordless Email OTP
/// - Social OAuth (Google, GitHub, Facebook, Discord)
/// - Profile management
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Quick access to auth client
  GoTrueClient get auth => supabase.auth;

  // Authentication getters
  User? get currentUser => supabase.auth.currentUser;
  Session? get currentSession => supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String deviceToken,
    Map<String, dynamic>? data,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'device_token': deviceToken, ...?data},
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Reset password for email
  Future<void> resetPasswordForEmail(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  /// Update user metadata
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await supabase.auth.updateUser(
      UserAttributes(email: email, password: password, data: data),
    );
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Sign in with OAuth provider (Google, Apple, etc.)
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    return await supabase.auth.signInWithOAuth(provider);
  }

  /// Verify OTP (One-Time Password)
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    return await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  // ========== PASSWORDLESS EMAIL OTP ==========

  /// Send email OTP for passwordless authentication
  ///
  /// This method will automatically handle hCaptcha verification
  /// before sending the OTP to the provided email.
  ///
  /// Throws an exception if hCaptcha verification fails
  Future<void> sendEmailOtp({
    required BuildContext context,
    required String email,
  }) async {
    try {
      // Get hCaptcha token
      final hcaptchaService = HCaptchaService();
      final captchaToken = await hcaptchaService.verify(context);

      // Send OTP with hCaptcha token
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // We use OTP, not magic link
        captchaToken: captchaToken,
      );
    } catch (e) {
      developer.log('Failed to send OTP: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Verify email OTP and complete authentication
  /// Returns AuthResponse with user session upon success
  ///
  /// Example:
  /// ```dart
  /// final response = await authService.verifyEmailOtp(
  ///   email: 'user@example.com',
  ///   otp: '123456',
  /// );
  /// print('Logged in: ${response.user?.email}');
  /// ```
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    return await supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
  }

  // ========== SOCIAL OAUTH LOGIN ==========

  /// Sign in with OAuth provider (Google, GitHub, Facebook, Discord)
  /// Automatically uses platform-specific redirect URIs
  ///
  /// For mobile: Uses custom URL scheme (e.g., myapp://callback)
  /// For web: Uses web callback URL
  ///
  /// Example:
  /// ```dart
  /// await authService.signInWithProvider(OAuthProvider.google);
  /// ```
  Future<bool> signInWithProvider(OAuthProvider provider) async {
    // Determine redirect URI based on platform
    String? redirectTo;
    if (Platform.isAndroid) {
      redirectTo = SupabaseConstants.redirectUriAndroid;
    } else if (Platform.isIOS) {
      redirectTo = SupabaseConstants.redirectUriIos;
    } else {
      redirectTo = SupabaseConstants.redirectUriWeb;
    }

    return await supabase.auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // Convenience methods for specific providers
  Future<bool> signInWithGoogle() => signInWithProvider(OAuthProvider.google);
  Future<bool> signInWithGithub() => signInWithProvider(OAuthProvider.github);
  Future<bool> signInWithFacebook() =>
      signInWithProvider(OAuthProvider.facebook);
  Future<bool> signInWithDiscord() => signInWithProvider(OAuthProvider.discord);

  // ========== PROFILE MANAGEMENT ==========

  /// Create a profile entry for the user if it doesn't exist
  /// This is a fallback in case the database trigger fails
  ///
  /// Should be called after successful authentication
  /// The database trigger should handle this automatically, but this provides a safety net
  Future<void> createProfileIfNotExists(User user) async {
    try {
      // Check if profile already exists
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Profile doesn't exist, create it
        await supabase.from('profiles').insert({
          'id': user.id,
          'username':
              user.email?.split('@')[0] ?? 'user_${user.id.substring(0, 8)}',
          'avatar_url': user.userMetadata?['avatar_url'],
          'bio': null,
        });
      }
    } catch (e) {
      // Log error but don't throw - profile creation should not block authentication
      developer.log(
        'Error creating profile: $e',
        name: 'AuthService',
        error: e,
      );
    }
  }

  /// Get user profile from profiles table
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      developer.log(
        'Error fetching profile: $e',
        name: 'AuthService',
        error: e,
      );
      return null;
    }
  }

  /// Update user profile in profiles table
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;

    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('id', userId);
    }
  }
}

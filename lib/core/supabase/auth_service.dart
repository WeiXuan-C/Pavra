import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../constants/supabase_constants.dart';
import '../../data/repositories/user_repository.dart';
import '../models/user_model.dart';

/// Authentication Service
/// Handles all authentication-related operations including:
/// - Passwordless Email OTP
/// - Social OAuth (Google, GitHub, Facebook, Discord)
/// - Profile management (使用 UserRepository)
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // User Repository for profile operations
  final _userRepository = UserRepository();

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
    Map<String, dynamic>? data,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
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
  /// For mobile platforms, sets emailRedirectTo for deep linking support.
  /// For web platforms, emailRedirectTo is null as it's not needed.
  Future<void> sendEmailOtp({required String email}) async {
    try {
      developer.log('=== Starting OTP Send Process ===', name: 'AuthService');
      developer.log('Email: $email', name: 'AuthService');
      developer.log(
        'Platform: ${Platform.operatingSystem}',
        name: 'AuthService',
      );
      developer.log('Is Web: $kIsWeb', name: 'AuthService');

      // Determine redirect URL based on platform
      // For web: null (OTP only, no redirect needed)
      // For mobile: use custom URL scheme for deep linking
      String? redirectTo;
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          redirectTo = SupabaseConstants.redirectUriAndroid;
          developer.log(
            'Using Android redirect: $redirectTo',
            name: 'AuthService',
          );
        } else if (Platform.isIOS) {
          redirectTo = SupabaseConstants.redirectUriIos;
          developer.log('Using iOS redirect: $redirectTo', name: 'AuthService');
        }
      } else {
        developer.log('Web platform - no redirect needed', name: 'AuthService');
      }

      // Check Supabase configuration
      developer.log(
        'Supabase URL configured: ${SupabaseConstants.supabaseUrl.isNotEmpty}',
        name: 'AuthService',
      );
      developer.log(
        'Supabase Key configured: ${SupabaseConstants.supabaseAnonKey.isNotEmpty}',
        name: 'AuthService',
      );

      // Send OTP
      developer.log(
        'Calling supabase.auth.signInWithOtp...',
        name: 'AuthService',
      );
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectTo,
      );

      developer.log('✅ OTP sent successfully!', name: 'AuthService');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to send OTP: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      developer.log('Error type: ${e.runtimeType}', name: 'AuthService');
      if (e is AuthException) {
        developer.log('Auth error message: ${e.message}', name: 'AuthService');
        developer.log(
          'Auth error status: ${e.statusCode}',
          name: 'AuthService',
        );
      }
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
      final exists = await _userRepository.profileExists(user.id);

      if (!exists) {
        // Profile doesn't exist, create it
        await _userRepository.createProfile(
          userId: user.id,
          username:
              user.email?.split('@')[0] ?? 'user_${user.id.substring(0, 8)}',
          email: user.email,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
        );
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
  /// Returns UserProfile model
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      developer.log('=== AuthService.getUserProfile ===', name: 'AuthService');
      developer.log('Fetching profile for: $userId', name: 'AuthService');

      final profile = await _userRepository.getProfileById(userId);

      if (profile != null) {
        developer.log('✅ Profile mapped successfully', name: 'AuthService');
        developer.log('Username: ${profile.username}', name: 'AuthService');
        developer.log('Role: ${profile.role}', name: 'AuthService');
      } else {
        developer.log('⚠️ Profile is null after mapping', name: 'AuthService');
      }

      developer.log('===================================', name: 'AuthService');
      return profile;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error fetching/mapping profile: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update user profile in profiles table
  /// Returns updated UserProfile model
  Future<UserProfile?> updateUserProfile({
    required String userId,
    String? username,
    String? avatarUrl,
    String? email,
    String? language,
    String? themeMode,
    bool? notificationsEnabled,
  }) async {
    try {
      return await _userRepository.updateProfile(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        email: email,
        language: language,
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
      );
    } catch (e) {
      developer.log(
        'Error updating profile: $e',
        name: 'AuthService',
        error: e,
      );
      return null;
    }
  }
}

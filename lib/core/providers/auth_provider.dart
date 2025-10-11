import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/auth_service.dart';
import '../models/user_model.dart';

/// Authentication Provider
/// Manages authentication state and provides methods for auth operations
/// Uses ChangeNotifier for state management with Provider pattern
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // State variables
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  // Theme and locale state
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  AuthProvider() {
    _initialize();
  }

  /// Initialize auth state and listen to auth changes
  void _initialize() {
    // Get current user if exists
    _user = _authService.currentUser;

    if (_user != null) {
      _loadUserProfile();
    }

    // Subscribe to auth state changes
    _authSubscription = _authService.authStateChanges.listen(
      (AuthState state) {
        _handleAuthStateChange(state);
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Handle authentication state changes
  Future<void> _handleAuthStateChange(AuthState state) async {
    final event = state.event;

    if (event == AuthChangeEvent.signedIn) {
      _user = state.session?.user;
      if (_user != null) {
        // Ensure profile exists (fallback if trigger fails)
        await _authService.createProfileIfNotExists(_user!);
        await _loadUserProfile();
      }
    } else if (event == AuthChangeEvent.signedOut) {
      _user = null;
      _userProfile = null;
    } else if (event == AuthChangeEvent.userUpdated) {
      _user = state.session?.user;
      await _loadUserProfile();
    }

    notifyListeners();
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      _userProfile = await _authService.getUserProfile(_user!.id);
    } catch (e) {
      _errorMessage = 'Error loading user profile: $e';
    }
  }

  // ========== AUTHENTICATION METHODS ==========

  /// Send OTP to email for passwordless authentication
  Future<bool> sendOtp(String email) async {
    developer.log('=== AuthProvider: sendOtp called ===', name: 'AuthProvider');
    developer.log('Email: $email', name: 'AuthProvider');
    
    _setLoading(true);
    _clearError();

    try {
      developer.log('Calling AuthService.sendEmailOtp...', name: 'AuthProvider');
      await _authService.sendEmailOtp(email: email);
      developer.log('✅ AuthProvider: OTP sent successfully', name: 'AuthProvider');
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to send OTP: ${e.toString()}';
      developer.log('❌ AuthProvider: $errorMsg', name: 'AuthProvider', error: e, stackTrace: stackTrace);
      _setError(errorMsg);
      _setLoading(false);
      return false;
    }
  }

  /// Verify OTP and complete authentication
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyEmailOtp(
        email: email,
        otp: otp,
      );

      if (response.user != null) {
        _user = response.user;
        // Profile creation is handled by auth state change listener
        _setLoading(false);
        return true;
      } else {
        _setError('Invalid OTP code');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Verification failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with social OAuth provider
  Future<bool> socialSignIn(OAuthProvider provider) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.signInWithProvider(provider);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Social login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() => socialSignIn(OAuthProvider.google);

  /// Sign in with GitHub
  Future<bool> signInWithGithub() => socialSignIn(OAuthProvider.github);

  /// Sign in with Facebook
  Future<bool> signInWithFacebook() => socialSignIn(OAuthProvider.facebook);

  /// Sign in with Discord
  Future<bool> signInWithDiscord() => socialSignIn(OAuthProvider.discord);

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      _setLoading(false);
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
      _setLoading(false);
    }
  }

  // ========== PROFILE METHODS ==========

  /// Update user profile
  Future<bool> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(
        userId: _user!.id,
        username: username,
        avatarUrl: avatarUrl,
      );

      // Reload profile
      await _loadUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ========== THEME & LOCALE METHODS ==========

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Set locale
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  // ========== HELPER METHODS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

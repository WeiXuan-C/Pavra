import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/auth_service.dart';
import '../models/user_model.dart';
import '../services/action_log_client.dart';
import '../services/onesignal_service.dart';
import 'locale_provider.dart';
import 'theme_provider.dart';

/// Authentication Provider
/// Manages authentication state and provides methods for auth operations
/// Uses ChangeNotifier for state management with Provider pattern
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ActionLogClient _actionLog = ActionLogClient();

  // Optional providers for syncing theme and language
  LocaleProvider? _localeProvider;
  ThemeProvider? _themeProvider;

  // State variables
  User? _user;
  UserProfile? _userProfile;
  bool _isInitializing = true; // For app initialization
  bool _isLoading = false; // For operations (sendOtp, verifyOtp, etc.)
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isInitializing => _isInitializing; // Used by RouteGuard
  bool get isLoading => _isLoading; // Used by UI components
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initialize();
  }

  /// Set providers for syncing theme and language settings
  /// Should be called after providers are initialized
  void setProviders({
    LocaleProvider? localeProvider,
    ThemeProvider? themeProvider,
  }) {
    _localeProvider = localeProvider;
    _themeProvider = themeProvider;
  }

  /// Initialize auth state and listen to auth changes
  Future<void> _initialize() async {
    _isInitializing = true;
    notifyListeners();

    // Get current user if exists
    _user = _authService.currentUser;

    if (_user != null) {
      await _loadUserProfile();
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

    // Initialization complete
    _isInitializing = false;
    notifyListeners();
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

        // 🔔 Set OneSignal External User ID
        try {
          await OneSignalService().setExternalUserId(_user!.id);
          developer.log(
            '✓ OneSignal External User ID set: ${_user!.id}',
            name: 'AuthProvider',
          );
        } catch (e) {
          developer.log(
            '⚠️ Failed to set OneSignal External User ID: $e',
            name: 'AuthProvider',
          );
        }

        // 🔥 Log sign-in action to backend
        _actionLog.logSignIn(
          userId: _user!.id,
          email: _user!.email ?? 'unknown',
          metadata: {
            'provider': _user!.appMetadata['provider'] ?? 'email',
            'platform': 'flutter_app',
          },
        );
      }
    } else if (event == AuthChangeEvent.signedOut) {
      // 🔥 Log sign-out action to backend
      if (_user != null) {
        _actionLog.logSignOut(userId: _user!.id, email: _user!.email);
      }

      // 🔔 Remove OneSignal External User ID
      try {
        await OneSignalService().removeExternalUserId();
        developer.log(
          '✓ OneSignal External User ID removed',
          name: 'AuthProvider',
        );
      } catch (e) {
        developer.log(
          '⚠️ Failed to remove OneSignal External User ID: $e',
          name: 'AuthProvider',
        );
      }

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

    developer.log('=== Loading User Profile ===', name: 'AuthProvider');
    developer.log('User ID: ${_user!.id}', name: 'AuthProvider');
    developer.log('User Email: ${_user!.email}', name: 'AuthProvider');

    try {
      _userProfile = await _authService.getUserProfile(_user!.id);

      if (_userProfile != null) {
        developer.log('✅ Profile loaded successfully', name: 'AuthProvider');
        developer.log(
          'Username: ${_userProfile!.username}',
          name: 'AuthProvider',
        );
        developer.log('Role: ${_userProfile!.role}', name: 'AuthProvider');
        developer.log('Email: ${_userProfile!.email}', name: 'AuthProvider');
        developer.log(
          'Language: ${_userProfile!.language}',
          name: 'AuthProvider',
        );
        developer.log(
          'Theme Mode: ${_userProfile!.themeMode}',
          name: 'AuthProvider',
        );

        // Sync theme and language settings from user profile
        await _syncUserPreferences();
      } else {
        developer.log('⚠️ Profile is NULL after query', name: 'AuthProvider');
        developer.log(
          'This means the query returned null',
          name: 'AuthProvider',
        );
      }
    } catch (e) {
      _errorMessage = 'Error loading user profile: $e';
      developer.log(
        '❌ Error loading profile: $e',
        name: 'AuthProvider',
        error: e,
      );
    }

    developer.log('===========================', name: 'AuthProvider');
  }

  /// Sync user preferences (theme and language) from profile to providers
  /// Only syncs if there's a difference to avoid circular updates
  Future<void> _syncUserPreferences() async {
    if (_userProfile == null) return;

    try {
      // Sync language
      if (_localeProvider != null) {
        final languageCode = _userProfile!.language;
        final currentLocale = _localeProvider!.locale.languageCode;

        if (languageCode != currentLocale) {
          developer.log(
            '🌐 Syncing language: $currentLocale -> $languageCode',
            name: 'AuthProvider',
          );
          await _localeProvider!.setLocale(Locale(languageCode));
        }
      }

      // Sync theme mode
      if (_themeProvider != null) {
        final themeModeString = _userProfile!.themeMode;
        ThemeMode themeMode;

        switch (themeModeString.toLowerCase()) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            themeMode = ThemeMode.system;
            break;
        }

        final currentThemeMode = _themeProvider!.themeMode;
        if (themeMode != currentThemeMode) {
          developer.log(
            '🎨 Syncing theme: $currentThemeMode -> $themeMode',
            name: 'AuthProvider',
          );
          await _themeProvider!.setThemeMode(themeMode);
        }
      }
    } catch (e) {
      developer.log(
        '⚠️ Error syncing user preferences: $e',
        name: 'AuthProvider',
        error: e,
      );
    }
  }

  /// Manually sync user preferences (useful after settings changes)
  Future<void> syncUserPreferences() async {
    await _syncUserPreferences();
  }

  // ========== AUTHENTICATION METHODS ==========

  /// Send OTP to email for passwordless authentication
  Future<bool> sendOtp(String email) async {
    developer.log('=== AuthProvider: sendOtp called ===', name: 'AuthProvider');
    developer.log('Email: $email', name: 'AuthProvider');

    _setLoading(true);
    _clearError();

    try {
      developer.log(
        'Calling AuthService.sendEmailOtp...',
        name: 'AuthProvider',
      );
      await _authService.sendEmailOtp(email: email);
      developer.log(
        '✅ AuthProvider: OTP sent successfully',
        name: 'AuthProvider',
      );
      _setLoading(false);
      return true;
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to send OTP: ${e.toString()}';
      developer.log(
        '❌ AuthProvider: $errorMsg',
        name: 'AuthProvider',
        error: e,
        stackTrace: stackTrace,
      );
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

        // 🔥 Check if this is a new user (sign-up) or existing user (sign-in)
        // New users created within the last minute are considered sign-ups
        final user = response.session?.user;
        final createdAt = user?.createdAt;
        final isNewUser =
            createdAt != null &&
            DateTime.now().difference(DateTime.parse(createdAt)).inMinutes < 1;

        if (isNewUser) {
          // Log as sign-up
          _actionLog.logSignUp(
            userId: _user!.id,
            email: email,
            username: email.split('@')[0],
            metadata: {'auth_method': 'email_otp', 'platform': 'flutter_app'},
          );
        }
        // Note: sign-in is logged in _handleAuthStateChange

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
  Future<bool> updateProfile({String? username, String? avatarUrl}) async {
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

  /// Manually reload user profile (useful for debugging or forcing refresh)
  Future<void> reloadUserProfile() async {
    if (_user != null) {
      await _loadUserProfile();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

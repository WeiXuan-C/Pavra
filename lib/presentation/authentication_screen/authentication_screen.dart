import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import 'widgets/login_widget.dart';
import 'widgets/otp_widget.dart';

/// Authentication Screen
/// Main screen for login and OTP verification
class AuthenticationScreen extends StatefulWidget {
  static const String routeName = '/authentication';

  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _showOtpWidget = false;
  String _email = '';

  /// Called when OTP is sent successfully
  void _onOtpSent(String email) {
    setState(() {
      _email = email;
      _showOtpWidget = true;
    });
  }

  /// Called when going back from OTP screen
  void _onBackToLogin() {
    setState(() {
      _showOtpWidget = false;
      _email = '';
    });
  }

  /// Called when OTP is verified successfully
  void _onOtpVerified() {
    // Navigation handled by main.dart auth state listener
    // User will be automatically redirected to home screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Show loading indicator if processing
            if (authProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show appropriate widget based on state
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showOtpWidget
                  ? OtpWidget(
                      key: const ValueKey('otp'),
                      email: _email,
                      onVerified: _onOtpVerified,
                      onBack: _onBackToLogin,
                    )
                  : LoginWidget(
                      key: const ValueKey('login'),
                      onOtpSent: _onOtpSent,
                    ),
            );
          },
        ),
      ),
    );
  }
}

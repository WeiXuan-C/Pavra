import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';

/// Login Widget
/// Allows users to enter email for OTP or use social login
class LoginWidget extends StatefulWidget {
  final Function(String email) onOtpSent;

  const LoginWidget({super.key, required this.onOtpSent});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate email format
  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.auth_emailHint;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return l10n.auth_invalidEmail;
    }

    return null;
  }

  /// Send OTP to email
  Future<void> _sendOtp() async {
    developer.log('=== LoginWidget: _sendOtp called ===', name: 'LoginWidget');

    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'LoginWidget');
      return;
    }

    if (!mounted) {
      developer.log('Widget not mounted, aborting', name: 'LoginWidget');
      return;
    }

    setState(() => _isProcessing = true);
    developer.log('UI state: _isProcessing = true', name: 'LoginWidget');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    developer.log('Email input: $email', name: 'LoginWidget');
    developer.log('Calling authProvider.sendOtp...', name: 'LoginWidget');

    final success = await authProvider.sendOtp(email);

    // Critical: Check mounted immediately after async call
    if (!mounted) {
      developer.log(
        'Widget unmounted after sendOtp, aborting',
        name: 'LoginWidget',
      );
      return;
    }

    setState(() => _isProcessing = false);
    developer.log('UI state: _isProcessing = false', name: 'LoginWidget');

    // Use post-frame callback to safely show snackbars
    if (success) {
      developer.log('✅ OTP sent successfully!', name: 'LoginWidget');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.auth_otpSent),
            backgroundColor: Colors.green,
          ),
        );
      });
      widget.onOtpSent(email);
    } else {
      developer.log(
        '❌ Failed to send OTP: ${authProvider.errorMessage}',
        name: 'LoginWidget',
      );
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? l10n.auth_otpFailed),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  /// Handle social login
  Future<void> _handleSocialLogin(String provider) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    switch (provider) {
      case 'google':
        success = await authProvider.signInWithGoogle();
        break;
      case 'github':
        success = await authProvider.signInWithGithub();
        break;
      case 'discord':
        success = await authProvider.signInWithDiscord();
        break;
      default:
        success = false;
    }

    // Critical: Check mounted immediately after async call
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!success) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? l10n.auth_verifyFailed),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),

            // App Icon/Logo
            Image.asset(
              'assets/images/logo-only-with-transparent-bg.png',
              width: 80,
              height: 80,
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              l10n.auth_welcomeTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              l10n.auth_welcomeSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Email Input
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                labelText: l10n.auth_emailLabel,
                hintText: l10n.auth_emailHint,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              validator: _validateEmail,
              onFieldSubmitted: (_) => _sendOtp(),
            ),

            const SizedBox(height: 16),

            // Send OTP Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.auth_sendOtp,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.auth_orContinueWith,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),

            const SizedBox(height: 32),

            // Social Login Buttons
            _SocialLoginButton(
              icon: Icons.g_mobiledata,
              label: l10n.auth_signInWithGoogle,
              color: Colors.red,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin('google'),
            ),

            const SizedBox(height: 12),

            _SocialLoginButton(
              icon: Icons.code,
              label: l10n.auth_signInWithGithub,
              color: Colors.green,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin('github'),
            ),

            const SizedBox(height: 12),

            _SocialLoginButton(
              icon: Icons.discord,
              label: l10n.auth_signInWithDiscord,
              color: Colors.blue,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin('discord'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Social Login Button Widget
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

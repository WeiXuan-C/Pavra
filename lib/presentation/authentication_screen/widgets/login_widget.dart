import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Send OTP to email
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    final success = await authProvider.sendOtp(email, context: context);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onOtpSent(email);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle social login
  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.socialSignIn(provider);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Social login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),

            // App Icon/Logo
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Welcome to Pavra',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Sign in to continue',
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
                labelText: 'Email',
                hintText: 'Enter your email',
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
                  : const Text('Send OTP', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey[600])),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),

            const SizedBox(height: 32),

            // Social Login Buttons
            _SocialLoginButton(
              icon: Icons.g_mobiledata,
              label: 'Continue with Google',
              color: Colors.red,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin(OAuthProvider.google),
            ),

            const SizedBox(height: 12),

            _SocialLoginButton(
              icon: Icons.code,
              label: 'Continue with GitHub',
              color: Colors.black,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin(OAuthProvider.github),
            ),

            const SizedBox(height: 12),

            _SocialLoginButton(
              icon: Icons.facebook,
              label: 'Continue with Facebook',
              color: Colors.blue[700]!,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin(OAuthProvider.facebook),
            ),

            const SizedBox(height: 12),

            _SocialLoginButton(
              icon: Icons.discord,
              label: 'Continue with Discord',
              color: Colors.indigo,
              onPressed: _isProcessing
                  ? null
                  : () => _handleSocialLogin(OAuthProvider.discord),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';

/// OTP Widget
/// 6-digit OTP input for email verification
class OtpWidget extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  const OtpWidget({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onBack,
  });

  @override
  State<OtpWidget> createState() => _OtpWidgetState();
}

class _OtpWidgetState extends State<OtpWidget> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isProcessing = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Get complete OTP code
  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  /// Verify OTP code
  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.auth_invalidOtp),
            backgroundColor: Colors.orange,
          ),
        );
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.email, _otpCode);

    // Critical: Check mounted immediately after async call
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.common_success),
            backgroundColor: Colors.green,
          ),
        );
      });
      widget.onVerified();
    } else {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.auth_invalidOtp),
            backgroundColor: Colors.red,
          ),
        );
      });

      // Clear OTP fields on error
      for (var controller in _controllers) {
        controller.clear();
      }
      if (_focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    }
  }

  /// Resend OTP
  Future<void> _resendOtp() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isProcessing = true);

    try {
      final success = await authProvider.sendOtp(widget.email);

      // Critical: Check mounted immediately after async call
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.auth_otpSent),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.auth_otpFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.auth_verifyFailed),
            backgroundColor: Colors.red,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _isProcessing ? null : widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),

          const SizedBox(height: 20),

          // Icon
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            l10n.auth_otpTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            l10n.auth_otpSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            widget.email,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: !_isProcessing,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      // Move to next field
                      if (index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        // Last field - trigger verification
                        _focusNodes[index].unfocus();
                        if (_otpCode.length == 6) {
                          _verifyOtp();
                        }
                      }
                    } else if (value.isEmpty && index > 0) {
                      // Move to previous field on delete
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Verify Button
          ElevatedButton(
            onPressed: _isProcessing ? null : _verifyOtp,
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
                : Text(l10n.auth_verify, style: const TextStyle(fontSize: 16)),
          ),

          const SizedBox(height: 24),

          // Resend OTP
          Center(
            child: TextButton(
              onPressed: _isProcessing ? null : _resendOtp,
              child: Text(l10n.auth_resendCode),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

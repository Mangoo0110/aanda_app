import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:aanda/src/features/auth/domain/usecases/verify_password_reset_otp.dart';

/// Screen allowing the user to request a password reset email/OTP and verify the code.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _isSending = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _errorMessage;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _sendResetCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final sendEmail = context.read<SendPasswordResetEmail>();
    final result = await sendEmail(email);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isSending = false;
        _codeSent = true;
      });
      _startCooldown();
    } else {
      setState(() {
        _isSending = false;
        _errorMessage = result.message.isNotEmpty
            ? result.message
            : 'Failed to send reset email. Please try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit recovery code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final verifyOtp = context.read<VerifyPasswordResetOtp>();
    final result = await verifyOtp(
      VerifyPasswordResetOtpParams(email: email, token: otp),
    );

    if (!mounted) return;

    if (result.success) {
      setState(() => _isVerifying = false);
      // Supabase establishes a recovery session; navigate to Reset Password
      context.go(AppRoutes.authResetPassword);
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = result.message.isNotEmpty
            ? result.message
            : 'Invalid or expired code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: colors.appBackgroundColor,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () {
            if (_codeSent) {
              setState(() {
                _codeSent = false;
                _errorMessage = null;
              });
            } else {
              context.go(AppRoutes.authLogin);
            }
          },
        ),
        title: Text(
          _codeSent ? 'Enter Reset Code' : 'Forgot Password',
          style: TextStyle(color: colors.textColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _codeSent
              ? _buildCodeVerificationView(colors)
              : _buildRequestEmailView(colors),
        ),
      ),
    );
  }

  Widget _buildRequestEmailView(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.tileColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: colors.primaryColor,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email address and we\'ll send you a recovery code to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.textColor.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendResetCode(),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: colors.errorColor, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSending ? null : _sendResetCode,
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Code'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.authLogin),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeVerificationView(AppColors colors) {
    final email = _emailCtrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.tileColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              color: colors.primaryColor,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit recovery code to\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.textColor.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 8,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
            labelText: '6-digit Recovery Code',
          ),
          onSubmitted: (_) => _verifyOtp(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.errorColor, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isVerifying ? null : _verifyOtp,
          child: _isVerifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify Code & Set Password'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _cooldownSeconds > 0 || _isSending
                  ? null
                  : _sendResetCode,
              child: Text(
                _cooldownSeconds > 0
                    ? 'Resend code in ${_cooldownSeconds}s'
                    : 'Resend Code',
              ),
            ),
            const Text('•'),
            TextButton(
              onPressed: () {
                setState(() {
                  _codeSent = false;
                  _errorMessage = null;
                });
              },
              child: const Text('Change Email'),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/presentation/bloc/register/register_bloc.dart';

/// Registration screen: email, optional full name, and password.
/// Displays an email confirmation view when verification is required.
class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (prev, curr) =>
          prev.resendSuccessMessage != curr.resendSuccessMessage &&
          curr.resendSuccessMessage != null,
      listener: (context, state) {
        if (state.resendSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.resendSuccessMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.needsEmailConfirmation) {
          return _buildEmailConfirmationView(context, state, colors);
        }

        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            leading: AppBackButton(onPressed: () => context.go(AppRoutes.auth)),
            title: Text(
              'Create Account',
              style: TextStyle(color: colors.textColor),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) => context.read<RegisterBloc>().add(
                      RegisterEmailChanged(v),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Full name (optional)
                  TextField(
                    controller: _fullNameCtrl,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) => context.read<RegisterBloc>().add(
                      RegisterFullNameChanged(v),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Full Name (optional)',
                      hintText: 'John Doe',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) => context.read<RegisterBloc>().add(
                      RegisterPasswordChanged(v),
                    ),
                    onSubmitted: (_) => _submit(context, state),
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      hintText: 'Min 6 characters',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Error message
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: colors.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Submit
                  FilledButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _submit(context, state),
                    child: state.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.authLogin),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailConfirmationView(
    BuildContext context,
    RegisterState state,
    AppColors colors,
  ) {
    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: colors.appBackgroundColor,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () => context.read<RegisterBloc>().add(
            RegisterEditEmailRequested(),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mail Icon Container
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    size: 46,
                    color: colors.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Check your email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                const Text(
                  'We sent a verification link to',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8C8D8E)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Email badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    state.email,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1D1F),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Tap the link in your email to activate your account.\nOnce verified, you can sign in to Aanda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8C8D8E),
                    height: 1.5,
                  ),
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: colors.errorColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Primary Button: Go to Sign In
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.authLogin),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend Email button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isResendingEmail
                        ? null
                        : () => context.read<RegisterBloc>().add(
                              RegisterResendEmailRequested(),
                            ),
                    icon: state.isResendingEmail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      state.isResendingEmail
                          ? 'Sending...'
                          : 'Resend verification email',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Edit email / wrong email
                TextButton(
                  onPressed: () => context.read<RegisterBloc>().add(
                        RegisterEditEmailRequested(),
                      ),
                  child: const Text(
                    'Wrong email? Edit details',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8C8D8E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context, RegisterState state) {
    if (state.isSubmitting) return;
    context.read<RegisterBloc>().add(RegisterSubmitted());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/presentation/bloc/login/login_bloc.dart';

/// Email + password sign-in screen.
class LoginNameView extends StatefulWidget {
  const LoginNameView({super.key});

  @override
  State<LoginNameView> createState() => _LoginNameViewState();
}

class _LoginNameViewState extends State<LoginNameView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (prev, curr) =>
          prev.isSubmitting && !curr.isSubmitting && curr.errorMessage == null,
      listener: (context, state) {
        // Successful sign-in: auth guard will redirect via router.
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            leading: BackButton(onPressed: () => context.go(AppRoutes.auth)),
            title: Text('Sign In', style: TextStyle(color: colors.textColor)),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) =>
                        context.read<LoginBloc>().add(LoginEmailChanged(v)),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) =>
                        context.read<LoginBloc>().add(LoginPasswordChanged(v)),
                    onSubmitted: (_) => _submit(context, state),
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                  // Submit button
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
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  // Switch to register
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.authRegister),
                      child: const Text("Don't have an account? Create one"),
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

  void _submit(BuildContext context, LoginState state) {
    if (state.isSubmitting) return;
    context.read<LoginBloc>().add(LoginSubmitted());
  }
}

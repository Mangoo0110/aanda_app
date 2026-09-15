import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/presentation/bloc/register/register_bloc.dart';

/// Registration screen: email, username, optional full name, and password.
class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (prev, curr) =>
          prev.isSubmitting && !curr.isSubmitting && curr.errorMessage == null,
      listener: (context, state) {
        // Successful registration: auth guard will redirect via router.
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            leading: BackButton(onPressed: () => context.go(AppRoutes.auth)),
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
                    onChanged: (v) => context
                        .read<RegisterBloc>()
                        .add(RegisterEmailChanged(v)),
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Username
                  TextField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) => context
                        .read<RegisterBloc>()
                        .add(RegisterUsernameChanged(v)),
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      hintText: 'e.g. john_doe',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Full name (optional)
                  TextField(
                    controller: _fullNameCtrl,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) => context
                        .read<RegisterBloc>()
                        .add(RegisterFullNameChanged(v)),
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
                    onChanged: (v) => context
                        .read<RegisterBloc>()
                        .add(RegisterPasswordChanged(v)),
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

  void _submit(BuildContext context, RegisterState state) {
    if (state.isSubmitting) return;
    context.read<RegisterBloc>().add(RegisterSubmitted());
  }
}

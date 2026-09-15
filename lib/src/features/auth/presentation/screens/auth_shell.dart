import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:aanda/src/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:aanda/src/features/auth/presentation/widgets/error_notice.dart';
import 'package:aanda/src/app/routing/app_routes.dart';

/// Shell that wraps all auth screens. Shows an error bar at the bottom
/// when the login or register bloc has an error.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.routePath, required this.child});

  final String routePath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AuthShellView(routePath: routePath, child: child);
  }
}

class _AuthShellView extends StatelessWidget {
  const _AuthShellView({required this.routePath, required this.child});

  final String routePath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      bottomNavigationBar: _AuthErrorBar(routePath: routePath),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthErrorBar extends StatelessWidget {
  const _AuthErrorBar({required this.routePath});

  final String routePath;

  @override
  Widget build(BuildContext context) {
    return switch (routePath) {
      AppRoutes.authLogin => BlocSelector<LoginBloc, LoginState, String?>(
        selector: (state) => state.errorMessage,
        builder: _buildErrorNotice,
      ),
      AppRoutes.authRegister =>
        BlocSelector<RegisterBloc, RegisterState, String?>(
          selector: (state) => state.errorMessage,
          builder: _buildErrorNotice,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildErrorNotice(BuildContext context, String? errorMessage) {
    if (errorMessage == null) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ErrorNotice(errorMessage),
    );
  }
}

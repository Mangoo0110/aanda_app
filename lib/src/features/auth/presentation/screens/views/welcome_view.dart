import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

/// Landing screen with "Sign In" and "Create Account" options.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo / branding
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Aanda',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Shared living, simplified.',
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              // Sign-in button
              FilledButton(
                onPressed: () => context.go(AppRoutes.authLogin),
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 12),
              // Register button
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.authRegister),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

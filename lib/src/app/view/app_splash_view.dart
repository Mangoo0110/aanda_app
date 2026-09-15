import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

/// Shown while auth state is loading or during route transitions.
class AppSplashView extends StatelessWidget {
  const AppSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

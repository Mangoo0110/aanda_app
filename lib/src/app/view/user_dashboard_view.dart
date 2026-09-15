import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

/// Placeholder dashboard view shown after login.
/// Will be replaced by the House feature shell in Phase 2.
class UserDashboardView extends StatelessWidget {
  const UserDashboardView({super.key, required this.accountName});

  final String accountName;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: Center(
        child: Text(
          'Welcome, $accountName!\n\nHouse feature coming soon.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textColor, fontSize: 18),
        ),
      ),
    );
  }
}

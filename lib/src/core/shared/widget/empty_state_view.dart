import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.tileColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: colors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionHeader.copyWith(
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.rowSubtitle.copyWith(
                color: colors.grey,
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

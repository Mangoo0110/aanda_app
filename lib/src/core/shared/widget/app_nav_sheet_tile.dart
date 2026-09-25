import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class AppNavSheetTile extends StatelessWidget {
  const AppNavSheetTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final effectiveIconColor = iconColor ?? colors.primaryColor;
    final effectiveIconBg = iconBackgroundColor ?? colors.tileColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: effectiveIconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.rowTitle.copyWith(
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.grey,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

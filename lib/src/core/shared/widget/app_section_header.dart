import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 8),
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.sectionHeader.copyWith(
              color: colors.textColor,
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

class StepperButton extends StatelessWidget {
  const StepperButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final primaryColor = colors.primaryColor;
    final subText = colors.textSecondaryColor;

    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? primaryColor.withValues(alpha: 0.12)
              : colors.textColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? primaryColor : subText.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

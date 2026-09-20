import 'package:flutter/material.dart';

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
    const primaryCoral = Color(0xFFD85A38);
    const subText = Color(0xFF8C8D8E);

    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? primaryCoral.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? primaryCoral : subText.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

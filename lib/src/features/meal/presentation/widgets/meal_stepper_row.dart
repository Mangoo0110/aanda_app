import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/meal/presentation/widgets/stepper_button.dart';

class MealStepperRow extends StatelessWidget {
  const MealStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final displayStr = value == 0.0
        ? '0'
        : value.truncateToDouble() == value
            ? value.toInt().toString()
            : value.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.softGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
          ),

          // − button
          StepperButton(
            icon: Icons.remove_rounded,
            onTap: value > 0
                ? () => onChanged(
                      (value - 0.5).clamp(0.0, double.infinity),
                    )
                : null,
          ),

          const SizedBox(width: 4),

          // Value badge
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: value > 0 ? colors.primaryColor : colors.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              displayStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: value > 0 ? Colors.white : colors.grey,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // + button
          StepperButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 0.5),
          ),
        ],
      ),
    );
  }
}

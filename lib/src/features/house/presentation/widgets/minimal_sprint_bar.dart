import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

class MinimalSprintBar extends StatelessWidget {
  const MinimalSprintBar({
    super.key,
    required this.sprints,
    required this.selectedSprint,
    required this.isAdmin,
    required this.onSprintSelected,
    required this.onCreateSprint,
  });

  final List<Sprint> sprints;
  final Sprint? selectedSprint;
  final bool isAdmin;
  final ValueChanged<Sprint> onSprintSelected;
  final VoidCallback onCreateSprint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...sprints.map((sprint) {
            final isSelected = selectedSprint?.id == sprint.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSprintSelected(sprint),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryColor
                        : colors.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sprint.isOpen) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${sprint.label} (${sprint.dateRangeFormatted})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : colors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (isAdmin)
            InkWell(
              onTap: onCreateSprint,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: colors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New Cycle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

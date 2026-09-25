import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

class MemberDailyMealRow extends StatelessWidget {
  const MemberDailyMealRow({
    super.key,
    required this.date,
    required this.meal,
    this.isToday,
    required this.onCycleBrk,
    required this.onCycleLunch,
    required this.onCycleDinner,
    required this.onTapRow,
  });

  final DateTime date;
  final MealLog? meal;
  final bool? isToday;
  final VoidCallback onCycleBrk;
  final VoidCallback onCycleLunch;
  final VoidCallback onCycleDinner;
  final VoidCallback onTapRow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final darkText = colors.textPrimaryColor;
    final subText = colors.textSecondaryColor;
    final primaryCoral = colors.primaryColor;
    const inactiveZero = Color(0xFFC7C9CC);

    final effectiveIsToday = isToday ?? DateUtils.isSameDay(date, DateTime.now());

    final breakfast = meal?.breakfast ?? 0.0;
    final lunch = meal?.lunch ?? 0.0;
    final dinner = meal?.dinner ?? 0.0;
    final total = breakfast + lunch + dinner;
    final totalStr = total.toStringAsFixed(
      total.truncateToDouble() == total ? 0 : 1,
    );

    return InkWell(
      onTap: onTapRow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date Column (flex: 36)
            Expanded(
              flex: 36,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('d MMM').format(date),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: effectiveIsToday ? primaryCoral : darkText,
                            ),
                          ),
                          if (effectiveIsToday) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: primaryCoral.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: primaryCoral,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        DateFormat('EEEE').format(date),
                        style: TextStyle(fontSize: 10, color: subText),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BRK Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: InkWell(
                  onTap: onCycleBrk,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      breakfast.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: breakfast > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: breakfast > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // LUNCH Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: InkWell(
                  onTap: onCycleLunch,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      lunch.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: lunch > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: lunch > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // DINNER Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: InkWell(
                  onTap: onCycleDinner,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      dinner.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: dinner > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: dinner > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // TOTAL Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: total > 0
                        ? primaryCoral.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    totalStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: total > 0 ? primaryCoral : inactiveZero,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

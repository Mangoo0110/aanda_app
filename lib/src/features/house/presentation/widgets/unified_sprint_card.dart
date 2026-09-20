import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

class UnifiedSprintCard extends StatelessWidget {
  const UnifiedSprintCard({
    super.key,
    required this.sprint,
    required this.totalSpent,
    required this.myContribution,
    required this.foodSpent,
    required this.totalMeals,
    required this.myMeals,
    required this.mealRate,
    required this.isComputingSettlement,
    required this.isAdmin,
    required this.onViewExpenses,
    required this.onManageMeals,
    required this.onEndSprint,
  });

  final Sprint? sprint;
  final double totalSpent;
  final double myContribution;
  final double foodSpent;
  final double totalMeals;
  final double myMeals;
  final double mealRate;
  final bool isComputingSettlement;
  final bool isAdmin;
  final VoidCallback onViewExpenses;
  final VoidCallback onManageMeals;
  final VoidCallback onEndSprint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sprint Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sprint?.label ?? 'Cycle Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textColor,
                    ),
                  ),
                  if (sprint != null)
                    Text(
                      sprint!.dateRangeFormatted,
                      style: TextStyle(fontSize: 12, color: colors.grey),
                    ),
                ],
              ),
              if (sprint != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: sprint!.isOpen
                        ? Colors.green.withValues(alpha: 0.12)
                        : colors.tileColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sprint!.isOpen) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        sprint!.isOpen ? 'ACTIVE' : 'SETTLED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: sprint!.isOpen ? Colors.green : colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Spent Amount
          Text(
            'TOTAL CYCLE EXPENSES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '৳ ${currencyFormat.format(totalSpent)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.textColor,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: colors.borderColor.withValues(alpha: 0.3)),
          const SizedBox(height: 14),

          // 4-Metric Grid (Clean 2x2)
          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Your Outflow',
                  value: '৳ ${currencyFormat.format(myContribution)}',
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: colors.borderColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCell(
                  label: 'Food Cost',
                  value: '৳ ${currencyFormat.format(foodSpent)}',
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Total Meals',
                  value:
                      '${totalMeals.toStringAsFixed(totalMeals.truncateToDouble() == totalMeals ? 0 : 1)} meals',
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: colors.borderColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCell(
                  label: 'Est. Meal Rate',
                  value: mealRate > 0
                      ? '৳ ${mealRate.toStringAsFixed(2)}'
                      : '—',
                  colors: colors,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Navigation buttons (Expenses & Meals)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onViewExpenses,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 15,
                          color: colors.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Expenses',
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onManageMeals,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          size: 15,
                          color: Colors.teal,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Meal Sheet',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Settle / End Sprint Button
          if (sprint != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: sprint!.isOpen
                      ? colors.primaryColor
                      : colors.grey,
                  side: BorderSide(
                    color: sprint!.isOpen
                        ? colors.primaryColor.withValues(alpha: 0.5)
                        : colors.borderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: isComputingSettlement
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        sprint!.isOpen
                            ? Icons.calculate_rounded
                            : Icons.assessment_rounded,
                        size: 16,
                      ),
                label: Text(
                  sprint!.isOpen
                      ? (isAdmin ? 'End Cycle & Settle' : 'View Cycle Summary')
                      : 'View Cycle Breakdown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                onPressed: isComputingSettlement ? null : onEndSprint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCell({
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
      ],
    );
  }
}

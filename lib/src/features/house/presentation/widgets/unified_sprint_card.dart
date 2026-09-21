import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

/// Account overview card — shows live expense totals and quick navigation.
/// The sprint/cycle selector and settle button have been removed;
/// settlement is now accessed via the FAB quick actions sheet.
class AccountOverviewCard extends StatelessWidget {
  const AccountOverviewCard({
    super.key,
    required this.accountName,
    required this.totalSpent,
    required this.myContribution,
    required this.foodSpent,
    required this.totalMeals,
    required this.myMeals,
    required this.mealRate,
    required this.isPersonal,
    required this.onViewExpenses,
    required this.onManageMeals,
  });

  final String accountName;
  final double totalSpent;
  final double myContribution;
  final double foodSpent;
  final double totalMeals;
  final double myMeals;
  final double mealRate;
  final bool isPersonal;
  final VoidCallback onViewExpenses;
  final VoidCallback onManageMeals;

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
          // Header
          Text(
            'ACCOUNT OVERVIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            accountName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textColor,
            ),
          ),

          const SizedBox(height: 16),

          // Total Spent Amount
          Text(
            'TOTAL EXPENSES',
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

          // Metrics grid
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
                  label: isPersonal ? 'This Month' : 'Food Cost',
                  value: '৳ ${currencyFormat.format(foodSpent)}',
                  colors: colors,
                ),
              ),
            ],
          ),
          if (!isPersonal) ...[
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
          ],

          const SizedBox(height: 18),

          // Navigation buttons
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
              if (!isPersonal) ...[
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
            ],
          ),
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

// Keep old name as alias to avoid breaking any imports that are not yet updated.
@Deprecated('Use AccountOverviewCard instead')
typedef UnifiedSprintCard = AccountOverviewCard;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

class SettlementBreakdownSheet extends StatelessWidget {
  const SettlementBreakdownSheet({
    super.key,
    required this.settlement,
    this.sprint,
    required this.isAdmin,
    required this.onConfirmClose,
  });

  final Settlement settlement;
  final Sprint? sprint;
  final bool isAdmin;
  final VoidCallback onConfirmClose;

  static void show({
    required BuildContext context,
    required Settlement settlement,
    Sprint? sprint,
    required bool isAdmin,
    required VoidCallback onConfirmClose,
  }) {
    final colors = AppColors.context(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SettlementBreakdownSheet(
        settlement: settlement,
        sprint: sprint,
        isAdmin: isAdmin,
        onConfirmClose: () {
          Navigator.of(ctx).pop();
          onConfirmClose();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('d MMM yyyy');

    final startDateStr = sprint != null
        ? dateFormat.format(sprint!.startDate)
        : '';
    final cutoffDate =
        settlement.calculationEndDate ??
        settlement.computedAt ??
        DateTime.now();
    final cutoffDateStr = dateFormat.format(cutoffDate);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calculate_rounded, color: colors.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Cycle Settlement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.textColor,
                    ),
                  ),
                  const Spacer(),
                  if (sprint != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sprint!.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Date Range Notice (Calculation from start date to tap date)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        startDateStr.isNotEmpty
                            ? 'Calculated from $startDateStr to $cutoffDateStr (tap date)'
                            : 'Calculated up to $cutoffDateStr',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Overview breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.appBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _MetricRow(
                      label: 'Total Food Expenses',
                      value:
                          '৳ ${currencyFormat.format(settlement.totalFoodCost)}',
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      label: 'Fixed & Other Expenses',
                      value:
                          '৳ ${currencyFormat.format(settlement.totalFixedCost + settlement.totalOtherCost)}',
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      label: 'Total Meals Consumed',
                      value:
                          '${settlement.totalMealCount.toStringAsFixed(1)} meals',
                    ),
                    const Divider(height: 20),
                    _MetricRow(
                      label: 'Calculated Meal Rate',
                      value:
                          '৳ ${settlement.mealRate.toStringAsFixed(2)} / meal',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Member Balances',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 10),

              ...settlement.memberSummaries.map((m) {
                final net = m.netBalance;
                final isDue = net > 0.01;
                final isRefund = net < -0.01;
                final balanceColor = isDue
                    ? colors.errorColor
                    : (isRefund ? Colors.teal : colors.grey);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.appBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          m.displayName.isNotEmpty
                              ? m.displayName[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textColor,
                              ),
                            ),
                            Text(
                              '${m.totalMeals.toStringAsFixed(1)} meals (৳${m.foodCharge.toStringAsFixed(0)}) • Paid ৳${m.totalPaid.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isDue
                                ? 'Owes'
                                : (isRefund ? 'Gets back' : 'Settled'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: balanceColor,
                            ),
                          ),
                          Text(
                            '৳ ${currencyFormat.format(net.abs())}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              if (isAdmin && sprint?.isOpen == true)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Confirm & Close Cycle',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: onConfirmClose,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 13,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted ? colors.textColor : colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 17 : 14,
            fontWeight: FontWeight.w800,
            color: isHighlighted ? colors.primaryColor : colors.textColor,
          ),
        ),
      ],
    );
  }
}

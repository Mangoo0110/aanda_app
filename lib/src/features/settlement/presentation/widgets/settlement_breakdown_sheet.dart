import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

/// Read-only settlement breakdown sheet — used from settlement history.
class SettlementBreakdownSheet extends StatelessWidget {
  const SettlementBreakdownSheet({super.key, required this.settlement});

  final Settlement settlement;

  static void show({
    required BuildContext context,
    required Settlement settlement,
  }) {
    final colors = AppColors.context(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SettlementBreakdownSheet(settlement: settlement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currFmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d MMM yyyy');

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
                  Icon(Icons.receipt_long_rounded, color: colors.textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Settlement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: settlement.status == SettlementStatus.published
                          ? Colors.orange.withValues(alpha: 0.12)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      settlement.status == SettlementStatus.published
                          ? 'COLLECTION OPEN'
                          : (settlement.status == SettlementStatus.draft
                              ? 'DRAFT'
                              : 'FINALISED'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: settlement.status == SettlementStatus.published
                            ? Colors.orange.shade800
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Date range pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 14,
                      color: colors.textColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFmt.format(settlement.fromDate)}  –  ${dateFmt.format(settlement.toDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key metrics card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.appBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _MetricRow(
                      label: 'Food Expenses',
                      value: '৳ ${currFmt.format(settlement.totalFoodCost)}',
                    ),
                    const SizedBox(height: 8),
                    _MetricRow(
                      label: 'Fixed & Other',
                      value:
                          '৳ ${currFmt.format(settlement.totalFixedCost + settlement.totalOtherCost)}',
                    ),
                    const Divider(height: 20),
                    _MetricRow(
                      label: 'Total',
                      value: '৳ ${currFmt.format(settlement.totalExpenses)}',
                      isHighlighted: true,
                    ),
                    if (settlement.totalMealCount > 0) ...[
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'Meal Rate',
                        value:
                            '৳ ${currFmt.format(settlement.mealRate)} / meal',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                settlement.memberSummaries.length == 1
                    ? 'Personal Summary'
                    : 'Member Balances',
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

                final Color balanceColor;
                final Color badgeBg;
                final String statusText;
                final String amountText;

                if (isDue) {
                  balanceColor = colors.errorColor;
                  badgeBg = colors.errorColor.withValues(alpha: 0.1);
                  statusText = 'To Pay';
                  amountText = '-৳ ${currFmt.format(net.abs())}';
                } else if (isRefund) {
                  balanceColor = Colors.green.shade700;
                  badgeBg = Colors.green.withValues(alpha: 0.1);
                  statusText = 'To Receive';
                  amountText = '+৳ ${currFmt.format(net.abs())}';
                } else {
                  balanceColor = colors.grey;
                  badgeBg = colors.softGrey;
                  statusText = 'Settled';
                  amountText = '৳ 0.00';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.appBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            colors.textColor.withValues(alpha: 0.08),
                        backgroundImage: getAvatarImageProvider(m.avatarUrl),
                        child: m.avatarUrl == null || m.avatarUrl!.isEmpty
                            ? Text(
                                m.displayName.isNotEmpty
                                    ? m.displayName[0].toUpperCase()
                                    : 'M',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textColor,
                                ),
                              )
                            : null,
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
                              'Share ৳${currFmt.format(m.totalOwed)}  ·  Net Dep ৳${currFmt.format(m.netDeposit)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.grey,
                              ),
                            ),
                            if (m.carryForwardIn.abs() > 0.01)
                              Text(
                                m.carryForwardIn > 0
                                    ? 'Prior debt: -৳${currFmt.format(m.carryForwardIn)}'
                                    : 'Prior credit: +৳${currFmt.format(m.carryForwardIn.abs())}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.grey,
                                ),
                              ),
                            if (m.resolutionType != null)
                              Text(
                                m.resolutionType == BalanceResolutionType.carryForward
                                    ? '→ Carried forward to next'
                                    : '→ Misc: ${m.resolutionReason ?? ""}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textColor.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: balanceColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            amountText,
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

              const SizedBox(height: 8),
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
            color: colors.textColor,
          ),
        ),
      ],
    );
  }
}

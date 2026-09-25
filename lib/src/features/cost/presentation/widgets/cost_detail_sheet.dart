import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';

class CostDetailSheet extends StatelessWidget {
  const CostDetailSheet({
    super.key,
    required this.cost,
    required this.isOwnCost,
    this.onEdit,
    this.onDelete,
  });

  final Cost cost;
  final bool isOwnCost;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static void show({
    required BuildContext context,
    required Cost cost,
    required bool isOwnCost,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final colors = AppColors.context(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CostDetailSheet(
        cost: cost,
        isOwnCost: isOwnCost,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');
    final isSettled = cost.isSettled;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSettled
                        ? colors.primaryColor.withValues(alpha: 0.12)
                        : colors.softGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSettled
                          ? colors.primaryColor.withValues(alpha: 0.3)
                          : colors.dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSettled
                            ? Icons.lock_outline_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color: isSettled ? colors.primaryColor : colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSettled ? 'Settled in Statement' : 'Unsettled Expense',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSettled ? colors.primaryColor : colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cost.name,
                        style: AppTextStyles.sectionHeader.copyWith(
                          fontSize: 20,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy • h:mm a',
                        ).format(cost.purchaseDate),
                        style: AppTextStyles.rowSubtitle.copyWith(
                          color: colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳${currencyFormat.format(cost.amount)}',
                  style: AppTextStyles.amountLarge.copyWith(
                    fontSize: 22,
                    color: colors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: colors.dividerColor),
            const SizedBox(height: 12),

            _detailRow(colors, 'Scope', cost.isPersonal ? 'Personal' : 'Shared House'),
            if (cost.categoryName != null)
              _detailRow(colors, 'Category', cost.categoryName!),
            _detailRow(
              colors,
              'Paid By',
              isOwnCost
                  ? 'You'
                  : (cost.payerName?.isNotEmpty == true
                      ? cost.payerName!
                      : 'House Member'),
            ),
            if (cost.note != null && cost.note!.isNotEmpty)
              _detailRow(colors, 'Details / Note', cost.note!),

            const SizedBox(height: 24),

            if (isSettled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This expense is reconciled in a settlement statement and cannot be modified or deleted.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.grey,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Action Buttons: Edit & Delete
              Row(
                children: [
                  if (onEdit != null)
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.textColor,
                          foregroundColor: colors.invertTextColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit!();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit Expense',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 10),
                  if (onDelete != null)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.unsettledColor.withValues(alpha: 0.12),
                          foregroundColor: colors.unsettledColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDelete!();
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(AppColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.rowSubtitle.copyWith(
              color: colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.rowTitle.copyWith(
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

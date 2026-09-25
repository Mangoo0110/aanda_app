import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';

class DashboardSettlementSheet extends StatelessWidget {
  const DashboardSettlementSheet({
    super.key,
    required this.house,
  });

  final House? house;

  static void show(BuildContext context, House? house) {
    final colors = AppColors.context(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DashboardSettlementSheet(house: house),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final houseName = house?.name ?? 'Shared House';
    final houseId = house?.id;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy, h:mm a').format(now);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: colors.textColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Cycle & Settle',
                        style: AppTextStyles.sectionHeader.copyWith(
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        houseName,
                        style: AppTextStyles.rowSubtitle.copyWith(
                          color: colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.softGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: colors.textColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Calculation Snapshot: $dateStr',
                        style: AppTextStyles.rowTitle.copyWith(
                          color: colors.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Settling ends the current cycle, tallies total expenses from the start date to right now, resolves balances, and starts a fresh new cycle.',
                    style: AppTextStyles.rowSubtitle.copyWith(
                      color: colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text(
                  'Calculate & End Cycle',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.textColor,
                  foregroundColor: colors.invertTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (houseId != null) {
                    context.push(
                      AppRoutes.settlementStart(houseId),
                      extra: {
                        'houseName': houseName,
                        'isAdmin': true,
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

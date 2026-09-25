import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/settlement/domain/entities/deposit.dart';
import 'package:aanda/src/features/settlement/presentation/widgets/record_deposit_sheet.dart';

class DepositDetailSheet extends StatelessWidget {
  const DepositDetailSheet({
    super.key,
    required this.deposit,
    required this.houseId,
    this.memberName,
    this.memberAvatarUrl,
    this.onChanged,
  });

  final Deposit deposit;
  final String houseId;
  final String? memberName;
  final String? memberAvatarUrl;
  final VoidCallback? onChanged;

  static Future<void> show({
    required BuildContext context,
    required Deposit deposit,
    required String houseId,
    String? memberName,
    String? memberAvatarUrl,
    VoidCallback? onChanged,
  }) {
    final colors = AppColors.context(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DepositDetailSheet(
        deposit: deposit,
        houseId: houseId,
        memberName: memberName,
        memberAvatarUrl: memberAvatarUrl,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final isSettled = deposit.isSettled;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deposit Details',
                style: AppTextStyles.sectionHeader.copyWith(
                  fontSize: 20,
                  color: colors.textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSettled
                      ? colors.settledColor.withValues(alpha: 0.12)
                      : colors.unsettledColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSettled ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                      size: 13,
                      color: isSettled ? colors.settledColor : colors.unsettledColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSettled ? 'Reconciled' : 'Unsettled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSettled ? colors.settledColor : colors.unsettledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Large Amount Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.softGrey,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.dividerColor),
            ),
            child: Column(
              children: [
                Text(
                  '৳${deposit.amount.toStringAsFixed(deposit.amount.truncateToDouble() == deposit.amount ? 0 : 2)}',
                  style: AppTextStyles.amountLarge.copyWith(
                    fontSize: 34,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deposit.depositType.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info Rows
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Member',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (memberAvatarUrl != null)
                  CircleAvatar(
                    radius: 11,
                    backgroundImage: NetworkImage(memberAvatarUrl!),
                  )
                else
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: colors.textColor,
                    child: Text(
                      (memberName?.isNotEmpty == true) ? memberName![0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 10, color: colors.invertTextColor),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  memberName ?? 'House Member',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Deposit Date',
            child: Text(
              DateFormat('d MMMM yyyy').format(deposit.depositDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
          ),
          if (deposit.note != null && deposit.note!.isNotEmpty) ...[
            const Divider(height: 20),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Note / Ref',
              child: Text(
                deposit.note!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textColor,
                ),
              ),
            ),
          ],
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.history_rounded,
            label: 'Recorded On',
            child: Text(
              DateFormat('d MMM yyyy, h:mm a').format(deposit.createdAt),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (!isSettled) ...[
            Row(
              children: [
                Expanded(
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
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final result = await RecordDepositSheet.show(
                        context: context,
                        houseId: houseId,
                        existingDeposit: deposit,
                      );
                      if (result == true) {
                        onChanged?.call();
                      }
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text(
                      'Edit Deposit',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.softGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 18, color: colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This deposit was reconciled into a past settlement and is locked to maintain ledger audit integrity.',
                      style: TextStyle(fontSize: 12, color: colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.grey),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        child,
      ],
    );
  }
}

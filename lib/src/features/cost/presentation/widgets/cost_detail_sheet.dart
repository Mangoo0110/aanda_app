import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';

class CostDetailSheet extends StatelessWidget {
  const CostDetailSheet({
    super.key,
    required this.cost,
    required this.isOwnCost,
    required this.onDelete,
  });

  final Cost cost;
  final bool isOwnCost;
  final VoidCallback onDelete;

  static void show({
    required BuildContext context,
    required Cost cost,
    required bool isOwnCost,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CostDetailSheet(
        cost: cost,
        isOwnCost: isOwnCost,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryCoral = Color(0xFFD85A38);
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy • hh:mm a',
                        ).format(cost.purchaseDate),
                        style: const TextStyle(fontSize: 13, color: subText),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳${currencyFormat.format(cost.amount)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryCoral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.black.withValues(alpha: 0.06)),
            const SizedBox(height: 12),

            _detailRow('Scope', cost.isPersonal ? 'Personal' : 'Shared House'),
            if (cost.categoryName != null)
              _detailRow('Category', cost.categoryName!),
            _detailRow(
              'Paid By',
              isOwnCost
                  ? 'You'
                  : (cost.payerName?.isNotEmpty == true
                      ? cost.payerName!
                      : 'House Member'),
            ),
            if (cost.note != null && cost.note!.isNotEmpty)
              _detailRow('Details / Note', cost.note!),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8C8D8E),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B1D1F),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';

class TabularLedgerRow extends StatelessWidget {
  const TabularLedgerRow({
    super.key,
    required this.cost,
    required this.currentUserId,
    required this.onTap,
  });

  final Cost cost;
  final String? currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(cost.purchaseDate);
    final detailStr = cost.note?.isNotEmpty == true
        ? '$timeStr · ${cost.note}'
        : (cost.categoryName?.isNotEmpty == true
            ? '$timeStr · ${cost.categoryName}'
            : timeStr);

    final currencyFormat = NumberFormat('#,##0');

    // Tag Pill logic matching mockup
    final (tagText, tagBg, tagColor) = _resolveTagInfo(cost);

    // Initial avatar logic
    final isYou = cost.paidBy == currentUserId;
    final initial = isYou
        ? 'U'
        : (cost.payerName?.isNotEmpty == true
            ? cost.payerName![0].toUpperCase()
            : 'M');

    final avatarBg = isYou
        ? const Color(0xFF1B1D1F)
        : (initial == 'R'
            ? const Color(0xFFD97706)
            : (initial == 'S'
                ? const Color(0xFF6B7280)
                : const Color(0xFF4B5563)));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. ITEM & DETAILS
            Expanded(
              flex: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detailStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8C8D8E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 2. TAG / POOL
            Expanded(
              flex: 25,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tagText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tagColor,
                    ),
                  ),
                ),
              ),
            ),

            // 3. BY (Avatar initial)
            Expanded(
              flex: 12,
              child: Center(
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: avatarBg,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // 4. AMOUNT
            Expanded(
              flex: 23,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '৳${currencyFormat.format(cost.amount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1D1F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, Color) _resolveTagInfo(Cost cost) {
    final cat = (cost.categoryName ?? '').toLowerCase();
    if (cost.isPersonal) {
      return ('Personal', const Color(0xFFEBF1F5), const Color(0xFF4A6B82));
    }
    if (cat.contains('bazar') || cat.contains('meal') || cat.contains('food')) {
      return ('Meal Pool', const Color(0xFFEDE9FF), const Color(0xFF6C47FF));
    }
    if (cat.contains('gas') ||
        cat.contains('bill') ||
        cat.contains('utilit') ||
        cat.contains('internet')) {
      return ('Utilities', const Color(0xFFF1F3F5), const Color(0xFF495057));
    }
    return ('Split +5', const Color(0xFFFDF0DD), const Color(0xFFD97706));
  }
}

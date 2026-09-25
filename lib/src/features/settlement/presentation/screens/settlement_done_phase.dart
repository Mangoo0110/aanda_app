part of 'settlement_screen.dart';

// ── Phase 4: Done ─────────────────────────────────────────────────────────────

class _DonePhase extends StatelessWidget {
  const _DonePhase({required this.settlement, required this.colors});

  final Settlement settlement;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settlement Finalised!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              settlement.dateRangeLabel,
              style: TextStyle(fontSize: 14, color: colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ৳ ${currFmt.format(settlement.totalExpenses)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () => Navigator.of(context).pop(true),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.textColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      size: 18,
                      color: colors.invertTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back to Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.invertTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

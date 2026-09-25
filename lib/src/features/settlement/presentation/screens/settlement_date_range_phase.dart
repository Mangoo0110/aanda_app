part of 'settlement_screen.dart';

// ── Phase 1: Date Range ───────────────────────────────────────────────────────

class _DateRangePhase extends StatefulWidget {
  const _DateRangePhase({
    required this.fromDate,
    required this.toDate,
    required this.isLoading,
    required this.colors,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isLoading;
  final AppColors colors;

  @override
  State<_DateRangePhase> createState() => _DateRangePhaseState();
}

class _DateRangePhaseState extends State<_DateRangePhase> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.fromDate ?? DateTime(now.year, now.month, 1);
    _to = widget.toDate ?? now;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final dateFmt = DateFormat('d MMM yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose the period you want to settle.',
            style: TextStyle(fontSize: 14, color: colors.grey),
          ),
          const SizedBox(height: 32),

          // FROM date
          _DatePicker(
            label: 'FROM',
            date: _from,
            colors: colors,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _from,
                firstDate: DateTime(2020),
                lastDate: _to,
              );
              if (picked != null) setState(() => _from = picked);
            },
          ),
          const SizedBox(height: 16),

          // Arrow connector
          Center(
            child: Icon(
              Icons.arrow_downward_rounded,
              color: colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),

          // TO date
          _DatePicker(
            label: 'TO',
            date: _to,
            colors: colors,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _to,
                firstDate: _from,
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _to = picked);
            },
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${dateFmt.format(_from)}  –  ${dateFmt.format(_to)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
          ),

          const Spacer(),

          // Load Costs button
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: widget.isLoading
                  ? null
                  : () {
                      context.read<SettlementBloc>().add(
                        SettlementDateRangeSet(fromDate: _from, toDate: _to),
                      );
                    },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colors.textColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.invertTextColor,
                        ),
                      )
                    else
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: colors.invertTextColor,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isLoading ? 'Loading costs…' : 'Load Costs →',
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
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.label,
    required this.date,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, d MMMM yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(date),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.calendar_month_rounded,
              color: colors.textColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

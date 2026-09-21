import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/presentation/bloc/settlement_bloc.dart';
import 'package:aanda/src/features/settlement/presentation/widgets/settlement_breakdown_sheet.dart';

class SettlementHistoryScreen extends StatefulWidget {
  const SettlementHistoryScreen({
    super.key,
    required this.houseId,
    required this.houseName,
    required this.isAdmin,
  });

  final String houseId;
  final String houseName;
  final bool isAdmin;

  @override
  State<SettlementHistoryScreen> createState() =>
      _SettlementHistoryScreenState();
}

class _SettlementHistoryScreenState extends State<SettlementHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettlementBloc>().add(
      SettlementHistoryRequested(houseId: widget.houseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: colors.appBackgroundColor,
        elevation: 0,
        leading: const AppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settlement History',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            Text(
              widget.houseName,
              style: TextStyle(fontSize: 11, color: colors.grey),
            ),
          ],
        ),
      ),
      body: BlocBuilder<SettlementBloc, SettlementState>(
        builder: (context, state) {
          if (state.isLoadingHistory) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (state.settlementHistory.isEmpty) {
            return _EmptyHistory(colors: colors);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: state.settlementHistory.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = state.settlementHistory[i];
              return _SettlementHistoryCard(
                settlement: s,
                colors: colors,
                onTap: () =>
                    SettlementBreakdownSheet.show(context: context, settlement: s),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettlementHistoryCard extends StatelessWidget {
  const _SettlementHistoryCard({
    required this.settlement,
    required this.colors,
    required this.onTap,
  });

  final Settlement settlement;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d MMM yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: colors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dateFmt.format(settlement.fromDate)}  –  ${dateFmt.format(settlement.toDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${settlement.memberSummaries.length} members  ·  ${settlement.includedCostIds.length} costs',
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳ ${currFmt.format(settlement.totalExpenses)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FINALISED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No settlements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first settlement from the\n+ quick actions menu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

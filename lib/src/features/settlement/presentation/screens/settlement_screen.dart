import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/presentation/bloc/settlement_bloc.dart';

class SettlementScreen extends StatelessWidget {
  const SettlementScreen({
    super.key,
    required this.houseId,
    required this.houseName,
    required this.isAdmin,
  });

  final String houseId;
  final String houseName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettlementBloc, SettlementState>(
      listenWhen: (prev, curr) =>
          (prev.phase != curr.phase && curr.phase == SettlementPhase.done) ||
          (prev.errorMessage == null && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.context(context).errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final colors = AppColors.context(context);
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            leading: state.phase != SettlementPhase.dateRange &&
                    state.phase != SettlementPhase.done
                ? IconButton(
                    icon:
                        Icon(Icons.arrow_back_rounded, color: colors.textColor),
                    onPressed: () {
                      if (state.phase == SettlementPhase.costSelection) {
                        context.read<SettlementBloc>().add(
                          SettlementStarted(
                            houseId: houseId,
                            isAdmin: isAdmin,
                          ),
                        );
                      } else if (state.phase == SettlementPhase.summary) {
                        context.read<SettlementBloc>().add(
                          SettlementDateRangeSet(
                            fromDate: state.fromDate!,
                            toDate: state.toDate!,
                          ),
                        );
                      }
                    },
                  )
                : const AppBackButton(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phaseTitle(state.phase),
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                Text(
                  houseName,
                  style: TextStyle(fontSize: 11, color: colors.grey),
                ),
              ],
            ),
          ),
          body: _buildBody(context, state, colors),
        );
      },
    );
  }

  String _phaseTitle(SettlementPhase phase) {
    return switch (phase) {
      SettlementPhase.dateRange => 'Start Settlement',
      SettlementPhase.costSelection => 'Select Costs',
      SettlementPhase.summary => 'Settlement Summary',
      SettlementPhase.done => 'Settlement Done',
    };
  }

  Widget _buildBody(
    BuildContext context,
    SettlementState state,
    AppColors colors,
  ) {
    return switch (state.phase) {
      SettlementPhase.dateRange => _DateRangePhase(
          fromDate: state.fromDate,
          toDate: state.toDate,
          isLoading: state.isLoading,
          colors: colors,
        ),
      SettlementPhase.costSelection => _CostSelectionPhase(
          state: state,
          colors: colors,
          isAdmin: isAdmin,
        ),
      SettlementPhase.summary => _SummaryPhase(
          settlement: state.previewSettlement!,
          isAdmin: isAdmin,
          isFinalising: state.isFinalising,
          colors: colors,
        ),
      SettlementPhase.done => _DonePhase(
          settlement: state.finalSettlement!,
          colors: colors,
        ),
    };
  }
}

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
                color: colors.primaryColor,
              ),
            ),
          ),

          const Spacer(),

          // Load Costs button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: widget.isLoading
                  ? null
                  : () {
                      context.read<SettlementBloc>().add(
                        SettlementDateRangeSet(fromDate: _from, toDate: _to),
                      );
                    },
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(
                widget.isLoading ? 'Loading costs…' : 'Load Costs →',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
          border: Border.all(color: colors.borderColor),
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
              color: colors.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 2: Cost Selection ───────────────────────────────────────────────────

class _CostSelectionPhase extends StatelessWidget {
  const _CostSelectionPhase({
    required this.state,
    required this.colors,
    required this.isAdmin,
  });

  final SettlementState state;
  final AppColors colors;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft!;
    final currFmt = NumberFormat('#,##0.00');

    return Column(
      children: [
        // Tab bar
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: colors.primaryColor,
                  unselectedLabelColor: colors.grey,
                  indicatorColor: colors.primaryColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(
                      text:
                          'In Period (${draft.inRangeCosts.length})',
                    ),
                    Tab(
                      text:
                          'Outstanding (${draft.outstandingCosts.length})',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CostTab(
                        costs: draft.inRangeCosts,
                        selectedCostIds: state.selectedCostIds,
                        colors: colors,
                      ),
                      _CostTab(
                        costs: draft.outstandingCosts,
                        selectedCostIds: state.selectedCostIds,
                        colors: colors,
                        emptyMessage:
                            'No outstanding costs.\nAll past costs have been settled.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            border: Border(
              top: BorderSide(color: colors.borderColor, width: 0.8),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SELECTED TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: colors.grey,
                        ),
                      ),
                      Text(
                        '৳ ${currFmt.format(state.selectedTotal)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.textColor,
                        ),
                      ),
                      Text(
                        '${state.includedCostIds.length} of ${draft.allCosts.length} costs',
                        style: TextStyle(fontSize: 11, color: colors.grey),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: state.includedCostIds.isEmpty
                      ? null
                      : () => context
                          .read<SettlementBloc>()
                          .add(SettlementPreviewRequested()),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.calculate_rounded, size: 16),
                  label: const Text(
                    'Compute →',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CostTab extends StatelessWidget {
  const _CostTab({
    required this.costs,
    required this.selectedCostIds,
    required this.colors,
    this.emptyMessage,
  });

  final List<Cost> costs;
  final Map<String, bool> selectedCostIds;
  final AppColors colors;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (costs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage ?? 'No costs in this period.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.grey),
          ),
        ),
      );
    }

    // Group costs by category
    final grouped = <String, List<Cost>>{};
    for (final c in costs) {
      final key = c.categoryId ?? 'uncategorised';
      (grouped[key] ??= []).add(c);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final categoryId = sections[i].key;
        final categoryCosts = sections[i].value;
        final firstName = categoryCosts.first;
        final categoryName =
            firstName.categoryName ?? firstName.categoryIcon ?? 'Uncategorised';
        final categoryIcon = firstName.categoryIcon ?? '📦';

        final checkState = context
            .watch<SettlementBloc>()
            .state
            .categoryCheckState(categoryId, costs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: checkState,
                    tristate: true,
                    activeColor: colors.primaryColor,
                    onChanged: (val) {
                      context.read<SettlementBloc>().add(
                        SettlementCategoryToggled(
                          categoryId: categoryId,
                          selected: val == true,
                        ),
                      );
                    },
                  ),
                  Text(categoryIcon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${categoryCosts.length} item${categoryCosts.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 11, color: colors.grey),
                  ),
                ],
              ),
            ),
            // Cost rows
            ...categoryCosts.map(
              (c) => _CostCheckRow(cost: c, colors: colors),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _CostCheckRow extends StatelessWidget {
  const _CostCheckRow({required this.cost, required this.colors});

  final Cost cost;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    final isChecked =
        context.watch<SettlementBloc>().state.selectedCostIds[cost.id] ?? true;
    final dateFmt = DateFormat('d MMM');

    return InkWell(
      onTap: () => context.read<SettlementBloc>().add(
        SettlementCostToggled(costId: cost.id, selected: !isChecked),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 16, 2),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              activeColor: colors.primaryColor,
              onChanged: (val) => context.read<SettlementBloc>().add(
                SettlementCostToggled(costId: cost.id, selected: val ?? false),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isChecked
                          ? colors.textColor
                          : colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${dateFmt.format(cost.purchaseDate)}  ·  ${cost.payerName ?? 'You'}',
                    style: TextStyle(fontSize: 11, color: colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '৳ ${currFmt.format(cost.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isChecked ? colors.textColor : colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 3: Settlement Summary ───────────────────────────────────────────────

class _SummaryPhase extends StatelessWidget {
  const _SummaryPhase({
    required this.settlement,
    required this.isAdmin,
    required this.isFinalising,
    required this.colors,
  });

  final Settlement settlement;
  final bool isAdmin;
  final bool isFinalising;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Period label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: colors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFmt.format(settlement.fromDate)}  –  ${dateFmt.format(settlement.toDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Totals card
              _SectionLabel(label: 'COST BREAKDOWN', colors: colors),
              const SizedBox(height: 8),
              _TotalsCard(settlement: settlement, colors: colors),
              const SizedBox(height: 20),

              // Member breakdown
              _SectionLabel(label: 'MEMBER BREAKDOWN', colors: colors),
              const SizedBox(height: 8),
              ...settlement.memberSummaries.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberSummaryCard(member: m, colors: colors),
                ),
              ),

              const SizedBox(height: 8),
              if (!isAdmin)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Only an admin can finalise the settlement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
                ),
            ],
          ),
        ),

        // Bottom action bar
        if (isAdmin)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              border: Border(
                top: BorderSide(color: colors.borderColor, width: 0.8),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isFinalising
                      ? null
                      : () => context
                          .read<SettlementBloc>()
                          .add(SettlementFinaliseRequested()),
                  icon: isFinalising
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isFinalising ? 'Saving…' : 'Finalise & Save Settlement',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.settlement, required this.colors});

  final Settlement settlement;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _TotalRow(
            label: 'Food Cost',
            value: '৳ ${currFmt.format(settlement.totalFoodCost)}',
            colors: colors,
          ),
          _TotalRow(
            label: 'Fixed Cost',
            value: '৳ ${currFmt.format(settlement.totalFixedCost)}',
            colors: colors,
          ),
          _TotalRow(
            label: 'Other Cost',
            value: '৳ ${currFmt.format(settlement.totalOtherCost)}',
            colors: colors,
          ),
          Divider(height: 20, color: colors.borderColor.withValues(alpha: 0.5)),
          _TotalRow(
            label: 'Total Expenses',
            value: '৳ ${currFmt.format(settlement.totalExpenses)}',
            colors: colors,
            bold: true,
          ),
          if (settlement.totalMealCount > 0) ...[
            const SizedBox(height: 4),
            _TotalRow(
              label: 'Meal Count',
              value:
                  '${settlement.totalMealCount.toStringAsFixed(1)} meals',
              colors: colors,
            ),
            _TotalRow(
              label: 'Meal Rate',
              value: '৳ ${currFmt.format(settlement.mealRate)} / meal',
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.colors,
    this.bold = false,
  });

  final String label;
  final String value;
  final AppColors colors;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? colors.textColor : colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  const _MemberSummaryCard({required this.member, required this.colors});

  final MemberSettlementSummary member;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    final isOwed = member.netBalance < -0.01;
    final owes = member.netBalance > 0.01;

    final balanceColor = isOwed
        ? Colors.green.shade600
        : owes
        ? colors.errorColor
        : colors.grey;

    final balanceLabel = isOwed
        ? 'gets back ৳ ${currFmt.format(member.netBalance.abs())}'
        : owes
        ? 'owes ৳ ${currFmt.format(member.netBalance)}'
        : 'settled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
                      member.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                    Text(
                      balanceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                member.netBalance == 0
                    ? '৳ 0'
                    : '${member.netBalance > 0 ? '+' : ''}৳ ${currFmt.format(member.netBalance)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: balanceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderColor.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          // Details grid
          Row(
            children: [
              _StatCell(
                label: 'Paid',
                value: '৳ ${currFmt.format(member.totalPaid)}',
                colors: colors,
              ),
              _StatCell(
                label: 'Owed',
                value: '৳ ${currFmt.format(member.totalOwed)}',
                colors: colors,
              ),
              _StatCell(
                label: 'Meals',
                value: member.totalMeals > 0
                    ? member.totalMeals.toStringAsFixed(0)
                    : '—',
                colors: colors,
              ),
            ],
          ),
          if (member.carryForwardIn.abs() > 0.01) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 13,
                  color: colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Carry forward: ৳ ${currFmt.format(member.carryForwardIn)}',
                  style: TextStyle(fontSize: 11, color: colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

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
                color: colors.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text(
                'Back to Account',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: colors.grey,
      ),
    );
  }
}

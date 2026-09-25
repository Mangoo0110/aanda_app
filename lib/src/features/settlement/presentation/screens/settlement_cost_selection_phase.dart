part of 'settlement_screen.dart';

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
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: colors.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                    labelColor: colors.textColor,
                    unselectedLabelColor: colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'In Period (${draft.inRangeCosts.length})'),
                      Tab(text: 'Outstanding (${draft.outstandingCosts.length})'),
                    ],
                  ),
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
                        emptyMessage: 'No outstanding costs.\nAll past costs have been settled.',
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
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
                InkWell(
                  onTap: state.includedCostIds.isEmpty || state.isLoading
                      ? null
                      : () => context
                          .read<SettlementBloc>()
                          .add(SettlementPreviewRequested()),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: state.includedCostIds.isEmpty
                          ? colors.softGrey
                          : colors.textColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.invertTextColor,
                            ),
                          )
                        else
                          Icon(
                            Icons.calculate_rounded,
                            size: 16,
                            color: state.includedCostIds.isEmpty
                                ? colors.grey
                                : colors.invertTextColor,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          'Compute →',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: state.includedCostIds.isEmpty
                                ? colors.grey
                                : colors.invertTextColor,
                          ),
                        ),
                      ],
                    ),
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
        final rawName = firstName.categoryName?.trim();
        final rawIcon = firstName.categoryIcon?.trim();
        final bool isIconUrl = rawIcon != null &&
            (rawIcon.startsWith('http://') || rawIcon.startsWith('https://'));

        final String categoryName;
        if (rawName != null && rawName.isNotEmpty) {
          categoryName = rawName;
        } else if (rawIcon != null && !isIconUrl && rawIcon.isNotEmpty) {
          categoryName = rawIcon;
        } else {
          categoryName = 'Uncategorised';
        }

        final checkState = context.watch<SettlementBloc>().state.categoryCheckState(categoryId, costs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: checkState,
                    tristate: true,
                    activeColor: colors.textColor,
                    onChanged: (val) {
                      context.read<SettlementBloc>().add(
                        SettlementCategoryToggled(
                          categoryId: categoryId,
                          selected: val == true,
                        ),
                      );
                    },
                  ),
                  CategoryIconView(
                    icon: firstName.categoryIcon,
                    categoryName: categoryName,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final isChecked = context.watch<SettlementBloc>().state.selectedCostIds[cost.id] ?? true;
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
              activeColor: colors.textColor,
              onChanged: (val) => context.read<SettlementBloc>().add(
                SettlementCostToggled(costId: cost.id, selected: val ?? false),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.note ?? "No Note!",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isChecked ? colors.textColor : colors.grey,
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

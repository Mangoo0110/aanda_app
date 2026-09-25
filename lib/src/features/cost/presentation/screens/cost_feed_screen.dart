import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/amount_text.dart';
import 'package:aanda/src/core/shared/widget/app_card.dart';
import 'package:aanda/src/core/shared/widget/app_page_header.dart';
import 'package:aanda/src/core/shared/widget/app_section_header.dart';
import 'package:aanda/src/core/shared/widget/cost_list_row.dart';
import 'package:aanda/src/core/shared/widget/empty_state_view.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_creation_journey_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_detail_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/filter_expenses_sheet.dart';

import '../../../../app/routing/app_routes.dart';

class CostFeedScreen extends StatefulWidget {
  const CostFeedScreen({super.key});

  @override
  State<CostFeedScreen> createState() => _CostFeedScreenState();
}

class _CostFeedScreenState extends State<CostFeedScreen> {
  @override
  void initState() {
    super.initState();
    final houseCtx = context.read<HouseContextCubit>();
    if (!houseCtx.state.hasHouses &&
        houseCtx.state.status != HouseContextStatus.loading) {
      houseCtx.load();
    }
    final houseCtxState = houseCtx.state;
    if (houseCtxState.isPersonalView) {
      if (context.read<CostFeedBloc>().state.selectedHouseId != null) {
        context.read<CostFeedBloc>().add(
          const CostFeedHouseFilterChanged(null),
        );
      }
    } else {
      final currentHouseId = houseCtxState.selectedHouse?.id;
      if (currentHouseId != null &&
          context.read<CostFeedBloc>().state.selectedHouseId != currentHouseId) {
        context.read<CostFeedBloc>().add(
          CostFeedHouseFilterChanged(currentHouseId),
        );
      }
    }
  }

  Map<String, List<Cost>> _groupCostsByDate(List<Cost> costs) {
    final Map<String, List<Cost>> groups = {};
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    for (final cost in costs) {
      final d = cost.purchaseDate;
      String key;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        key = 'Today';
      } else if (d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day) {
        key = 'Yesterday';
      } else if (d.year == now.year) {
        key = DateFormat('d MMMM').format(d);
      } else {
        key = DateFormat('d MMMM, yyyy').format(d);
      }
      groups.putIfAbsent(key, () => []).add(cost);
    }
    return groups;
  }


  void _pickCustomDate(BuildContext context, CostFeedState state) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && context.mounted) {
      context.read<CostFeedBloc>().add(CostFeedMonthChanged(picked));
    }
  }

  void _navigateToAddExpense(BuildContext context) async {
    final houseId = context.read<CostFeedBloc>().state.selectedHouseId;
    await CostCreationJourneySheet.start(context, preferredHouseId: houseId);
    if (context.mounted) {
      context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
    }
  }

  void _showFilterSheet(BuildContext context, CostFeedState state) {
    FilterExpensesSheet.show(
      context: context,
      state: state,
      memberCount:
          context.read<HouseContextCubit>().state.selectedHouse?.members.length ??
              0,
      onApply: (sprint, payerId, categoryId, scope) {
        context.read<CostFeedBloc>().add(
              CostFeedFiltersApplied(
                sprint: sprint,
                payerId: payerId,
                categoryId: categoryId,
                scope: scope,
              ),
            );
      },
      onReset: () {
        context.read<CostFeedBloc>().add(const CostFeedFiltersCleared());
      },
    );
  }

  void _showCostDetailSheet(
    BuildContext context, {
    required Cost cost,
    required String? currentUserId,
  }) {
    CostDetailSheet.show(
      context: context,
      cost: cost,
      isOwnCost: cost.paidBy == currentUserId,
      onEdit: cost.isSettled
          ? null
          : () async {
              final res = await context.push(
                AppRoutes.costAdd,
                extra: {'cost': cost},
              );
              if (res == true && context.mounted) {
                context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
                context.read<HouseContextCubit>().notifyCostUpdated();
              }
            },
      onDelete: cost.isSettled
          ? null
          : () {
              context.read<CostFeedBloc>().add(CostFeedDeleted(cost.id));
              context.read<HouseContextCubit>().notifyCostUpdated();
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocListener<HouseContextCubit, HouseContextState>(
      listenWhen: (prev, curr) =>
          prev.selectedHouse?.id != curr.selectedHouse?.id ||
          prev.isPersonalView != curr.isPersonalView ||
          prev.costUpdateCounter != curr.costUpdateCounter ||
          (prev.status != curr.status &&
              curr.status == HouseContextStatus.loaded),
      listener: (context, houseState) {
        final currentHouseId =
            houseState.isPersonalView ? null : houseState.selectedHouse?.id;
        final currentBlocHouse =
            context.read<CostFeedBloc>().state.selectedHouseId;
        if (currentHouseId != currentBlocHouse ||
            context.read<CostFeedBloc>().state.status ==
                CostFeedStatus.initial) {
          context.read<CostFeedBloc>().add(
            CostFeedHouseFilterChanged(currentHouseId),
          );
        } else {
          context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
        }
      },
      child: BlocConsumer<CostFeedBloc, CostFeedState>(
        listenWhen: (previous, current) =>
            (current.errorMessage != null &&
                current.errorMessage != previous.errorMessage) ||
            previous.costs.length != current.costs.length,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colors.errorColor,
              ),
            );
          } else {
            // When cost deleted or updated in CostFeedBloc, broadcast to other screens (Home, Settlement)
            context.read<HouseContextCubit>().notifyCostUpdated();
          }
        },
        builder: (context, state) {
          final displayCosts = state.displayCosts;
          final totalSpend = displayCosts.fold(0.0, (s, c) => s + c.amount);

          final houseCtx = context.watch<HouseContextCubit>();
          final isPersonal = houseCtx.state.isPersonalView;
          final selectedHouse = houseCtx.state.selectedHouse;
          final houseName = isPersonal
              ? 'Personal Account'
              : (selectedHouse?.name ?? 'Shared House');

          final groupedCosts = _groupCostsByDate(displayCosts);

          return Scaffold(
            backgroundColor: colors.appBackgroundColor,
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () => _navigateToAddExpense(context),
                backgroundColor: const Color(0xFF141414),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: colors.primaryColor,
                onRefresh: () async {
                  context.read<CostFeedBloc>().add(
                    const CostFeedRefreshRequested(),
                  );
                  context.read<HouseContextCubit>().refresh();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── 1. Page Header with Filter Action ───────────────────
                    SliverToBoxAdapter(
                      child: AppPageHeader(
                        title: 'Costs',
                        subtitle: houseName,
                        trailing: InkWell(
                          onTap: () => _showFilterSheet(context, state),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: state.activeFiltersCount > 0
                                  ? colors.primaryColor
                                  : colors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: state.activeFiltersCount > 0
                                      ? Colors.white
                                      : colors.textColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.activeFiltersCount > 0
                                      ? 'Filter (${state.activeFiltersCount})'
                                      : 'Filter',
                                  style: AppTextStyles.caption.copyWith(
                                    color: state.activeFiltersCount > 0
                                        ? Colors.white
                                        : colors.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── 2. Date / Cycle Navigator ────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                color: colors.textColor,
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  final prev = DateTime(
                                    state.selectedMonth.year,
                                    state.selectedMonth.month - 1,
                                  );
                                  context.read<CostFeedBloc>().add(
                                    CostFeedMonthChanged(prev),
                                  );
                                },
                              ),
                              InkWell(
                                onTap: () => _pickCustomDate(context, state),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: colors.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        state.selectedSprint != null
                                            ? '${state.selectedSprint!.label} (${state.selectedSprint!.dateRangeFormatted})'
                                            : DateFormat(
                                                'MMMM yyyy',
                                              ).format(state.selectedMonth),
                                        style: AppTextStyles.rowTitle.copyWith(
                                          color: colors.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                color: colors.textColor,
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  final next = DateTime(
                                    state.selectedMonth.year,
                                    state.selectedMonth.month + 1,
                                  );
                                  context.read<CostFeedBloc>().add(
                                    CostFeedMonthChanged(next),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── 3. Total Period Spend & Filter Action Card ───────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL SPENT',
                                      style: AppTextStyles.badge.copyWith(
                                        color: colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        AmountText(
                                          amount: totalSpend,
                                          style: AppTextStyles.amountMedium.copyWith(
                                            color: colors.textColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${displayCosts.length} items)',
                                          style: AppTextStyles.rowSubtitle.copyWith(
                                            color: colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Entries count badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.appBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 14,
                                      color: colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${displayCosts.length} ${displayCosts.length == 1 ? 'entry' : 'entries'}',
                                      style: AppTextStyles.badge.copyWith(
                                        color: colors.textColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── 4. Active Filters Chips Bar ───────────────────────────
                    if (state.activeFiltersCount > 0)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.only(top: 2, bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              if (state.selectedSprint != null)
                                _activeChip(
                                  colors: colors,
                                  label: state.selectedSprint!.label,
                                  onDeleted: () => context
                                      .read<CostFeedBloc>()
                                      .add(const CostFeedSprintSelected(null)),
                                ),
                              if (state.selectedScope != null) ...[
                                const SizedBox(width: 6),
                                _activeChip(
                                  colors: colors,
                                  label: state.selectedScope == CostScope.personal
                                      ? 'Personal'
                                      : 'Shared House',
                                  onDeleted: () =>
                                      context.read<CostFeedBloc>().add(
                                        const CostFeedScopeFilterChanged(null),
                                      ),
                                ),
                              ],
                              if (state.selectedCategoryId != null) ...[
                                const SizedBox(width: 6),
                                _activeChip(
                                  colors: colors,
                                  label: state.categories
                                          .where(
                                            (c) =>
                                                c.id == state.selectedCategoryId,
                                          )
                                          .firstOrNull
                                          ?.name ??
                                      'Category',
                                  onDeleted: () =>
                                      context.read<CostFeedBloc>().add(
                                        const CostFeedCategoryFilterChanged(null),
                                      ),
                                ),
                              ],
                              if (state.selectedPayerId != null) ...[
                                const SizedBox(width: 6),
                                _activeChip(
                                  colors: colors,
                                  label: state.uniquePayers
                                          .where(
                                            (p) => p.id == state.selectedPayerId,
                                          )
                                          .firstOrNull
                                          ?.name ??
                                      'Member',
                                  onDeleted: () =>
                                      context.read<CostFeedBloc>().add(
                                        const CostFeedPayerFilterChanged(null),
                                      ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => context.read<CostFeedBloc>().add(
                                  const CostFeedFiltersCleared(),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Reset all',
                                    style: AppTextStyles.rowSubtitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── 5. Date-Grouped Cost List ────────────────────────────
                    if (state.isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    else if (displayCosts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: state.activeFiltersCount > 0
                              ? 'No matching costs'
                              : 'No expenses yet',
                          subtitle: state.activeFiltersCount > 0
                              ? 'Try modifying your search or resetting filters.'
                              : 'Tap the + button below to add your first expense.',
                        ),
                      )
                    else ...[
                      for (final entry in groupedCosts.entries) ...[
                        SliverToBoxAdapter(
                          child: AppSectionHeader(
                            label: entry.key,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: entry.value.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 68,
                                  color: colors.dividerColor,
                                ),
                                itemBuilder: (context, idx) {
                                  final cost = entry.value[idx];
                                  return CostListRow(
                                    cost: cost,
                                    currentUserId: currentUserId,
                                    onTap: () => _showCostDetailSheet(
                                      context,
                                      cost: cost,
                                      currentUserId: currentUserId,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _activeChip({
    required AppColors colors,
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: colors.tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: colors.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: colors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

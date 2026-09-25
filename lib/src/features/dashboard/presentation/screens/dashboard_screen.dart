import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/constants/assets.dart';
import 'package:aanda/src/core/shared/widget/amount_text.dart';
import 'package:aanda/src/core/shared/widget/app_card.dart';
import 'package:aanda/src/core/shared/widget/app_section_header.dart';
import 'package:aanda/src/core/shared/widget/cost_list_row.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/usecases/delete_cost.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_creation_journey_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_detail_sheet.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_quick_action_card.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_quick_actions_sheet.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/today_meals_table_card.dart';
import 'package:aanda/src/features/house/presentation/widgets/facebook_account_switcher_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final houseCtx = context.read<HouseContextCubit>();
    if (!houseCtx.state.hasHouses &&
        houseCtx.state.status != HouseContextStatus.loading) {
      houseCtx.load();
    }
    final initialHouseId = houseCtx.state.isPersonalView
        ? null
        : houseCtx.state.selectedHouse?.id;
    context.read<DashboardBloc>().add(
      DashboardHouseFilterChanged(initialHouseId),
    );
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(const DashboardRefreshRequested());
    context.read<HouseContextCubit>().refresh();
  }

  void _navigateToMeals() {
    final house = context.read<HouseContextCubit>().state.selectedHouse;
    if (house != null) {
      context.go(AppRoutes.mealsTab);
    } else {
      context.push(AppRoutes.meals);
    }
  }

  void _showQuickActionSheet() {
    final isPersonal =
        context.read<HouseContextCubit>().state.isPersonalView;
    DashboardQuickActionsSheet.show(
      context: context,
      isPersonal: isPersonal,
      onRefresh: _refresh,
      onNavigateToMeals: _navigateToMeals,
    );
  }

  void _handleSettle(BuildContext context) {
    final houseCtx = context.read<HouseContextCubit>().state;
    final accountId = houseCtx.activeAccountId ?? houseCtx.personalAccount?.id;
    if (accountId == null) {
      FacebookAccountSwitcherSheet.show(context);
      return;
    }
    final isPersonal = houseCtx.isPersonalView;
    final accountName = isPersonal
        ? 'Personal Account'
        : (houseCtx.selectedHouse?.name ?? 'Shared House');

    context.push(
      AppRoutes.settlementStart(accountId),
      extra: {
        'houseName': accountName,
        'isAdmin': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final houseCtxState = context.watch<HouseContextCubit>().state;
    final isPersonal = houseCtxState.isPersonalView;

    return BlocListener<HouseContextCubit, HouseContextState>(
      listenWhen: (prev, curr) =>
          prev.selectedHouse?.id != curr.selectedHouse?.id ||
          prev.isPersonalView != curr.isPersonalView ||
          prev.costUpdateCounter != curr.costUpdateCounter ||
          prev.mealUpdateCounter != curr.mealUpdateCounter ||
          (prev.status != curr.status &&
              curr.status == HouseContextStatus.loaded),
      listener: (context, houseState) {
        final currentHouseId =
            houseState.isPersonalView ? null : houseState.selectedHouse?.id;
        final currentBlocHouse =
            context.read<DashboardBloc>().state.selectedHouseId;
        if (currentHouseId != currentBlocHouse ||
            context.read<DashboardBloc>().state.status ==
                DashboardStatus.initial) {
          context.read<DashboardBloc>().add(
            DashboardHouseFilterChanged(currentHouseId),
          );
        } else {
          context.read<DashboardBloc>().add(const DashboardRefreshRequested());
        }
      },
      child: Scaffold(
        backgroundColor: colors.appBackgroundColor,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton(
            heroTag: null,
            onPressed: _showQuickActionSheet,
            backgroundColor: const Color(0xFF141414),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<DashboardBloc, DashboardState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: colors.errorColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              final currentUserId =
                  Supabase.instance.client.auth.currentUser?.id;
              final heroAmount = isPersonal
                  ? state.personalSpent
                  : state.totalHouseSpent;
              final recentCosts = state.effectiveRecentCosts;
              final hasExpenses = recentCosts.isNotEmpty ||
                  state.activities.isNotEmpty ||
                  heroAmount > 0 ||
                  state.totalHouseSpent > 0;

              return Column(
                children: [
                  // ── 1. Persistent Top App Bar ──────────────────────────────
                  Container(
                    color: colors.appBackgroundColor,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Banana Illustration + Track Banana Title Logo
                        Image.asset(
                          Assets.appLogoAndName,
                          height: 44,
                          fit: BoxFit.contain,
                        ),

                        // Right: Spending total with Green value in larger font
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  isPersonal ? 'Spending:   ' : 'House Cost:   ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: colors.grey,
                                  ),
                                ),
                                AmountText(
                                  amount: heroAmount,
                                  color: const Color.fromARGB(255, 61, 228, 114),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 2. Scrollable Content ──────────────────────────────────
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      color: colors.textColor,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 4)),

                    if (hasExpenses) ...[
                      if (!isPersonal) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () => _handleSettle(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.softGrey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Settle',
                                          style: AppTextStyles.badge.copyWith(
                                            color: colors.textColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 13,
                                          color: colors.textColor,
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
                      const SliverToBoxAdapter(child: SizedBox(height: 4)),

                      // ── Today's Meals Matrix (Shared House) ───────────────
                      if (!isPersonal) ...[
                        SliverToBoxAdapter(
                          child: TodayMealsTableCard(
                            members: state.houseMembers,
                            mealLogs: state.todayMealLogs,
                            isLoading: state.isTodayMealsLoading,
                            onOpenMealLog: _navigateToMeals,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],

                      // ── 3. Last Activity (Recent Costs) ──────────────────
                      if (recentCosts.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: AppSectionHeader(
                            label: 'Last Activity',
                            actionLabel: 'View all',
                            onAction: () => context.go(AppRoutes.costs),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: _buildLastActivityList(
                                colors,
                                recentCosts,
                                currentUserId,
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ] else ...[
                      // ── Empty State Guidance (No ৳0, Friendly UI) ───────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: colors.softGrey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 26,
                                    color: colors.textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No expenses recorded yet',
                                  style: AppTextStyles.pageTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isPersonal
                                      ? 'Add your first personal expense, or join a shared house to split costs with roommates.'
                                      : 'Add your first expense or meal to start tracking this cycle, or join another house.',
                                  style: AppTextStyles.rowSubtitle.copyWith(
                                    color: colors.grey,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        final houseCtx = context.read<HouseContextCubit>().state;
                                        final prefHouseId = houseCtx.isPersonalView ? null : houseCtx.selectedHouse?.id;
                                        await CostCreationJourneySheet.start(context, preferredHouseId: prefHouseId);
                                        if (context.mounted) {
                                          _refresh();
                                        }
                                      },
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      label: const Text('Add Expense'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colors.textColor,
                                        textStyle: AppTextStyles.rowTitle
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          context.push(AppRoutes.houseJoin),
                                      icon: const Icon(
                                          Icons.group_add_outlined,
                                          size: 18),
                                      label: const Text('Join a House'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colors.textColor,
                                        textStyle: AppTextStyles.rowTitle
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isPersonal) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(
                          child: TodayMealsTableCard(
                            members: state.houseMembers,
                            mealLogs: state.todayMealLogs,
                            isLoading: state.isTodayMealsLoading,
                            onOpenMealLog: _navigateToMeals,
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],

                    // ── 4. Quick Access Links ─────────────────────────────────
                    const SliverToBoxAdapter(
                      child: AppSectionHeader(label: 'Quick Access'),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.receipt_long_rounded,
                                    title: 'Expenses',
                                    subtitle: 'Browse all ledger costs',
                                    onTap: () => context.go(AppRoutes.costs),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.account_balance_rounded,
                                    title: 'Settlements',
                                    subtitle: 'Reconcile house balance',
                                    onTap: () => context.go(AppRoutes.settlement),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.add_home_rounded,
                                    title: 'Create House',
                                    subtitle: 'Start a new flat/mess',
                                    onTap: () => context.push(AppRoutes.houseCreate),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: QuickActionCard(
                                    icon: Icons.group_add_rounded,
                                    title: 'Join House',
                                    subtitle: 'Enter invite code',
                                    onTap: () => context.push(AppRoutes.houseJoin),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
          ),
        ),
      ),
    );
  }

  // ── Recent Costs List Builder ─────────────────────────────────────────────

  Widget _buildLastActivityList(
    AppColors colors,
    List<Cost> costs,
    String? currentUserId,
  ) {
    if (costs.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: costs.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 68,
        color: colors.dividerColor,
      ),
      itemBuilder: (context, index) {
        final cost = costs[index];
        return CostListRow(
          cost: cost,
          currentUserId: currentUserId,
          showDate: true,
          onTap: () => _showCostDetailSheet(
            context,
            cost: cost,
            currentUserId: currentUserId,
          ),
        );
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
                _refresh();
                context.read<HouseContextCubit>().notifyCostUpdated();
              }
            },
      onDelete: cost.isSettled
          ? null
          : () async {
              try {
                await context.read<DeleteCost>()(DeleteCostParams(costId: cost.id));
              } catch (_) {}
              if (context.mounted) {
                _refresh();
                context.read<HouseContextCubit>().notifyCostUpdated();
              }
            },
    );
  }
}

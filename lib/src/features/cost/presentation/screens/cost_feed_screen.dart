import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_detail_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/filter_expenses_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/tabular_ledger_row.dart';
import 'package:aanda/src/features/house/presentation/widgets/account_picker_sheet.dart';

class CostFeedScreen extends StatefulWidget {
  const CostFeedScreen({super.key});

  @override
  State<CostFeedScreen> createState() => _CostFeedScreenState();
}

class _CostFeedScreenState extends State<CostFeedScreen> {
  // Warm peach/cream ledger aesthetic colors
  static const Color backgroundColor = Color(0xFFFFF7EE);
  static const Color cardColor = Colors.white;
  static const Color primaryCoral = Color(0xFFD85A38);
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);

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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocListener<HouseContextCubit, HouseContextState>(
      listenWhen: (prev, curr) =>
          prev.selectedHouse?.id != curr.selectedHouse?.id ||
          prev.isPersonalView != curr.isPersonalView,
      listener: (context, houseState) {
        if (houseState.isPersonalView) {
          context.read<CostFeedBloc>().add(
            const CostFeedHouseFilterChanged(null),
          );
        } else {
          final houseId = houseState.selectedHouse?.id;
          if (houseId != context.read<CostFeedBloc>().state.selectedHouseId) {
            context.read<CostFeedBloc>().add(
              CostFeedHouseFilterChanged(houseId),
            );
          }
        }
      },
      child: BlocConsumer<CostFeedBloc, CostFeedState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colors.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final displayCosts = state.displayCosts;
          final totalSpend = displayCosts.fold(0.0, (s, c) => s + c.amount);
          final currencyFormat = NumberFormat('#,##0');

          final houseCtx = context.watch<HouseContextCubit>();
          final isPersonal = houseCtx.state.isPersonalView;
          final selectedHouse = houseCtx.state.selectedHouse;
          final houseName = isPersonal
              ? 'Personal Account'
              : (selectedHouse?.name ?? 'Shared House');
          final memberCount = selectedHouse?.members.length ?? 0;

        return Scaffold(
          backgroundColor: backgroundColor,
          floatingActionButton: FloatingActionButton(
            onPressed: _showQuickActionSheet,
            backgroundColor: primaryCoral,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: primaryCoral,
              onRefresh: () async {
                context.read<CostFeedBloc>().add(
                  const CostFeedRefreshRequested(),
                );
                context.read<HouseContextCubit>().refresh();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Top Navigation Bar ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          // Back button
                          const AppBackButton(margin: EdgeInsets.zero),
                          const SizedBox(width: 12),

                          // Title obeying appbar theme
                          Text(
                            'Expenses',
                            style: Theme.of(context).appBarTheme.titleTextStyle,
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final houseId =
                                  context.read<HouseContextCubit>().state.selectedHouse?.id;
                              if (houseId != null) {
                                context.push(AppRoutes.houseMeals(houseId));
                              } else {
                                context.push(AppRoutes.meals);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEEE8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🍲', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Meals',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryCoral,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // House selector chip on the right
                          InkWell(
                            onTap: _showHousePicker,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: primaryCoral.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: isPersonal
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 16,
                                            color: primaryCoral,
                                          )
                                        : Text(
                                            houseName.isNotEmpty
                                                ? houseName[0].toUpperCase()
                                                : 'H',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: primaryCoral,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            houseName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: darkText,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 14,
                                            color: subText,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: isPersonal
                                                  ? primaryCoral
                                                  : Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isPersonal
                                                ? 'Personal costs'
                                                : '$memberCount members',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: subText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Date / Cycle Navigator Pill ────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 20,
                              ),
                              color: darkText,
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
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: primaryCoral,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    state.selectedSprint != null
                                        ? '${state.selectedSprint!.label} (${state.selectedSprint!.dateRangeFormatted})'
                                        : DateFormat(
                                            'd MMM yyyy',
                                          ).format(state.selectedMonth),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              color: darkText,
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

                  // ── Total Period Spend & Filter Action Row ──────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            // Total spend stat
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL PERIOD SPEND',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: subText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '৳${currencyFormat.format(totalSpend)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: darkText,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${displayCosts.length} entries)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: subText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Filter Button with Badge
                            InkWell(
                              onTap: () => _showFilterSheet(context, state),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: state.activeFiltersCount > 0
                                      ? primaryCoral
                                      : primaryCoral.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 15,
                                      color: state.activeFiltersCount > 0
                                          ? Colors.white
                                          : primaryCoral,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      state.activeFiltersCount > 0
                                          ? 'Filter (${state.activeFiltersCount})'
                                          : 'Filter',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: state.activeFiltersCount > 0
                                            ? Colors.white
                                            : primaryCoral,
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
                  ),

                  // ── Active Filters Chips Bar ────────────────────────────────
                  if (state.activeFiltersCount > 0)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (state.selectedSprint != null)
                              _activeChip(
                                label: state.selectedSprint!.label,
                                onDeleted: () => context
                                    .read<CostFeedBloc>()
                                    .add(const CostFeedSprintSelected(null)),
                              ),
                            if (state.selectedScope != null) ...[
                              const SizedBox(width: 6),
                              _activeChip(
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
                                label:
                                    state.categories
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
                                label:
                                    state.uniquePayers
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
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Reset all',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryCoral,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Tabular Ledger Card ─────────────────────────────────────
                  if (state.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryCoral,
                          ),
                        ),
                      ),
                    )
                  else if (displayCosts.isEmpty)
                    SliverFillRemaining(child: _emptyStateView(context, state))
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Table Header Row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 40,
                                      child: Text(
                                        'ITEM & DETAILS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: subText.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 25,
                                      child: Center(
                                        child: Text(
                                          'TAG / POOL',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: subText.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 12,
                                      child: Center(
                                        child: Text(
                                          'BY',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: subText.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 23,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'AMOUNT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: subText.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: Colors.black.withValues(alpha: 0.06),
                              ),

                              // Table Ledger Rows
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayCosts.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.black.withValues(alpha: 0.04),
                                ),
                                itemBuilder: (context, idx) {
                                  final cost = displayCosts[idx];
                                  return TabularLedgerRow(
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
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _activeChip({required String label, required VoidCallback onDeleted}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD85A38).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD85A38),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFFD85A38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateView(BuildContext context, CostFeedState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: Color(0xFF8C8D8E),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              state.activeFiltersCount > 0
                  ? 'No matching expenses'
                  : 'No expenses yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B1D1F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.activeFiltersCount > 0
                  ? 'Try resetting the active filters.'
                  : 'Tap the + button below to add your first expense.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHousePicker() {
    AccountPickerSheet.show(context);
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
    final result = await context.push(AppRoutes.costAdd);
    if (result == true && context.mounted) {
      context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
    }
  }

  void _showQuickActionSheet() {
    final houseCtx = context.read<HouseContextCubit>();
    final isPersonal = houseCtx.state.isPersonalView;
    final selectedHouseId = houseCtx.state.selectedHouse?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose what you want to record',
                  style: TextStyle(fontSize: 12, color: subText),
                ),
                const SizedBox(height: 16),
                _buildQuickActionTile(
                  emoji: '📝',
                  title: 'Add Expense',
                  subtitle: 'Record personal or shared house cost',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _navigateToAddExpense(context);
                  },
                ),
                const SizedBox(height: 10),
                _buildQuickActionTile(
                  emoji: '🏷️',
                  title: 'New Expense Category',
                  subtitle: 'Create a custom category for expenses',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final res = await context.push(AppRoutes.costCategoryAdd);
                    if (res == true && mounted) {
                      context.read<CostFeedBloc>().add(
                        const CostFeedRefreshRequested(),
                      );
                    }
                  },
                ),
                if (!isPersonal) ...[
                  const SizedBox(height: 10),
                  _buildQuickActionTile(
                    emoji: '🍲',
                    title: 'Meal Log (Add Meal)',
                    subtitle: 'Record breakfast, lunch & dinner for today',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (selectedHouseId != null) {
                        context.push(AppRoutes.houseMeals(selectedHouseId));
                      } else {
                        context.push(AppRoutes.meals);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 10),
                _buildQuickActionTile(
                  emoji: '🏠',
                  title: 'Create Shared House',
                  subtitle: 'Start a new house/flat with flatmates',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final res = await context.push(AppRoutes.houseCreate);
                    if (res == true && mounted) {
                      context.read<HouseContextCubit>().refresh();
                      context.read<CostFeedBloc>().add(
                        const CostFeedRefreshRequested(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildQuickActionTile(
                  emoji: '🔑',
                  title: 'Join House with Code',
                  subtitle: 'Enter an invite code shared by flatmates',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final res = await context.push(AppRoutes.houseJoin);
                    if (res == true && mounted) {
                      context.read<HouseContextCubit>().refresh();
                      context.read<CostFeedBloc>().add(
                        const CostFeedRefreshRequested(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: subText),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: subText,
              size: 22,
            ),
          ],
        ),
      ),
    );
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
      onDelete: () {
        context.read<CostFeedBloc>().add(CostFeedDeleted(cost.id));
      },
    );
  }
}

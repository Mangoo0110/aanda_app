import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

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

  Map<String, dynamic>? _currentHouse;
  List<Map<String, dynamic>> _houses = [];

  @override
  void initState() {
    super.initState();
    _loadHouseDetails();
  }

  Future<void> _loadHouseDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from('houses').select('id, name, house_members(id, user_id, role, display_name)');
      final list = (data as List).cast<Map<String, dynamic>>();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _houses = list;
          _currentHouse = list.first;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocConsumer<CostFeedBloc, CostFeedState>(
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
        final displayCosts = state.displayCosts;
        final totalSpend = displayCosts.fold(0.0, (s, c) => s + c.amount);
        final currencyFormat = NumberFormat('#,##0');

        final houseName = _currentHouse?['name'] as String? ?? 'Dhaka Flat';
        final memberList = _currentHouse?['house_members'] as List? ?? [];
        final memberCount = memberList.isNotEmpty ? memberList.length : 5;

        return Scaffold(
          backgroundColor: backgroundColor,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showQuickActionSheet(context),
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
                context
                    .read<CostFeedBloc>()
                    .add(const CostFeedRefreshRequested());
                await _loadHouseDetails();
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
                          // Back button in rounded square
                          InkWell(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.home);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final houseId = _currentHouse?['id'] as String?;
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
                                    backgroundColor: primaryCoral.withValues(alpha: 0.12),
                                    child: Text(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$memberCount members',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 20),
                              color: darkText,
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                final prev = DateTime(
                                  state.selectedMonth.year,
                                  state.selectedMonth.month - 1,
                                );
                                context
                                    .read<CostFeedBloc>()
                                    .add(CostFeedMonthChanged(prev));
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
                                        : DateFormat('d MMM yyyy').format(state.selectedMonth),
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
                              icon: const Icon(Icons.chevron_right_rounded, size: 20),
                              color: darkText,
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                final next = DateTime(
                                  state.selectedMonth.year,
                                  state.selectedMonth.month + 1,
                                );
                                context
                                    .read<CostFeedBloc>()
                                    .add(CostFeedMonthChanged(next));
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
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
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
                                onDeleted: () => context
                                    .read<CostFeedBloc>()
                                    .add(const CostFeedScopeFilterChanged(null)),
                              ),
                            ],
                            if (state.selectedCategoryId != null) ...[
                              const SizedBox(width: 6),
                              _activeChip(
                                label: state.categories
                                        .where((c) => c.id == state.selectedCategoryId)
                                        .firstOrNull
                                        ?.name ??
                                    'Category',
                                onDeleted: () => context
                                    .read<CostFeedBloc>()
                                    .add(const CostFeedCategoryFilterChanged(null)),
                              ),
                            ],
                            if (state.selectedPayerId != null) ...[
                              const SizedBox(width: 6),
                              _activeChip(
                                label: state.uniquePayers
                                        .where((p) => p.id == state.selectedPayerId)
                                        .firstOrNull
                                        ?.name ??
                                    'Member',
                                onDeleted: () => context
                                    .read<CostFeedBloc>()
                                    .add(const CostFeedPayerFilterChanged(null)),
                              ),
                            ],
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => context
                                  .read<CostFeedBloc>()
                                  .add(const CostFeedFiltersCleared()),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                          valueColor: AlwaysStoppedAnimation<Color>(primaryCoral),
                        ),
                      ),
                    )
                  else if (displayCosts.isEmpty)
                    SliverFillRemaining(
                      child: _emptyStateView(context, state),
                    )
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
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                                            color: subText.withValues(alpha: 0.9),
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
                                            color: subText.withValues(alpha: 0.9),
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
                                            color: subText.withValues(alpha: 0.9),
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
                                  return _TabularLedgerRow(
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
    if (_houses.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select House',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _houses.length,
                    itemBuilder: (context, idx) {
                      final h = _houses[idx];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFDEEE6),
                          child: Icon(Icons.home_work_rounded,
                              color: Color(0xFFD85A38)),
                        ),
                        title: Text(
                          h['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: _currentHouse?['id'] == h['id']
                            ? const Icon(Icons.check_rounded,
                                color: Color(0xFFD85A38))
                            : null,
                        onTap: () {
                          setState(() => _currentHouse = h);
                          Navigator.of(ctx).pop();
                          context.read<CostFeedBloc>().add(
                              CostFeedHouseFilterChanged(h['id'] as String));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void _showQuickActionSheet(BuildContext context) {
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
                // 1. Add Expense Option
                InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _navigateToAddExpense(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5EE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Text('📝', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Expense',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Record personal or shared house cost',
                                style: TextStyle(fontSize: 12, color: subText),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subText,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 2. Meal Log Option
                InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    final houseId = _currentHouse?['id'] as String?;
                    if (houseId != null) {
                      context.push(AppRoutes.houseMeals(houseId));
                    } else {
                      context.push(AppRoutes.meals);
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5EE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Text('🍲', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meal Log (Add Meal)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Record breakfast, lunch & dinner for today',
                                style: TextStyle(fontSize: 12, color: subText),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subText,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, CostFeedState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FilterExpensesSheet(
        state: state,
        memberCount: _currentHouse?['house_members'] != null
            ? (_currentHouse!['house_members'] as List).length
            : 5,
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
      ),
    );
  }

  void _showCostDetailSheet(
    BuildContext context, {
    required Cost cost,
    required String? currentUserId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CostDetailSheet(
        cost: cost,
        isOwnCost: cost.paidBy == currentUserId,
        onDelete: () {
          context.read<CostFeedBloc>().add(CostFeedDeleted(cost.id));
        },
      ),
    );
  }
}

// ── Tabular Ledger Row ───────────────────────────────────────────────────────

class _TabularLedgerRow extends StatelessWidget {
  const _TabularLedgerRow({
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
            : (initial == 'S' ? const Color(0xFF6B7280) : const Color(0xFF4B5563)));

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      return ('Meal Pool', const Color(0xFFFDEEE6), const Color(0xFFD85A38));
    }
    if (cat.contains('gas') || cat.contains('bill') || cat.contains('utilit') || cat.contains('internet')) {
      return ('Utilities', const Color(0xFFF1F3F5), const Color(0xFF495057));
    }
    return ('Split +5', const Color(0xFFFDF0DD), const Color(0xFFD97706));
  }
}

// ── Filter Expenses Bottom Sheet (Exact Match to Mockup) ─────────────────────

class _FilterExpensesSheet extends StatefulWidget {
  const _FilterExpensesSheet({
    required this.state,
    required this.memberCount,
    required this.onApply,
    required this.onReset,
  });

  final CostFeedState state;
  final int memberCount;
  final void Function(
    Sprint? sprint,
    String? payerId,
    String? categoryId,
    CostScope? scope,
  ) onApply;
  final VoidCallback onReset;

  @override
  State<_FilterExpensesSheet> createState() => _FilterExpensesSheetState();
}

class _FilterExpensesSheetState extends State<_FilterExpensesSheet> {
  Sprint? _selectedSprint;
  String? _selectedPayerId;
  String? _selectedCategoryId;
  CostScope? _selectedScope;

  @override
  void initState() {
    super.initState();
    _selectedSprint = widget.state.selectedSprint;
    _selectedPayerId = widget.state.selectedPayerId;
    _selectedCategoryId = widget.state.selectedCategoryId;
    _selectedScope = widget.state.selectedScope;
  }

  int get _activeCount {
    int count = 0;
    if (_selectedSprint != null) count++;
    if (_selectedPayerId != null) count++;
    if (_selectedCategoryId != null) count++;
    if (_selectedScope != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    const primaryCoral = Color(0xFFD85A38);
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    const unselectedChipBg = Color(0xFFF4F4F4);

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
            // Drag Handle
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
            const SizedBox(height: 16),

            // Title Row with Active badge, Reset all, and close X
            Row(
              children: [
                const Text(
                  'Filter Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(width: 8),
                if (_activeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_activeCount Active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryCoral,
                      ),
                    ),
                  ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSprint = null;
                      _selectedPayerId = null;
                      _selectedCategoryId = null;
                      _selectedScope = null;
                    });
                    widget.onReset();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Reset all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryCoral,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Section 1: SETTLEMENT CYCLE ─────────────────────────────────
            const Text(
              'SETTLEMENT CYCLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: subText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.state.sprints.isNotEmpty) ...[
                  ...widget.state.sprints.map((s) {
                    final isSel = _selectedSprint?.id == s.id;
                    final label = s.isOpen
                        ? 'Current Cycle (${s.dateRangeFormatted} → Active)'
                        : s.label;
                    return _filterChip(
                      label: label,
                      isSelected: isSel,
                      onTap: () => setState(() {
                        _selectedSprint = isSel ? null : s;
                      }),
                      primaryColor: primaryCoral,
                      unselectedBg: unselectedChipBg,
                    );
                  }),
                ] else ...[
                  _filterChip(
                    label: 'Current Cycle (16 Sep → Active)',
                    isSelected: _selectedSprint == null,
                    onTap: () => setState(() => _selectedSprint = null),
                    primaryColor: primaryCoral,
                    unselectedBg: unselectedChipBg,
                  ),
                ],
                _filterChip(
                  label: 'Custom 📅',
                  isSelected: false,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (date != null && context.mounted) {
                      context.read<CostFeedBloc>().add(CostFeedMonthChanged(date));
                    }
                  },
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Section 2: TAG / EXPENSE POOL ───────────────────────────────
            const Text(
              'TAG / EXPENSE POOL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: subText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  label: 'All Tags',
                  isSelected: _selectedScope == null && _selectedCategoryId == null,
                  onTap: () => setState(() {
                    _selectedScope = null;
                    _selectedCategoryId = null;
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Bazar (Pool)',
                  isSelected: _selectedScope == CostScope.shared &&
                      _isCategoryMatch('bazar'),
                  onTap: () => setState(() {
                    _selectedScope = CostScope.shared;
                    _selectedCategoryId = _findCategoryId('bazar');
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Groceries',
                  isSelected: _isCategoryMatch('grocer'),
                  onTap: () => setState(() {
                    _selectedCategoryId = _findCategoryId('grocer');
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Utilities',
                  isSelected: _isCategoryMatch('utilit'),
                  onTap: () => setState(() {
                    _selectedCategoryId = _findCategoryId('utilit');
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Personal',
                  isSelected: _selectedScope == CostScope.personal,
                  onTap: () => setState(() {
                    _selectedScope = CostScope.personal;
                    _selectedCategoryId = null;
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Section 3: PAID BY MEMBER ───────────────────────────────────
            const Text(
              'PAID BY MEMBER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: subText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  label: 'All Members',
                  isSelected: _selectedPayerId == null,
                  onTap: () => setState(() => _selectedPayerId = null),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                ...widget.state.uniquePayers.map((p) {
                  final isSel = _selectedPayerId == p.id;
                  final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : 'M';
                  return _memberFilterChip(
                    label: p.name,
                    initial: initial,
                    isSelected: isSel,
                    onTap: () => setState(() {
                      _selectedPayerId = isSel ? null : p.id;
                    }),
                    primaryColor: primaryCoral,
                    unselectedBg: unselectedChipBg,
                  );
                }),
              ],
            ),
            const SizedBox(height: 26),

            // ── Bottom Action Buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {
                      widget.onApply(
                        _selectedSprint,
                        _selectedPayerId,
                        _selectedCategoryId,
                        _selectedScope,
                      );
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: primaryCoral,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Apply Filters (${widget.state.displayCosts.length} entries)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isCategoryMatch(String keyword) {
    if (_selectedCategoryId == null) return false;
    final cat = widget.state.categories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;
    return cat?.name.toLowerCase().contains(keyword) ?? false;
  }

  String? _findCategoryId(String keyword) {
    return widget.state.categories
        .where((c) => c.name.toLowerCase().contains(keyword))
        .firstOrNull
        ?.id;
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color unselectedBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1B1D1F),
          ),
        ),
      ),
    );
  }

  Widget _memberFilterChip({
    required String label,
    required String initial,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color unselectedBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFD97706),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1B1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cost Detail Bottom Sheet ─────────────────────────────────────────────────

class _CostDetailSheet extends StatelessWidget {
  const _CostDetailSheet({
    required this.cost,
    required this.isOwnCost,
    required this.onDelete,
  });

  final Cost cost;
  final bool isOwnCost;
  final VoidCallback onDelete;

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
                        DateFormat('EEEE, d MMMM yyyy • hh:mm a')
                            .format(cost.purchaseDate),
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

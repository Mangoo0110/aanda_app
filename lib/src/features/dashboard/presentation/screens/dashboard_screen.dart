import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_category_card.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_cycle_picker_sheet.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_profile_sheet.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_quick_action_card.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_quick_actions_sheet.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/dashboard_settlement_sheet.dart';
import 'package:aanda/src/features/house/presentation/widgets/account_picker_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Theme constants matching warm cream / peach minimal aesthetic
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
    // Load dashboard for active account (personal account or selected house).
    context.read<DashboardBloc>().add(
      DashboardHouseFilterChanged(houseCtx.state.activeAccountId),
    );
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(const DashboardRefreshRequested());
    context.read<HouseContextCubit>().refresh();
  }

  void _showCyclePicker(BuildContext context, DashboardState state) {
    DashboardCyclePickerSheet.show(context, state);
  }

  void _navigateToMeals() {
    final house = context.read<HouseContextCubit>().state.selectedHouse;
    if (house != null) {
      context.push(AppRoutes.houseMeals(house.id));
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0');

    final houseCtxState = context.watch<HouseContextCubit>().state;
    final isPersonal = houseCtxState.isPersonalView;
    final houseName = houseCtxState.selectedHouse?.name ?? 'My House';
    final chipLabel = isPersonal ? 'Personal Account' : houseName;
    final chipIcon = isPersonal ? '👤' : '🏠';
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';
    final avatarLetter = userEmail.isNotEmpty
        ? userEmail[0].toUpperCase()
        : 'U';

    return BlocListener<HouseContextCubit, HouseContextState>(
      listenWhen: (prev, curr) =>
          prev.selectedHouse?.id != curr.selectedHouse?.id ||
          prev.isPersonalView != curr.isPersonalView ||
          prev.personalAccount?.id != curr.personalAccount?.id,
      listener: (context, houseState) {
        final currentAccount = houseState.activeAccountId;
        final currentBlocHouse =
            context.read<DashboardBloc>().state.selectedHouseId;
        if (currentAccount != currentBlocHouse) {
          context.read<DashboardBloc>().add(
            DashboardHouseFilterChanged(currentAccount),
          );
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: _showQuickActionSheet,
          backgroundColor: primaryCoral,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
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
              // Cycle label and index
              final cycle = state.selectedCycle;
              final String cycleLabel;
              if (cycle != null) {
                final startFormatted =
                    DateFormat('d MMM').format(cycle.startDate);
                final endFormatted = cycle.endDate == null
                    ? 'Now'
                    : DateFormat('d MMM').format(cycle.endDate!);
                cycleLabel = '${cycle.label} • $startFormatted – $endFormatted';
              } else {
                cycleLabel = 'No Active Cycle';
              }

              final cycleIndex =
                  cycle != null ? state.cycles.indexOf(cycle) : -1;
              final hasOlderCycle = cycleIndex != -1 &&
                  cycleIndex < state.cycles.length - 1;
              final hasNewerCycle = cycleIndex > 0;

              return RefreshIndicator(
                onRefresh: _refresh,
                color: primaryCoral,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // ── 1. Top Bar: House Chip | Streak Badge | User Avatar ──────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Account/House Selector Pill
                            GestureDetector(
                              onTap: _showHousePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      chipLabel,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      chipIcon,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: subText,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // User Avatar
                            InkWell(
                              onTap: () => _showUserMenu(context),
                              borderRadius: BorderRadius.circular(18),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFFF2D1B3),
                                child: Text(
                                  avatarLetter,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5D3A1A),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14).toSliver(),

                    // ── 2. Settlement Cycle Navigator Pill ──
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  size: 18,
                                ),
                                color: hasOlderCycle
                                    ? darkText
                                    : subText.withValues(alpha: 0.3),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: hasOlderCycle
                                    ? () {
                                        final older =
                                            state.cycles[cycleIndex + 1];
                                        context.read<DashboardBloc>().add(
                                          DashboardCycleChanged(older),
                                        );
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _showCyclePicker(context, state),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        cycleLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: darkText,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: subText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                                color: hasNewerCycle
                                    ? darkText
                                    : subText.withValues(alpha: 0.3),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: hasNewerCycle
                                    ? () {
                                        final newer =
                                            state.cycles[cycleIndex - 1];
                                        context.read<DashboardBloc>().add(
                                          DashboardCycleChanged(newer),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14).toSliver(),

                    // ── 3. Hero Spend Stat & Settle Pill ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      isPersonal
                                          ? '৳${currencyFormat.format(state.personalSpent)}'
                                          : '৳${currencyFormat.format(state.myTotalSpent)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: darkText,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isPersonal
                                          ? 'Personal Spending'
                                          : 'Your Account Spending',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: subText,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isPersonal) ...[
                                  const SizedBox(width: 14),
                                  InkWell(
                                    onTap: () => _handleSettle(context),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDE745B),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Settle',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Secondary Badges: House Pool & Personal
                            if (!isPersonal)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'House Pool: ৳${currencyFormat.format(state.totalHouseSpent)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: darkText,
                                    ),
                                  ),
                                ),
                                if (state.personalSpent > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Personal: ৳${currencyFormat.format(state.personalSpent)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: subText,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12).toSliver(),

                   // ── 3.5 Core Feature Shortcuts ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await context.push(AppRoutes.costs);
                                if (mounted) _refresh();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('📊', style: TextStyle(fontSize: 15)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Expenses',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Meal Log shortcut only shown for shared house
                          if (!isPersonal) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: _navigateToMeals,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('🍲', style: TextStyle(fontSize: 15)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Meal Log',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16).toSliver(),

                  // ── 4. Recent Section Header ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await context.push(AppRoutes.costs);
                              if (mounted) _refresh();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              child: Text(
                                'View all',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryCoral,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8).toSliver(),

                  // ── 5. Recent Items Card ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildRecentList(currencyFormat, state.activities),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20).toSliver(),

                  // ── 6. Categories Section Header ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          InkWell(
                            onTap: _showManageCategoriesSheet,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              child: Text(
                                'Manage',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryCoral,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10).toSliver(),

                  // ── 7. 2x2 Categories Grid ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCategoriesGrid(),
                    ),
                  ),

                  const SizedBox(height: 20).toSliver(),

                  // ── 8. Quick Actions Section ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUICK ACTIONS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: subText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Add Expense Action Card
                              Expanded(
                                child: QuickActionCard(
                                  iconEmoji: '📝',
                                  title: 'Add Expense',
                                  subtitle: 'Quick log',
                                  onTap: () async {
                                    final res = await context.push(
                                      AppRoutes.costAdd,
                                    );
                                    if (res == true && mounted) _refresh();
                                  },
                                ),
                              ),
                              // Add Meal Action Card only for shared house
                              if (!isPersonal) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: QuickActionCard(
                                    iconEmoji: '🍲',
                                    title: 'Add Meal',
                                    subtitle: 'Shared house',
                                    onTap: _navigateToMeals,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  // ── Recent List Builder ───────────────────────────────────────────────────

  Widget _buildRecentList(
    NumberFormat currencyFormat,
    List<DashboardActivity> activities,
  ) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          'No recent activity yet. Start adding expenses or meals!',
          style: TextStyle(fontSize: 13, color: subText),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 64,
        color: Colors.black.withValues(alpha: 0.04),
      ),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final emoji = activity.type.name == 'meal' ? '🍲' : '💳';
        final amount = activity.amount ?? 0.0;
        final dateLabel = _formatRecentDate(
          activity.timestamp.toIso8601String(),
        );

        return InkWell(
          onTap: () async {
            await context.push(AppRoutes.costs);
            if (mounted) _refresh();
          },
          borderRadius: BorderRadius.vertical(
            top: index == 0 ? const Radius.circular(22) : Radius.zero,
            bottom: index == activities.length - 1
                ? const Radius.circular(22)
                : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.tag,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.title,
                        style: const TextStyle(fontSize: 12, color: subText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Amount & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (amount > 0)
                      Text(
                        '-৳${currencyFormat.format(amount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: const TextStyle(fontSize: 11, color: subText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Categories 2x2 Grid ───────────────────────────────────────────────────

  Widget _buildCategoriesGrid() {
    final defaultGrid = [
      {
        'emoji': '🏠',
        'title': 'Rent',
        'amount': '৳12K',
        'target': '৳12K',
        'sub': 'House · Mar 1',
      },
      {
        'emoji': '☕',
        'title': 'Coffee',
        'amount': '৳850',
        'target': '৳1.5K',
        'sub': 'Starbucks · 3 logs',
      },
      {
        'emoji': '🛒',
        'title': 'Supermarket',
        'amount': '৳4.2K',
        'target': '৳7.0K',
        'sub': 'Kitchen Pool · Daily',
      },
      {
        'emoji': '⚡',
        'title': 'Utilities',
        'amount': '৳1.4K',
        'target': '৳3.0K',
        'sub': 'Wifi & Gas',
      },
    ];

    return Row(
      children: [
        // Column 1
        Expanded(
          child: Column(
            children: [
              CategoryCard(
                emoji: defaultGrid[0]['emoji']!,
                title: defaultGrid[0]['title']!,
                amount: defaultGrid[0]['amount']!,
                target: defaultGrid[0]['target']!,
                subtitle: defaultGrid[0]['sub']!,
                onAdd: () => _addExpenseForCategory(defaultGrid[0]['title']!),
              ),
              const SizedBox(height: 12),
              CategoryCard(
                emoji: defaultGrid[2]['emoji']!,
                title: defaultGrid[2]['title']!,
                amount: defaultGrid[2]['amount']!,
                target: defaultGrid[2]['target']!,
                subtitle: defaultGrid[2]['sub']!,
                onAdd: () => _addExpenseForCategory(defaultGrid[2]['title']!),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Column 2
        Expanded(
          child: Column(
            children: [
              CategoryCard(
                emoji: defaultGrid[1]['emoji']!,
                title: defaultGrid[1]['title']!,
                amount: defaultGrid[1]['amount']!,
                target: defaultGrid[1]['target']!,
                subtitle: defaultGrid[1]['sub']!,
                onAdd: () => _addExpenseForCategory(defaultGrid[1]['title']!),
              ),
              const SizedBox(height: 12),
              CategoryCard(
                emoji: defaultGrid[3]['emoji']!,
                title: defaultGrid[3]['title']!,
                amount: defaultGrid[3]['amount']!,
                target: defaultGrid[3]['target']!,
                subtitle: defaultGrid[3]['sub']!,
                onAdd: () => _addExpenseForCategory(defaultGrid[3]['title']!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addExpenseForCategory(String categoryName) async {
    final res = await context.push(AppRoutes.costAdd);
    if (res == true && mounted) _refresh();
  }

  String _formatRecentDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'today';
      }
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return 'today';
    }
  }


  // ── Actions & Bottom Sheets ───────────────────────────────────────────────

  void _handleSettle(BuildContext context) {
    final house = context.read<HouseContextCubit>().state.selectedHouse;
    if (house == null) {
      _showHousePicker();
      return;
    }
    _showSettlementSheet(context);
  }

  void _showSettlementSheet(BuildContext context) {
    final house = context.read<HouseContextCubit>().state.selectedHouse;
    DashboardSettlementSheet.show(context, house);
  }

  void _showHousePicker() {
    AccountPickerSheet.show(context);
  }

  void _showManageCategoriesSheet() {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expense Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showCreateCategoryDialog();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: primaryCoral,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryCoral,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (context
                        .read<HouseContextCubit>()
                        .state
                        .selectedHouse ==
                    null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Standard system categories (Food, Rent, Utilities, Coffee, etc.) are active.',
                      style: TextStyle(color: subText, fontSize: 13),
                    ),
                  )
                else
                  BlocBuilder<HouseContextCubit, HouseContextState>(
                    builder: (context, houseCtxState) {
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCategoryDialog() {
    final houseId =
        context.read<HouseContextCubit>().state.selectedHouse?.id;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Create Category',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Internet, Laundry, Groceries',
            filled: true,
            fillColor: const Color(0xFFFBF4EB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: subText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryCoral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(dialogCtx).pop();
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.from('cost_categories').insert({
                    'name': text,
                    'icon': '🏷️',
                    if (houseId != null) 'house_id': houseId,
                  });
                  _refresh();
                } catch (_) {}
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    DashboardProfileSheet.show(
      context: context,
      onManageHouses: _showHousePicker,
      onNavigateToMeals: _navigateToMeals,
    );
  }
}

extension _SliverSpacer on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}

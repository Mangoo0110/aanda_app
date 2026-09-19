import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

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
    final cycles = state.cycles;
    final selectedCycle = state.selectedCycle;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.6,
            ),
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
                    'Select Cycle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (cycles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No cycles recorded yet for this house.',
                          style: TextStyle(color: subText, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cycles.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                        itemBuilder: (_, index) {
                          final cycle = cycles[index];
                          final isSelected = cycle.id == selectedCycle?.id;
                          final isOpen = cycle.status == SprintStatus.open;
                          final startFormatted =
                              DateFormat('d MMM yyyy').format(cycle.startDate);
                          final endFormatted = isOpen
                              ? 'Now (Open)'
                              : DateFormat('d MMM yyyy').format(cycle.endDate!);

                          return InkWell(
                            onTap: () {
                              Navigator.of(sheetCtx).pop();
                              context.read<DashboardBloc>().add(
                                DashboardCycleChanged(cycle),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isSelected
                                        ? primaryCoral.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.05),
                                    child: Icon(
                                      isOpen
                                          ? Icons.timelapse_rounded
                                          : Icons.lock_clock_rounded,
                                      size: 18,
                                      color: isSelected
                                          ? primaryCoral
                                          : subText,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              cycle.label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? primaryCoral
                                                    : darkText,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isOpen
                                                    ? const Color(0xFFE8F5E9)
                                                    : const Color(0xFFEEEEEE),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isOpen ? 'ACTIVE' : 'CLOSED',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: isOpen
                                                      ? const Color(0xFF2E7D32)
                                                      : const Color(0xFF757575),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '$startFormatted – $endFormatted',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: subText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryCoral,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final res = await context.push(AppRoutes.costAdd);
                    if (res == true && mounted) _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildQuickActionTile(
                  emoji: '🏷️',
                  title: 'New Expense Category',
                  subtitle: 'Create a custom category for expenses',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await context.push(AppRoutes.costCategoryAdd);
                    if (mounted) _refresh();
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
                      _navigateToMeals();
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
                      _refresh();
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
                      _refresh();
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
                                child: _QuickActionCard(
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
                                  child: _QuickActionCard(
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
              _CategoryCard(
                emoji: defaultGrid[0]['emoji']!,
                title: defaultGrid[0]['title']!,
                amount: defaultGrid[0]['amount']!,
                target: defaultGrid[0]['target']!,
                subtitle: defaultGrid[0]['sub']!,
                onAdd: () => _addExpenseForCategory(defaultGrid[0]['title']!),
              ),
              const SizedBox(height: 12),
              _CategoryCard(
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
              _CategoryCard(
                emoji: defaultGrid[1]['emoji']!,
                title: defaultGrid[1]['title']!,
                amount: defaultGrid[1]['amount']!,
                target: defaultGrid[1]['target']!,
                subtitle: defaultGrid[1]['sub']!,
                onAdd: () => _addExpenseForCategory(defaultGrid[1]['title']!),
              ),
              const SizedBox(height: 12),
              _CategoryCard(
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
    final houseName = house?.name ?? 'Shared House';
    final houseId = house?.id;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy, h:mm a').format(now);

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
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryCoral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('⚖️', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Cycle & Settle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          Text(
                            houseName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: subText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5EE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: primaryCoral,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Calculation Snapshot: $dateStr',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Settling ends the current cycle, tallies total expenses and meal share from the start date to right now, resolves member balances, and starts a fresh new cycle.',
                        style: TextStyle(
                          fontSize: 12,
                          color: subText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: const Text(
                      'Calculate & End Cycle',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryCoral,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      if (houseId != null) {
                        context.push(AppRoutes.houseDetail(houseId));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: subText,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showHousePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
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
                    'Switch Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: BlocBuilder<HouseContextCubit, HouseContextState>(
                      builder: (context, houseCtxState) {
                        final isPersonalSelected = houseCtxState.isPersonalView;

                        return ListView(
                          shrinkWrap: true,
                          children: [
                            // —— Personal Account option ——
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isPersonalSelected
                                    ? primaryCoral.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: isPersonalSelected
                                      ? primaryCoral
                                      : darkText,
                                ),
                              ),
                              title: Text(
                                'My Personal Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isPersonalSelected ? primaryCoral : darkText,
                                ),
                              ),
                              subtitle: const Text(
                                'Only your personal expenses',
                                style: TextStyle(fontSize: 11, color: subText),
                              ),
                              trailing: isPersonalSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryCoral,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                context
                                    .read<HouseContextCubit>()
                                    .selectPersonal();
                                Navigator.of(sheetContext).pop();
                                _refresh();
                              },
                            ),
                            Divider(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            if (houseCtxState.hasSharedHouses) ...[
                              // —— Shared houses ——
                              ...houseCtxState.sharedHouses.map((h) {
                                final isSelected =
                                    !isPersonalSelected &&
                                    h.id == houseCtxState.selectedHouse?.id;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? primaryCoral.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.05),
                                    child: Text(
                                      h.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? primaryCoral
                                            : darkText,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    h.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? primaryCoral : darkText,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${h.members.length} member${h.members.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: subText,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.restaurant_rounded,
                                          size: 20,
                                        ),
                                        color: primaryCoral,
                                        tooltip: 'Open Meals',
                                        onPressed: () {
                                          Navigator.of(sheetContext).pop();
                                          context.push(
                                            AppRoutes.houseMeals(h.id),
                                          );
                                        },
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: primaryCoral,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    context
                                        .read<HouseContextCubit>()
                                        .selectHouse(h);
                                    Navigator.of(sheetContext).pop();
                                    _refresh();
                                  },
                                );
                              }),
                            ] else ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text(
                                    'No shared houses joined yet.',
                                    style: TextStyle(fontSize: 12, color: subText),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create House'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryCoral,
                            side: const BorderSide(color: primaryCoral),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            final res = await context.push(
                              AppRoutes.houseCreate,
                            );
                            if (res == true && mounted) {
                              context.read<HouseContextCubit>().refresh();
                              _refresh();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.group_add_rounded, size: 18),
                          label: const Text('Join House'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryCoral,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            final res = await context.push(AppRoutes.houseJoin);
                            if (res == true && mounted) {
                              context.read<HouseContextCubit>().refresh();
                              _refresh();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'User';

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF2D1B3),
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D3A1A),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.home_work_rounded,
                  color: primaryCoral,
                ),
                title: const Text(
                  'Manage Houses',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showHousePicker();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.receipt_long_rounded,
                  color: primaryCoral,
                ),
                title: const Text(
                  'Expenses Ledger',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.costs);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: primaryCoral,
                ),
                title: const Text(
                  'Meal Log (Daily Ledger)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _navigateToMeals();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.vpn_key_rounded,
                  color: primaryCoral,
                ),
                title: const Text(
                  'Change Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.authResetPassword);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final logout = context.read<Logout>();
                  await logout(const NoParams());
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFF8C8D8E),
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF8C8D8E),
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showDeleteAccountConfirmation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    bool isDeleting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFD85A38),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Account?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your login access will be immediately revoked. '
                  'Shared expense and meal history you\'ve contributed '
                  'to will be preserved for your housemates.\n\n'
                  'This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: subText,
                    height: 1.5,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD85A38).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFD85A38),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setState(() {
                              isDeleting = true;
                              errorMessage = null;
                            });
                            try {
                              final deleteAccount =
                                  context.read<DeleteAccount>();
                              final result =
                                  await deleteAccount(const NoParams());
                              if (result.success) {
                                // Auth deletion triggers the auth stream →
                                // auto-redirect to auth screen.
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              } else {
                                setState(() {
                                  isDeleting = false;
                                  errorMessage = result.message.isNotEmpty
                                      ? result.message
                                      : 'Failed to delete account. Please try again.';
                                });
                              }
                            } catch (e) {
                              setState(() {
                                isDeleting = false;
                                errorMessage = e.toString();
                              });
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD85A38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Yes, Delete My Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.of(sheetCtx).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Card Widget ────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.amount,
    required this.target,
    required this.subtitle,
    required this.onAdd,
  });

  final String emoji;
  final String title;
  final String amount;
  final String target;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    const primaryCoral = Color(0xFFD85A38);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Icon & Plus button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEEE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: primaryCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 2),

          // Amount Progress: ৳12K of ৳12K
          Row(
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'of $target',
                style: const TextStyle(fontSize: 10, color: subText),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Subtitle: House · Mar 1
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: subText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card Widget ────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.iconEmoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconEmoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(iconEmoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: subText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Extension for Sliver spacer convenience ─────────────────────────────────

extension _SliverSpacer on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}

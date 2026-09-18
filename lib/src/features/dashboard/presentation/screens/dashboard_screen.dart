import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';

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

  List<Map<String, dynamic>> _houses = [];
  Map<String, dynamic>? _currentHouse;
  List<Map<String, dynamic>> _recentCosts = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadAllDashboardData();
  }

  Future<void> _loadAllDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch Houses
      final houseRes = await supabase
          .from('houses')
          .select('id, name, house_members(id, user_id, role, display_name)');
      final houses = (houseRes as List).cast<Map<String, dynamic>>();

      Map<String, dynamic>? activeHouse = _currentHouse;
      if (houses.isNotEmpty) {
        if (activeHouse == null ||
            !houses.any((h) => h['id'] == activeHouse?['id'])) {
          activeHouse = houses.first;
        } else {
          activeHouse = houses.firstWhere((h) => h['id'] == activeHouse?['id']);
        }
      }

      // 2. Fetch Recent Costs
      var costsQuery = supabase
          .from('costs')
          .select(
            'id, name, amount, purchase_date, cost_scope, note, cost_categories(id, name, icon)',
          )
          .order('purchase_date', ascending: false)
          .limit(5);

      if (activeHouse != null) {
        costsQuery = supabase
            .from('costs')
            .select(
              'id, name, amount, purchase_date, cost_scope, note, cost_categories(id, name, icon)',
            )
            .or('house_id.eq.${activeHouse['id']},cost_scope.eq.personal')
            .order('purchase_date', ascending: false)
            .limit(5);
      }

      final costsData = await costsQuery;
      final recentCosts = (costsData as List).cast<Map<String, dynamic>>();

      // 3. Fetch Categories
      final catRes = await supabase
          .from('cost_categories')
          .select('id, name, icon')
          .order('created_at', ascending: true)
          .limit(8);
      final categories = (catRes as List).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _houses = houses;
          _currentHouse = activeHouse;
          _recentCosts = recentCosts;
          _categories = categories;
        });
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(const DashboardRefreshRequested());
    await _loadAllDashboardData();
  }

  void _navigateToMeals() {
    final houseId =
        _currentHouse?['id'] as String? ??
        (_houses.isNotEmpty ? _houses.first['id'] as String? : null);
    if (houseId != null) {
      context.push(AppRoutes.houseMeals(houseId));
    } else {
      context.push(AppRoutes.meals);
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
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final res = await context.push(AppRoutes.costAdd);
                    if (res == true && mounted) _refresh();
                  },
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
                    _navigateToMeals();
                  },
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0');

    final houseName = _currentHouse?['name'] as String? ?? 'Dhaka Flat';
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';
    final avatarLetter = userEmail.isNotEmpty
        ? userEmail[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionSheet(context),
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
            // Total spend: totalHouseSpent + personalSpent or state summary
            final totalPeriodSpend = state.summary != null
                ? (state.totalHouseSpent > 0
                      ? state.totalHouseSpent
                      : state.personalSpent)
                : 18450.0;

            // Cycle label
            final now = DateTime.now();
            final isCurrentMonth =
                state.selectedMonth.year == now.year &&
                state.selectedMonth.month == now.month;
            final cycleLabel = isCurrentMonth
                ? '${DateFormat('MMMM d, yyyy').format(DateTime(now.year, now.month, 1))} – Now'
                : DateFormat('MMMM yyyy').format(state.selectedMonth);

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
                          // House Selector Pill
                          InkWell(
                            onTap: _showHousePicker,
                            borderRadius: BorderRadius.circular(20),
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
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    houseName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: darkText,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '🏠',
                                    style: TextStyle(fontSize: 13),
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

                  // ── 2. Settlement Cycle Navigator Pill ───────────────────────
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
                              color: subText,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () {
                                final prev = DateTime(
                                  state.selectedMonth.year,
                                  state.selectedMonth.month - 1,
                                );
                                context.read<DashboardBloc>().add(
                                  DashboardMonthChanged(prev),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cycleLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                              ),
                              color: subText,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () {
                                final next = DateTime(
                                  state.selectedMonth.year,
                                  state.selectedMonth.month + 1,
                                );
                                context.read<DashboardBloc>().add(
                                  DashboardMonthChanged(next),
                                );
                              },
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '৳${currencyFormat.format(totalPeriodSpend)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
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
                      ),
                    ),
                  ),

                  const SizedBox(height: 12).toSliver(),

                  // ── 3.5 Core Feature Shortcuts (Expenses & Meal Log) ────────
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
                        child: _buildRecentList(currencyFormat),
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
                              const SizedBox(width: 12),

                              // Add Meal Action Card
                              Expanded(
                                child: _QuickActionCard(
                                  iconEmoji: '🍲',
                                  title: 'Add Meal',
                                  subtitle: 'Shared house',
                                  onTap: _navigateToMeals,
                                ),
                              ),
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
    );
  }

  // ── Recent List Builder ───────────────────────────────────────────────────

  Widget _buildRecentList(NumberFormat currencyFormat) {
    // If recent costs loaded from DB, use them; else fallback to mockup items
    final items = _recentCosts.isNotEmpty
        ? _recentCosts
        : [
            {
              'name': 'Starbucks',
              'note': 'Coffee',
              'amount': 450.0,
              'date_label': 'today',
              'emoji': '☕',
            },
            {
              'name': 'Supermarket',
              'note': 'Groceries',
              'amount': 3200.0,
              'date_label': 'Mar 4',
              'emoji': '🛒',
            },
            {
              'name': 'House',
              'note': 'Rent',
              'amount': 12000.0,
              'date_label': 'Mar 1',
              'emoji': '🏠',
            },
          ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 64,
        color: Colors.black.withValues(alpha: 0.04),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] as String? ?? 'Expense';
        final note = (item['note'] as String?)?.isNotEmpty == true
            ? item['note'] as String
            : (item['cost_categories'] != null &&
                      item['cost_categories']['name'] != null
                  ? item['cost_categories']['name'] as String
                  : 'General');

        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final dateLabel =
            item['date_label'] as String? ??
            (item['purchase_date'] != null
                ? _formatRecentDate(item['purchase_date'] as String)
                : 'today');

        final emoji =
            item['emoji'] as String? ??
            _resolveEmoji(name, note, item['cost_categories']?['icon']);

        return InkWell(
          onTap: () async {
            await context.push(AppRoutes.costs);
            if (mounted) _refresh();
          },
          borderRadius: BorderRadius.vertical(
            top: index == 0 ? const Radius.circular(22) : Radius.zero,
            bottom: index == items.length - 1
                ? const Radius.circular(22)
                : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon in soft tinted rounded container
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

                // Name & Note/Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
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
                        note,
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

  String _resolveEmoji(String name, String note, String? icon) {
    if (icon != null && icon.isNotEmpty && icon.length <= 4) {
      return icon;
    }
    final combined = '$name $note'.toLowerCase();
    if (combined.contains('coffee') ||
        combined.contains('tea') ||
        combined.contains('starbucks')) {
      return '☕';
    }
    if (combined.contains('market') ||
        combined.contains('grocer') ||
        combined.contains('bazar') ||
        combined.contains('food')) {
      return '🛒';
    }
    if (combined.contains('rent') ||
        combined.contains('house') ||
        combined.contains('flat')) {
      return '🏠';
    }
    if (combined.contains('gas') ||
        combined.contains('utilit') ||
        combined.contains('electric') ||
        combined.contains('wifi') ||
        combined.contains('bill')) {
      return '⚡';
    }
    return '💳';
  }

  // ── Actions & Bottom Sheets ───────────────────────────────────────────────

  void _handleSettle(BuildContext context) {
    if (_currentHouse == null) {
      _showHousePicker();
      return;
    }
    _showSettlementSheet(context);
  }

  void _showSettlementSheet(BuildContext context) {
    final houseName = _currentHouse?['name'] as String? ?? 'Shared House';
    final houseId = _currentHouse?['id'] as String?;
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
                    'Select Shared House',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_houses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No shared houses joined yet.',
                        style: TextStyle(color: subText, fontSize: 13),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _houses.length,
                        itemBuilder: (context, idx) {
                          final h = _houses[idx];
                          final isSelected = h['id'] == _currentHouse?['id'];
                          final members = h['house_members'] as List? ?? [];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? primaryCoral.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.05),
                              child: Text(
                                (h['name'] as String? ?? 'H')[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? primaryCoral : darkText,
                                ),
                              ),
                            ),
                            title: Text(
                              h['name'] as String? ?? 'House',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? primaryCoral : darkText,
                              ),
                            ),
                            subtitle: Text(
                              '${members.length} members',
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
                                      AppRoutes.houseMeals(h['id'] as String),
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
                              setState(() {
                                _currentHouse = h;
                              });
                              Navigator.of(sheetContext).pop();
                              _refresh();
                            },
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
                            if (res == true && mounted) _refresh();
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
                            if (res == true && mounted) _refresh();
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
                if (_categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Standard system categories (Food, Rent, Utilities, Coffee, etc.) are active.',
                      style: TextStyle(color: subText, fontSize: 13),
                    ),
                  )
                else
                  ..._categories.map((cat) {
                    final catName = cat['name'] as String? ?? 'Category';
                    final catIcon = cat['icon'] as String? ?? '🏷️';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            catIcon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      title: Text(
                        catName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: darkText,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: subText,
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _addExpenseForCategory(catName);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCategoryDialog() {
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
                    if (_currentHouse != null) 'house_id': _currentHouse!['id'],
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
            ],
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

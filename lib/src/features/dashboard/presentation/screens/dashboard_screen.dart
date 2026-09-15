import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: colors.textColor,
          ),
        ),
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.iconColor),
            tooltip: 'Refresh',
            onPressed: () {
              context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested());
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colors.errorColor),
            tooltip: 'Log Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: colors.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
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
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Month Navigator ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _MonthNavigator(
                    selectedMonth: state.selectedMonth,
                    onMonthChanged: (month) {
                      context
                          .read<DashboardBloc>()
                          .add(DashboardMonthChanged(month));
                    },
                  ),
                ),

                // ── 2. Owner's Impact Card ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroImpactCard(
                    personalSpent: state.personalSpent,
                    myHouseContribution: state.myHouseContribution,
                    cycleMonth: state.selectedMonth,
                  ),
                ),

                // ── 3. Quick Access Stat Tiles ──────────────────────────────
                SliverToBoxAdapter(
                  child: _QuickAccessStatTiles(
                    personalSpent: state.personalSpent,
                    totalHouseSpent: state.totalHouseSpent,
                    myHouseContribution: state.myHouseContribution,
                    onOpenExpenses: () async {
                      await context.push(AppRoutes.costs);
                      if (context.mounted) {
                        context
                            .read<DashboardBloc>()
                            .add(const DashboardRefreshRequested());
                      }
                    },
                    onManageHouse: () => _openHouseDetails(context),
                  ),
                ),

                // ── 4. Recent Activity Stories Header ───────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: colors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        if (state.activities.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.activities.length} updates',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── 5. Activity Feed / Loading / Empty ───────────────────────
                if (state.isLoading && state.summary == null)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.activities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bubble_chart_outlined,
                              size: 44,
                              color: colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No activity recorded for this period',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your personal expenses or log meals in your house to see updates here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = state.activities[index];
                        return _ActivityFeedTile(activity: activity);
                      },
                      childCount: state.activities.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final colors = AppColors.context(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
        content: Text(
          email != null
              ? 'Are you sure you want to log out of $email?'
              : 'Are you sure you want to log out of your account?',
          style: TextStyle(
            color: colors.textColor.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final logout = context.read<Logout>();
              await logout(const NoParams());
            },
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    final colors = AppColors.context(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: colors.primaryColor,
                    ),
                  ),
                  title: Text(
                    'Add Expense',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Log a personal or shared house expense',
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.iconColor,
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final result = await context.push(AppRoutes.costAdd);
                    if (result == true && context.mounted) {
                      context
                          .read<DashboardBloc>()
                          .add(const DashboardRefreshRequested());
                    }
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  title: Text(
                    'Add a Shared House',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Create a shared group for housemates',
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.iconColor,
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final result = await context.push(AppRoutes.houseCreate);
                    if (result == true && context.mounted) {
                      context
                          .read<DashboardBloc>()
                          .add(const DashboardRefreshRequested());
                    }
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.group_add_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  title: Text(
                    'Join a Shared House',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Enter an invite code from your housemate',
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.iconColor,
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final result = await context.push(AppRoutes.houseJoin);
                    if (result == true && context.mounted) {
                      context
                          .read<DashboardBloc>()
                          .add(const DashboardRefreshRequested());
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

  void _openHouseDetails(BuildContext context) async {
    final colors = AppColors.context(context);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from('houses').select('id, name');
      final houses = (data as List).cast<Map<String, dynamic>>();

      if (!context.mounted) return;
      if (houses.isEmpty) {
        final res = await context.push(AppRoutes.houseCreate);
        if (res == true && context.mounted) {
          context
              .read<DashboardBloc>()
              .add(const DashboardRefreshRequested());
        }
      } else if (houses.length == 1) {
        context.push(AppRoutes.houseDetail(houses.first['id'] as String));
      } else {
        showModalBottomSheet(
          context: context,
          backgroundColor: colors.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a House',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...houses.map(
                      (h) => ListTile(
                        leading: const Icon(
                          Icons.home_work_rounded,
                          color: Colors.teal,
                        ),
                        title: Text(
                          h['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textColor,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.push(
                            AppRoutes.houseDetail(h['id'] as String),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (_) {}
  }
}

// ── Month Navigator ─────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: colors.iconColor),
            onPressed: () {
              final prev = DateTime(selectedMonth.year, selectedMonth.month - 1);
              onMonthChanged(prev);
            },
          ),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: colors.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: colors.iconColor),
            onPressed: () {
              final next = DateTime(selectedMonth.year, selectedMonth.month + 1);
              onMonthChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

// ── Hero Impact Card ─────────────────────────────────────────────────────────

class _HeroImpactCard extends StatelessWidget {
  const _HeroImpactCard({
    required this.personalSpent,
    required this.myHouseContribution,
    required this.cycleMonth,
  });

  final double personalSpent;
  final double myHouseContribution;
  final DateTime cycleMonth;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryColor,
              colors.primaryColor.withValues(alpha: 0.84),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.primaryColor.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Personal Expenses',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(cycleMonth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '৳ ${currencyFormat.format(personalSpent)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Direct Personal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '৳ ${currencyFormat.format(personalSpent)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contribution to House',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '৳ ${currencyFormat.format(myHouseContribution)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Access Stat Tiles ──────────────────────────────────────────────────

class _QuickAccessStatTiles extends StatelessWidget {
  const _QuickAccessStatTiles({
    required this.personalSpent,
    required this.totalHouseSpent,
    required this.myHouseContribution,
    required this.onOpenExpenses,
    required this.onManageHouse,
  });

  final double personalSpent;
  final double totalHouseSpent;
  final double myHouseContribution;
  final VoidCallback onOpenExpenses;
  final VoidCallback onManageHouse;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Tile 1: Your Expenses
          Expanded(
            child: _StatTile(
              title: 'Your Expenses',
              badgeText: 'Personal',
              stat: 'BDT ${currencyFormat.format(personalSpent)}',
              subtitle: 'Direct personal spend',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: Colors.blueAccent,
              buttonLabel: 'View Expenses',
              onTap: onOpenExpenses,
            ),
          ),
          const SizedBox(width: 12),
          // Tile 2: Shared House
          Expanded(
            child: _StatTile(
              title: 'Shared House',
              badgeText: 'House Pool',
              stat: 'BDT ${currencyFormat.format(totalHouseSpent)}',
              subtitle: myHouseContribution > 0
                  ? 'Contributed: BDT ${currencyFormat.format(myHouseContribution)}'
                  : 'Total house expenses',
              icon: Icons.home_work_rounded,
              accentColor: Colors.teal,
              buttonLabel: 'Manage House',
              onTap: onManageHouse,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.badgeText,
    required this.stat,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String badgeText;
  final String stat;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.borderColor.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.grey,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              stat,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: accentColor,
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

// ── Activity Feed Tile ───────────────────────────────────────────────────────

class _ActivityFeedTile extends StatelessWidget {
  const _ActivityFeedTile({required this.activity});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final isExpense = activity.isExpense;
    final accent = isExpense ? Colors.amber.shade700 : Colors.teal;
    final icon = isExpense ? Icons.receipt_long_rounded : Icons.restaurant_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activity.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatActivityTime(activity.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatActivityTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('d MMM, h:mm a').format(dt);
  }
}

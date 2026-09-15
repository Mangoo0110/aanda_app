import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';

class CostFeedScreen extends StatelessWidget {
  const CostFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

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
              context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
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
      body: BlocConsumer<CostFeedBloc, CostFeedState>(
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
          final myRecent = state.myRecentCosts(currentUserId, 3);
          final uniquePayers = state.uniquePayers;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Month selector bar ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _MonthNavigator(
                    selectedMonth: state.selectedMonth,
                    onMonthChanged: (month) {
                      context
                          .read<CostFeedBloc>()
                          .add(CostFeedMonthChanged(month));
                    },
                  ),
                ),

                // ── 1. Owner's Life Impact & Overview Card ──────────────────
                SliverToBoxAdapter(
                  child: _OwnerImpactCard(
                    myTotalSpent: state.myTotalSpent(currentUserId),
                    myPersonalSpent: state.myPersonalSpent(currentUserId),
                    mySharedSpent: state.mySharedSpent(currentUserId),
                    cycleMonth: state.selectedMonth,
                  ),
                ),

                // ── 2. Dual Cards (Personal vs House Pool) ──────────────────
                SliverToBoxAdapter(
                  child: _ScopeDualCards(
                    personalSpent: state.personalSpent,
                    sharedSpent: state.sharedSpent,
                    selectedScope: state.selectedScope,
                    lastPersonal: state.lastPersonalActivity,
                    lastHouse: state.lastHouseActivity,
                    onSelectScope: (scope) {
                      context
                          .read<CostFeedBloc>()
                          .add(CostFeedScopeFilterChanged(scope));
                    },
                    onManageHouse: () => _openHouseDetails(context),
                  ),
                ),

                // ── 3. My Recent Expenses (Last 2-3 of oneself) ─────────────
                if (myRecent.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _MyRecentExpensesSection(
                      recentCosts: myRecent,
                      onCostTap: (cost) {},
                    ),
                  ),

                // ── 4. Member / Owner Filter Bar (if multiple payers) ───────
                if (uniquePayers.length > 1)
                  SliverToBoxAdapter(
                    child: _PayerFilterBar(
                      selectedPayerId: state.selectedPayerId,
                      currentUserId: currentUserId,
                      uniquePayers: uniquePayers,
                      onPayerChanged: (payerId) {
                        context
                            .read<CostFeedBloc>()
                            .add(CostFeedPayerFilterChanged(payerId));
                      },
                    ),
                  ),

                // ── 5. Detailed List of expenses ────────────────────────────
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (displayCosts.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyFeedView(
                      scope: state.selectedScope,
                      isFilteredByPayer: state.selectedPayerId != null,
                      onAddPressed: () async {
                        final result = await context.push(AppRoutes.costAdd);
                        if (result == true && context.mounted) {
                          context
                              .read<CostFeedBloc>()
                              .add(const CostFeedRefreshRequested());
                        }
                      },
                    ),
                  )
                else
                  _CostListSliver(
                    costs: displayCosts,
                    currentUserId: currentUserId,
                    onDelete: (costId) {
                      context
                          .read<CostFeedBloc>()
                          .add(CostFeedDeleted(costId));
                    },
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
                    'Record a personal or shared expense',
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
                          .read<CostFeedBloc>()
                          .add(const CostFeedRefreshRequested());
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
                          .read<CostFeedBloc>()
                          .add(const CostFeedRefreshRequested());
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
                          .read<CostFeedBloc>()
                          .add(const CostFeedRefreshRequested());
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
          context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
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
                    ...houses.map((h) => ListTile(
                          leading: const Icon(Icons.home_work_rounded, color: Colors.teal),
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
                            context.push(AppRoutes.houseDetail(h['id'] as String));
                          },
                        )),
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

// ── 1. Owner's Impact Card ──────────────────────────────────────────────────

class _OwnerImpactCard extends StatelessWidget {
  const _OwnerImpactCard({
    required this.myTotalSpent,
    required this.myPersonalSpent,
    required this.mySharedSpent,
    required this.cycleMonth,
  });

  final double myTotalSpent;
  final double myPersonalSpent;
  final double mySharedSpent;
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
                      Icons.account_circle_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'My Out-of-Pocket Spend',
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
                  child: const Text(
                    'Active Cycle',
                    style: TextStyle(
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
              '৳ ${currencyFormat.format(myTotalSpent)}',
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
                        'Personal Life',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '৳ ${currencyFormat.format(myPersonalSpent)}',
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
                        'House Contribution',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '৳ ${currencyFormat.format(mySharedSpent)}',
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

// ── 2. Scope Dual Cards (Personal vs House) ─────────────────────────────────

class _ScopeDualCards extends StatelessWidget {
  const _ScopeDualCards({
    required this.personalSpent,
    required this.sharedSpent,
    required this.selectedScope,
    required this.lastPersonal,
    required this.lastHouse,
    required this.onSelectScope,
    required this.onManageHouse,
  });

  final double personalSpent;
  final double sharedSpent;
  final CostScope? selectedScope;
  final Cost? lastPersonal;
  final Cost? lastHouse;
  final ValueChanged<CostScope?> onSelectScope;
  final VoidCallback onManageHouse;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Personal Card
          Expanded(
            child: _ActivityCard(
              title: 'Personal',
              icon: Icons.person_rounded,
              iconColor: Colors.blueAccent,
              isSelected: selectedScope == CostScope.personal,
              total: '৳ ${currencyFormat.format(personalSpent)}',
              lastActivityTitle: lastPersonal?.name ?? 'No entries yet',
              lastActivitySubtitle: lastPersonal != null
                  ? '৳ ${currencyFormat.format(lastPersonal!.amount)}'
                  : 'Start tracking',
              onTap: () => onSelectScope(
                selectedScope == CostScope.personal ? null : CostScope.personal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // House Card
          Expanded(
            child: _ActivityCard(
              title: 'House Pool',
              icon: Icons.home_work_rounded,
              iconColor: Colors.teal,
              isSelected: selectedScope == CostScope.shared,
              total: '৳ ${currencyFormat.format(sharedSpent)}',
              lastActivityTitle: lastHouse?.name ?? 'No shared costs',
              lastActivitySubtitle: lastHouse != null
                  ? '${lastHouse!.payerName ?? "Member"} • ৳ ${currencyFormat.format(lastHouse!.amount)}'
                  : 'Add shared cost',
              actionLabel: 'Details ➔',
              onActionTap: onManageHouse,
              onTap: () => onSelectScope(
                selectedScope == CostScope.shared ? null : CostScope.shared,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.total,
    required this.lastActivityTitle,
    required this.lastActivitySubtitle,
    required this.onTap,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final String total;
  final String lastActivityTitle;
  final String lastActivitySubtitle;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.primaryColor
                : colors.borderColor.withValues(alpha: 0.4),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: colors.primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              total,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.tileColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Activity',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastActivityTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  Text(
                    lastActivitySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (onActionTap != null) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onActionTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel ?? 'Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: colors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 3. My Recent Expenses Section ───────────────────────────────────────────

class _MyRecentExpensesSection extends StatelessWidget {
  const _MyRecentExpensesSection({
    required this.recentCosts,
    required this.onCostTap,
  });

  final List<Cost> recentCosts;
  final ValueChanged<Cost> onCostTap;

  IconData _iconForCategory(String? iconKey) {
    return switch (iconKey) {
      'restaurant' => Icons.restaurant_rounded,
      'shopping_basket' => Icons.shopping_basket_rounded,
      'directions_bus' => Icons.directions_bus_rounded,
      'flash_on' => Icons.flash_on_rounded,
      'home' => Icons.home_rounded,
      'shopping_bag' => Icons.shopping_bag_rounded,
      'medical_services' => Icons.medical_services_rounded,
      'movie' => Icons.movie_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: colors.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'My Recent Expenses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: recentCosts.length,
              separatorBuilder: (_, __) => Divider(
                color: colors.borderColor.withValues(alpha: 0.25),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final cost = recentCosts[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.tileColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForCategory(cost.categoryIcon),
                      color: colors.primaryColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    cost.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    '${DateFormat('d MMM').format(cost.purchaseDate)} • ${cost.isPersonal ? "Personal" : "Shared"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.grey,
                    ),
                  ),
                  trailing: Text(
                    '৳ ${currencyFormat.format(cost.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Member / Owner Filter Bar ────────────────────────────────────────────

class _PayerFilterBar extends StatelessWidget {
  const _PayerFilterBar({
    required this.selectedPayerId,
    required this.currentUserId,
    required this.uniquePayers,
    required this.onPayerChanged,
  });

  final String? selectedPayerId;
  final String? currentUserId;
  final List<({String id, String name})> uniquePayers;
  final ValueChanged<String?> onPayerChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _PayerChip(
              label: 'All Payers',
              isSelected: selectedPayerId == null,
              onTap: () => onPayerChanged(null),
            ),
            const SizedBox(width: 8),
            if (currentUserId != null) ...[
              _PayerChip(
                label: 'Only Me',
                icon: Icons.person_rounded,
                isSelected: selectedPayerId == currentUserId,
                onTap: () => onPayerChanged(
                  selectedPayerId == currentUserId ? null : currentUserId,
                ),
              ),
              const SizedBox(width: 8),
            ],
            ...uniquePayers
                .where((p) => p.id != currentUserId)
                .map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PayerChip(
                        label: p.name,
                        isSelected: selectedPayerId == p.id,
                        onTap: () => onPayerChanged(
                          selectedPayerId == p.id ? null : p.id,
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}

class _PayerChip extends StatelessWidget {
  const _PayerChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor : colors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.primaryColor
                : colors.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : colors.iconColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 5. Detailed List Sliver ─────────────────────────────────────────────────

class _CostListSliver extends StatelessWidget {
  const _CostListSliver({
    required this.costs,
    required this.currentUserId,
    required this.onDelete,
  });

  final List<Cost> costs;
  final String? currentUserId;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Cost>>{};
    for (final cost in costs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(cost.purchaseDate);
      grouped.putIfAbsent(dateKey, () => []).add(cost);
    }

    final dateKeys = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dateKey = dateKeys[index];
          final dateCosts = grouped[dateKey]!;
          final date = DateTime.parse(dateKey);

          return _DateGroupSection(
            date: date,
            costs: dateCosts,
            currentUserId: currentUserId,
            onDelete: onDelete,
          );
        },
        childCount: dateKeys.length,
      ),
    );
  }
}

class _DateGroupSection extends StatelessWidget {
  const _DateGroupSection({
    required this.date,
    required this.costs,
    required this.currentUserId,
    required this.onDelete,
  });

  final DateTime date;
  final List<Cost> costs;
  final String? currentUserId;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    final headerText = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : DateFormat('EEE, d MMM').format(date);

    final dayTotal = costs.fold(0.0, (s, c) => s + c.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.grey,
                  ),
                ),
                Text(
                  '৳ ${NumberFormat('#,##0.00').format(dayTotal)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ...costs.map(
            (c) => _CostTile(
              cost: c,
              isOwnCost: c.paidBy == currentUserId,
              onDelete: () => onDelete(c.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostTile extends StatelessWidget {
  const _CostTile({
    required this.cost,
    required this.isOwnCost,
    required this.onDelete,
  });

  final Cost cost;
  final bool isOwnCost;
  final VoidCallback onDelete;

  IconData _iconForCategory(String? iconKey) {
    return switch (iconKey) {
      'restaurant' => Icons.restaurant_rounded,
      'shopping_basket' => Icons.shopping_basket_rounded,
      'directions_bus' => Icons.directions_bus_rounded,
      'flash_on' => Icons.flash_on_rounded,
      'home' => Icons.home_rounded,
      'shopping_bag' => Icons.shopping_bag_rounded,
      'medical_services' => Icons.medical_services_rounded,
      'movie' => Icons.movie_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Dismissible(
      key: Key(cost.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.tileColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForCategory(cost.categoryIcon),
                color: colors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title, scope badge, category, payer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Scope badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cost.isPersonal
                              ? colors.softGrey
                              : colors.tileColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cost.isPersonal ? 'Personal' : 'Shared',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cost.isPersonal
                                ? colors.grey
                                : colors.primaryColor,
                          ),
                        ),
                      ),
                      if (cost.categoryName != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${cost.categoryName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.grey,
                          ),
                        ),
                      ],
                      if (cost.isShared && cost.payerName != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${isOwnCost ? "You" : cost.payerName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '৳ ${currencyFormat.format(cost.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView({
    required this.scope,
    required this.isFilteredByPayer,
    required this.onAddPressed,
  });

  final CostScope? scope;
  final bool isFilteredByPayer;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final label = isFilteredByPayer
        ? 'No expenses found for selected member'
        : scope == CostScope.personal
            ? 'No personal expenses this month'
            : scope == CostScope.shared
                ? 'No shared expenses this month'
                : 'No expenses recorded this month';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.tileColor.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: colors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the button below to quickly record an expense.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

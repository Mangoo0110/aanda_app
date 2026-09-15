import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';

class CostFeedScreen extends StatelessWidget {
  const CostFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Expenses',
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push(AppRoutes.costAdd);
          if (result == true && context.mounted) {
            context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
          }
        },
        backgroundColor: colors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
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

                // ── Summary Cards ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SummaryOverview(
                    totalSpent: state.totalSpent,
                    personalSpent: state.personalSpent,
                    sharedSpent: state.sharedSpent,
                  ),
                ),

                // ── Scope Filter Segment ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ScopeFilterBar(
                    selectedScope: state.selectedScope,
                    onScopeChanged: (scope) {
                      context
                          .read<CostFeedBloc>()
                          .add(CostFeedScopeFilterChanged(scope));
                    },
                  ),
                ),

                // ── List of expenses ────────────────────────────────────────
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.costs.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyFeedView(
                      scope: state.selectedScope,
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
                    costs: state.costs,
                    onDelete: (costId) {
                      context
                          .read<CostFeedBloc>()
                          .add(CostFeedDeleted(costId));
                    },
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
          Text(
            monthLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textColor,
            ),
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

class _SummaryOverview extends StatelessWidget {
  const _SummaryOverview({
    required this.totalSpent,
    required this.personalSpent,
    required this.sharedSpent,
  });

  final double totalSpent;
  final double personalSpent;
  final double sharedSpent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryColor,
              colors.primaryColor.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.primaryColor.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Spent This Month',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '৳ ${currencyFormat.format(totalSpent)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.person_rounded,
                    label: 'Personal',
                    amount: '৳ ${currencyFormat.format(personalSpent)}',
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.home_work_rounded,
                    label: 'Shared',
                    amount: '৳ ${currencyFormat.format(sharedSpent)}',
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeFilterBar extends StatelessWidget {
  const _ScopeFilterBar({
    required this.selectedScope,
    required this.onScopeChanged,
  });

  final CostScope? selectedScope;
  final ValueChanged<CostScope?> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.tileColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _FilterTab(
              title: 'All',
              isSelected: selectedScope == null,
              onTap: () => onScopeChanged(null),
            ),
            _FilterTab(
              title: 'Personal',
              icon: Icons.person_outline_rounded,
              isSelected: selectedScope == CostScope.personal,
              onTap: () => onScopeChanged(CostScope.personal),
            ),
            _FilterTab(
              title: 'Shared',
              icon: Icons.home_outlined,
              isSelected: selectedScope == CostScope.shared,
              onTap: () => onScopeChanged(CostScope.shared),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : colors.unselectedLabelColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.unselectedLabelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostListSliver extends StatelessWidget {
  const _CostListSliver({
    required this.costs,
    required this.onDelete,
  });

  final List<Cost> costs;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    // Group costs by purchase date string
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
    required this.onDelete,
  });

  final DateTime date;
  final List<Cost> costs;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.grey,
                  ),
                ),
                Text(
                  '৳ ${NumberFormat('#,##0.00').format(dayTotal)}',
                  style: TextStyle(
                    fontSize: 13,
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
    required this.onDelete,
  });

  final Cost cost;
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.tileColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForCategory(cost.categoryIcon),
                color: colors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Title, scope badge, category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.name,
                    style: TextStyle(
                      fontSize: 15,
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
                            fontSize: 12,
                            color: colors.grey,
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
                fontSize: 16,
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

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView({
    required this.scope,
    required this.onAddPressed,
  });

  final CostScope? scope;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final label = scope == CostScope.personal
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.tileColor.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: colors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the button below to log your first expense and start tracking your budget.',
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

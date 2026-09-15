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
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

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
          BlocBuilder<CostFeedBloc, CostFeedState>(
            builder: (context, state) {
              final activeCount = state.activeFiltersCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: colors.iconColor),
                    tooltip: 'Filter Expenses',
                    onPressed: () => _showFilterSheet(context, state),
                  ),
                  if (activeCount > 0)
                    Positioned(
                      right: 6,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
          final uniquePayers = state.uniquePayers;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CostFeedBloc>().add(const CostFeedRefreshRequested());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Sprint Header or Month Navigator ─────────────────────────
                SliverToBoxAdapter(
                  child: state.selectedSprint != null
                      ? _SprintFeedHeader(
                          selectedSprint: state.selectedSprint!,
                          sprints: state.sprints,
                          onSprintSelected: (s) {
                            context
                                .read<CostFeedBloc>()
                                .add(CostFeedSprintSelected(s));
                          },
                          onSwitchToMonthly: () {
                            context
                                .read<CostFeedBloc>()
                                .add(const CostFeedSprintSelected(null));
                          },
                        )
                      : _MonthNavigator(
                          selectedMonth: state.selectedMonth,
                          onMonthChanged: (month) {
                            context
                                .read<CostFeedBloc>()
                                .add(CostFeedMonthChanged(month));
                          },
                        ),
                ),

                // ── Active Filters Chip Bar ─────────────────────────────────
                if (state.activeFiltersCount > 0)
                  SliverToBoxAdapter(
                    child: _ActiveFiltersChipBar(
                      state: state,
                      onRemoveSprint: () => context
                          .read<CostFeedBloc>()
                          .add(const CostFeedSprintSelected(null)),
                      onRemovePayer: () => context
                          .read<CostFeedBloc>()
                          .add(const CostFeedPayerFilterChanged(null)),
                      onRemoveCategory: () => context
                          .read<CostFeedBloc>()
                          .add(const CostFeedCategoryFilterChanged(null)),
                      onRemoveScope: () => context
                          .read<CostFeedBloc>()
                          .add(const CostFeedScopeFilterChanged(null)),
                      onClearAll: () => context
                          .read<CostFeedBloc>()
                          .add(const CostFeedFiltersCleared()),
                    ),
                  ),

                // ── 1. Owner's Personal Expenses & Overview Card ────────────
                SliverToBoxAdapter(
                  child: _OwnerImpactCard(
                    myPersonalSpent: state.myPersonalSpent(currentUserId),
                    myHouseContribution: state.mySharedSpent(currentUserId),
                    cycleMonth: state.selectedMonth,
                  ),
                ),

                // ── 2. Quick Access Stat Tiles (Your Expenses & Shared House) ──
                SliverToBoxAdapter(
                  child: _QuickAccessStatTiles(
                    personalSpent: state.personalSpent,
                    sharedSpent: state.sharedSpent,
                    myHouseContribution: state.mySharedSpent(currentUserId),
                    selectedScope: state.selectedScope,
                    onOpenExpenses: () {
                      context.read<CostFeedBloc>().add(
                        CostFeedScopeFilterChanged(
                          state.selectedScope == CostScope.personal
                              ? null
                              : CostScope.personal,
                        ),
                      );
                    },
                    onManageHouse: () => _openHouseDetails(context),
                  ),
                ),

                // ── 3. Recent Activity Stream (Expenses & Meals) ────────────
                SliverToBoxAdapter(
                  child: _RecentActivitySection(
                    recentCosts: state.costs.take(5).toList(),
                    currentUserId: currentUserId,
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

  void _showFilterSheet(BuildContext context, CostFeedState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FilterBottomSheet(
        state: state,
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
}

// ── Sprint Feed Header ───────────────────────────────────────────────────────

class _SprintFeedHeader extends StatelessWidget {
  const _SprintFeedHeader({
    required this.selectedSprint,
    required this.sprints,
    required this.onSprintSelected,
    required this.onSwitchToMonthly,
  });

  final Sprint selectedSprint;
  final List<Sprint> sprints;
  final ValueChanged<Sprint> onSprintSelected;
  final VoidCallback onSwitchToMonthly;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border(
          bottom: BorderSide(color: colors.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedSprint.isOpen) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  selectedSprint.isOpen ? 'RUNNING SPRINT' : 'SPRINT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: colors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${selectedSprint.label} (${selectedSprint.dateRangeFormatted})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PopupMenuButton<dynamic>(
            icon: Icon(Icons.arrow_drop_down_rounded, color: colors.iconColor),
            tooltip: 'Change Sprint',
            onSelected: (val) {
              if (val is Sprint) {
                onSprintSelected(val);
              } else if (val == 'monthly') {
                onSwitchToMonthly();
              }
            },
            itemBuilder: (ctx) => [
              ...sprints.map((s) => PopupMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        if (s.id == selectedSprint.id)
                          Icon(Icons.check_rounded,
                              size: 16, color: colors.primaryColor)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Text('${s.label} (${s.dateRangeFormatted})'),
                      ],
                    ),
                  )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    SizedBox(width: 22),
                    Text('Switch to Calendar Month'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active Filters Chip Bar ──────────────────────────────────────────────────

class _ActiveFiltersChipBar extends StatelessWidget {
  const _ActiveFiltersChipBar({
    required this.state,
    required this.onRemoveSprint,
    required this.onRemovePayer,
    required this.onRemoveCategory,
    required this.onRemoveScope,
    required this.onClearAll,
  });

  final CostFeedState state;
  final VoidCallback onRemoveSprint;
  final VoidCallback onRemovePayer;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveScope;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: colors.surfaceColor.withValues(alpha: 0.6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (state.selectedSprint != null)
            _FilterTagChip(
              label: 'Sprint: ${state.selectedSprint!.label}',
              onDeleted: onRemoveSprint,
            ),
          if (state.selectedPayerId != null) ...[
            const SizedBox(width: 6),
            _FilterTagChip(
              label: 'Payer: ${_payerName(state.selectedPayerId!, state.uniquePayers)}',
              onDeleted: onRemovePayer,
            ),
          ],
          if (state.selectedCategoryId != null) ...[
            const SizedBox(width: 6),
            _FilterTagChip(
              label: 'Category: ${_catName(state.selectedCategoryId!, state.categories)}',
              onDeleted: onRemoveCategory,
            ),
          ],
          if (state.selectedScope != null) ...[
            const SizedBox(width: 6),
            _FilterTagChip(
              label: state.selectedScope == CostScope.personal
                  ? 'Personal Only'
                  : 'Shared House Only',
              onDeleted: onRemoveScope,
            ),
          ],
          const SizedBox(width: 8),
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(40, 28),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _payerName(String id, List<({String id, String name})> payers) {
    return payers.where((p) => p.id == id).firstOrNull?.name ?? 'Member';
  }

  String _catName(String id, List<CostCategory> categories) {
    return categories.where((c) => c.id == id).firstOrNull?.name ?? 'Category';
  }
}

class _FilterTagChip extends StatelessWidget {
  const _FilterTagChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: Icon(Icons.close_rounded,
                size: 14, color: colors.primaryColor),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.state,
    required this.onApply,
    required this.onReset,
  });

  final CostFeedState state;
  final void Function(
    Sprint? sprint,
    String? payerId,
    String? categoryId,
    CostScope? scope,
  ) onApply;
  final VoidCallback onReset;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSprint = null;
                        _selectedPayerId = null;
                        _selectedCategoryId = null;
                        _selectedScope = null;
                      });
                      widget.onReset();
                      Navigator.of(context).pop();
                    },
                    child: Text('Reset', style: TextStyle(color: colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 1. Sprints Section ────────────────────────────────────────
              if (widget.state.sprints.isNotEmpty) ...[
                _FilterSectionTitle(
                  title: 'Sprint (Date-to-Date)',
                  icon: Icons.timeline_rounded,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Calendar Month'),
                      selected: _selectedSprint == null,
                      onSelected: (_) => setState(() => _selectedSprint = null),
                    ),
                    ...widget.state.sprints.map((s) => ChoiceChip(
                          label: Text('${s.label} (${s.dateRangeFormatted})'),
                          selected: _selectedSprint?.id == s.id,
                          onSelected: (sel) => setState(() {
                            _selectedSprint = sel ? s : null;
                          }),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ── 2. Scope Section ──────────────────────────────────────────
              const _FilterSectionTitle(
                title: 'Expense Scope',
                icon: Icons.pie_chart_outline_rounded,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedScope == null,
                    onSelected: (_) => setState(() => _selectedScope = null),
                  ),
                  ChoiceChip(
                    label: const Text('Personal Only'),
                    selected: _selectedScope == CostScope.personal,
                    onSelected: (sel) => setState(() {
                      _selectedScope = sel ? CostScope.personal : null;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Shared House Only'),
                    selected: _selectedScope == CostScope.shared,
                    onSelected: (sel) => setState(() {
                      _selectedScope = sel ? CostScope.shared : null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 3. Payers / Members Section ───────────────────────────────
              if (widget.state.uniquePayers.isNotEmpty) ...[
                const _FilterSectionTitle(
                  title: 'Paid By (Member)',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Payers'),
                      selected: _selectedPayerId == null,
                      onSelected: (_) =>
                          setState(() => _selectedPayerId = null),
                    ),
                    ...widget.state.uniquePayers.map((p) => ChoiceChip(
                          label: Text(p.name),
                          selected: _selectedPayerId == p.id,
                          onSelected: (sel) => setState(() {
                            _selectedPayerId = sel ? p.id : null;
                          }),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ── 4. Categories / Labels Section ────────────────────────────
              if (widget.state.categories.isNotEmpty) ...[
                const _FilterSectionTitle(
                  title: 'Category / Label',
                  icon: Icons.label_rounded,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                    ),
                    ...widget.state.categories.map((c) => ChoiceChip(
                          label: Text(c.name),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (sel) => setState(() {
                            _selectedCategoryId = sel ? c.id : null;
                          }),
                        )),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ── Apply Button ──────────────────────────────────────────────
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  widget.onApply(
                    _selectedSprint,
                    _selectedPayerId,
                    _selectedCategoryId,
                    _selectedScope,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
      ],
    );
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
    required this.myPersonalSpent,
    required this.myHouseContribution,
    required this.cycleMonth,
  });

  final double myPersonalSpent;
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
              '৳ ${currencyFormat.format(myPersonalSpent)}',
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

// ── 2. Quick Access Stat Tiles (Personal vs Shared House) ───────────────────

class _QuickAccessStatTiles extends StatelessWidget {
  const _QuickAccessStatTiles({
    required this.personalSpent,
    required this.sharedSpent,
    required this.myHouseContribution,
    required this.selectedScope,
    required this.onOpenExpenses,
    required this.onManageHouse,
  });

  final double personalSpent;
  final double sharedSpent;
  final double myHouseContribution;
  final CostScope? selectedScope;
  final VoidCallback onOpenExpenses;
  final VoidCallback onManageHouse;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Stat Tile 1: Your Expenses
          Expanded(
            child: _StatTile(
              title: 'Your Expenses',
              badgeText: 'Personal',
              stat: 'BDT ${currencyFormat.format(personalSpent)}',
              subtitle: 'Direct personal spend',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: Colors.blueAccent,
              buttonLabel: 'View Expenses',
              isSelected: selectedScope == CostScope.personal,
              onTap: onOpenExpenses,
            ),
          ),
          const SizedBox(width: 12),
          // Stat Tile 2: Shared House
          Expanded(
            child: _StatTile(
              title: 'Shared House',
              badgeText: 'House Pool',
              stat: 'BDT ${currencyFormat.format(sharedSpent)}',
              subtitle: myHouseContribution > 0
                  ? 'Contributed: BDT ${currencyFormat.format(myHouseContribution)}'
                  : 'Total house expenses',
              icon: Icons.home_work_rounded,
              accentColor: Colors.teal,
              buttonLabel: 'Manage House',
              isSelected: selectedScope == CostScope.shared,
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
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String badgeText;
  final String stat;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String buttonLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor
                : colors.borderColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
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

// ── 3. Recent Activity Section (Expenses & Meals) ───────────────────────────

enum _ActivityType { expense, meal }

class _ActivityItem {
  const _ActivityItem({
    required this.type,
    required this.title,
    required this.timestamp,
    required this.tag,
    this.cost,
  });

  final _ActivityType type;
  final String title;
  final DateTime timestamp;
  final String tag;
  final Cost? cost;
}

class _RecentActivitySection extends StatefulWidget {
  const _RecentActivitySection({
    required this.recentCosts,
    required this.currentUserId,
    required this.onCostTap,
  });

  final List<Cost> recentCosts;
  final String? currentUserId;
  final ValueChanged<Cost> onCostTap;

  @override
  State<_RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  List<Map<String, dynamic>> _mealLogs = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentMealLogs();
  }

  Future<void> _loadRecentMealLogs() async {
    try {
      final res = await Supabase.instance.client
          .from('meal_logs')
          .select('*, profiles(username, full_name)')
          .order('updated_at', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() {
          _mealLogs = (res as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    // Build unified activity list
    final activities = <_ActivityItem>[];

    // 1. Add cost activities
    for (final cost in widget.recentCosts) {
      final payer = (cost.paidBy == widget.currentUserId)
          ? 'You'
          : (cost.payerName?.isNotEmpty == true ? cost.payerName! : 'Member');

      activities.add(_ActivityItem(
        type: _ActivityType.expense,
        title: 'Expense: BDT ${currencyFormat.format(cost.amount)} ${cost.name.toLowerCase()} by $payer',
        timestamp: cost.purchaseDate,
        tag: cost.isPersonal ? 'Personal' : 'Shared House',
        cost: cost,
      ));
    }

    // 2. Add meal activities
    for (final meal in _mealLogs) {
      final profile = meal['profiles'] as Map<String, dynamic>?;
      final memberName =
          profile?['full_name'] ?? profile?['username'] ?? 'Member';
      final logDate = DateTime.tryParse(meal['log_date'] as String? ?? '');
      final isToday = logDate != null &&
          logDate.year == DateTime.now().year &&
          logDate.month == DateTime.now().month &&
          logDate.day == DateTime.now().day;
      final dateStr = isToday
          ? 'today'
          : (logDate != null ? DateFormat('d MMM').format(logDate) : 'today');

      final breakfast = (meal['breakfast'] as num?)?.toDouble() ?? 0;
      final lunch = (meal['lunch'] as num?)?.toDouble() ?? 0;
      final dinner = (meal['dinner'] as num?)?.toDouble() ?? 0;

      final mealParts = <String>[];
      if (dinner > 0) mealParts.add('${dinner == 1 ? "1" : dinner} dinner');
      if (lunch > 0) mealParts.add('${lunch == 1 ? "1" : lunch} lunch');
      if (breakfast > 0) {
        mealParts.add('${breakfast == 1 ? "1" : breakfast} breakfast');
      }
      final mealStr = mealParts.isNotEmpty ? mealParts.join(', ') : 'meal';

      activities.add(_ActivityItem(
        type: _ActivityType.meal,
        title: 'Meal: $mealStr added/updated for $dateStr for $memberName',
        timestamp: DateTime.tryParse(meal['updated_at'] as String? ?? '') ??
            DateTime.now(),
        tag: 'House Meal',
      ));
    }

    // Sort by timestamp descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayActivities = activities.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.electric_bolt_rounded,
                  size: 15,
                  color: colors.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: displayActivities.length,
              separatorBuilder: (_, __) => Divider(
                color: colors.borderColor.withValues(alpha: 0.25),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = displayActivities[index];
                final isExpense = item.type == _ActivityType.expense;

                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isExpense ? Colors.teal : Colors.deepPurple)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.receipt_long_rounded
                          : Icons.restaurant_rounded,
                      color: isExpense ? Colors.teal : Colors.deepPurple,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('d MMM, h:mm a').format(item.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.grey,
                    ),
                  ),
                  trailing: item.cost != null
                      ? Text(
                          '৳ ${currencyFormat.format(item.cost!.amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textColor,
                          ),
                        )
                      : null,
                  onTap: item.cost != null
                      ? () => widget.onCostTap(item.cost!)
                      : null,
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

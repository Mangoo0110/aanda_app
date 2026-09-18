import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_detail/house_detail_bloc.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/presentation/widgets/settlement_breakdown_sheet.dart';

class HouseDetailScreen extends StatefulWidget {
  const HouseDetailScreen({super.key, required this.houseId});

  final String houseId;

  @override
  State<HouseDetailScreen> createState() => _HouseDetailScreenState();
}

class _HouseDetailScreenState extends State<HouseDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HouseDetailBloc>().add(HouseDetailStarted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = switch (context.read<AppAuthGuardBloc>().state) {
      Authenticated(:final account) => account.id,
      _ => '',
    };

    return BlocConsumer<HouseDetailBloc, HouseDetailState>(
      listenWhen: (prev, curr) =>
          (prev.isActioning && !curr.isActioning && curr.errorMessage != null) ||
          (prev.settlement == null && curr.settlement != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.errorColor,
            ),
          );
        } else if (state.settlement != null) {
          _showSettlementModal(context, state.settlement!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.surfaceColor,
            elevation: 0,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.house?.name ?? 'House Detail',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: colors.textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (state.house != null)
                  Text(
                    '${state.house!.members.length} members  •  ${state.sprints.length} sprints',
                    style: TextStyle(fontSize: 12, color: colors.grey),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.iconColor),
                tooltip: 'Refresh',
                onPressed: () => context
                    .read<HouseDetailBloc>()
                    .add(HouseDetailRefreshRequested()),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : state.house == null
                  ? _ErrorBody(
                      message: state.errorMessage ?? 'Failed to load house.',
                      onRetry: () => context
                          .read<HouseDetailBloc>()
                          .add(HouseDetailRefreshRequested()),
                    )
                  : _HouseDetailContent(
                      state: state,
                      currentUserId: currentUserId,
                    ),
        );
      },
    );
  }

  void _showSettlementModal(BuildContext context, Settlement settlement) {
    final selectedSprint = context.read<HouseDetailBloc>().state.selectedSprint;
    final isAdmin = context.read<HouseDetailBloc>().state.house?.members.any(
              (m) =>
                  m.userId ==
                      (switch (context.read<AppAuthGuardBloc>().state) {
                        Authenticated(:final account) => account.id,
                        _ => '',
                      }) &&
                  m.isAdmin,
            ) ??
        false;

    SettlementBreakdownSheet.show(
      context: context,
      settlement: settlement,
      sprint: selectedSprint,
      isAdmin: isAdmin,
      onConfirmClose: () {
        context.read<HouseDetailBloc>().add(
              HouseDetailConfirmCloseSprintRequested(settlement.cycleId),
            );
      },
    );
  }
}

// ── House Detail Content ─────────────────────────────────────────────────────

class _HouseDetailContent extends StatelessWidget {
  const _HouseDetailContent({
    required this.state,
    required this.currentUserId,
  });

  final HouseDetailState state;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final house = state.house!;
    final currentMember = house.members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;
    final selectedSprint = state.selectedSprint;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HouseDetailBloc>().add(HouseDetailRefreshRequested());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── 1. Horizontal Sprint Selector Bar ──────────────────────────────
          if (state.sprints.isNotEmpty || isAdmin)
            _MinimalSprintBar(
              sprints: state.sprints,
              selectedSprint: selectedSprint,
              isAdmin: isAdmin,
              onSprintSelected: (s) {
                context
                    .read<HouseDetailBloc>()
                    .add(HouseDetailSprintSelected(s));
              },
              onCreateSprint: () => _showCreateSprintDialog(context),
            ),

          const SizedBox(height: 12),

          // ── 2. Unified Sprint Overview Card ───────────────────────────────
          _UnifiedSprintCard(
            sprint: selectedSprint,
            totalSpent: state.sprintTotalSpent,
            myContribution: state.sprintMyContribution,
            foodSpent: state.sprintFoodSpent,
            totalMeals: state.sprintTotalMeals,
            myMeals: state.sprintMyMeals,
            mealRate: state.sprintEstimatedMealRate,
            isComputingSettlement: state.isComputingSettlement,
            isAdmin: isAdmin,
            onViewExpenses: () {
              final query = StringBuffer();
              query.write('?houseId=${state.houseId}');
              if (selectedSprint != null) {
                query.write('&cycleId=${selectedSprint.id}');
              }
              context.push('${AppRoutes.costs}$query');
            },
            onManageMeals: () {
              final query = selectedSprint != null
                  ? '?cycleId=${selectedSprint.id}'
                  : '';
              context.push(
                '/houses/${state.houseId}/meals$query',
                extra: selectedSprint,
              );
            },
            onEndSprint: () {
              context
                  .read<HouseDetailBloc>()
                  .add(HouseDetailEndSprintRequested());
            },
          ),

          const SizedBox(height: 18),

          // ── 3. Minimal Invite Code Pill ───────────────────────────────────
          if (state.invite != null) ...[
            _MinimalInviteCodeCard(
              inviteCode: state.invite!.code,
              isAdmin: isAdmin,
              isActioning: state.isActioning,
            ),
            const SizedBox(height: 18),
          ],

          // ── 4. Members Section ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MEMBERS (${house.members.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderColor.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: house.members.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 58,
                color: colors.borderColor.withValues(alpha: 0.25),
              ),
              itemBuilder: (context, idx) {
                final m = house.members[idx];
                return _MinimalMemberTile(
                  member: m,
                  isCurrentUser: m.userId == currentUserId,
                  canRemove: isAdmin && m.userId != currentUserId,
                  onRemove: () => context
                      .read<HouseDetailBloc>()
                      .add(HouseDetailMemberRemoveRequested(m.userId)),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          if (!isAdmin)
            Center(
              child: TextButton.icon(
                onPressed:
                    state.isActioning ? null : () => _confirmLeave(context),
                icon: Icon(Icons.exit_to_app_rounded,
                    size: 16, color: colors.errorColor),
                label: Text(
                  'Leave House',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.errorColor,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showCreateSprintDialog(BuildContext context) {
    final colors = AppColors.context(context);
    final now = DateTime.now();
    final nameCtrl = TextEditingController(text: 'Sprint');
    DateTime startDate = now;
    DateTime endDate = now.add(const Duration(days: 14));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'New Sprint',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Sprint Name / Label',
                  filled: true,
                  fillColor: colors.appBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.date_range_rounded, color: colors.primaryColor),
                title: Text(
                  '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                subtitle: Text(
                  'Tap to pick date range',
                  style: TextStyle(fontSize: 11, color: colors.grey),
                ),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange:
                        DateTimeRange(start: startDate, end: endDate),
                  );
                  if (range != null) {
                    setDialogState(() {
                      startDate = range.start;
                      endDate = range.end;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final label = nameCtrl.text.trim();
                if (label.isEmpty) return;
                Navigator.of(ctx).pop();
                context.read<HouseDetailBloc>().add(
                      HouseDetailCreateSprintRequested(
                        label: label,
                        startDate: startDate,
                        endDate: endDate,
                      ),
                    );
              },
              child: const Text('Start Sprint'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    final colors = AppColors.context(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave House',
          style:
              TextStyle(fontWeight: FontWeight.w700, color: colors.textColor),
        ),
        content: Text(
          'Are you sure you want to leave this house?',
          style: TextStyle(color: colors.textColor.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.errorColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<HouseDetailBloc>().add(HouseDetailLeaveRequested());
              context.pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ── Minimal Sprint Selector Bar ──────────────────────────────────────────────

class _MinimalSprintBar extends StatelessWidget {
  const _MinimalSprintBar({
    required this.sprints,
    required this.selectedSprint,
    required this.isAdmin,
    required this.onSprintSelected,
    required this.onCreateSprint,
  });

  final List<Sprint> sprints;
  final Sprint? selectedSprint;
  final bool isAdmin;
  final ValueChanged<Sprint> onSprintSelected;
  final VoidCallback onCreateSprint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...sprints.map((sprint) {
            final isSelected = selectedSprint?.id == sprint.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSprintSelected(sprint),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryColor
                        : colors.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? colors.primaryColor
                          : colors.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sprint.isOpen) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${sprint.label} (${sprint.dateRangeFormatted})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : colors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (isAdmin)
            InkWell(
              onTap: onCreateSprint,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 14, color: colors.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'New Sprint',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Unified Sprint Overview Card ─────────────────────────────────────────────

class _UnifiedSprintCard extends StatelessWidget {
  const _UnifiedSprintCard({
    required this.sprint,
    required this.totalSpent,
    required this.myContribution,
    required this.foodSpent,
    required this.totalMeals,
    required this.myMeals,
    required this.mealRate,
    required this.isComputingSettlement,
    required this.isAdmin,
    required this.onViewExpenses,
    required this.onManageMeals,
    required this.onEndSprint,
  });

  final Sprint? sprint;
  final double totalSpent;
  final double myContribution;
  final double foodSpent;
  final double totalMeals;
  final double myMeals;
  final double mealRate;
  final bool isComputingSettlement;
  final bool isAdmin;
  final VoidCallback onViewExpenses;
  final VoidCallback onManageMeals;
  final VoidCallback onEndSprint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sprint Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sprint?.label ?? 'Sprint Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textColor,
                    ),
                  ),
                  if (sprint != null)
                    Text(
                      sprint!.dateRangeFormatted,
                      style: TextStyle(fontSize: 12, color: colors.grey),
                    ),
                ],
              ),
              if (sprint != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sprint!.isOpen
                        ? Colors.green.withValues(alpha: 0.12)
                        : colors.tileColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sprint!.isOpen) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        sprint!.isOpen ? 'ACTIVE' : 'SETTLED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color:
                              sprint!.isOpen ? Colors.green : colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Spent Amount
          Text(
            'TOTAL SPRINT EXPENSES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '৳ ${currencyFormat.format(totalSpent)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.textColor,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colors.borderColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),

          // 4-Metric Grid (Clean 2x2)
          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Your Outflow',
                  value: '৳ ${currencyFormat.format(myContribution)}',
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: colors.borderColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCell(
                  label: 'Food Cost',
                  value: '৳ ${currencyFormat.format(foodSpent)}',
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Total Meals',
                  value:
                      '${totalMeals.toStringAsFixed(totalMeals.truncateToDouble() == totalMeals ? 0 : 1)} meals',
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: colors.borderColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCell(
                  label: 'Est. Meal Rate',
                  value: mealRate > 0
                      ? '৳ ${mealRate.toStringAsFixed(2)}'
                      : '—',
                  colors: colors,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Navigation buttons (Expenses & Meals)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onViewExpenses,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 15, color: colors.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onManageMeals,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_rounded,
                            size: 15, color: Colors.teal),
                        SizedBox(width: 6),
                        Text(
                          'Meal Sheet',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Settle / End Sprint Button
          if (sprint != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      sprint!.isOpen ? colors.primaryColor : colors.grey,
                  side: BorderSide(
                    color: sprint!.isOpen
                        ? colors.primaryColor.withValues(alpha: 0.5)
                        : colors.borderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: isComputingSettlement
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        sprint!.isOpen
                            ? Icons.calculate_rounded
                            : Icons.assessment_rounded,
                        size: 16,
                      ),
                label: Text(
                  sprint!.isOpen
                      ? (isAdmin ? 'End Sprint & Settle' : 'Compute Settlement')
                      : 'View Settlement Breakdown',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                onPressed: isComputingSettlement ? null : onEndSprint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCell({
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
        ),
      ],
    );
  }
}

// ── Minimal Invite Code Card ─────────────────────────────────────────────────

class _MinimalInviteCodeCard extends StatelessWidget {
  const _MinimalInviteCodeCard({
    required this.inviteCode,
    required this.isAdmin,
    required this.isActioning,
  });

  final String inviteCode;
  final bool isAdmin;
  final bool isActioning;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key_rounded, size: 16, color: colors.primaryColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVITE CODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: colors.grey,
                ),
              ),
              Text(
                inviteCode,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy Invite Code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite code copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: 'Regenerate Code',
              onPressed: isActioning
                  ? null
                  : () => context
                      .read<HouseDetailBloc>()
                      .add(HouseDetailRegenerateCodeRequested()),
            ),
        ],
      ),
    );
  }
}

// ── Minimal Member Tile ──────────────────────────────────────────────────────

class _MinimalMemberTile extends StatelessWidget {
  const _MinimalMemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.canRemove,
    required this.onRemove,
  });

  final HouseMember member;
  final bool isCurrentUser;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: colors.primaryColor.withValues(alpha: 0.1),
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : 'M',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textColor,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(You)',
                        style: TextStyle(fontSize: 12, color: colors.grey),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.role == MemberRole.admin ? 'Admin' : 'Member',
                  style: TextStyle(
                    fontSize: 12,
                    color: member.role == MemberRole.admin
                        ? colors.primaryColor
                        : colors.grey,
                    fontWeight: member.role == MemberRole.admin
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: colors.errorColor,
                size: 18,
              ),
              tooltip: 'Remove Member',
              onPressed: () => _confirmRemove(context),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final colors = AppColors.context(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Member', style: TextStyle(color: colors.textColor)),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this house?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.errorColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              onRemove();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Error Body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: colors.errorColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

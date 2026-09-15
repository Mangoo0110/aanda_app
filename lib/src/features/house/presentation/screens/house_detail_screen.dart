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
            title: Text(
              state.house?.name ?? 'House Detail',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: colors.textColor,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.iconColor),
                onPressed: () => context
                    .read<HouseDetailBloc>()
                    .add(HouseDetailRefreshRequested()),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ── 1. Top Sprints Selector Slider / Dropdown ─────────────────
          if (state.sprints.isNotEmpty)
            _SprintSelectorBar(
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

          const SizedBox(height: 14),

          // ── 2. Sprint Expenses Stats Card ────────────────────────────
          _SprintExpenseStatsCard(
            sprint: selectedSprint,
            totalSpent: state.sprintTotalSpent,
            myContribution: state.sprintMyContribution,
            foodSpent: state.sprintFoodSpent,
            onViewExpenses: () {
              final query = StringBuffer();
              query.write('?houseId=${state.houseId}');
              if (selectedSprint != null) {
                query.write('&cycleId=${selectedSprint.id}');
              }
              context.push('${AppRoutes.costs}$query');
            },
          ),

          const SizedBox(height: 12),

          // ── 3. Sprint Meals Stats Card ───────────────────────────────
          _SprintMealStatsCard(
            sprint: selectedSprint,
            totalMeals: state.sprintTotalMeals,
            myMeals: state.sprintMyMeals,
            mealRate: state.sprintEstimatedMealRate,
            onManageMeals: () {
              if (selectedSprint != null) {
                context.push(
                  '/houses/${state.houseId}/meals?cycleId=${selectedSprint.id}',
                  extra: selectedSprint,
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // ── 4. End Sprint & Settlement Button ────────────────────────
          if (selectedSprint != null)
            _EndSprintActionButton(
              sprint: selectedSprint,
              isComputing: state.isComputingSettlement,
              onEndSprint: () {
                context
                    .read<HouseDetailBloc>()
                    .add(HouseDetailEndSprintRequested());
              },
            ),

          const SizedBox(height: 24),

          // ── 5. Invite Code Card ──────────────────────────────────────
          if (state.invite != null) ...[
            _InviteCodeCard(
              inviteCode: state.invite!.code,
              isAdmin: isAdmin,
              isActioning: state.isActioning,
            ),
            const SizedBox(height: 24),
          ],

          // ── 6. Members Section ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${house.members.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...house.members.map(
            (m) => _MemberTile(
              member: m,
              isCurrentUser: m.userId == currentUserId,
              canRemove: isAdmin && m.userId != currentUserId,
              onRemove: () => context
                  .read<HouseDetailBloc>()
                  .add(HouseDetailMemberRemoveRequested(m.userId)),
            ),
          ),

          const SizedBox(height: 28),
          if (!isAdmin)
            OutlinedButton.icon(
              onPressed: state.isActioning ? null : () => _confirmLeave(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.errorColor,
                side: BorderSide(color: colors.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Leave House'),
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
                leading: Icon(Icons.date_range_rounded, color: colors.primaryColor),
                title: Text(
                  '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                subtitle: Text('Tap to pick date range', style: TextStyle(fontSize: 11, color: colors.grey)),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: DateTimeRange(start: startDate, end: endDate),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: TextStyle(fontWeight: FontWeight.w700, color: colors.textColor),
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

// ── Sprint Selector Bar ──────────────────────────────────────────────────────

class _SprintSelectorBar extends StatelessWidget {
  const _SprintSelectorBar({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline_rounded, size: 16, color: colors.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Sprint / Billing Cycle',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.grey,
              ),
            ),
            const Spacer(),
            if (isAdmin)
              InkWell(
                onTap: onCreateSprint,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: colors.primaryColor),
                      const SizedBox(width: 2),
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
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sprints.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sprint = sprints[index];
              final isSelected = selectedSprint?.id == sprint.id;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sprint.isOpen) ...[
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
                      '${sprint.label} (${sprint.dateRangeFormatted})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : colors.textColor,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: colors.primaryColor,
                backgroundColor: colors.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? colors.primaryColor
                        : colors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                onSelected: (_) => onSprintSelected(sprint),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Sprint Expense Stats Card ────────────────────────────────────────────────

class _SprintExpenseStatsCard extends StatelessWidget {
  const _SprintExpenseStatsCard({
    required this.sprint,
    required this.totalSpent,
    required this.myContribution,
    required this.foodSpent,
    required this.onViewExpenses,
  });

  final Sprint? sprint;
  final double totalSpent;
  final double myContribution;
  final double foodSpent;
  final VoidCallback onViewExpenses;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
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
                  color: Colors.blueAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sprint Expenses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                    Text(
                      sprint != null
                          ? '${sprint!.label} • ${sprint!.dateRangeFormatted}'
                          : 'Running cycle',
                      style: TextStyle(fontSize: 11, color: colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '৳ ${currencyFormat.format(totalSpent)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Contribution',
                      style: TextStyle(fontSize: 11, color: colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '৳ ${currencyFormat.format(myContribution)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: colors.borderColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Purchases',
                      style: TextStyle(fontSize: 11, color: colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '৳ ${currencyFormat.format(foodSpent)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onViewExpenses,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Expenses for this Sprint',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.blueAccent,
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

// ── Sprint Meal Stats Card ───────────────────────────────────────────────────

class _SprintMealStatsCard extends StatelessWidget {
  const _SprintMealStatsCard({
    required this.sprint,
    required this.totalMeals,
    required this.myMeals,
    required this.mealRate,
    required this.onManageMeals,
  });

  final Sprint? sprint;
  final double totalMeals;
  final double myMeals;
  final double mealRate;
  final VoidCallback onManageMeals;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
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
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sprint Meals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                    Text(
                      sprint != null
                          ? '${sprint!.label} • ${sprint!.dateRangeFormatted}'
                          : 'Spreadsheet',
                      style: TextStyle(fontSize: 11, color: colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${totalMeals.toStringAsFixed(totalMeals.truncateToDouble() == totalMeals ? 0 : 1)} meals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Meals',
                      style: TextStyle(fontSize: 11, color: colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${myMeals.toStringAsFixed(myMeals.truncateToDouble() == myMeals ? 0 : 1)} meals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: colors.borderColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Est. Meal Rate',
                      style: TextStyle(fontSize: 11, color: colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mealRate > 0 ? '৳ ${mealRate.toStringAsFixed(2)}' : 'TBD',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onManageMeals,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open Meal Spreadsheet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.teal,
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

// ── End Sprint Action Button ─────────────────────────────────────────────────

class _EndSprintActionButton extends StatelessWidget {
  const _EndSprintActionButton({
    required this.sprint,
    required this.isComputing,
    required this.onEndSprint,
  });

  final Sprint sprint;
  final bool isComputing;
  final VoidCallback onEndSprint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: sprint.isOpen ? colors.primaryColor : colors.grey,
        side: BorderSide(
          color: sprint.isOpen
              ? colors.primaryColor.withValues(alpha: 0.6)
              : colors.borderColor,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: isComputing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              sprint.isOpen
                  ? Icons.calculate_outlined
                  : Icons.receipt_long_outlined,
            ),
      label: Text(
        sprint.isOpen
            ? 'End Sprint & Settle with Calculation'
            : 'View Sprint Settlement Summary',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      onPressed: isComputing ? null : onEndSprint,
    );
  }
}

// ── Error Body & Members List Widgets ────────────────────────────────────────

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
            Icon(Icons.error_outline_rounded, size: 48, color: colors.errorColor),
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

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded, size: 16, color: colors.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Invite Code',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colors.textColor,
                ),
              ),
              const Spacer(),
              if (isAdmin)
                TextButton.icon(
                  onPressed: isActioning
                      ? null
                      : () => context
                          .read<HouseDetailBloc>()
                          .add(HouseDetailRegenerateCodeRequested()),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Regenerate', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  inviteCode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: colors.primaryColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copy Invite Code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite code copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colors.primaryColor.withValues(alpha: 0.12),
        child: Text(
          member.displayName.isNotEmpty
              ? member.displayName[0].toUpperCase()
              : 'M',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.primaryColor,
          ),
        ),
      ),
      title: Row(
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
            Text('(You)', style: TextStyle(fontSize: 12, color: colors.grey)),
          ],
        ],
      ),
      subtitle: Text(
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
      trailing: canRemove
          ? IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded,
                  color: colors.errorColor, size: 20),
              tooltip: 'Remove Member',
              onPressed: () => _confirmRemove(context),
            )
          : null,
    );
  }

  void _confirmRemove(BuildContext context) {
    final colors = AppColors.context(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
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

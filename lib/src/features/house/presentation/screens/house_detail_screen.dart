import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_detail/house_detail_bloc.dart';
import 'package:aanda/src/features/house/presentation/widgets/house_invite_code_card.dart';
import 'package:aanda/src/features/house/presentation/widgets/house_member_tile.dart';
import 'package:aanda/src/features/house/presentation/widgets/unified_sprint_card.dart';

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
          prev.isActioning && !curr.isActioning && curr.errorMessage != null,
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
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            leading: const AppBackButton(),
            titleSpacing: 12,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.house?.name ?? 'Account Detail',
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                if (state.house != null)
                  Text(
                    '${state.house!.members.length} member${state.house!.members.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 11, color: colors.grey),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.iconColor),
                tooltip: 'Refresh',
                onPressed: () => context.read<HouseDetailBloc>().add(
                  HouseDetailRefreshRequested(),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : state.house == null
              ? _ErrorBody(
                  message: state.errorMessage ?? 'Failed to load account.',
                  onRetry: () => context.read<HouseDetailBloc>().add(
                    HouseDetailRefreshRequested(),
                  ),
                )
              : _HouseDetailContent(
                  state: state,
                  currentUserId: currentUserId,
                ),
        );
      },
    );
  }
}

// ── House Detail Content ─────────────────────────────────────────────────────

class _HouseDetailContent extends StatelessWidget {
  const _HouseDetailContent({required this.state, required this.currentUserId});

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

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HouseDetailBloc>().add(HouseDetailRefreshRequested());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── 1. Account Overview Card ─────────────────────────────────────
          AccountOverviewCard(
            accountName: house.name,
            totalSpent: state.totalSpent,
            myContribution: state.myContribution,
            foodSpent: state.foodSpent,
            totalMeals: state.totalMeals,
            myMeals: state.myMeals,
            mealRate: state.estimatedMealRate,
            isPersonal: house.isPersonal,
            onViewExpenses: () {
              context.push('${AppRoutes.costs}?houseId=${state.houseId}');
            },
            onManageMeals: () {
              context.push('/houses/${state.houseId}/meals');
            },
          ),

          const SizedBox(height: 14),

          // ── 2. Settlement History link ───────────────────────────────────
          if (house.isShared)
            _ActionTile(
              icon: Icons.receipt_long_rounded,
              label: 'Settlement History',
              subtitle: 'View past settlements for this account',
              colors: colors,
              onTap: () => context.push(
                AppRoutes.settlementHistory(state.houseId),
              ),
            ),

          const SizedBox(height: 14),

          // ── 3. Invite Code Card ──────────────────────────────────────────
          if (state.invite != null) ...[
            HouseInviteCodeCard(
              inviteCode: state.invite!.code,
              isAdmin: isAdmin,
              isActioning: state.isActioning,
            ),
            const SizedBox(height: 18),
          ],

          // ── 4. Members Section ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              'MEMBERS (${house.members.length})',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
                color: colors.grey,
              ),
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
                return HouseMemberTile(
                  member: m,
                  isCurrentUser: m.userId == currentUserId,
                  canRemove: isAdmin && m.userId != currentUserId,
                  onRemove: () => context.read<HouseDetailBloc>().add(
                    HouseDetailMemberRemoveRequested(m.userId),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          if (!isAdmin)
            Center(
              child: TextButton.icon(
                onPressed: state.isActioning
                    ? null
                    : () => _confirmLeave(context),
                icon: Icon(
                  Icons.exit_to_app_rounded,
                  size: 16,
                  color: colors.errorColor,
                ),
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

  void _confirmLeave(BuildContext context) {
    final colors = AppColors.context(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave House',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: colors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.grey,
              size: 20,
            ),
          ],
        ),
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
            Icon(Icons.error_outline_rounded, size: 48, color: colors.errorColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_detail/house_detail_bloc.dart';

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
          prev.isActioning &&
          !curr.isActioning &&
          curr.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: colors.errorColor,
          ),
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.appBackgroundColor,
            title: Text(
              state.house?.name ?? 'House',
              style: TextStyle(color: colors.textColor),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: colors.iconColor),
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
              : _HouseDetailBody(
                  state: state,
                  currentUserId: currentUserId,
                ),
        );
      },
    );
  }
}

class _HouseDetailBody extends StatelessWidget {
  const _HouseDetailBody({
    required this.state,
    required this.currentUserId,
  });

  final HouseDetailState state;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final house = state.house!;
    final currentMember = house.members.where(
      (m) => m.userId == currentUserId,
    ).firstOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.invite != null) ...[
          _InviteCodeCard(
            inviteCode: state.invite!.code,
            isAdmin: isAdmin,
            isActioning: state.isActioning,
          ),
          const SizedBox(height: 24),
        ],

        // ── Members section ────────────────────────────────────────────
        Text(
          'Members (${house.members.length})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 12),
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

        const SizedBox(height: 24),
        // ── Leave button ───────────────────────────────────────────────
        if (!isAdmin)
          OutlinedButton.icon(
            onPressed: state.isActioning
                ? null
                : () => _confirmLeave(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.errorColor,
              side: BorderSide(color: colors.errorColor),
            ),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave House'),
          ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave House?'),
        content: const Text('You will lose access to this house.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<HouseDetailBloc>().add(HouseDetailLeaveRequested());
      context.pop();
    }
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Code',
            style: TextStyle(color: colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                inviteCode,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: colors.primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, color: colors.iconColor),
                tooltip: 'Copy code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied!')),
                  );
                },
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(Icons.refresh, color: colors.iconColor),
                  tooltip: 'Regenerate',
                  onPressed: isActioning
                      ? null
                      : () => context
                            .read<HouseDetailBloc>()
                            .add(HouseDetailRegenerateCodeRequested()),
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
        backgroundColor: colors.tileColor,
        child: Text(
          (member.displayName).isNotEmpty
              ? member.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(color: colors.primaryColor),
        ),
      ),
      title: Text(
        member.displayName + (isCurrentUser ? ' (you)' : ''),
        style: TextStyle(color: colors.textColor),
      ),
      subtitle: Text(
        member.role == MemberRole.admin ? 'Admin' : 'Member',
        style: TextStyle(color: colors.grey, fontSize: 12),
      ),
      trailing: canRemove
          ? IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colors.errorColor),
              onPressed: onRemove,
            )
          : null,
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.errorColor),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

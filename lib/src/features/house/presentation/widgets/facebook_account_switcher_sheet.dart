import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/profile/presentation/cubit/profile_cubit.dart';

class FacebookAccountSwitcherSheet extends StatelessWidget {
  const FacebookAccountSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = AppColors.context(context);
    final houseCubit = context.read<HouseContextCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: houseCubit,
        child: const FacebookAccountSwitcherSheet(),
      ),
    );
  }

  void _switchToPersonal(BuildContext context) {
    context.read<HouseContextCubit>().selectPersonal();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to Personal Account'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _switchToHouse(BuildContext context, House house) {
    context.read<HouseContextCubit>().selectHouse(house);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${house.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'User';
    final userInitial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: BlocBuilder<HouseContextCubit, HouseContextState>(
          builder: (context, houseCtxState) {
            final isPersonal = houseCtxState.isPersonalView;
            final selectedHouse = houseCtxState.selectedHouse;
            final sharedHouses = houseCtxState.sharedHouses;

            final profile = context.watch<ProfileCubit>().state.profile;
            final personalAvatarUrl = profile?.avatarUrl;
            final houseAvatarUrl = selectedHouse?.avatarUrl;
            final activeAvatarUrl = isPersonal ? personalAvatarUrl : houseAvatarUrl;
            final activeAvatarProvider = getAvatarImageProvider(activeAvatarUrl);

            final activeName = isPersonal
                ? (profile?.fullName?.isNotEmpty == true ? profile!.fullName! : 'Personal Account')
                : (selectedHouse?.name ?? 'Shared House');
            final activeSubtitle = isPersonal ? email : 'Shared House • ${selectedHouse?.members.length ?? 0} members';
            final activeInitial = isPersonal ? userInitial : (selectedHouse?.name.isNotEmpty == true ? selectedHouse!.name[0].toUpperCase() : 'H');

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag Handle ──────────────────────────────────────────
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

                // ── Header Title ─────────────────────────────────────────
                Text(
                  'Switch Profile or House',
                  style: AppTextStyles.sectionHeader.copyWith(
                    fontSize: 19,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and switch between your personal ledger & shared houses',
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Active Profile Card (Facebook style) ─────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.tileColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
                            backgroundImage: activeAvatarProvider,
                            child: activeAvatarProvider == null
                                ? Text(
                                    activeInitial,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: colors.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeName,
                              style: AppTextStyles.rowTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: colors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeSubtitle,
                              style: AppTextStyles.rowSubtitle.copyWith(
                                fontSize: 11,
                                color: colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 3),
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Other Accounts Section ───────────────────────────────
                Text(
                  'Your Profiles & Houses',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.grey,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ── 1. Personal Account Tile ──────────────────────────
                      _AccountTile(
                        title: profile?.fullName?.isNotEmpty == true ? profile!.fullName! : 'Personal Account',
                        subtitle: email,
                        initial: userInitial,
                        avatarUrl: personalAvatarUrl,
                        isActive: isPersonal,
                        isPersonal: true,
                        colors: colors,
                        onSwitch: () => _switchToPersonal(context),
                      ),

                      // ── 2. Shared Houses List ─────────────────────────────
                      ...sharedHouses.map((house) {
                        final isHouseActive = !isPersonal && house.id == selectedHouse?.id;
                        final houseInitial = house.name.isNotEmpty ? house.name[0].toUpperCase() : 'H';

                        return _AccountTile(
                          title: house.name,
                          subtitle: 'Shared House • ${house.members.length} members',
                          initial: houseInitial,
                          avatarUrl: house.avatarUrl,
                          isActive: isHouseActive,
                          isPersonal: false,
                          colors: colors,
                          onSwitch: () => _switchToHouse(context, house),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Divider(height: 1, color: colors.dividerColor),
                const SizedBox(height: 12),

                // ── Action Buttons ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.houseCreate);
                        },
                        icon: const Icon(Icons.add_home_rounded, size: 16),
                        label: const Text('New House'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.softGrey,
                          foregroundColor: colors.textColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.houseJoin);
                        },
                        icon: const Icon(Icons.group_add_rounded, size: 16),
                        label: const Text('Join House'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.softGrey,
                          foregroundColor: colors.textColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.title,
    required this.subtitle,
    required this.initial,
    this.avatarUrl,
    required this.isActive,
    required this.isPersonal,
    required this.colors,
    required this.onSwitch,
  });

  final String title;
  final String subtitle;
  final String initial;
  final String? avatarUrl;
  final bool isActive;
  final bool isPersonal;
  final AppColors colors;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final avatarProvider = getAvatarImageProvider(avatarUrl);

    return InkWell(
      onTap: isActive ? null : onSwitch,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: isActive
                  ? colors.primaryColor.withValues(alpha: 0.12)
                  : colors.softGrey,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? (isPersonal
                      ? Icon(
                          Icons.person_rounded,
                          size: 19,
                          color: isActive ? colors.primaryColor : colors.grey,
                        )
                      : Text(
                          initial,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isActive ? colors.primaryColor : colors.grey,
                          ),
                        ))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.rowTitle.copyWith(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? colors.primaryColor : colors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.rowSubtitle.copyWith(
                      fontSize: 11,
                      color: colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle_rounded,
                color: colors.primaryColor,
                size: 20,
              )
            else
              InkWell(
                onTap: onSwitch,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.tileColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: colors.textColor),
                      const SizedBox(width: 4),
                      Text(
                        'Switch',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

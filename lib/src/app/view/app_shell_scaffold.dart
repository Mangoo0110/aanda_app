import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/bloc/house_context/house_context_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers/avatar_image_provider.dart';
import '../../features/house/presentation/widgets/facebook_account_switcher_sheet.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';

class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  @override
  void initState() {
    super.initState();
    _checkLoad();
  }

  void _checkLoad() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profileCubit = context.read<ProfileCubit>();
      if (profileCubit.state.profile == null && !profileCubit.state.isLoading) {
        profileCubit.loadProfile(user.id);
      }
      final houseCubit = context.read<HouseContextCubit>();
      if (!houseCubit.state.hasHouses &&
          houseCubit.state.status != HouseContextStatus.loading) {
        houseCubit.load();
      }
    }
  }

  void _onItemTapped(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final selectedIndex = widget.navigationShell.currentIndex;

    return BlocBuilder<HouseContextCubit, HouseContextState>(
      builder: (context, houseState) {
        final isPersonal = houseState.isPersonalView;
        final selectedHouse = houseState.selectedHouse;

        // If currently on Meal Log branch (2) but personal view is active, switch to Home (0)
        if (isPersonal && selectedIndex == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onItemTapped(0);
          });
        }

        final user = Supabase.instance.client.auth.currentUser;
        final email = user?.email ?? 'User';
        final userInitial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
        final houseInitial = (selectedHouse?.name.isNotEmpty == true)
            ? selectedHouse!.name[0].toUpperCase()
            : 'H';

        final profile = context.watch<ProfileCubit>().state.profile;
        final personalAvatarUrl = profile?.avatarUrl;
        final houseAvatarUrl = selectedHouse?.avatarUrl;
        final activeAvatarUrl = isPersonal ? personalAvatarUrl : houseAvatarUrl;

        final activeInitial = isPersonal ? userInitial : houseInitial;

        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          body: widget.navigationShell,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 58,
                child: Row(
                  children: [
                    // ── 1. Home (Branch 0) ─────────────────────────
                    _NavItem(
                      icon: FontAwesomeIcons.house,
                      selectedIcon: FontAwesomeIcons.solidHouse,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => _onItemTapped(0),
                      colors: colors,
                    ),

                    // ── 2. Costs (Branch 1) ────────────────────────
                    _NavItem(
                      icon: FontAwesomeIcons.moneyBillWave,
                      selectedIcon: FontAwesomeIcons.moneyBill1Wave,
                      label: 'Costs',
                      isSelected: selectedIndex == 1,
                      onTap: () => _onItemTapped(1),
                      colors: colors,
                    ),

                    // ── 3. Meal Log (Branch 2 - Only for Shared House) ──
                    if (!isPersonal)
                      _NavItem(
                        icon: FontAwesomeIcons.utensils,
                        selectedIcon: FontAwesomeIcons.utensils,
                        label: 'Meal Log',
                        isSelected: selectedIndex == 2,
                        onTap: () => _onItemTapped(2),
                        colors: colors,
                      ),

                    // ── 4. Settlement (Branch 3) ───────────────────
                    _NavItem(
                      icon: FontAwesomeIcons.handshake,
                      selectedIcon: FontAwesomeIcons.solidHandshake,
                      label: 'Settlement',
                      isSelected: selectedIndex == 3,
                      onTap: () => _onItemTapped(3),
                      colors: colors,
                    ),

                    // ── 5. Account with Active Avatar (Branch 4) ───
                    _AccountNavItem(
                      initial: activeInitial,
                      isPersonal: isPersonal,
                      avatarUrl: activeAvatarUrl,
                      label: 'Account',
                      isSelected: selectedIndex == 4,
                      onTap: () => _onItemTapped(4),
                      onLongPress: () => FacebookAccountSwitcherSheet.show(context),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final FaIconData icon;
  final FaIconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              isSelected ? selectedIcon : icon,
              size: 19,
              color: isSelected ? colors.primaryColor : colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.primaryColor : colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountNavItem extends StatelessWidget {
  const _AccountNavItem({
    required this.initial,
    required this.isPersonal,
    required this.avatarUrl,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.colors,
  });

  final String initial;
  final bool isPersonal;
  final String? avatarUrl;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final AppColors colors;

  Widget _buildFallback() {
    if (isPersonal) {
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? colors.primaryColor : colors.textColor,
          ),
        ),
      );
    }
    return Center(
      child: initial.isNotEmpty && initial != 'H'
          ? Text(
              initial,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? colors.primaryColor : colors.textColor,
              ),
            )
          : Icon(
              Icons.home_work_rounded,
              size: 13,
              color: isSelected ? colors.primaryColor : colors.textColor,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = getAvatarImageProvider(avatarUrl);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Borderless by default to adhere strictly to "no need to give color to borders"
                border: isSelected
                    ? Border.all(
                        color: colors.primaryColor,
                        width: 2.0,
                      )
                    : null,
                color: isSelected
                    ? colors.primaryColor.withValues(alpha: 0.15)
                    : colors.softGrey,
              ),
              child: ClipOval(
                child: avatarProvider != null
                    ? Image(
                        image: avatarProvider,
                        fit: BoxFit.cover,
                        width: 26,
                        height: 26,
                        errorBuilder: (_, __, ___) => _buildFallback(),
                      )
                    : _buildFallback(),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.primaryColor : colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


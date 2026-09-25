import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/profile/presentation/cubit/profile_cubit.dart';

class DashboardProfileSheet extends StatelessWidget {
  const DashboardProfileSheet({
    super.key,
    required this.onManageHouses,
    required this.onNavigateToMeals,
  });

  final VoidCallback onManageHouses;
  final VoidCallback onNavigateToMeals;

  static void show({
    required BuildContext context,
    required VoidCallback onManageHouses,
    required VoidCallback onNavigateToMeals,
  }) {
    final colors = AppColors.context(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DashboardProfileSheet(
        onManageHouses: onManageHouses,
        onNavigateToMeals: onNavigateToMeals,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'User';
    final profile = context.watch<ProfileCubit>().state.profile;
    final avatarProvider = getAvatarImageProvider(profile?.avatarUrl);
    final displayName = (profile?.fullName?.isNotEmpty == true)
        ? profile!.fullName!
        : email;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.tileColor,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? Text(
                      email.isNotEmpty ? email[0].toUpperCase() : 'U',
                      style: AppTextStyles.amountLarge.copyWith(
                        color: colors.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              displayName,
              style: AppTextStyles.rowTitle.copyWith(
                fontSize: 15,
                color: colors.textColor,
              ),
            ),
            if (profile?.country != null) ...[
              const SizedBox(height: 2),
              Text(
                profile!.country!,
                style: AppTextStyles.rowSubtitle.copyWith(
                  fontSize: 12,
                  color: colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Divider(height: 1, color: colors.dividerColor),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.home_work_rounded,
                color: colors.primaryColor,
              ),
              title: Text(
                'Manage Houses',
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.textColor,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onManageHouses();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.receipt_long_rounded,
                color: colors.primaryColor,
              ),
              title: Text(
                'Expenses Ledger',
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.textColor,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.costs);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.restaurant_menu_rounded,
                color: colors.primaryColor,
              ),
              title: Text(
                'Meal Log (Daily Ledger)',
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.textColor,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onNavigateToMeals();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.vpn_key_rounded,
                color: colors.primaryColor,
              ),
              title: Text(
                'Change Password',
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.textColor,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.authResetPassword);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.logout_rounded,
                color: colors.unsettledColor,
              ),
              title: Text(
                'Log Out',
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.unsettledColor,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final logout = context.read<Logout>();
                await logout(const NoParams());
              },
            ),
            Divider(height: 1, color: colors.dividerColor),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_forever_rounded,
                color: colors.grey,
              ),
              title: Text(
                'Delete Account',
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.grey,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteAccountConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showDeleteAccountConfirmation(BuildContext context) {
    final colors = AppColors.context(context);
    bool isDeleting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.unsettledColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: colors.unsettledColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Account?',
                  style: AppTextStyles.sectionHeader.copyWith(
                    fontSize: 18,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your login access will be immediately revoked. '
                  'Shared expense and meal history you\'ve contributed '
                  'to will be preserved for your housemates.\n\n'
                  'This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.grey,
                    height: 1.5,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.unsettledColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: colors.unsettledColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setState(() {
                              isDeleting = true;
                              errorMessage = null;
                            });
                            try {
                              final deleteAccount =
                                  context.read<DeleteAccount>();
                              final result =
                                  await deleteAccount(const NoParams());
                              if (result.success) {
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              } else {
                                setState(() {
                                  isDeleting = false;
                                  errorMessage = result.message.isNotEmpty
                                      ? result.message
                                      : 'Failed to delete account. Please try again.';
                                });
                              }
                            } catch (e) {
                              setState(() {
                                isDeleting = false;
                                errorMessage = e.toString();
                              });
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.unsettledColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Yes, Delete My Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.of(sheetCtx).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

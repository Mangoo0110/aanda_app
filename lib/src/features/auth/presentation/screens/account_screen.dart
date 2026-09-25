import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/bloc/house_context/house_context_cubit.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/shared/widget/app_card.dart';
import '../../../../core/shared/widget/app_page_header.dart';
import '../../../../core/shared/widget/app_section_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/utils/helpers/avatar_image_provider.dart';
import '../../../house/domain/entities/house.dart';
import '../../../house/domain/usecases/house_usecases.dart';
import '../../../house/presentation/widgets/facebook_account_switcher_sheet.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../cost/presentation/screens/cost_categories_screen.dart';
import '../../domain/usecases/auth_usecases.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
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
    }
  }


  Future<void> _pickAndUploadHouseAvatar(BuildContext context, House house) async {
    final uploadHouseAvatar = context.read<UploadHouseAvatar>();
    final updateHouseAvatar = context.read<UpdateHouseAvatar>();
    final houseContextCubit = context.read<HouseContextCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Uploading house photo...'),
        duration: Duration(seconds: 1),
      ),
    );

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last;

    final uploadRes = await uploadHouseAvatar(
      UploadHouseAvatarParams(
        houseId: house.id,
        fileBytes: bytes,
        fileExtension: ext,
      ),
    );

    if (uploadRes.success && uploadRes.data != null) {
      final avatarUrl = uploadRes.data!;
      await updateHouseAvatar(
        UpdateHouseAvatarParams(
          houseId: house.id,
          avatarUrl: avatarUrl,
        ),
      );
      houseContextCubit.updateHouseAvatar(house.id, avatarUrl);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('House photo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to upload house photo. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditHouseNameDialog(BuildContext context, House house) {
    final controller = TextEditingController(text: house.name);
    final colors = AppColors.context(context);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit House Name',
          style: AppTextStyles.rowTitle.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter house name',
            filled: true,
            fillColor: colors.appBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == house.name) {
                Navigator.of(dialogCtx).pop();
                return;
              }
              Navigator.of(dialogCtx).pop();
              try {
                await Supabase.instance.client
                    .from('houses')
                    .update({'name': newName})
                    .eq('id', house.id);
                if (context.mounted) {
                  context.read<HouseContextCubit>().refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('House renamed to $newName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update house name: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback({
    required HouseContextState houseState,
    required String initial,
    required AppColors colors,
  }) {
    final houseInitial = (houseState.selectedHouse?.name.isNotEmpty == true)
        ? houseState.selectedHouse!.name[0].toUpperCase()
        : 'H';

    return Center(
      child: Text(
        houseState.isPersonalView ? initial : houseInitial,
        style: AppTextStyles.amountMedium.copyWith(
          color: colors.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'User';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<HouseContextCubit, HouseContextState>(
          builder: (context, houseState) {
            final isPersonal = houseState.isPersonalView;
            final selectedHouse = houseState.selectedHouse;
            final activeAccountName = isPersonal
                ? 'Personal Account'
                : (selectedHouse?.name ?? 'Shared House');

            final profile = context.watch<ProfileCubit>().state.profile;
            final userDisplayName = (profile?.fullName?.isNotEmpty == true)
                ? profile!.fullName!
                : email;
            final userAvatarUrl = profile?.avatarUrl;
            final personalAvatarProvider = getAvatarImageProvider(userAvatarUrl);

            final activeTitle = isPersonal
                ? userDisplayName
                : (selectedHouse?.name ?? 'Shared House');

            final activeSubtitle = isPersonal
                ? (profile?.country != null
                    ? '${profile!.country!} • Personal Profile'
                    : 'Personal Profile')
                : 'Shared House • ${selectedHouse?.members.length ?? 0} members';

            final activeAvatarProvider = isPersonal
                ? personalAvatarProvider
                : getAvatarImageProvider(selectedHouse?.avatarUrl);

            void onEditProfileTap() {
              if (isPersonal) {
                context.push(AppRoutes.profileEdit);
              } else if (selectedHouse != null) {
                context.push(AppRoutes.houseDetail(selectedHouse.id));
              }
            }

            void onAvatarTap() {
              if (isPersonal) {
                context.push(AppRoutes.profileEdit);
              } else if (selectedHouse != null) {
                _pickAndUploadHouseAvatar(context, selectedHouse);
              }
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: isPersonal ? 'Account' : 'House Profile',
                    subtitle: isPersonal
                        ? 'Manage your personal profile and account settings'
                        : 'Manage ${selectedHouse?.name ?? "House"} settings and members',
                  ),

                  // Profile Card (Displays either Personal Profile or Shared House Profile based on active account)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onAvatarTap,
                            child: Stack(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colors.primaryColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: activeAvatarProvider != null
                                        ? Image(
                                            image: activeAvatarProvider,
                                            fit: BoxFit.cover,
                                            width: 56,
                                            height: 56,
                                            errorBuilder: (_, __, ___) => _buildAvatarFallback(
                                              houseState: houseState,
                                              initial: initial,
                                              colors: colors,
                                            ),
                                          )
                                        : _buildAvatarFallback(
                                            houseState: houseState,
                                            initial: initial,
                                            colors: colors,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: colors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: onEditProfileTap,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          activeTitle,
                                          style: AppTextStyles.rowTitle.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isPersonal) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            if (selectedHouse != null) {
                                              _showEditHouseNameDialog(context, selectedHouse);
                                            }
                                          },
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 15,
                                            color: colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activeSubtitle,
                                    style: AppTextStyles.rowSubtitle.copyWith(
                                      color: colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => FacebookAccountSwitcherSheet.show(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colors.softGrey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sync_alt_rounded,
                                    size: 15,
                                    color: colors.textColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Switch',
                                    style: AppTextStyles.badge.copyWith(
                                      color: colors.textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Preferences & Accounts
                  AppSectionHeader(label: isPersonal ? 'Account & Settings' : 'House & Settings'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            context: context,
                            icon: isPersonal
                                ? Icons.person_outline_rounded
                                : Icons.home_work_outlined,
                            title: isPersonal
                                ? 'Edit Profile'
                                : 'Edit House Profile & Members',
                            subtitle: isPersonal
                                ? 'Update photo, name, country, gender & age'
                                : 'Manage members, invite code & house settings',
                            onTap: onEditProfileTap,
                          ),
                          Divider(height: 1, color: colors.dividerColor),
                          if (!isPersonal && selectedHouse != null) ...[
                            _buildListTile(
                              context: context,
                              icon: Icons.add_a_photo_outlined,
                              title: 'Change House Photo',
                              subtitle:
                                  'Upload a picture for ${selectedHouse.name}',
                              onTap: () => _pickAndUploadHouseAvatar(
                                  context, selectedHouse),
                            ),
                            Divider(height: 1, color: colors.dividerColor),
                            _buildListTile(
                              context: context,
                              icon: Icons.person_outline_rounded,
                              title: 'Personal Profile',
                              subtitle: 'Logged in as $userDisplayName ($email)',
                              onTap: () => context.push(AppRoutes.profileEdit),
                            ),
                            Divider(height: 1, color: colors.dividerColor),
                          ],
                          _buildListTile(
                            context: context,
                            icon: Icons.sync_alt_rounded,
                            title: 'Switch / Manage House',
                            subtitle: activeAccountName,
                            onTap: () => FacebookAccountSwitcherSheet.show(context),
                          ),
                          Divider(height: 1, color: colors.dividerColor),
                          _buildListTile(
                            context: context,
                            icon: Icons.vpn_key_rounded,
                            title: 'Change Password',
                            subtitle: 'Update your account login password',
                            onTap: () => context.push(AppRoutes.authResetPassword),
                          ),
                          Divider(height: 1, color: colors.dividerColor),
                          _buildListTile(
                            context: context,
                            icon: Icons.category_outlined,
                            title: 'Category Presets',
                            subtitle: 'Manage expense categories for $activeAccountName',
                            onTap: () {
                              final accountId = houseState.activeAccountId ??
                                  (isPersonal
                                      ? houseState.personalAccount?.id
                                      : selectedHouse?.id);
                              if (accountId != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CostCategoriesScreen(
                                      accountId: accountId,
                                      accountName: activeAccountName,
                                      isPersonal: isPersonal,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions Section
                  const AppSectionHeader(label: 'Actions'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            context: context,
                            icon: Icons.logout_rounded,
                            iconColor: colors.unsettledColor,
                            title: 'Log Out',
                            titleColor: colors.unsettledColor,
                            subtitle: 'Sign out of your session on this device',
                            onTap: () async {
                              final logout = context.read<Logout>();
                              await logout(const NoParams());
                            },
                          ),
                          Divider(height: 1, color: colors.dividerColor),
                          _buildListTile(
                            context: context,
                            icon: Icons.delete_forever_rounded,
                            iconColor: colors.grey,
                            title: 'Delete Account',
                            titleColor: colors.grey,
                            subtitle: 'Permanently remove your personal credentials',
                            onTap: () => _showDeleteAccountConfirmation(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.context(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (iconColor ?? colors.primaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? colors.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.rowTitle.copyWith(
                        color: titleColor ?? colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
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

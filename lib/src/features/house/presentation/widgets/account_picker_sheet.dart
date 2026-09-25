import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';

import 'package:aanda/src/features/house/presentation/widgets/facebook_account_switcher_sheet.dart';

/// Reusable modal bottom sheet to switch between Personal account and shared houses,
/// or navigate to create/join houses.
class AccountPickerSheet extends StatelessWidget {
  const AccountPickerSheet({
    super.key,
    this.onAccountSelected,
  });

  final VoidCallback? onAccountSelected;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAccountSelected,
  }) {
    return FacebookAccountSwitcherSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Switch Account',
                style: AppTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: BlocBuilder<HouseContextCubit, HouseContextState>(
                  builder: (ctx, houseCtxState) {
                    final isPersonalSelected = houseCtxState.isPersonalView;

                    return ListView(
                      shrinkWrap: true,
                      children: [
                        // —— Personal Account option ——
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isPersonalSelected
                                ? colors.tileColor
                                : colors.softGrey,
                            child: Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: isPersonalSelected
                                  ? colors.primaryColor
                                  : colors.grey,
                            ),
                          ),
                          title: Text(
                            'My Personal Account',
                            style: AppTextStyles.rowTitle.copyWith(
                              color: isPersonalSelected
                                  ? colors.primaryColor
                                  : colors.textColor,
                              fontWeight: isPersonalSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Only your personal expenses',
                            style: AppTextStyles.rowSubtitle.copyWith(
                              color: colors.grey,
                            ),
                          ),
                          trailing: isPersonalSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.primaryColor,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            ctx.read<HouseContextCubit>().selectPersonal();
                            Navigator.of(context).pop();
                            onAccountSelected?.call();
                          },
                        ),
                        Divider(
                          height: 1,
                          color: colors.dividerColor,
                        ),
                        if (houseCtxState.hasSharedHouses) ...[
                          // —— Shared houses ——
                          ...houseCtxState.sharedHouses.map((h) {
                            final isSelected = !isPersonalSelected &&
                                h.id == houseCtxState.selectedHouse?.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? colors.tileColor
                                    : colors.softGrey,
                                child: Text(
                                  h.name.isNotEmpty
                                      ? h.name[0].toUpperCase()
                                      : 'H',
                                  style: AppTextStyles.rowTitle.copyWith(
                                    color: isSelected
                                        ? colors.primaryColor
                                        : colors.grey,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                h.name,
                                style: AppTextStyles.rowTitle.copyWith(
                                  color: isSelected
                                      ? colors.primaryColor
                                      : colors.textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${h.members.length} member${h.members.length == 1 ? '' : 's'}',
                                style: AppTextStyles.rowSubtitle.copyWith(
                                  color: colors.grey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.restaurant_rounded,
                                      size: 20,
                                    ),
                                    color: colors.primaryColor,
                                    tooltip: 'Open Meals',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.push(AppRoutes.houseMeals(h.id));
                                    },
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: colors.primaryColor,
                                      size: 20,
                                    ),
                                ],
                              ),
                              onTap: () {
                                ctx.read<HouseContextCubit>().selectHouse(h);
                                Navigator.of(context).pop();
                                onAccountSelected?.call();
                              },
                            );
                          }),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'No shared houses joined yet.',
                                style: AppTextStyles.rowSubtitle.copyWith(
                                  color: colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: colors.dividerColor,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create House'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final res = await context.push(AppRoutes.houseCreate);
                        if (res == true && context.mounted) {
                          context.read<HouseContextCubit>().refresh();
                          onAccountSelected?.call();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.group_add_rounded, size: 18),
                      label: const Text('Join House'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final res = await context.push(AppRoutes.houseJoin);
                        if (res == true && context.mounted) {
                          context.read<HouseContextCubit>().refresh();
                          onAccountSelected?.call();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_creation_journey_sheet.dart';
import 'package:aanda/src/features/settlement/presentation/widgets/record_deposit_sheet.dart';
import 'package:aanda/src/core/shared/widget/app_nav_sheet_tile.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';

class DashboardQuickActionsSheet extends StatelessWidget {
  const DashboardQuickActionsSheet({
    super.key,
    required this.isPersonal,
    required this.onRefresh,
    required this.onNavigateToMeals,
    this.houseId,
    this.houseName,
    this.isAdmin,
  });

  final bool isPersonal;
  final VoidCallback onRefresh;
  final VoidCallback onNavigateToMeals;
  final String? houseId;
  final String? houseName;
  final bool? isAdmin;

  static void show({
    required BuildContext context,
    required bool isPersonal,
    required VoidCallback onRefresh,
    required VoidCallback onNavigateToMeals,
    String? houseId,
    String? houseName,
    bool? isAdmin,
  }) {
    final colors = AppColors.context(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DashboardQuickActionsSheet(
        isPersonal: isPersonal,
        onRefresh: onRefresh,
        onNavigateToMeals: onNavigateToMeals,
        houseId: houseId,
        houseName: houseName,
        isAdmin: isAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Quick Actions',
              style: AppTextStyles.sectionHeader.copyWith(
                fontSize: 18,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose what you want to record or create',
              style: AppTextStyles.rowSubtitle.copyWith(color: colors.grey),
            ),
            const SizedBox(height: 16),
            AppNavSheetTile(
              icon: Icons.receipt_long_rounded,
              title: 'Add Expense',
              subtitle: 'Record personal or shared house cost',
              onTap: () async {
                Navigator.of(context).pop();
                await CostCreationJourneySheet.start(
                  context,
                  preferredHouseId: isPersonal ? null : houseId,
                );
                onRefresh();
              },
            ),
            const SizedBox(height: 8),
            AppNavSheetTile(
              icon: Icons.category_rounded,
              title: 'New Expense Category',
              subtitle: 'Create a custom category preset',
              onTap: () async {
                Navigator.of(context).pop();
                await context.push(AppRoutes.costCategoryAdd);
                onRefresh();
              },
            ),
            if (!isPersonal) ...[
              const SizedBox(height: 8),
              AppNavSheetTile(
                icon: Icons.restaurant_menu_rounded,
                title: 'Log Meals',
                subtitle: 'Record breakfast, lunch & dinner for today',
                onTap: () {
                  Navigator.of(context).pop();
                  onNavigateToMeals();
                },
              ),
              const SizedBox(height: 8),
              AppNavSheetTile(
                icon: Icons.payments_rounded,
                title: 'Record Member Deposit',
                subtitle: 'Add cash advance or deposit from house member',
                onTap: () {
                  Navigator.of(context).pop();
                  if (houseId != null) {
                    RecordDepositSheet.show(
                      context: context,
                      houseId: houseId!,
                      onDepositSaved: onRefresh,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              AppNavSheetTile(
                icon: Icons.account_balance_rounded,
                title: 'Start Settlement',
                subtitle: 'Settle shared costs for this cycle',
                onTap: () {
                  Navigator.of(context).pop();
                  if (houseId != null) {
                    context.push(
                      AppRoutes.settlementStart(houseId!),
                      extra: {
                        'houseName': houseName ?? 'Account',
                        'isAdmin': isAdmin ?? false,
                      },
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
            AppNavSheetTile(
              icon: Icons.add_home_rounded,
              title: 'Create Shared House',
              subtitle: 'Start a new house or flat with flatmates',
              onTap: () async {
                Navigator.of(context).pop();
                final res = await context.push(AppRoutes.houseCreate);
                if (res == true) {
                  if (context.mounted) {
                    context.read<HouseContextCubit>().refresh();
                  }
                  onRefresh();
                }
              },
            ),
            const SizedBox(height: 8),
            AppNavSheetTile(
              icon: Icons.group_add_rounded,
              title: 'Join House with Code',
              subtitle: 'Enter an invite code shared by housemates',
              onTap: () async {
                Navigator.of(context).pop();
                final res = await context.push(AppRoutes.houseJoin);
                if (res == true) {
                  if (context.mounted) {
                    context.read<HouseContextCubit>().refresh();
                  }
                  onRefresh();
                }
              },
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';

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

  static const Color cardColor = Colors.white;
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);

  static void show({
    required BuildContext context,
    required bool isPersonal,
    required VoidCallback onRefresh,
    required VoidCallback onNavigateToMeals,
    String? houseId,
    String? houseName,
    bool? isAdmin,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
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
    return SafeArea(
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
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose what you want to record',
              style: TextStyle(fontSize: 12, color: subText),
            ),
            const SizedBox(height: 16),
            _buildTile(
              context: context,
              emoji: '📝',
              title: 'Add Expense',
              subtitle: 'Record personal or shared house cost',
              onTap: () async {
                Navigator.of(context).pop();
                final res = await context.push(AppRoutes.costAdd);
                if (res == true) onRefresh();
              },
            ),
            const SizedBox(height: 10),
            _buildTile(
              context: context,
              emoji: '🏷️',
              title: 'New Expense Category',
              subtitle: 'Create a custom category for expenses',
              onTap: () async {
                Navigator.of(context).pop();
                await context.push(AppRoutes.costCategoryAdd);
                onRefresh();
              },
            ),
            if (!isPersonal) ...[
              const SizedBox(height: 10),
              _buildTile(
                context: context,
                emoji: '🍲',
                title: 'Meal Log (Add Meal)',
                subtitle: 'Record breakfast, lunch & dinner for today',
                onTap: () {
                  Navigator.of(context).pop();
                  onNavigateToMeals();
                },
              ),
              const SizedBox(height: 10),
              _buildTile(
                context: context,
                emoji: '⚖️',
                title: 'Start Settlement',
                subtitle: 'Settle shared costs for a date range',
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
            const SizedBox(height: 10),
            _buildTile(
              context: context,
              emoji: '🏠',
              title: 'Create Shared House',
              subtitle: 'Start a new house/flat with flatmates',
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
            const SizedBox(height: 10),
            _buildTile(
              context: context,
              emoji: '🔑',
              title: 'Join House with Code',
              subtitle: 'Enter an invite code shared by flatmates',
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
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: subText),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: subText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

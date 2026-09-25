import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';

class CostCategoryPickerSheet extends StatelessWidget {
  const CostCategoryPickerSheet({
    super.key,
    required this.state,
    required this.onCategorySelected,
  });

  final CostFormState state;
  final void Function(CostCategory category) onCategorySelected;

  static Future<void> show({
    required BuildContext context,
    required CostFormState state,
    required void Function(CostCategory category) onCategorySelected,
  }) {
    final colors = AppColors.context(context);
    final bloc = context.read<CostFormBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: CostCategoryPickerSheet(
          state: state,
          onCategorySelected: onCategorySelected,
        ),
      ),
    );
  }

  Future<void> _showNewCategoryDialog(BuildContext context) async {
    final houseId = state.selectedHouseId ??
        (state.availableHouses.isNotEmpty
            ? state.availableHouses.first.id
            : null);
    final houseName = state.selectedHouse?.name ??
        (state.availableHouses.isNotEmpty
            ? state.availableHouses.first.name
            : 'Personal');

    final result = await Navigator.of(context).push<CostCategory>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CostCategoryFormScreen(
          initialHouseId: houseId,
          initialHouseName: houseName,
        ),
      ),
    );

    if (!context.mounted) return;
    if (result != null) {
      context.read<CostFormBloc>().add(CostFormCategoryChanged(result));
      onCategorySelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Category',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: colors.textColor,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showNewCategoryDialog(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.tileColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: colors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: AppTextStyles.badge.copyWith(
                              color: colors.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.availableCategories.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 56,
                    color: colors.dividerColor,
                  ),
                  itemBuilder: (ctx, index) {
                    final cat = state.availableCategories[index];
                    final isSel = state.selectedCategory?.id == cat.id;
                    final isBlocked = state.isPersonal && cat.isFood;

                    final tile = ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: CategoryIconView(
                        icon: cat.icon,
                        categoryName: cat.name,
                        size: 38,
                        fallbackEmoji: '🏷️',
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              style: AppTextStyles.rowTitle.copyWith(
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w600,
                                color: isSel ? colors.primaryColor : colors.textColor,
                              ),
                            ),
                          ),
                          if (isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Shared House Only',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE02424),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: isBlocked
                          ? Text(
                              'Meal pool is only for shared houses with meal tracking',
                              style: AppTextStyles.rowSubtitle.copyWith(
                                color: const Color(0xFFE02424).withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            )
                          : ((cat.costNature != 'variable' &&
                                  cat.defaultAmount != null &&
                                  cat.defaultAmount! > 0)
                              ? Text(
                                  'Default: ৳${cat.defaultAmount!.toInt()}',
                                  style: AppTextStyles.rowSubtitle.copyWith(
                                    color: colors.grey,
                                  ),
                                )
                              : null),
                      trailing: isBlocked
                          ? Icon(
                              Icons.block_rounded,
                              color: colors.grey,
                              size: 18,
                            )
                          : (isSel
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.primaryColor,
                                  size: 20,
                                )
                              : null),
                      onTap: isBlocked
                          ? () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Meal pool category "${cat.name}" cannot be used for personal expenses. Meal pooling is only for shared houses with meal tracking.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFFC81E1E),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          : () {
                              context.read<CostFormBloc>().add(
                                    CostFormCategoryChanged(cat),
                                  );
                              onCategorySelected(cat);
                              Navigator.of(context).pop();
                            },
                    );

                    if (isBlocked) {
                      return Opacity(
                        opacity: 0.42,
                        child: tile,
                      );
                    }
                    return tile;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

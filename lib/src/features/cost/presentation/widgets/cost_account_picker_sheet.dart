import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';

class CostAccountPickerSheet extends StatelessWidget {
  const CostAccountPickerSheet({super.key, required this.state});

  final CostFormState state;

  static Future<void> show({
    required BuildContext context,
    required CostFormState state,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CostFormBloc>(),
        child: CostAccountPickerSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Select Account',
              style: AppTextStyles.sectionHeader.copyWith(
                fontSize: 18,
                color: colors.textColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Personal Account option
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.tileColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_rounded,
                color: colors.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              'Personal Account',
              style: AppTextStyles.rowTitle.copyWith(
                color: colors.textColor,
              ),
            ),
            subtitle: Text(
              'Only visible to you',
              style: AppTextStyles.rowSubtitle.copyWith(
                color: colors.grey,
              ),
            ),
            trailing: state.costScope == CostScope.personal
                ? Icon(
                    Icons.check_circle_rounded,
                    color: colors.primaryColor,
                    size: 20,
                  )
                : null,
            onTap: () {
              context.read<CostFormBloc>().add(
                    const CostFormHouseChanged(null),
                  );
              Navigator.of(context).pop();
            },
          ),

          if (state.availableHouses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'SHARED HOUSES',
                style: AppTextStyles.badge.copyWith(
                  color: colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...state.availableHouses.map((house) {
              final isSelected = state.costScope == CostScope.shared &&
                  state.selectedHouseId == house.id;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.tileColor : colors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: house.avatarUrl != null && house.avatarUrl!.isNotEmpty
                      ? Image(
                          image: getAvatarImageProvider(house.avatarUrl)!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.home_work_rounded,
                            color: isSelected ? colors.primaryColor : colors.grey,
                            size: 20,
                          ),
                        )
                      : Icon(
                          Icons.home_work_rounded,
                          color: isSelected ? colors.primaryColor : colors.grey,
                          size: 20,
                        ),
                ),
                title: Text(
                  house.name,
                  style: AppTextStyles.rowTitle.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? colors.primaryColor : colors.textColor,
                  ),
                ),
                subtitle: Text(
                  'Shared house account',
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.grey,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: colors.primaryColor,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  context.read<CostFormBloc>().add(
                        CostFormHouseChanged(house.id),
                      );
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

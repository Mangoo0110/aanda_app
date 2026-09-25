import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

class DashboardCyclePickerSheet extends StatelessWidget {
  const DashboardCyclePickerSheet({
    super.key,
    required this.state,
  });

  final DashboardState state;

  static void show(BuildContext context, DashboardState state) {
    final colors = AppColors.context(context);
    final bloc = context.read<DashboardBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: bloc,
        child: DashboardCyclePickerSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final cycles = state.cycles;
    final selectedCycle = state.selectedCycle;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
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
                'Select Cycle',
                style: AppTextStyles.sectionHeader.copyWith(
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 14),
              if (cycles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No cycles recorded yet for this house.',
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cycles.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colors.dividerColor,
                    ),
                    itemBuilder: (ctx, index) {
                      final cycle = cycles[index];
                      final isSelected = cycle.id == selectedCycle?.id;
                      final isOpen = cycle.status == SprintStatus.open;
                      final startFormatted =
                          DateFormat('d MMM yyyy').format(cycle.startDate);
                      final endFormatted = isOpen
                          ? 'Now (Open)'
                          : DateFormat('d MMM yyyy').format(cycle.endDate!);

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.read<DashboardBloc>().add(
                                DashboardCycleChanged(cycle),
                              );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? colors.tileColor
                                    : colors.softGrey,
                                child: Icon(
                                  isOpen
                                      ? Icons.timelapse_rounded
                                      : Icons.lock_clock_rounded,
                                  size: 18,
                                  color: isSelected
                                      ? colors.primaryColor
                                      : colors.grey,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          cycle.label,
                                          style: AppTextStyles.rowTitle.copyWith(
                                            color: isSelected
                                                ? colors.primaryColor
                                                : colors.textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isOpen
                                                ? colors.positiveColor
                                                    .withValues(alpha: 0.12)
                                                : colors.softGrey,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOpen ? 'ACTIVE' : 'CLOSED',
                                            style: AppTextStyles.badge.copyWith(
                                              color: isOpen
                                                  ? colors.positiveColor
                                                  : colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$startFormatted – $endFormatted',
                                      style: AppTextStyles.rowSubtitle.copyWith(
                                        color: colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
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

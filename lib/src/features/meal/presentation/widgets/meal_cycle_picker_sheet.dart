import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';

class MealCyclePickerSheet extends StatelessWidget {
  const MealCyclePickerSheet({
    super.key,
    required this.state,
  });

  final HouseMealsState state;

  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);
  static const Color primaryCoral = Color(0xFFD85A38);
  static const Color cardColor = Colors.white;

  static void show(BuildContext context, HouseMealsState state) {
    final bloc = context.read<HouseMealsBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: bloc,
        child: MealCyclePickerSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycles = state.sprints;
    final now = DateTime.now();

    final displayCycles = cycles.isNotEmpty ? cycles : <Sprint>[];

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
              const Text(
                'Select Cycle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 14),
              if (displayCycles.isEmpty)
                _buildCycleTile(
                  context: context,
                  label: 'Cycle 1',
                  dateRange:
                      '${DateFormat('d MMM').format(now.subtract(const Duration(days: 30)))} – ${DateFormat('d MMM').format(now.subtract(const Duration(days: 1)))}',
                  isSelected: false,
                  isOpen: false,
                  onTap: null,
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: displayCycles.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    itemBuilder: (ctx, idx) {
                      final cycle = displayCycles[idx];
                      final isSelected = cycle.id == state.cycleId;
                      return _buildCycleTile(
                        context: context,
                        label: cycle.label,
                        dateRange: cycle.endDate == null
                            ? '${DateFormat('d MMM').format(cycle.startDate)} – Now'
                            : '${DateFormat('d MMM').format(cycle.startDate)} – ${DateFormat('d MMM').format(cycle.endDate!)}',
                        isSelected: isSelected,
                        isOpen: cycle.isOpen,
                        onTap: isSelected
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                context.read<HouseMealsBloc>().add(
                                      HouseMealsCycleChanged(cycle),
                                    );
                              },
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

  Widget _buildCycleTile({
    required BuildContext context,
    required String label,
    required String dateRange,
    required bool isSelected,
    required bool isOpen,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? primaryCoral.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.event_repeat_rounded,
          size: 18,
          color: isSelected ? primaryCoral : subText,
        ),
      ),
      title: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? primaryCoral : darkText,
            ),
          ),
          if (isOpen) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        dateRange,
        style: const TextStyle(fontSize: 12, color: subText),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: primaryCoral, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

class DashboardCyclePickerSheet extends StatelessWidget {
  const DashboardCyclePickerSheet({
    super.key,
    required this.state,
  });

  final DashboardState state;

  static const Color cardColor = Colors.white;
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);
  static const Color primaryCoral = Color(0xFFD85A38);

  static void show(BuildContext context, DashboardState state) {
    final bloc = context.read<DashboardBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
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
              const Text(
                'Select Cycle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 14),
              if (cycles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No cycles recorded yet for this house.',
                      style: TextStyle(color: subText, fontSize: 13),
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? primaryCoral.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Icon(
                                  isOpen
                                      ? Icons.timelapse_rounded
                                      : Icons.lock_clock_rounded,
                                  size: 18,
                                  color: isSelected ? primaryCoral : subText,
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
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? primaryCoral
                                                : darkText,
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
                                                ? const Color(0xFFE8F5E9)
                                                : const Color(0xFFEEEEEE),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOpen ? 'ACTIVE' : 'CLOSED',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: isOpen
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFF757575),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$startFormatted – $endFormatted',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: subText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: primaryCoral,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Select Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B1D1F),
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
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF475467),
                size: 20,
              ),
            ),
            title: const Text(
              'Personal Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1D1F),
              ),
            ),
            subtitle: const Text(
              'Only visible to you',
              style: TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
            ),
            trailing: state.costScope == CostScope.personal
                ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF1B1D1F),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'SHARED HOUSES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF8C8D8E),
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
                    color: const Color(0xFFEDF8F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Color(0xFF1E824C),
                    size: 20,
                  ),
                ),
                title: Text(
                  house.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: const Color(0xFF1B1D1F),
                  ),
                ),
                subtitle: const Text(
                  'Shared house account',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF1B1D1F),
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

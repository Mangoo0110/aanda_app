import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';

class CostPayerPickerSheet extends StatelessWidget {
  const CostPayerPickerSheet({super.key, required this.state});

  final CostFormState state;

  static void show(BuildContext context, CostFormState state) {
    if (state.costScope == CostScope.personal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal expenses are always recorded for yourself.'),
        ),
      );
      return;
    }

    if (!state.isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only house admins can record expenses on behalf of other members.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CostFormBloc>(),
        child: CostPayerPickerSheet(state: state),
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
              'Paid / Deposited By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B1D1F),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Admin override: select who paid this expense',
              style: TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
            ),
          ),
          const SizedBox(height: 14),

          if (state.members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No members found for this house.',
                  style: TextStyle(color: Color(0xFF8C8D8E)),
                ),
              ),
            )
          else
            ...state.members.map((m) {
              final isSelected = m.userId == state.selectedPayerId;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFDEEE9),
                  backgroundImage:
                      m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                          ? NetworkImage(m.avatarUrl!)
                          : null,
                  child: m.avatarUrl == null || m.avatarUrl!.isEmpty
                      ? Text(
                          m.displayName.isNotEmpty
                              ? m.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFFD85A38),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Row(
                  children: [
                    Text(
                      m.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF1B1D1F),
                      ),
                    ),
                    if (m.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                        CostFormPayerChanged(
                          payerId: m.userId,
                          payerName: m.displayName,
                        ),
                      );
                  Navigator.of(context).pop();
                },
              );
            }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';
import 'package:aanda/src/features/meal/presentation/widgets/meal_stepper_row.dart';

class QuickLogMealSheet extends StatefulWidget {
  const QuickLogMealSheet({
    super.key,
    required this.members,
    required this.selectedDate,
  });

  final List<HouseMember> members;
  final DateTime selectedDate;

  static void show(BuildContext context) {
    final bloc = context.read<HouseMealsBloc>();
    final state = bloc.state;
    final members = state.members;
    if (members.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: QuickLogMealSheet(
          members: members,
          selectedDate: state.selectedDate,
        ),
      ),
    );
  }

  @override
  State<QuickLogMealSheet> createState() => _QuickLogMealSheetState();
}

class _QuickLogMealSheetState extends State<QuickLogMealSheet> {
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);
  static const Color primaryCoral = Color(0xFFD85A38);

  double _breakfast = 1.0;
  double _lunch = 1.0;
  double _dinner = 1.0;
  late String _selectedUserId;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.members.first.userId;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Log Meals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(widget.selectedDate),
                  style: const TextStyle(fontSize: 12, color: subText),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Apply to all toggle
            InkWell(
              onTap: () {
                setState(() => _applyToAll = !_applyToAll);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _applyToAll
                      ? primaryCoral.withValues(alpha: 0.1)
                      : const Color(0xFFFAF5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _applyToAll
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: _applyToAll ? primaryCoral : subText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apply to all housemates today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _applyToAll ? primaryCoral : darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (!_applyToAll) ...[
              const Text(
                'Select Roommate',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subText,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAF5EE),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: widget.members.map((m) {
                  return DropdownMenuItem(
                    value: m.userId,
                    child: Text(
                      m.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedUserId = val);
                  }
                },
              ),
              const SizedBox(height: 14),
            ],

            // Counters for Breakfast, Lunch, Dinner
            MealStepperRow(
              label: 'Breakfast (BRK)',
              value: _breakfast,
              onChanged: (v) => setState(() => _breakfast = v),
            ),
            const SizedBox(height: 10),
            MealStepperRow(
              label: 'Lunch',
              value: _lunch,
              onChanged: (v) => setState(() => _lunch = v),
            ),
            const SizedBox(height: 10),
            MealStepperRow(
              label: 'Dinner',
              value: _dinner,
              onChanged: (v) => setState(() => _dinner = v),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryCoral,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_applyToAll) {
                    for (final m in widget.members) {
                      context.read<HouseMealsBloc>().add(
                            HouseMealEntryChanged(
                              userId: m.userId,
                              logDate: widget.selectedDate,
                              breakfast: _breakfast,
                              lunch: _lunch,
                              dinner: _dinner,
                            ),
                          );
                    }
                  } else {
                    context.read<HouseMealsBloc>().add(
                          HouseMealEntryChanged(
                            userId: _selectedUserId,
                            logDate: widget.selectedDate,
                            breakfast: _breakfast,
                            lunch: _lunch,
                            dinner: _dinner,
                          ),
                        );
                  }
                },
                child: const Text(
                  'Save Meals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

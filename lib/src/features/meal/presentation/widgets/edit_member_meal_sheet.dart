import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';
import 'package:aanda/src/features/meal/presentation/widgets/meal_stepper_row.dart';

class EditMemberMealSheet extends StatefulWidget {
  const EditMemberMealSheet({
    super.key,
    required this.member,
    required this.meal,
    required this.date,
  });

  final HouseMember member;
  final MealLog? meal;
  final DateTime date;

  static void show({
    required BuildContext context,
    required HouseMember member,
    required MealLog? meal,
    required DateTime date,
  }) {
    final bloc = context.read<HouseMealsBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditMemberMealSheet(
          member: member,
          meal: meal,
          date: date,
        ),
      ),
    );
  }

  @override
  State<EditMemberMealSheet> createState() => _EditMemberMealSheetState();
}

class _EditMemberMealSheetState extends State<EditMemberMealSheet> {
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);
  static const Color primaryCoral = Color(0xFFD85A38);

  late double _breakfast;
  late double _lunch;
  late double _dinner;

  @override
  void initState() {
    super.initState();
    _breakfast = widget.meal?.breakfast ?? 0.0;
    _lunch = widget.meal?.lunch ?? 0.0;
    _dinner = widget.meal?.dinner ?? 0.0;
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
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryCoral.withValues(alpha: 0.15),
                  child: Text(
                    widget.member.displayName.isNotEmpty
                        ? widget.member.displayName[0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primaryCoral,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.member.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM yyyy').format(widget.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: subText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

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
                  context.read<HouseMealsBloc>().add(
                        HouseMealEntryChanged(
                          userId: widget.member.userId,
                          logDate: widget.date,
                          breakfast: _breakfast,
                          lunch: _lunch,
                          dinner: _dinner,
                        ),
                      );
                },
                child: const Text(
                  'Update Meals',
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

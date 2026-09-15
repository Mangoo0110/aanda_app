import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';

class HouseMealsScreen extends StatelessWidget {
  const HouseMealsScreen({
    super.key,
    required this.houseId,
    required this.cycleId,
    this.sprint,
  });

  final String houseId;
  final String cycleId;
  final Sprint? sprint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Spreadsheet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: colors.textColor,
              ),
            ),
            if (sprint != null)
              Text(
                '${sprint!.label} (${sprint!.dateRangeFormatted})',
                style: TextStyle(fontSize: 12, color: colors.grey),
              ),
          ],
        ),
        backgroundColor: colors.surfaceColor,
        elevation: 0,
        actions: [
          BlocBuilder<HouseMealsBloc, HouseMealsState>(
            builder: (context, state) {
              if (state.isSaving) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.iconColor),
                onPressed: () => context
                    .read<HouseMealsBloc>()
                    .add(const HouseMealsRefreshRequested()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<HouseMealsBloc, HouseMealsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colors.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Build dates in sprint or current week
          final startDate = sprint?.startDate ??
              DateTime.now().subtract(const Duration(days: 7));
          final endDate = sprint?.endDate ??
              DateTime.now().add(const Duration(days: 7));

          final daysCount = endDate.difference(startDate).inDays + 1;
          final dates = List.generate(
            daysCount > 0 && daysCount < 60 ? daysCount : 15,
            (i) => startDate.add(Duration(days: i)),
          );

          return Column(
            children: [
              // ── 1. Date Selector Strip ──────────────────────────────────
              _DateSelectorStrip(
                dates: dates,
                selectedDate: state.selectedDate,
                onDateSelected: (date) {
                  context
                      .read<HouseMealsBloc>()
                      .add(HouseMealsDateSelected(date));
                },
              ),

              // ── 2. Daily Summary Bar ────────────────────────────────────
              _DailyMealSummaryBar(
                selectedDate: state.selectedDate,
                totalMealsOnDate: state.totalMealsForSelectedDate,
                totalSprintMeals: state.totalSprintMeals,
              ),

              // ── 3. Members List with Meal Counters ──────────────────────
              Expanded(
                child: state.members.isEmpty
                    ? Center(
                        child: Text(
                          'No members found in this house.',
                          style: TextStyle(color: colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: state.members.length,
                        itemBuilder: (context, index) {
                          final member = state.members[index];
                          final meal = state.mealFor(
                            member.userId,
                            state.selectedDate,
                          );

                          return _MemberMealCard(
                            member: member,
                            meal: meal,
                            selectedDate: state.selectedDate,
                            onChanged: (b, l, d) {
                              context.read<HouseMealsBloc>().add(
                                    HouseMealEntryChanged(
                                      userId: member.userId,
                                      logDate: state.selectedDate,
                                      breakfast: b,
                                      lunch: l,
                                      dinner: d,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Date Selector Strip ──────────────────────────────────────────────────────

class _DateSelectorStrip extends StatelessWidget {
  const _DateSelectorStrip({
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final now = DateTime.now();

    return Container(
      height: 78,
      color: colors.surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onDateSelected(date),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primaryColor
                      : (isToday
                          ? colors.primaryColor.withValues(alpha: 0.12)
                          : colors.appBackgroundColor),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? colors.primaryColor
                        : (isToday
                            ? colors.primaryColor.withValues(alpha: 0.4)
                            : colors.borderColor.withValues(alpha: 0.4)),
                    width: isSelected || isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isToday ? colors.primaryColor : colors.grey),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : (isToday ? colors.primaryColor : colors.textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Daily Summary Bar ────────────────────────────────────────────────────────

class _DailyMealSummaryBar extends StatelessWidget {
  const _DailyMealSummaryBar({
    required this.selectedDate,
    required this.totalMealsOnDate,
    required this.totalSprintMeals,
  });

  final DateTime selectedDate;
  final double totalMealsOnDate;
  final double totalSprintMeals;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border(
          bottom: BorderSide(color: colors.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_rounded, size: 16, color: colors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${totalMealsOnDate.toStringAsFixed(totalMealsOnDate.truncateToDouble() == totalMealsOnDate ? 0 : 1)} meals today',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member Meal Card ─────────────────────────────────────────────────────────

class _MemberMealCard extends StatelessWidget {
  const _MemberMealCard({
    required this.member,
    required this.meal,
    required this.selectedDate,
    required this.onChanged,
  });

  final HouseMember member;
  final MealLog? meal;
  final DateTime selectedDate;
  final void Function(double b, double l, double d) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    final breakfast = meal?.breakfast ?? 0.0;
    final lunch = meal?.lunch ?? 0.0;
    final dinner = meal?.dinner ?? 0.0;
    final total = breakfast + lunch + dinner;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor,
                        ),
                      ),
                      if (member.role.name == 'admin')
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 1)} meals',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MealCounter(
                    label: 'Breakfast',
                    icon: Icons.free_breakfast_rounded,
                    value: breakfast,
                    step: 0.5,
                    onChanged: (v) => onChanged(v, lunch, dinner),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MealCounter(
                    label: 'Lunch',
                    icon: Icons.lunch_dining_rounded,
                    value: lunch,
                    step: 1.0,
                    onChanged: (v) => onChanged(breakfast, v, dinner),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MealCounter(
                    label: 'Dinner',
                    icon: Icons.dinner_dining_rounded,
                    value: dinner,
                    step: 1.0,
                    onChanged: (v) => onChanged(breakfast, lunch, v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCounter extends StatelessWidget {
  const _MealCounter({
    required this.label,
    required this.icon,
    required this.value,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double value;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final valueStr = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.appBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged((value - step).clamp(0.0, 10.0)) : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value > 0 ? colors.textColor : colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  valueStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: value > 0 ? colors.textColor : colors.grey,
                  ),
                ),
              ),
              InkWell(
                onTap: () => onChanged((value + step).clamp(0.0, 10.0)),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: colors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

part of 'house_meals_screen.dart';

class _HouseMealsMemberView extends StatelessWidget {
  const _HouseMealsMemberView({
    required this.selectedMember,
    required this.currentUserId,
    required this.memberTotalMeals,
    required this.activeSprint,
    required this.sprintDays,
    required this.today,
    required this.state,
    required this.onSelectMember,
    required this.onSelectCycle,
    required this.onCycleMeal,
    required this.onTapRow,
  });

  final HouseMember selectedMember;
  final String? currentUserId;
  final double memberTotalMeals;
  final Sprint? activeSprint;
  final List<DateTime> sprintDays;
  final DateTime today;
  final HouseMealsState state;
  final VoidCallback onSelectMember;
  final VoidCallback onSelectCycle;
  final void Function(String userId, String mealType, MealLog? meal, DateTime date) onCycleMeal;
  final void Function(HouseMember member, MealLog? meal, DateTime date) onTapRow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final isCurrentUser = selectedMember.userId == currentUserId;
    final formattedTotal = memberTotalMeals.toStringAsFixed(memberTotalMeals.truncateToDouble() == memberTotalMeals ? 0 : 1);

    return SliverMainAxisGroup(
      slivers: [
        // Member Selector Pill & Total Meals Pill
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Member Selector Pill
                Expanded(
                  child: InkWell(
                    onTap: onSelectMember,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: isCurrentUser
                                ? const Color(0xFF1B1D1F)
                                : colors.primaryColor.withValues(alpha: 0.12),
                            child: Text(
                              selectedMember.displayName.isNotEmpty ? selectedMember.displayName[0].toUpperCase() : 'M',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCurrentUser ? Colors.white : colors.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    selectedMember.displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: colors.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'You',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Total Meals Pill: • Total: 42.5 meals
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total: $formattedTotal meals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cycle Selector
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: InkWell(
              onTap: onSelectCycle,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_repeat_rounded, size: 15, color: colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      activeSprint != null
                          ? '${activeSprint!.label}  ${DateFormat('d MMM').format(activeSprint!.startDate)}–${activeSprint!.endDate != null ? DateFormat('d MMM').format(activeSprint!.endDate!) : 'Now'}'
                          : 'Select Cycle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Table Card for Member Daily Logs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header Row: DATE | BRK | LUNCH | DINNER | TOTAL
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 36,
                          child: Text(
                            'DATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: Center(
                            child: Text(
                              'BRK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: colors.grey.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: Center(
                            child: Text(
                              'LUNCH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: colors.grey.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: Center(
                            child: Text(
                              'DINNER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: colors.grey.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: Center(
                            child: Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: colors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: colors.dividerColor,
                  ),

                  // Table Date Rows for Selected Member
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sprintDays.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colors.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final date = sprintDays[index];
                      final meal = state.mealFor(selectedMember.userId, date);
                      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

                      return MemberDailyMealRow(
                        date: date,
                        meal: meal,
                        isToday: isToday,
                        onCycleBrk: () => onCycleMeal(selectedMember.userId, 'brk', meal, date),
                        onCycleLunch: () => onCycleMeal(selectedMember.userId, 'lunch', meal, date),
                        onCycleDinner: () => onCycleMeal(selectedMember.userId, 'dinner', meal, date),
                        onTapRow: () => onTapRow(selectedMember, meal, date),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

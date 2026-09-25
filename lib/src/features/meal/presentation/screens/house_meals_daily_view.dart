part of 'house_meals_screen.dart';

class _HouseMealsDailyView extends StatelessWidget {
  const _HouseMealsDailyView({
    required this.selectedDate,
    required this.totalMeals,
    required this.members,
    required this.currentUserId,
    required this.state,
    required this.onPickDate,
    required this.onPrevDate,
    required this.onNextDate,
    required this.onCycleMeal,
    required this.onTapRow,
  });

  final DateTime selectedDate;
  final double totalMeals;
  final List<HouseMember> members;
  final String? currentUserId;
  final HouseMealsState state;
  final VoidCallback onPickDate;
  final VoidCallback onPrevDate;
  final VoidCallback onNextDate;
  final void Function(String userId, String mealType, MealLog? meal, DateTime date) onCycleMeal;
  final void Function(HouseMember member, MealLog? meal, DateTime date) onTapRow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final formattedTotal = totalMeals.toStringAsFixed(totalMeals.truncateToDouble() == totalMeals ? 0 : 1);

    return SliverMainAxisGroup(
      slivers: [
        // Date Navigator Pill & Total Meals Pill
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Date Navigator Pill: < 📅 16 Sep 2026 >
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 18),
                          color: colors.grey,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: onPrevDate,
                        ),
                        InkWell(
                          onTap: onPickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📅', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('d MMM yyyy').format(selectedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 18),
                          color: colors.grey,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: onNextDate,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Total Meals Pill: • Total: 12.5 meals
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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

        const SizedBox(height: 10).toSliver(),

        // Tabular Ledger Card (Roommates x Meals)
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
                  // Table Header Row: ROOMMATE | BRK | LUNCH | DINNER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 42,
                          child: Text(
                            'ROOMMATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 18,
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
                          flex: 18,
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
                          flex: 18,
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
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: colors.dividerColor,
                  ),

                  // Table Member Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colors.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final meal = state.mealFor(member.userId, selectedDate);
                      final isYou = (member.userId == currentUserId) || index == 0;

                      return MemberMealRow(
                        member: member,
                        meal: meal,
                        isYou: isYou,
                        index: index,
                        onCycleBrk: () => onCycleMeal(member.userId, 'brk', meal, selectedDate),
                        onCycleLunch: () => onCycleMeal(member.userId, 'lunch', meal, selectedDate),
                        onCycleDinner: () => onCycleMeal(member.userId, 'dinner', meal, selectedDate),
                        onTapRow: () => onTapRow(member, meal, selectedDate),
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

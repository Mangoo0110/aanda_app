import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/presentation/widgets/account_picker_sheet.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';
import 'package:aanda/src/features/meal/presentation/widgets/edit_member_meal_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/meal_cycle_picker_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/meal_member_picker_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/member_daily_meal_row.dart';
import 'package:aanda/src/features/meal/presentation/widgets/member_meal_row.dart';
import 'package:aanda/src/features/meal/presentation/widgets/quick_log_meal_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/view_toggle_button.dart';

enum MealViewMode { daily, member }

class HouseMealsScreen extends StatefulWidget {
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
  State<HouseMealsScreen> createState() => _HouseMealsScreenState();
}

class _HouseMealsScreenState extends State<HouseMealsScreen> {
  // Theme constants matching warm cream / peach minimal ledger aesthetic
  static const Color backgroundColor = Color(0xFFFFF7EE);
  static const Color cardColor = Colors.white;
  static const Color primaryCoral = Color(0xFFD85A38);
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);

  MealViewMode _viewMode = MealViewMode.daily;
  String? _selectedMemberUserId;

  @override
  void initState() {
    super.initState();
    final houseCtx = context.read<HouseContextCubit>();
    if (!houseCtx.state.hasHouses &&
        houseCtx.state.status != HouseContextStatus.loading) {
      houseCtx.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickLogSheet(context),
        backgroundColor: primaryCoral,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: BlocConsumer<HouseMealsBloc, HouseMealsState>(
          listenWhen: (previous, current) =>
              current.errorMessage != null &&
              current.errorMessage != previous.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: colors.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.members.isEmpty) {
              return const Scaffold(
                backgroundColor: backgroundColor,
                body: Center(
                  child: CircularProgressIndicator(color: primaryCoral),
                ),
              );
            }

            final houseCtx = context.watch<HouseContextCubit>();
            final currentHouse = houseCtx.state.houses.where(
              (h) => h.id == widget.houseId,
            ).firstOrNull ?? houseCtx.state.selectedHouse;
            final houseName = currentHouse?.name ?? 'My House';
            final memberCount = state.members.isNotEmpty
                ? state.members.length
                : (currentHouse?.members.length ?? 0);

            final selectedDate = state.selectedDate;
            final totalMeals = state.totalMealsForSelectedDate;
            final members = state.members;

            final selectedMember = members.firstWhere(
              (m) => m.userId == (_selectedMemberUserId ?? currentUserId),
              orElse: () => members.isNotEmpty
                  ? members.first
                  : HouseMember(
                      id: '',
                      houseId: widget.houseId,
                      userId: currentUserId ?? '',
                      role: MemberRole.member,
                      joinedAt: DateTime.now(),
                      fullName: 'Member',
                    ),
            );

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            // Use the bloc's active sprint (updated when user switches cycles)
            // falling back to the widget-level sprint passed in from the route.
            final activeSprint = state.activeSprint ?? widget.sprint;
            final sprintStart = activeSprint != null
                ? DateTime(
                    activeSprint.startDate.year,
                    activeSprint.startDate.month,
                    activeSprint.startDate.day,
                  )
                : DateTime(now.year, now.month, 1);
            final sprintEnd = activeSprint != null
                ? (activeSprint.endDate != null
                    ? DateTime(
                        activeSprint.endDate!.year,
                        activeSprint.endDate!.month,
                        activeSprint.endDate!.day,
                      )
                    : DateTime(now.year, now.month, now.day)) // open cycle = today
                : DateTime(now.year, now.month + 1, 0);

            final List<DateTime> sprintDays = [];
            var currDate = sprintEnd;
            while (!currDate.isBefore(sprintStart)) {
              sprintDays.add(currDate);
              currDate = currDate.subtract(const Duration(days: 1));
            }


            final memberTotalMeals = state.mealLogs
                .where((m) => m.userId == selectedMember.userId)
                .fold<double>(0.0, (sum, m) => sum + m.totalMeals);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Top Bar: Back Button | Title | House Selector Chip ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        // Back button
                        const AppBackButton(margin: EdgeInsets.zero),
                        const SizedBox(width: 12),

                        // Title obeying appbar theme
                        Text(
                          'Meals',
                          style: Theme.of(context).appBarTheme.titleTextStyle,
                        ),

                        const Spacer(),

                        // House selector chip on the right
                        InkWell(
                          onTap: _showHousePicker,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
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
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: primaryCoral.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Text(
                                        houseName.isNotEmpty
                                            ? houseName[0].toUpperCase()
                                            : 'H',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: primaryCoral,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          houseName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: darkText,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 14,
                                          color: subText,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$memberCount members',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: subText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 1.5. View Switcher Pill: Daily View | Member Log ─────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardColor,
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
                          Expanded(
                            child: ViewToggleButton(
                              title: 'Daily View',
                              icon: Icons.calendar_view_day_rounded,
                              isSelected: _viewMode == MealViewMode.daily,
                              onTap: () {
                                if (_viewMode != MealViewMode.daily) {
                                  setState(() => _viewMode = MealViewMode.daily);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ViewToggleButton(
                              title: 'Member Log',
                              icon: Icons.person_rounded,
                              isSelected: _viewMode == MealViewMode.member,
                              onTap: () {
                                if (_viewMode != MealViewMode.member) {
                                  setState(() => _viewMode = MealViewMode.member);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_viewMode == MealViewMode.daily) ...[
                  // ── 2. Date Navigator Pill & Total Meals Pill ───────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Date Navigator Pill: < 📅 16 Sep 2026 >
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18,
                                    ),
                                    color: subText,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: () {
                                      final prev = selectedDate.subtract(
                                        const Duration(days: 1),
                                      );
                                      context.read<HouseMealsBloc>().add(
                                        HouseMealsDateSelected(prev),
                                      );
                                    },
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        _pickDate(context, selectedDate),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            '📅',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat(
                                              'd MMM yyyy',
                                            ).format(selectedDate),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: darkText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                    ),
                                    color: subText,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: () {
                                      final next = selectedDate.add(
                                        const Duration(days: 1),
                                      );
                                      context.read<HouseMealsBloc>().add(
                                        HouseMealsDateSelected(next),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Total Meals Pill: • Total: 12.5 meals
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDE745B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Total: ${totalMeals.toStringAsFixed(totalMeals.truncateToDouble() == totalMeals ? 0 : 1)} meals',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7A7265),
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

                  // ── 3. Tabular Ledger Card (Roommates x Meals) ───────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
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
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                10,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 42,
                                    child: Text(
                                      'ROOMMATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: subText,
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
                                          color: subText.withValues(alpha: 0.9),
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
                                          color: subText.withValues(alpha: 0.9),
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
                                          color: subText.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Divider(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.04),
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
                                color: Colors.black.withValues(alpha: 0.04),
                              ),
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final meal = state.mealFor(
                                  member.userId,
                                  selectedDate,
                                );
                                final isYou =
                                    member.userId == currentUserId ||
                                    index == 0;

                                return MemberMealRow(
                                  member: member,
                                  meal: meal,
                                  isYou: isYou,
                                  index: index,
                                  onCycleBrk: () => _cycleMeal(
                                    context,
                                    member.userId,
                                    'brk',
                                    meal,
                                    selectedDate,
                                  ),
                                  onCycleLunch: () => _cycleMeal(
                                    context,
                                    member.userId,
                                    'lunch',
                                    meal,
                                    selectedDate,
                                  ),
                                  onCycleDinner: () => _cycleMeal(
                                    context,
                                    member.userId,
                                    'dinner',
                                    meal,
                                    selectedDate,
                                  ),
                                  onTapRow: () => _showEditMealForMemberSheet(
                                    context,
                                    member,
                                    meal,
                                    selectedDate,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // ── Member Log View ──────────────────────────────────────────
                  // Member Selector Pill & Total Meals Pill
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          // Member Selector Pill
                          Expanded(
                            child: InkWell(
                              onTap: () => _showMemberPicker(
                                context,
                                members,
                                selectedMember,
                                state,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor:
                                          (selectedMember.userId ==
                                                  currentUserId)
                                              ? const Color(0xFF1B1D1F)
                                              : primaryCoral.withValues(
                                                alpha: 0.12,
                                              ),
                                      child: Text(
                                        selectedMember.displayName.isNotEmpty
                                            ? selectedMember.displayName[0]
                                                .toUpperCase()
                                            : 'M',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              (selectedMember.userId ==
                                                      currentUserId)
                                                  ? Colors.white
                                                  : primaryCoral,
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
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: darkText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (selectedMember.userId ==
                                              currentUserId) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primaryCoral.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'You',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryCoral,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: subText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Total Meals Pill: • Total: 42.5 meals
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDE745B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Total: ${memberTotalMeals.toStringAsFixed(memberTotalMeals.truncateToDouble() == memberTotalMeals ? 0 : 1)} meals',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7A7265),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Cycle Selector ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: InkWell(
                        onTap: () => _showCyclePicker(context, state),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
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
                              const Icon(
                                Icons.event_repeat_rounded,
                                size: 15,
                                color: subText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                activeSprint != null
                                    ? '${activeSprint.label}  ${DateFormat('d MMM').format(activeSprint.startDate)}–${activeSprint.endDate != null ? DateFormat('d MMM').format(activeSprint.endDate!) : 'Now'}'
                                    : 'Select Cycle',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: subText,
                              ),
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
                          color: cardColor,
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
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                10,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 36,
                                    child: Text(
                                      'DATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: subText,
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
                                          color: subText.withValues(alpha: 0.9),
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
                                          color: subText.withValues(alpha: 0.9),
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
                                          color: subText.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 16,
                                    child: Center(
                                      child: Text(
                                        'TOTAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: primaryCoral,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Divider(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.04),
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
                                color: Colors.black.withValues(alpha: 0.04),
                              ),
                              itemBuilder: (context, index) {
                                final date = sprintDays[index];
                                final meal = state.mealFor(
                                  selectedMember.userId,
                                  date,
                                );
                                final isToday =
                                    date.year == today.year &&
                                    date.month == today.month &&
                                    date.day == today.day;

                                return MemberDailyMealRow(
                                  date: date,
                                  meal: meal,
                                  isToday: isToday,
                                  onCycleBrk: () => _cycleMeal(
                                    context,
                                    selectedMember.userId,
                                    'brk',
                                    meal,
                                    date,
                                  ),
                                  onCycleLunch: () => _cycleMeal(
                                    context,
                                    selectedMember.userId,
                                    'lunch',
                                    meal,
                                    date,
                                  ),
                                  onCycleDinner: () => _cycleMeal(
                                    context,
                                    selectedMember.userId,
                                    'dinner',
                                    meal,
                                    date,
                                  ),
                                  onTapRow: () => _showEditMealForMemberSheet(
                                    context,
                                    selectedMember,
                                    meal,
                                    date,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Helpers & Cell Tapping ────────────────────────────────────────────────

  /// Tapping a meal cell opens the full edit sheet so users can enter
  /// any quantity — including multiple meals for guests.
  void _cycleMeal(
    BuildContext context,
    String userId,
    String mealType,
    MealLog? currentLog,
    DateTime date,
  ) {
    // Find the member from state
    final member = context
        .read<HouseMealsBloc>()
        .state
        .members
        .where((m) => m.userId == userId)
        .firstOrNull;
    if (member == null) return;
    _showEditMealForMemberSheet(context, member, currentLog, date);
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final bloc = context.read<HouseMealsBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryCoral,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      bloc.add(HouseMealsDateSelected(picked));
    }
  }

  // ── Quick Log Bottom Sheet ────────────────────────────────────────────────

  void _showQuickLogSheet(BuildContext context) {
    QuickLogMealSheet.show(context);
  }

  void _showEditMealForMemberSheet(
    BuildContext context,
    HouseMember member,
    MealLog? meal,
    DateTime date,
  ) {
    EditMemberMealSheet.show(
      context: context,
      member: member,
      meal: meal,
      date: date,
    );
  }

  void _showHousePicker() {
    AccountPickerSheet.show(
      context,
      onAccountSelected: () {
        final house = context.read<HouseContextCubit>().state.selectedHouse;
        if (house != null && house.id != widget.houseId) {
          context.pushReplacement(
            AppRoutes.houseMeals(house.id),
          );
        }
      },
    );
  }

  void _showCyclePicker(BuildContext context, HouseMealsState state) {
    MealCyclePickerSheet.show(context, state);
  }

  void _showMemberPicker(
    BuildContext context,
    List<HouseMember> members,
    HouseMember currentSelected,
    HouseMealsState state,
  ) {
    MealMemberPickerSheet.show(
      context: context,
      members: members,
      currentSelected: currentSelected,
      state: state,
      onSelectMember: (userId) {
        setState(() {
          _selectedMemberUserId = userId;
        });
      },
    );
  }
}

extension _SliverSpacer on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}

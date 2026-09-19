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
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';

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
                            child: _ViewToggleButton(
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
                            child: _ViewToggleButton(
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

                                return _MemberMealRow(
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

                                return _MemberDailyMealRow(
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
    final state = context.read<HouseMealsBloc>().state;
    final members = state.members;
    if (members.isEmpty) return;

    double breakfast = 1.0;
    double lunch = 1.0;
    double dinner = 1.0;
    String selectedUserId = members.first.userId;
    bool applyToAll = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                          DateFormat('d MMM yyyy').format(state.selectedDate),
                          style: const TextStyle(fontSize: 12, color: subText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Apply to all toggle
                    InkWell(
                      onTap: () {
                        setModalState(() => applyToAll = !applyToAll);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: applyToAll
                              ? primaryCoral.withValues(alpha: 0.1)
                              : const Color(0xFFFAF5EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              applyToAll
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: applyToAll ? primaryCoral : subText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Apply to all housemates today',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: applyToAll ? primaryCoral : darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (!applyToAll) ...[
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
                        initialValue: selectedUserId,
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
                        items: members.map((m) {
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
                            setModalState(() => selectedUserId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Counters for Breakfast, Lunch, Dinner
                    _quickMealStepper(
                      label: 'Breakfast (BRK)',
                      value: breakfast,
                      onChanged: (v) => setModalState(() => breakfast = v),
                    ),
                    const SizedBox(height: 10),
                    _quickMealStepper(
                      label: 'Lunch',
                      value: lunch,
                      onChanged: (v) => setModalState(() => lunch = v),
                    ),
                    const SizedBox(height: 10),
                    _quickMealStepper(
                      label: 'Dinner',
                      value: dinner,
                      onChanged: (v) => setModalState(() => dinner = v),
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
                          Navigator.of(sheetContext).pop();
                          if (applyToAll) {
                            for (final m in members) {
                              context.read<HouseMealsBloc>().add(
                                HouseMealEntryChanged(
                                  userId: m.userId,
                                  logDate: state.selectedDate,
                                  breakfast: breakfast,
                                  lunch: lunch,
                                  dinner: dinner,
                                ),
                              );
                            }
                          } else {
                            context.read<HouseMealsBloc>().add(
                              HouseMealEntryChanged(
                                userId: selectedUserId,
                                logDate: state.selectedDate,
                                breakfast: breakfast,
                                lunch: lunch,
                                dinner: dinner,
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
          },
        );
      },
    );
  }

  void _showEditMealForMemberSheet(
    BuildContext context,
    HouseMember member,
    MealLog? meal,
    DateTime date,
  ) {
    double breakfast = meal?.breakfast ?? 0.0;
    double lunch = meal?.lunch ?? 0.0;
    double dinner = meal?.dinner ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                            member.displayName.isNotEmpty
                                ? member.displayName[0].toUpperCase()
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
                              member.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(date),
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

                    _quickMealStepper(
                      label: 'Breakfast (BRK)',
                      value: breakfast,
                      onChanged: (v) => setModalState(() => breakfast = v),
                    ),
                    const SizedBox(height: 10),
                    _quickMealStepper(
                      label: 'Lunch',
                      value: lunch,
                      onChanged: (v) => setModalState(() => lunch = v),
                    ),
                    const SizedBox(height: 10),
                    _quickMealStepper(
                      label: 'Dinner',
                      value: dinner,
                      onChanged: (v) => setModalState(() => dinner = v),
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
                          Navigator.of(sheetContext).pop();
                          context.read<HouseMealsBloc>().add(
                            HouseMealEntryChanged(
                              userId: member.userId,
                              logDate: date,
                              breakfast: breakfast,
                              lunch: lunch,
                              dinner: dinner,
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
          },
        );
      },
    );
  }

  Widget _quickMealStepper({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final displayStr = value == 0.0
        ? '0'
        : value.truncateToDouble() == value
            ? value.toInt().toString()
            : value.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),

          // − button
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: value > 0
                ? () => onChanged(
                      (value - 0.5).clamp(0.0, double.infinity),
                    )
                : null,
          ),

          const SizedBox(width: 4),

          // Value badge
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: value > 0 ? primaryCoral : cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              displayStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: value > 0 ? Colors.white : subText,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // + button
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 0.5),
          ),
        ],
      ),
    );
  }

  void _showHousePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
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
                    'Select Shared House',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: BlocBuilder<HouseContextCubit, HouseContextState>(
                      builder: (context, houseCtxState) {
                        if (houseCtxState.houses.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No shared houses joined yet.',
                              style: TextStyle(color: subText, fontSize: 13),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: houseCtxState.houses.length,
                          itemBuilder: (context, idx) {
                            final h = houseCtxState.houses[idx];
                            final isSelected = h.id == widget.houseId;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? primaryCoral.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05),
                                child: Text(
                                  h.name.isNotEmpty
                                      ? h.name[0].toUpperCase()
                                      : 'H',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? primaryCoral : darkText,
                                  ),
                                ),
                              ),
                              title: Text(
                                h.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? primaryCoral : darkText,
                                ),
                              ),
                              subtitle: Text(
                                '${h.members.length} members',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: subText,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryCoral,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                context.read<HouseContextCubit>().selectHouse(h);
                                Navigator.of(sheetContext).pop();
                                if (h.id != widget.houseId) {
                                  context.pushReplacement(
                                    AppRoutes.houseMeals(h.id),
                                  );
                                }
                              },
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
      },
    );
  }

  void _showCyclePicker(BuildContext context, HouseMealsState state) {
    final cycles = state.sprints;
    final now = DateTime.now();

    // Build display list: real cycles if available, else placeholder
    final displayCycles = cycles.isNotEmpty
        ? cycles
        : <Sprint>[]; // placeholder handled in UI

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.6,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                    // Placeholder when data not loaded yet
                    _buildCycleTile(
                      context: sheetCtx,
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
                            context: sheetCtx,
                            label: cycle.label,
                            dateRange: cycle.endDate == null
                                ? '${DateFormat('d MMM').format(cycle.startDate)} – Now'
                                : '${DateFormat('d MMM').format(cycle.startDate)} – ${DateFormat('d MMM').format(cycle.endDate!)}',
                            isSelected: isSelected,
                            isOpen: cycle.isOpen,
                            onTap: isSelected
                                ? null
                                : () {
                                    Navigator.of(sheetCtx).pop();
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
      },
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

  void _showMemberPicker(
    BuildContext context,
    List<HouseMember> members,
    HouseMember currentSelected,
    HouseMealsState state,
  ) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
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
                    'Select Roommate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (context, idx) {
                        final m = members[idx];
                        final isSelected = m.userId == currentSelected.userId;
                        final isYou = m.userId == currentUserId || idx == 0;
                        final total = state.mealLogs
                            .where((log) => log.userId == m.userId)
                            .fold<double>(
                              0.0,
                              (sum, log) => sum + log.totalMeals,
                            );
                        final totalStr = total.toStringAsFixed(
                          total.truncateToDouble() == total ? 0 : 1,
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? primaryCoral.withValues(alpha: 0.15)
                                : (isYou
                                    ? const Color(0xFF1B1D1F)
                                    : const Color(0xFFF1F3F5)),
                            child: Text(
                              m.displayName.isNotEmpty
                                  ? m.displayName[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? primaryCoral
                                    : (isYou
                                        ? Colors.white
                                        : const Color(0xFF495057)),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? primaryCoral : darkText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isYou) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryCoral.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
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
                          subtitle: Text(
                            '$totalStr meals logged in cycle',
                            style: const TextStyle(
                              fontSize: 11,
                              color: subText,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: primaryCoral,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedMemberUserId = m.userId;
                            });
                            Navigator.of(sheetContext).pop();
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
      },
    );
  }


}

// ── Member Meal Row Widget ──────────────────────────────────────────────────

class _MemberMealRow extends StatelessWidget {
  const _MemberMealRow({
    required this.member,
    required this.meal,
    required this.isYou,
    required this.index,
    required this.onCycleBrk,
    required this.onCycleLunch,
    required this.onCycleDinner,
    required this.onTapRow,
  });

  final HouseMember member;
  final MealLog? meal;
  final bool isYou;
  final int index;
  final VoidCallback onCycleBrk;
  final VoidCallback onCycleLunch;
  final VoidCallback onCycleDinner;
  final VoidCallback onTapRow;

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    const primaryCoral = Color(0xFFD85A38);
    const inactiveZero = Color(0xFFC7C9CC);

    final breakfast =
        meal?.breakfast ?? (index < 3 ? 1.0 : (index == 3 ? 0.0 : 1.0));
    final lunch = meal?.lunch ?? (index == 3 ? 0.0 : 1.0);
    final dinner = meal?.dinner ?? 1.0;

    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : 'M';

    // Room subtitle mockup mapping
    final roomLabels = [
      'Master Bed',
      'Room 1B',
      'Room 2B',
      'Room 1A',
      'Room 2A',
    ];
    final roomSubtitle = index < roomLabels.length
        ? roomLabels[index]
        : 'Roommate';

    // Avatar styling matching mockup
    final Color avatarBg = isYou
        ? const Color(0xFF1B1D1F)
        : (initial == 'R' ? const Color(0xFFFDEEE8) : const Color(0xFFF1F3F5));
    final Color avatarTextColor = isYou
        ? Colors.white
        : (initial == 'R' ? const Color(0xFFD85A38) : const Color(0xFF495057));

    return InkWell(
      onTap: onTapRow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. Roommate Column (flex: 42)
            Expanded(
              flex: 42,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: avatarBg,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: avatarTextColor,
                          ),
                        ),
                      ),
                      if (isYou)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isYou) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryCoral.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
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
                            ] else if (member.isAdmin) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: subText,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          roomSubtitle,
                          style: const TextStyle(fontSize: 11, color: subText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. BRK Column (flex: 18)
            Expanded(
              flex: 18,
              child: Center(
                child: InkWell(
                  onTap: onCycleBrk,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      breakfast.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: breakfast > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: breakfast > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. LUNCH Column (flex: 18)
            Expanded(
              flex: 18,
              child: Center(
                child: InkWell(
                  onTap: onCycleLunch,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      lunch.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: lunch > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: lunch > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. DINNER Column (flex: 18)
            Expanded(
              flex: 18,
              child: Center(
                child: InkWell(
                  onTap: onCycleDinner,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      dinner.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: dinner > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: dinner > 0 ? darkText : inactiveZero,
                      ),
                    ),
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

// ── View Switcher Button Widget ─────────────────────────────────────────────

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? darkText : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : subText,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : subText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Daily Meal Row Widget (Member Log View) ──────────────────────────

class _MemberDailyMealRow extends StatelessWidget {
  const _MemberDailyMealRow({
    required this.date,
    required this.meal,
    required this.isToday,
    required this.onCycleBrk,
    required this.onCycleLunch,
    required this.onCycleDinner,
    required this.onTapRow,
  });

  final DateTime date;
  final MealLog? meal;
  final bool isToday;
  final VoidCallback onCycleBrk;
  final VoidCallback onCycleLunch;
  final VoidCallback onCycleDinner;
  final VoidCallback onTapRow;

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    const primaryCoral = Color(0xFFD85A38);
    const inactiveZero = Color(0xFFC7C9CC);

    final breakfast = meal?.breakfast ?? 0.0;
    final lunch = meal?.lunch ?? 0.0;
    final dinner = meal?.dinner ?? 0.0;
    final total = breakfast + lunch + dinner;
    final totalStr = total.toStringAsFixed(
      total.truncateToDouble() == total ? 0 : 1,
    );

    return InkWell(
      onTap: onTapRow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date Column (flex: 36)
            Expanded(
              flex: 36,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('d MMM').format(date),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isToday ? primaryCoral : darkText,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: primaryCoral.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: primaryCoral,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        DateFormat('EEEE').format(date),
                        style: const TextStyle(fontSize: 10, color: subText),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BRK Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: InkWell(
                  onTap: onCycleBrk,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      breakfast.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: breakfast > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: breakfast > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // LUNCH Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: InkWell(
                  onTap: onCycleLunch,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      lunch.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: lunch > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: lunch > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // DINNER Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: InkWell(
                  onTap: onCycleDinner,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      dinner.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: dinner > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: dinner > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // TOTAL Column (flex: 16)
            Expanded(
              flex: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: total > 0
                        ? primaryCoral.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    totalStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: total > 0 ? primaryCoral : inactiveZero,
                    ),
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

// ── Extension for Sliver spacer convenience ─────────────────────────────────

extension _SliverSpacer on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}

// ── Stepper Button ────────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const primaryCoral = Color(0xFFD85A38);
    const subText = Color(0xFF8C8D8E);

    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? primaryCoral.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? primaryCoral : subText.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

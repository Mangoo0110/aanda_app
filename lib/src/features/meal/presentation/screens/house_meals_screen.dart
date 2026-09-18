import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';

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

  String _houseName = 'Dhaka Flat';
  int _memberCount = 5;
  List<Map<String, dynamic>> _houses = [];

  @override
  void initState() {
    super.initState();
    _loadHouseDetails();
  }

  Future<void> _loadHouseDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('houses')
          .select('id, name, house_members(id, user_id, role, display_name)');
      final list = (data as List).cast<Map<String, dynamic>>();
      if (mounted && list.isNotEmpty) {
        final current = list.firstWhere(
          (h) => h['id'] == widget.houseId,
          orElse: () => list.first,
        );
        final members = current['house_members'] as List? ?? [];
        setState(() {
          _houses = list;
          _houseName = current['name'] as String? ?? 'Dhaka Flat';
          _memberCount = members.isNotEmpty ? members.length : 5;
        });
      }
    } catch (_) {}
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
            final selectedDate = state.selectedDate;
            final totalMeals = state.totalMealsForSelectedDate;
            final members = state.members.isNotEmpty
                ? state.members
                : _fallbackMembers();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Top Bar: Back Button | Title | House Selector Chip ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        // Back button in rounded square
                        InkWell(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.home);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: darkText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title
                        const Text(
                          'Meals',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
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
                                      backgroundColor:
                                          primaryCoral.withValues(alpha: 0.12),
                                      child: Text(
                                        _houseName.isNotEmpty
                                            ? _houseName[0].toUpperCase()
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
                                          _houseName,
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
                                      '$_memberCount members',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  onTap: () => _pickDate(context, selectedDate),
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
                                          DateFormat('d MMM yyyy').format(
                                            selectedDate,
                                          ),
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
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                              final isYou = member.userId == currentUserId ||
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

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Helpers & Cell Tapping ────────────────────────────────────────────────

  void _cycleMeal(
    BuildContext context,
    String userId,
    String mealType,
    MealLog? currentLog,
    DateTime date,
  ) {
    final b = currentLog?.breakfast ?? 0.0;
    final l = currentLog?.lunch ?? 0.0;
    final d = currentLog?.dinner ?? 0.0;

    double nextVal(double curr) {
      if (curr == 0.0) return 1.0;
      if (curr == 1.0) return 0.5;
      return 0.0;
    }

    double newB = b;
    double newL = l;
    double newD = d;

    if (mealType == 'brk') newB = nextVal(b);
    if (mealType == 'lunch') newL = nextVal(l);
    if (mealType == 'dinner') newD = nextVal(d);

    context.read<HouseMealsBloc>().add(
          HouseMealEntryChanged(
            userId: userId,
            logDate: date,
            breakfast: newB,
            lunch: newL,
            dinner: newD,
          ),
        );
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
    final members = state.members.isNotEmpty ? state.members : _fallbackMembers();

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          Row(
            children: [
              ...[0.0, 0.5, 1.0, 1.5, 2.0].map((v) {
                final isSelected = (value - v).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => onChanged(v),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryCoral : cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : darkText,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
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
                  if (_houses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No shared houses joined yet.',
                        style: TextStyle(color: subText, fontSize: 13),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _houses.length,
                        itemBuilder: (context, idx) {
                          final h = _houses[idx];
                          final isSelected = h['id'] == widget.houseId;
                          final members =
                              h['house_members'] as List? ?? [];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? primaryCoral.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.05),
                              child: Text(
                                (h['name'] as String? ?? 'H')[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? primaryCoral : darkText,
                                ),
                              ),
                            ),
                            title: Text(
                              h['name'] as String? ?? 'House',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? primaryCoral : darkText,
                              ),
                            ),
                            subtitle: Text(
                              '${members.length} members',
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
                              Navigator.of(sheetContext).pop();
                              if (h['id'] != widget.houseId) {
                                context.pushReplacement(
                                  AppRoutes.houseMeals(h['id'] as String),
                                );
                              }
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

  List<HouseMember> _fallbackMembers() {
    final now = DateTime.now();
    return [
      HouseMember(
        id: '1',
        houseId: widget.houseId,
        userId: 'user-1',
        role: MemberRole.member,
        joinedAt: now,
        fullName: 'Tanvir',
      ),
      HouseMember(
        id: '2',
        houseId: widget.houseId,
        userId: 'user-2',
        role: MemberRole.admin,
        joinedAt: now,
        fullName: 'Rahim',
      ),
      HouseMember(
        id: '3',
        houseId: widget.houseId,
        userId: 'user-3',
        role: MemberRole.member,
        joinedAt: now,
        fullName: 'Sadia',
      ),
      HouseMember(
        id: '4',
        houseId: widget.houseId,
        userId: 'user-4',
        role: MemberRole.member,
        joinedAt: now,
        fullName: 'Karim',
      ),
      HouseMember(
        id: '5',
        houseId: widget.houseId,
        userId: 'user-5',
        role: MemberRole.member,
        joinedAt: now,
        fullName: 'Farhan',
      ),
    ];
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

    final breakfast = meal?.breakfast ?? (index < 3 ? 1.0 : (index == 3 ? 0.0 : 1.0));
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
    final roomSubtitle = index < roomLabels.length ? roomLabels[index] : 'Roommate';

    // Avatar styling matching mockup
    final Color avatarBg = isYou
        ? const Color(0xFF1B1D1F)
        : (initial == 'R'
            ? const Color(0xFFFDEEE8)
            : const Color(0xFFF1F3F5));
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
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: subText,
                          ),
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
                        fontWeight:
                            breakfast > 0 ? FontWeight.w700 : FontWeight.w500,
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
                        fontWeight:
                            lunch > 0 ? FontWeight.w700 : FontWeight.w500,
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
                        fontWeight:
                            dinner > 0 ? FontWeight.w700 : FontWeight.w500,
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

// ── Extension for Sliver spacer convenience ─────────────────────────────────

extension _SliverSpacer on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';
import 'package:aanda/src/features/meal/presentation/widgets/edit_member_meal_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/meal_cycle_picker_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/meal_member_picker_sheet.dart';
import 'package:aanda/src/features/meal/presentation/widgets/member_daily_meal_row.dart';
import 'package:aanda/src/features/meal/presentation/widgets/member_meal_row.dart';
import 'package:aanda/src/features/meal/presentation/widgets/quick_log_meal_sheet.dart';

part 'house_meals_top_bar.dart';
part 'house_meals_daily_view.dart';
part 'house_meals_member_view.dart';

enum MealViewMode { daily, member }

class HouseMealsScreen extends StatefulWidget {
  const HouseMealsScreen({
    super.key,
    required this.houseId,
    required this.cycleId,
    this.sprint,
    this.showBackButton = true,
  });

  final String houseId;
  final String cycleId;
  final Sprint? sprint;
  final bool showBackButton;

  @override
  State<HouseMealsScreen> createState() => _HouseMealsScreenState();
}

class _HouseMealsScreenState extends State<HouseMealsScreen> {
  MealViewMode _viewMode = MealViewMode.daily;

  @override
  void initState() {
    super.initState();
    final houseCtx = context.read<HouseContextCubit>();
    if (!houseCtx.state.hasHouses && houseCtx.state.status != HouseContextStatus.loading) {
      houseCtx.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showQuickLogSheet(context),
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: BlocListener<HouseContextCubit, HouseContextState>(
          listenWhen: (prev, curr) =>
              prev.mealUpdateCounter != curr.mealUpdateCounter,
          listener: (context, state) {
            context.read<HouseMealsBloc>().add(const HouseMealsStarted());
          },
          child: BlocConsumer<HouseMealsBloc, HouseMealsState>(
            listenWhen: (previous, current) =>
                current.errorMessage != null && current.errorMessage != previous.errorMessage,
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
            if (state.isLoading && state.members.isEmpty) {
              return Scaffold(
                backgroundColor: colors.appBackgroundColor,
                body: Center(
                  child: CircularProgressIndicator(color: colors.primaryColor),
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

            final HouseMember selectedMember = state.selectedMember(currentUserId);
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final activeSprint = state.activeSprint ?? widget.sprint;
            final sprintDays = state.sprintDays;
            final memberTotalMeals = state.memberTotalMeals(selectedMember.userId);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _HouseMealsTopBar(
                  houseName: houseName,
                  memberCount: memberCount,
                  viewMode: _viewMode,
                  onViewModeChanged: (mode) {
                    if (_viewMode != mode) setState(() => _viewMode = mode);
                  },
                  showBackButton: widget.showBackButton,
                ),
                if (_viewMode == MealViewMode.daily)
                  _HouseMealsDailyView(
                    selectedDate: selectedDate,
                    totalMeals: totalMeals,
                    members: members,
                    currentUserId: currentUserId,
                    state: state,
                    onPickDate: () => _pickDate(context, selectedDate),
                    onPrevDate: () {
                      final prev = selectedDate.subtract(const Duration(days: 1));
                      context.read<HouseMealsBloc>().add(HouseMealsDateSelected(prev));
                    },
                    onNextDate: () {
                      final next = selectedDate.add(const Duration(days: 1));
                      context.read<HouseMealsBloc>().add(HouseMealsDateSelected(next));
                    },
                    onCycleMeal: (userId, type, meal, date) => _cycleMeal(context, userId, type, meal, date),
                    onTapRow: (m, meal, date) => _showEditMealForMemberSheet(context, m, meal, date),
                  )
                else
                  _HouseMealsMemberView(
                    selectedMember: selectedMember,
                    currentUserId: currentUserId,
                    memberTotalMeals: memberTotalMeals,
                    activeSprint: activeSprint,
                    sprintDays: sprintDays,
                    today: today,
                    state: state,
                    onSelectMember: () => _showMemberPicker(context, members, selectedMember, state),
                    onSelectCycle: () => _showCyclePicker(context, state),
                    onCycleMeal: (userId, type, meal, date) => _cycleMeal(context, userId, type, meal, date),
                    onTapRow: (m, meal, date) => _showEditMealForMemberSheet(context, m, meal, date),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  // ── Helpers & Modals ──────────────────────────────────────────────────────

  void _cycleMeal(
    BuildContext context,
    String userId,
    String mealType,
    MealLog? currentLog,
    DateTime date,
  ) {
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
    );
    if (picked != null && mounted) {
      bloc.add(HouseMealsDateSelected(picked));
    }
  }

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
        context.read<HouseMealsBloc>().add(HouseMealsMemberSelected(userId));
      },
    );
  }
}

extension _SliverSpacer on SizedBox {
  Widget toSliver() => SliverToBoxAdapter(child: this);
}
